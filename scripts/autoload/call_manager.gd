extends Node
## Call queue, scenario loading, active call state + localization / VO.

signal incoming_call(scenario: CallScenario)
signal call_updated(line: String, speaker: String)
signal call_ended()
signal queue_changed(pending: int)
signal all_calls_completed()

var scenarios_per_shift: int = 7
var pending_queue: Array[CallScenario] = []
var active_scenario: CallScenario = null
var is_on_call: bool = false

var _scenario_paths: Array[String] = []
var _night_index: int = 1


func _ready() -> void:
	_discover_scenarios()
	if LocaleManager:
		LocaleManager.locale_changed.connect(_on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	if is_on_call and active_scenario:
		_reemit_current_line()


func _reemit_current_line() -> void:
	# Refresh visible line after language switch (no new VO)
	var line := LocaleManager.call_line(active_scenario.id, "opening", active_scenario.opening_line)
	var name := LocaleManager.call_line(active_scenario.id, "caller_name", active_scenario.caller_name)
	call_updated.emit(line, name)


func _discover_scenarios() -> void:
	_scenario_paths.clear()
	var dir := DirAccess.open("res://dialogue/scenarios")
	if dir == null:
		push_warning("CallManager: dialogue/scenarios folder missing.")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			_scenario_paths.append("res://dialogue/scenarios/%s" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	_scenario_paths.sort()


func start_shift(night: int) -> void:
	_night_index = night
	pending_queue.clear()
	active_scenario = null
	is_on_call = false

	var pool: Array[CallScenario] = []
	for path in _scenario_paths:
		var s := _load_scenario(path)
		if s:
			pool.append(s)

	pool.shuffle()
	var count: int = mini(scenarios_per_shift + night - 1, pool.size())
	for i in count:
		pending_queue.append(pool[i])

	queue_changed.emit(pending_queue.size())
	_schedule_next_call(3.0)


func stop_shift() -> void:
	is_on_call = false
	active_scenario = null
	pending_queue.clear()
	queue_changed.emit(0)
	if VoiceManager:
		VoiceManager.stop()


func _schedule_next_call(delay_sec: float) -> void:
	if not GameManager.is_shift_active:
		return
	var timer := get_tree().create_timer(delay_sec)
	timer.timeout.connect(_try_ring_next)


func _try_ring_next() -> void:
	if is_on_call or not GameManager.is_shift_active:
		return
	if pending_queue.is_empty():
		return
	active_scenario = pending_queue.pop_front()
	is_on_call = true
	queue_changed.emit(pending_queue.size())
	incoming_call.emit(active_scenario)


func answer_call() -> void:
	if active_scenario == null:
		return
	var line := LocaleManager.call_line(active_scenario.id, "opening", active_scenario.opening_line)
	var speaker := LocaleManager.call_line(active_scenario.id, "caller_name", active_scenario.caller_name)
	_emit_dialogue(line, speaker, "opening")
	CctvManager.set_scenario_hint(active_scenario.cctv_camera_id, active_scenario.anomaly_id)


func ask_question(question_id: String) -> void:
	if active_scenario == null:
		return
	for q in active_scenario.questions:
		if q.get("id", "") == question_id:
			var label_fb: String = q.get("label", "")
			var response_fb: String = q.get("response", "...")
			var response := LocaleManager.call_question_response(
				active_scenario.id, question_id, response_fb
			)
			var speaker := LocaleManager.call_line(
				active_scenario.id, "caller_name", active_scenario.caller_name
			)
			_emit_dialogue(response, speaker, "q.%s" % question_id)
			return
	var fail := LocaleManager.tr_key("call.static_fail", "[static] ...could not verify.")
	var speaker := LocaleManager.call_line(active_scenario.id, "caller_name", active_scenario.caller_name)
	_emit_dialogue(fail, speaker, "static_fail")


func _emit_dialogue(line: String, speaker: String, vo_line_id: String) -> void:
	call_updated.emit(line, speaker)
	if VoiceManager and active_scenario:
		VoiceManager.play_call_line(active_scenario, vo_line_id, line)


func end_call_with_decision(action_id: String) -> Dictionary:
	if active_scenario == null:
		return {}

	if active_scenario.anomaly_id != "":
		SaveManager.unlock_anomaly(active_scenario.anomaly_id)

	var result := DecisionManager.apply_decision(action_id, active_scenario)
	GameManager.register_call_resolved()
	GameManager.consequence_message.emit(result.get("message", ""))

	active_scenario = null
	is_on_call = false
	if VoiceManager:
		VoiceManager.stop()
	call_ended.emit()

	if not pending_queue.is_empty():
		_schedule_next_call(randf_range(5.0, 12.0))
	else:
		all_calls_completed.emit()

	return result


func has_pending_calls() -> bool:
	return not pending_queue.is_empty()


func get_tenant_record() -> Dictionary:
	if active_scenario == null:
		return {}
	var truth_key := "ui.truth.verified" if active_scenario.truth_value else "ui.truth.unverified"
	return {
		"name": LocaleManager.call_line(active_scenario.id, "caller_name", active_scenario.caller_name),
		"unit": active_scenario.caller_unit,
		"voice": active_scenario.voice_profile,
		"state": active_scenario.emotional_state,
		"truth": LocaleManager.tr_ui(truth_key),
		"notes": LocaleManager.call_line(active_scenario.id, "notes", active_scenario.notes_for_player),
	}


func _load_scenario(path: String) -> CallScenario:
	if not FileAccess.file_exists(path):
		return null
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("Invalid scenario JSON: %s" % path)
		return null
	return _dict_to_scenario(data)


func _dict_to_scenario(data: Dictionary) -> CallScenario:
	var s := CallScenario.new()
	s.id = data.get("id", "")
	s.caller_name = data.get("caller_name", "Unknown")
	s.caller_unit = data.get("caller_unit", "—")
	s.voice_profile = data.get("voice_profile", "")
	s.emotional_state = data.get("emotional_state", "")
	s.truth_value = data.get("truth_value", true)
	s.opening_line = data.get("opening_line", "")
	s.anomaly_id = data.get("anomaly_id", "")
	s.cctv_camera_id = data.get("cctv_camera_id", "")
	s.notes_for_player = data.get("notes_for_player", "")

	var type_str: String = data.get("call_type", "suspicious")
	match type_str:
		"normal":
			s.call_type = CallScenario.CallType.NORMAL
		"active_anomaly":
			s.call_type = CallScenario.CallType.ACTIVE_ANOMALY
		"mimic":
			s.call_type = CallScenario.CallType.MIMIC
		_:
			s.call_type = CallScenario.CallType.SUSPICIOUS

	var actions: Array = data.get("correct_actions", [])
	for a in actions:
		s.correct_actions.append(str(a))

	var questions: Array = data.get("questions", [])
	for q in questions:
		if q is Dictionary:
			s.questions.append(q)

	return s
