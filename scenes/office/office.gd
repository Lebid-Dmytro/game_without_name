extends Control

@onready var threat_meter: ProgressBar = %ThreatMeter
@onready var threat_label: Label = %ThreatLabel
@onready var shift_timer_label: Label = %ShiftTimerLabel
@onready var phone_panel: PanelContainer = %PhonePanel
@onready var call_status_label: Label = %CallStatusLabel
@onready var dialogue_label: Label = %DialogueLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var answer_button: Button = %AnswerButton
@onready var question_list: VBoxContainer = %QuestionList
@onready var cctv_label: Label = %CctvLabel
@onready var cctv_desc: RichTextLabel = %CctvDesc
@onready var cam_prev_button: Button = %CamPrevButton
@onready var cam_next_button: Button = %CamNextButton
@onready var tenant_name: Label = %TenantName
@onready var tenant_details: RichTextLabel = %TenantDetails
@onready var consequence_log: RichTextLabel = %ConsequenceLog
@onready var pause_menu: PanelContainer = %PauseMenu
@onready var shift_end_panel: PanelContainer = %ShiftEndPanel
@onready var shift_end_text: Label = %ShiftEndText
@onready var dispatch_label: Label = %DispatchLabel

var _ringing: bool = false
var _call_connected: bool = false
var _question_ids: Array[String] = ["location", "appearance", "timeline", "camera"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_diegetic_ui_style()
	_connect_signals()
	_build_question_buttons()
	_build_dispatch_buttons()
	_apply_static_ui_text()
	_refresh_cctv()
	_refresh_threat()
	_update_shift_timer()
	pause_menu.hide()
	shift_end_panel.hide()

	if LocaleManager:
		LocaleManager.locale_changed.connect(_on_locale_changed)
	if VoiceManager:
		VoiceManager.line_started.connect(_on_vo_started)
		VoiceManager.line_finished.connect(_on_vo_finished)

	GameManager.start_shift(1)
	call_status_label.text = _tr("ui.office.awaiting_call")


func _tr(key: String) -> String:
	return LocaleManager.tr_ui(key) if LocaleManager else key


func _on_locale_changed(_locale: String) -> void:
	_apply_static_ui_text()
	_update_question_button_labels()
	_update_dispatch_button_labels()
	_refresh_cctv()
	_refresh_threat()
	_refresh_tenant()
	_update_shift_timer()
	if CallManager.is_on_call and CallManager.active_scenario:
		CallManager._reemit_current_line()


func _apply_static_ui_text() -> void:
	cctv_label.text = _tr("ui.office.cctv")
	cam_prev_button.text = _tr("ui.office.cam_prev")
	cam_next_button.text = _tr("ui.office.cam_next")
	answer_button.text = _tr("ui.office.answer")
	dispatch_label.text = _tr("ui.office.dispatch")
	%ResumeButton.text = _tr("ui.office.resume")
	%MainMenuButton.text = _tr("ui.office.main_menu")
	%ShiftEndMenuButton.text = _tr("ui.office.return_menu")
	%PauseTitle.text = _tr("ui.office.paused")
	consequence_log.text = _tr("ui.office.log_ready")


func _apply_diegetic_ui_style() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.08, 0.9)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.22, 0.24, 0.3, 0.9)
	panel_style.corner_radius_top_left = 2
	panel_style.corner_radius_top_right = 2
	panel_style.corner_radius_bottom_right = 2
	panel_style.corner_radius_bottom_left = 2

	for node in find_children("*", "PanelContainer", true, false):
		var p := node as PanelContainer
		p.add_theme_stylebox_override("panel", panel_style.duplicate())


func _connect_signals() -> void:
	CallManager.incoming_call.connect(_on_incoming_call)
	CallManager.call_updated.connect(_on_call_updated)
	CallManager.call_ended.connect(_on_call_ended)
	CallManager.queue_changed.connect(_on_queue_changed)
	CallManager.all_calls_completed.connect(_on_all_calls_completed)
	ThreatManager.critical_warning.connect(_on_critical_warning)
	CctvManager.camera_changed.connect(_on_camera_changed)
	CctvManager.feed_updated.connect(_on_feed_updated)
	ThreatManager.level_changed.connect(_on_threat_changed)
	GameManager.consequence_message.connect(_on_consequence)
	GameManager.shift_ended.connect(_on_shift_ended)
	GameManager.game_paused.connect(_on_game_paused)

	answer_button.pressed.connect(_on_answer_pressed)
	cam_prev_button.pressed.connect(_on_cam_prev)
	cam_next_button.pressed.connect(_on_cam_next)

	%ResumeButton.pressed.connect(_on_resume)
	%MainMenuButton.pressed.connect(_on_main_menu)
	%ShiftEndMenuButton.pressed.connect(_on_main_menu)


func _build_question_buttons() -> void:
	for child in question_list.get_children():
		child.queue_free()
	for qid in _question_ids:
		var btn := Button.new()
		btn.set_meta("question_id", qid)
		btn.text = _tr("ui.question.%s" % qid)
		btn.pressed.connect(_on_question.bind(qid))
		question_list.add_child(btn)


func _update_question_button_labels() -> void:
	for btn in question_list.get_children():
		if btn is Button and btn.has_meta("question_id"):
			var qid: String = btn.get_meta("question_id")
			btn.text = _tr("ui.question.%s" % qid)


func _build_dispatch_buttons() -> void:
	var container: VBoxContainer = %DispatchButtons
	for child in container.get_children():
		child.queue_free()
	for action in DecisionManager.ACTION_IDS:
		var btn := Button.new()
		btn.set_meta("action_id", action)
		btn.text = _tr("ui.action.%s" % action)
		btn.pressed.connect(_on_decision.bind(action))
		container.add_child(btn)


func _update_dispatch_button_labels() -> void:
	for btn in %DispatchButtons.get_children():
		if btn is Button and btn.has_meta("action_id"):
			btn.text = _tr("ui.action.%s" % btn.get_meta("action_id"))


func _on_vo_started(_sid: String, _lid: String) -> void:
	_set_call_controls_enabled(false)


func _on_vo_finished() -> void:
	_set_call_controls_enabled(_call_connected)


func _set_call_controls_enabled(enabled: bool) -> void:
	for btn in question_list.get_children():
		if btn is Button:
			btn.disabled = not enabled
	for btn in %DispatchButtons.get_children():
		if btn is Button:
			btn.disabled = not enabled


func _on_question(id: String) -> void:
	if VoiceManager and VoiceManager.is_playing():
		return
	AudioManager.play_ui_tick()
	CallManager.ask_question(id)


func _on_cam_prev() -> void:
	CctvManager.switch_camera(-1)


func _on_cam_next() -> void:
	CctvManager.switch_camera(1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		if GameManager.state == GameManager.GameState.PLAYING:
			GameManager.pause_game()
			pause_menu.show()
		elif GameManager.state == GameManager.GameState.PAUSED:
			_on_resume()


func _process(_delta: float) -> void:
	_update_shift_timer()


func _on_incoming_call(_scenario: CallScenario) -> void:
	var scenario := CallManager.active_scenario
	if scenario == null:
		return
	_ringing = true
	_call_connected = false
	var name := LocaleManager.call_line(scenario.id, "caller_name", scenario.caller_name)
	call_status_label.text = "%s: %s (%s)" % [_tr("ui.office.incoming"), name, scenario.caller_unit]
	dialogue_label.text = _tr("ui.office.ringing")
	subtitle_label.text = _tr("ui.office.static")
	answer_button.disabled = false
	phone_panel.modulate = Color(1.15, 0.88, 0.88)


func _on_answer_pressed() -> void:
	if not _ringing and CallManager.active_scenario == null:
		return
	_ringing = false
	_call_connected = true
	answer_button.disabled = true
	phone_panel.modulate = Color.WHITE
	AudioManager.stop_ring()
	CallManager.answer_call()
	_refresh_tenant()


func _on_call_updated(line: String, speaker: String) -> void:
	dialogue_label.text = "%s: \"%s\"" % [speaker, line]
	if SettingsManager.subtitles_enabled:
		subtitle_label.text = line
	else:
		subtitle_label.text = ""


func _on_call_ended() -> void:
	_call_connected = false
	_set_call_controls_enabled(false)
	call_status_label.text = _tr("ui.office.line_closed")
	dialogue_label.text = ""
	subtitle_label.text = ""
	_refresh_tenant()
	_refresh_cctv()


func _on_queue_changed(pending: int) -> void:
	%QueueLabel.text = "%s: %d" % [_tr("ui.office.queue"), pending]
	if pending > 0:
		GameManager.all_calls_received = false


func _on_all_calls_completed() -> void:
	GameManager.mark_all_calls_received()
	call_status_label.text = _tr("ui.office.shift_hold")
	%QueueLabel.text = _tr("ui.office.queue_done")


func _on_critical_warning() -> void:
	GameManager.consequence_message.emit(_tr("game.threat.warning"))
	phone_panel.modulate = Color(1.1, 0.75, 0.75)


func _on_decision(action_id: String) -> void:
	if VoiceManager and VoiceManager.is_playing():
		return
	AudioManager.play_ui_tick()
	if CallManager.active_scenario == null:
		GameManager.consequence_message.emit(_tr("game.msg.no_call"))
		return
	if not _call_connected:
		GameManager.consequence_message.emit(_tr("game.msg.answer_first"))
		return
	CallManager.end_call_with_decision(action_id)


func _on_camera_changed(_camera_id: String) -> void:
	_refresh_cctv()


func _on_feed_updated(_camera_id: String, _feed: Dictionary) -> void:
	_refresh_cctv()


func _on_threat_changed(level: float, band: String) -> void:
	threat_meter.value = level
	var band_txt := _tr("ui.band.%s" % band)
	threat_label.text = "%s: %.0f%% (%s)" % [_tr("ui.office.anomaly"), level, band_txt]
	var col := Color(0.3, 0.7, 0.35)
	if band == "medium":
		col = Color(0.85, 0.75, 0.2)
	elif band == "high":
		col = Color(0.95, 0.45, 0.2)
	elif band == "critical":
		col = Color(0.95, 0.2, 0.2)
	threat_label.add_theme_color_override("font_color", col)


func _on_consequence(text: String) -> void:
	consequence_log.append_text("\n• " + text)


func _on_shift_ended(ending_id: String) -> void:
	shift_end_panel.show()
	shift_end_text.text = _ending_message(ending_id)


func _on_game_paused(paused: bool) -> void:
	if not paused:
		pause_menu.hide()


func _on_resume() -> void:
	GameManager.resume_game()
	pause_menu.hide()


func _on_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _refresh_cctv() -> void:
	var feed := CctvManager.get_active_feed()
	if feed.is_empty():
		return
	cctv_label.text = feed.get("label", "CAM —")
	var desc: String = feed.get("description", "")
	if feed.get("anomaly_visible", false):
		desc = "[color=#ff6666]%s[/color]\n%s" % [_tr("cctv.anomaly"), desc]
	cctv_desc.text = desc


func _refresh_threat() -> void:
	_on_threat_changed(ThreatManager.level, ThreatManager.get_band())


func _refresh_tenant() -> void:
	var rec := CallManager.get_tenant_record()
	if rec.is_empty():
		tenant_name.text = _tr("ui.office.no_call")
		tenant_details.text = _tr("ui.office.awaiting_data")
		return
	tenant_name.text = "%s / %s" % [rec.get("name", ""), rec.get("unit", "")]
	var verified: bool = CallManager.active_scenario.truth_value if CallManager.active_scenario else true
	var truth_col := "#6a6" if verified else "#a66"
	tenant_details.text = (
		"%s: %s\n%s: %s\n%s: [color=%s]%s[/color]\n\n[color=#888]%s:[/color] %s"
		% [
			_tr("ui.tenant.voice"), rec.get("voice", ""),
			_tr("ui.tenant.state"), rec.get("state", ""),
			_tr("ui.tenant.truth"), truth_col, rec.get("truth", ""),
			_tr("ui.tenant.note"), rec.get("notes", ""),
		]
	)


func _update_shift_timer() -> void:
	var mins := int(GameManager.shift_time_remaining) / 60
	var secs := int(GameManager.shift_time_remaining) % 60
	shift_timer_label.text = "%s: %02d:%02d" % [_tr("ui.office.shift"), mins, secs]


func _ending_message(ending_id: String) -> String:
	match ending_id:
		"good_containment":
			return _tr("game.end.good")
		"bad_collapse":
			return _tr("game.end.bad")
		"neutral_survived":
			return _tr("game.end.neutral")
		_:
			return _tr("game.end.default")
