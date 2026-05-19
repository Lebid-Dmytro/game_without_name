extends Node
## Tracks resources and validates player decisions per call.

signal resources_changed(guards: int, power: int, comm_stability: int)
signal action_cooldown(active: bool)

const ACTION_IDS := [
	"ignore",
	"dispatch",
	"lock_floor",
	"evacuate",
	"quarantine",
	"cut_power",
]

var guards_available: int = 3
var power_reserve: int = 100
var comm_stability: int = 100
var dispatch_cooldown_sec: float = 0.0

var _last_action: String = ""


func _msg(key: String) -> String:
	return LocaleManager.tr_key(key, key) if LocaleManager else key


func reset_for_shift() -> void:
	guards_available = 3
	power_reserve = 100
	comm_stability = 100
	dispatch_cooldown_sec = 0.0
	_last_action = ""
	_emit_resources()


func _process(delta: float) -> void:
	if dispatch_cooldown_sec > 0.0:
		dispatch_cooldown_sec = maxf(0.0, dispatch_cooldown_sec - delta)
		if dispatch_cooldown_sec <= 0.0:
			action_cooldown.emit(false)


func apply_decision(action_id: String, scenario: CallScenario) -> Dictionary:
	_last_action = action_id
	var result := {
		"action": action_id,
		"correct": action_id in scenario.correct_actions,
		"message": "",
		"threat_delta": 0.0,
	}

	var anomaly: AnomalyDefinition = AnomalyRegistry.get_anomaly(scenario.anomaly_id)
	if anomaly == null and scenario.anomaly_id != "":
		result.message = _msg("decision.unknown_anomaly")
		return result

	match action_id:
		"ignore":
			result = _resolve_ignore(result, scenario, anomaly)
		"dispatch":
			result = _resolve_dispatch(result, scenario, anomaly)
		"lock_floor":
			result = _resolve_lock_floor(result, scenario, anomaly)
		"evacuate":
			result = _resolve_evacuate(result, scenario, anomaly)
		"quarantine":
			result = _resolve_quarantine(result, scenario, anomaly)
		"cut_power":
			result = _resolve_cut_power(result, scenario, anomaly)
		_:
			result.message = _msg("decision.invalid")
			result.correct = false

	ThreatManager.add_threat(result.threat_delta)
	if not result.correct and scenario.anomaly_id != "":
		GameManager.register_death()

	_emit_resources()
	return result


func _resolve_ignore(result: Dictionary, scenario: CallScenario, anomaly: AnomalyDefinition) -> Dictionary:
	if scenario.anomaly_id == "":
		result.message = _msg("decision.ignore_ok")
		result.threat_delta = 1.0
		result.correct = true
		return result

	result.correct = false
	result.threat_delta = anomaly.threat_on_ignore if anomaly else 10.0
	result.message = _msg("decision.ignore_bad")
	return result


func _resolve_dispatch(result: Dictionary, scenario: CallScenario, anomaly: AnomalyDefinition) -> Dictionary:
	if guards_available <= 0:
		result.message = _msg("decision.no_guards")
		result.correct = false
		result.threat_delta = 5.0
		return result

	if dispatch_cooldown_sec > 0.0:
		result.message = _msg("decision.dispatch_busy")
		result.correct = false
		return result

	guards_available -= 1
	dispatch_cooldown_sec = 8.0
	action_cooldown.emit(true)

	if result.correct:
		result.threat_delta = anomaly.threat_on_correct if anomaly else -5.0
		result.message = _msg("decision.dispatch_ok")
	else:
		result.threat_delta = anomaly.threat_on_wrong_action if anomaly else 12.0
		result.message = _msg("decision.dispatch_bad")
	return result


func _resolve_lock_floor(result: Dictionary, scenario: CallScenario, anomaly: AnomalyDefinition) -> Dictionary:
	power_reserve -= 5
	if result.correct:
		result.threat_delta = anomaly.threat_on_correct if anomaly else -6.0
		result.message = _msg("decision.lock_ok")
	else:
		result.threat_delta = anomaly.threat_on_wrong_action if anomaly else 10.0
		result.message = _msg("decision.lock_bad")
	return result


func _resolve_evacuate(result: Dictionary, scenario: CallScenario, anomaly: AnomalyDefinition) -> Dictionary:
	comm_stability -= 10
	if result.correct:
		result.threat_delta = anomaly.threat_on_correct if anomaly else -3.0
		result.message = _msg("decision.evac_ok")
	else:
		result.threat_delta = anomaly.threat_on_wrong_action if anomaly else 15.0
		result.message = _msg("decision.evac_bad")
	return result


func _resolve_quarantine(result: Dictionary, scenario: CallScenario, anomaly: AnomalyDefinition) -> Dictionary:
	if result.correct:
		result.threat_delta = anomaly.threat_on_correct if anomaly else -7.0
		result.message = _msg("decision.quar_ok")
	else:
		result.threat_delta = anomaly.threat_on_wrong_action if anomaly else 8.0
		result.message = _msg("decision.quar_bad")
	return result


func _resolve_cut_power(result: Dictionary, scenario: CallScenario, anomaly: AnomalyDefinition) -> Dictionary:
	power_reserve -= 25
	if result.correct:
		result.threat_delta = anomaly.threat_on_correct if anomaly else -4.0
		result.message = _msg("decision.power_ok")
	else:
		result.threat_delta = anomaly.threat_on_wrong_action if anomaly else 14.0
		result.message = _msg("decision.power_bad")
	return result


func _emit_resources() -> void:
	resources_changed.emit(guards_available, power_reserve, comm_stability)
