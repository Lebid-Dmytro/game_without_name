extends Node
## Global anomaly meter 0-100.

signal level_changed(level: float, band: String)
signal critical_warning()  # Emitted once when crossing 80%

const CRITICAL_THRESHOLD := 90.0
const WARNING_THRESHOLD := 80.0
const HIGH_THRESHOLD := 70.0
const MEDIUM_THRESHOLD := 40.0

var level: float = 12.0
var _warned: bool = false


func reset_for_shift() -> void:
	level = 10.0 + float(GameManager.night_index - 1) * 3.0
	_warned = false
	_emit()


func add_threat(amount: float) -> void:
	var prev := level
	level = clampf(level + amount, 0.0, 100.0)
	_emit()
	if not _warned and prev < WARNING_THRESHOLD and level >= WARNING_THRESHOLD:
		_warned = true
		critical_warning.emit()
	if level >= CRITICAL_THRESHOLD:
		if LocaleManager:
			GameManager.consequence_message.emit(LocaleManager.tr_key("game.threat.collapse", ""))
		GameManager.end_shift("bad_collapse")


func reduce_threat(amount: float) -> void:
	add_threat(-amount)


func is_critical() -> bool:
	return level >= CRITICAL_THRESHOLD


func get_band() -> String:
	if level >= CRITICAL_THRESHOLD:
		return "critical"
	if level >= HIGH_THRESHOLD:
		return "high"
	if level >= MEDIUM_THRESHOLD:
		return "medium"
	return "low"


func _emit() -> void:
	level_changed.emit(level, get_band())
