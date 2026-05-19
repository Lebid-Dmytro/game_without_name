extends Node3D
## Procedural PS1-style hotline office — built at runtime.

signal environment_ready

@export var desk_lamp_path: NodePath = NodePath("../DeskLamp")

var desk_lamp: OmniLight3D


func _ready() -> void:
	desk_lamp = get_node_or_null(desk_lamp_path) as OmniLight3D
	_build_room()
	_build_desk_set()
	ThreatManager.level_changed.connect(_on_threat_changed)
	CallManager.incoming_call.connect(_on_incoming_call)
	CallManager.call_ended.connect(_on_call_ended)
	_on_threat_changed(ThreatManager.level, ThreatManager.get_band())
	environment_ready.emit()


func _build_room() -> void:
	# Floor
	_add_box(Vector3(5.0, 0.1, 4.5), Vector3(0, -0.05, 1.2), _mat(Color(0.07, 0.07, 0.08)))
	# Ceiling
	_add_box(Vector3(5.0, 0.08, 4.5), Vector3(0, 2.45, 1.2), _mat(Color(0.05, 0.05, 0.06)))
	# Back wall
	_add_box(Vector3(5.0, 2.5, 0.12), Vector3(0, 1.25, -0.95), _mat(Color(0.09, 0.09, 0.11)))
	# Side walls
	_add_box(Vector3(0.12, 2.5, 4.5), Vector3(-2.45, 1.25, 1.2), _mat(Color(0.08, 0.08, 0.1)))
	_add_box(Vector3(0.12, 2.5, 4.5), Vector3(2.45, 1.25, 1.2), _mat(Color(0.08, 0.08, 0.1)))
	# Window recess (dark)
	_add_box(Vector3(1.8, 1.0, 0.06), Vector3(0, 1.55, -0.88), _mat(Color(0.02, 0.03, 0.05)))
	# Cable conduit along wall
	_add_box(Vector3(0.04, 0.04, 3.0), Vector3(-2.38, 0.4, 1.0), _mat(Color(0.04, 0.04, 0.05)))


func _build_desk_set() -> void:
	var desk_y := 0.72
	# Desktop
	_add_box(Vector3(1.65, 0.06, 0.75), Vector3(0, desk_y, 0.55), _mat(Color(0.12, 0.1, 0.08)))
	# Leg panel
	_add_box(Vector3(1.5, 0.55, 0.55), Vector3(0, desk_y - 0.28, 0.58), _mat(Color(0.08, 0.07, 0.06)))
	# Chair back (player POV — barely visible at bottom)
	_add_box(Vector3(0.5, 0.45, 0.06), Vector3(0, 0.55, 1.05), _mat(Color(0.06, 0.05, 0.05)))

	# Left monitor (CCTV) — angled
	var mon_l := _add_box(Vector3(0.42, 0.32, 0.06), Vector3(-0.48, desk_y + 0.22, 0.38), _mat_monitor())
	mon_l.rotation_degrees = Vector3(-8, 18, 0)
	# Main monitor
	var mon_m := _add_box(Vector3(0.52, 0.38, 0.06), Vector3(0.08, desk_y + 0.24, 0.32), _mat_monitor())
	mon_m.rotation_degrees = Vector3(-10, 0, 0)
	# Phone cradle area
	_add_box(Vector3(0.18, 0.05, 0.14), Vector3(0.42, desk_y + 0.06, 0.52), _mat(Color(0.15, 0.14, 0.13)))
	# Papers
	for i in 3:
		_add_box(
			Vector3(0.18 + randf() * 0.05, 0.01, 0.12),
			Vector3(-0.15 + i * 0.12, desk_y + 0.04, 0.62 + randf() * 0.08),
			_mat(Color(0.18, 0.17, 0.14))
		)
	# Keyboard slab
	_add_box(Vector3(0.38, 0.02, 0.14), Vector3(-0.05, desk_y + 0.04, 0.48), _mat(Color(0.05, 0.05, 0.06)))

	# Emergency strip light (ceiling)
	_add_box(Vector3(0.8, 0.03, 0.08), Vector3(0, 2.38, 0.2), _mat_emissive(Color(0.35, 0.4, 0.32), 0.4))


func _add_box(size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.position = pos
	mesh_inst.material_override = material
	add_child(mesh_inst)
	return mesh_inst


func _mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


func _mat_monitor() -> StandardMaterial3D:
	var m := _mat(Color(0.04, 0.05, 0.04))
	m.emission_enabled = true
	m.emission = Color(0.08, 0.18, 0.1)
	m.emission_energy_multiplier = 0.35
	return m


func _mat_emissive(col: Color, energy: float) -> StandardMaterial3D:
	var m := _mat(col)
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	return m


func _on_threat_changed(level: float, band: String) -> void:
	if desk_lamp == null:
		return
	var t := level / 100.0
	match band:
		"critical", "high":
			desk_lamp.light_color = Color(0.95, 0.45, 0.35)
			desk_lamp.light_energy = 0.55 + t * 0.5
		"medium":
			desk_lamp.light_color = Color(0.9, 0.72, 0.5)
			desk_lamp.light_energy = 0.65
		_:
			desk_lamp.light_color = Color(0.85, 0.78, 0.62)
			desk_lamp.light_energy = 0.75


func _on_incoming_call(_s: CallScenario) -> void:
	if desk_lamp:
		var tw := create_tween()
		tw.set_loops(6)
		tw.tween_property(desk_lamp, "light_energy", 1.2, 0.08)
		tw.tween_property(desk_lamp, "light_energy", 0.4, 0.08)


func _on_call_ended() -> void:
	_on_threat_changed(ThreatManager.level, ThreatManager.get_band())
