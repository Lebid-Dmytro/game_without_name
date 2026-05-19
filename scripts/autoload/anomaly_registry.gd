extends Node
## Loads anomaly definitions for threat/decision resolution.

var _anomalies: Dictionary = {}


func _ready() -> void:
	_register_defaults()


func _register_defaults() -> void:
	_register(_make(
		"faceless_tenant",
		"Faceless tenant",
		"Subject lacks facial features under lobby lighting.",
		"CAM: Figure facing camera. Face region flat / absent.",
		10.0, 14.0, -6.0
	))
	_register(_make(
		"wrong_apartment_number",
		"Wrong apartment number",
		"Door plaque does not match building records.",
		"CAM: Unit label reads 4B but directory shows 4C.",
		7.0, 9.0, -5.0
	))
	_register(_make(
		"endless_staircase",
		"Endless staircase",
		"Stairwell segment repeats beyond architectural limit.",
		"CAM: Same landing appears twice in one feed.",
		9.0, 11.0, -5.0
	))
	_register(_make(
		"duplicate_person",
		"Duplicate person",
		"Same individual visible on two feeds simultaneously.",
		"CAM: Identical clothing on Floor 2 and Floor 4.",
		11.0, 13.0, -7.0
	))
	_register(_make(
		"corridor_expansion",
		"Corridor expansion",
		"Hallway length exceeds blueprint by ~40%.",
		"CAM: Corridor vanishing point farther than yesterday.",
		8.0, 10.0, -4.0
	))
	_register(_make(
		"fake_child_voice",
		"Fake child voice",
		"Caller profile does not match vocal signature.",
		"CAM: Small figure. Movement pattern non-childlike.",
		12.0, 15.0, -8.0
	))


func _make(
	id: String,
	display_name: String,
	description: String,
	cctv_hint: String,
	on_ignore: float,
	on_wrong: float,
	on_correct: float
) -> AnomalyDefinition:
	var a := AnomalyDefinition.new()
	a.id = id
	a.display_name = display_name
	a.description = description
	a.cctv_hint = cctv_hint
	a.threat_on_ignore = on_ignore
	a.threat_on_wrong_action = on_wrong
	a.threat_on_correct = on_correct
	return a


func _register(anomaly: AnomalyDefinition) -> void:
	_anomalies[anomaly.id] = anomaly


func get_anomaly(id: String) -> AnomalyDefinition:
	return _anomalies.get(id, null)


func get_all_ids() -> Array:
	return _anomalies.keys()
