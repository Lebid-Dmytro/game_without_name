extends SubViewportContainer
## Applies CRT shader uniforms from active CCTV feed + threat.

@onready var _shader: Shader = preload("res://shaders/crt_cctv.gdshader")


func _ready() -> void:
	stretch = true
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	material = mat
	CctvManager.camera_changed.connect(func(_id): _update_uniforms())
	CctvManager.feed_updated.connect(func(_a, _b): _update_uniforms())
	ThreatManager.level_changed.connect(func(_l, _b): _update_uniforms())
	_update_uniforms()


func _process(_delta: float) -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("noise_intensity", 0.06 + randf() * 0.03)


func _update_uniforms() -> void:
	if not material is ShaderMaterial:
		return
	var mat := material as ShaderMaterial
	var feed := CctvManager.get_active_feed()
	var corruption: float = feed.get("corruption", 0.1)
	if feed.get("anomaly_visible", false):
		corruption += 0.15
	corruption += ThreatManager.level * 0.002
	mat.set_shader_parameter("corruption", corruption)
	mat.set_shader_parameter("scanline_intensity", 0.22)
	mat.set_shader_parameter("vignette", 0.4)
