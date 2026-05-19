extends Control
## Subtle desk lamp flicker + screen glow pulse tied to threat level.

@export var flicker_strength: float = 0.04

var _base_color: Color = Color(0.03, 0.03, 0.05)
var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ThreatManager:
		ThreatManager.level_changed.connect(_on_threat_changed)


func _process(delta: float) -> void:
	_pulse += delta
	var flicker := sin(_pulse * 7.3) * flicker_strength + sin(_pulse * 13.1) * flicker_strength * 0.5
	var threat := ThreatManager.level / 100.0 if ThreatManager else 0.0
	var r := _base_color.r + flicker + threat * 0.02
	var g := _base_color.g + flicker * 0.5
	var b := _base_color.b + flicker * 0.3 - threat * 0.01
	modulate = Color(r, g, b, 1.0)


func _on_threat_changed(level: float, band: String) -> void:
	if band == "critical" or band == "high":
		_base_color = Color(0.05, 0.02, 0.03)
	elif band == "medium":
		_base_color = Color(0.04, 0.03, 0.04)
	else:
		_base_color = Color(0.03, 0.03, 0.05)
