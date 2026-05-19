extends Node3D
## 3D office shell + instanced gameplay UI overlay.

const UI_SCENE := preload("res://scenes/office/office_ui.tscn")

@onready var desk_camera: Camera3D = $DeskCamera
@onready var desk_lamp: OmniLight3D = $DeskLamp

var _cam_base_pos: Vector3
var _cam_base_rot: Vector3
var _breath: float = 0.0


func _ready() -> void:
	_cam_base_pos = desk_camera.position
	_cam_base_rot = desk_camera.rotation_degrees

	var ui := UI_SCENE.instantiate()
	$GameUI.add_child(ui)

	# Slight film grain feel via dim world
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.08, 0.09, 0.12)
	env.ambient_light_energy = 0.35
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.06, 0.08)
	env.fog_density = 0.08
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	$WorldEnvironment.environment = env


func _process(delta: float) -> void:
	if GameManager.state == GameManager.GameState.PAUSED:
		return
	_breath += delta
	var sway := sin(_breath * 0.55) * 0.004
	var bob := sin(_breath * 1.1) * 0.003
	desk_camera.position = _cam_base_pos + Vector3(sway, bob, 0)
	desk_camera.rotation_degrees.x = _cam_base_rot.x + sin(_breath * 0.35) * 0.4
