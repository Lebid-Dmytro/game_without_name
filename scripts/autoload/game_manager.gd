extends Node
## Central game state: shift flow, timers, win/lose.

signal shift_started(night_index: int)
signal shift_ended(ending_id: String)
signal game_paused(is_paused: bool)
signal consequence_message(text: String)

enum GameState { MENU, BRIEFING, PLAYING, PAUSED, SHIFT_END }

const SHIFT_DURATION_SEC := 600.0  # 10 min prototype; set 1200–2400 for full MVP shift

var state: GameState = GameState.MENU
var night_index: int = 1
var shift_time_remaining: float = SHIFT_DURATION_SEC
var death_count: int = 0
var calls_handled: int = 0
var is_shift_active: bool = false

var _ending_triggered: bool = false
var all_calls_received: bool = false


func start_shift(night: int = 1) -> void:
	night_index = night
	shift_time_remaining = SHIFT_DURATION_SEC
	death_count = 0
	calls_handled = 0
	_ending_triggered = false
	all_calls_received = false
	is_shift_active = true
	state = GameState.PLAYING

	ThreatManager.reset_for_shift()
	DecisionManager.reset_for_shift()
	CallManager.start_shift(night)
	CctvManager.reset_for_shift()

	shift_started.emit(night_index)


func end_shift(ending_id: String = "neutral") -> void:
	if _ending_triggered:
		return
	_ending_triggered = true
	is_shift_active = false
	state = GameState.SHIFT_END
	CallManager.stop_shift()
	shift_ended.emit(ending_id)
	SaveManager.record_shift_complete(night_index, ending_id, ThreatManager.level)


func pause_game() -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.PAUSED
	get_tree().paused = true
	game_paused.emit(true)


func resume_game() -> void:
	if state != GameState.PAUSED:
		return
	state = GameState.PLAYING
	get_tree().paused = false
	game_paused.emit(false)


func register_call_resolved() -> void:
	calls_handled += 1


func mark_all_calls_received() -> void:
	all_calls_received = true
	if LocaleManager:
		consequence_message.emit(LocaleManager.tr_key("game.shift.all_calls_done", ""))


func register_death() -> void:
	death_count += 1
	var msg := "Resident status: DECEASED. Incident logged."
	if LocaleManager:
		msg = LocaleManager.tr_key("game.death", msg)
	consequence_message.emit(msg)


func _process(delta: float) -> void:
	if not is_shift_active or state == GameState.PAUSED:
		return

	shift_time_remaining -= delta
	_check_end_conditions()

	# Slow creep while monitoring after all calls (tension during quiet phase)
	if all_calls_received and CallManager.pending_queue.is_empty():
		ThreatManager.add_threat(delta * 0.35)

	if shift_time_remaining <= 0.0:
		_resolve_shift_by_threat()


func _check_end_conditions() -> void:
	if ThreatManager.is_critical():
		end_shift("bad_collapse")
	elif ThreatManager.level <= 15.0 and calls_handled >= CallManager.scenarios_per_shift:
		end_shift("good_containment")


func _resolve_shift_by_threat() -> void:
	if ThreatManager.level >= 70.0:
		end_shift("bad_collapse")
	elif ThreatManager.level <= 40.0:
		end_shift("good_containment")
	else:
		end_shift("neutral_survived")
