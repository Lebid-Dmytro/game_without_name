extends Node
## VO playback: real OGG files when present, else procedural placeholder.

signal line_started(scenario_id: String, line_id: String)
signal line_finished()

const VO_BUS := "VO"
const VO_ROOT := "res://audio/vo"

var vo_enabled: bool = true
var vo_volume: float = 0.85

var _player: AudioStreamPlayer
var _playing: bool = false


func is_playing() -> bool:
	return _playing


func _ready() -> void:
	_ensure_vo_bus()
	_player = AudioStreamPlayer.new()
	_player.bus = VO_BUS
	_player.finished.connect(_on_finished)
	add_child(_player)
	if SettingsManager:
		vo_enabled = SettingsManager.vo_enabled
		vo_volume = SettingsManager.vo_volume
		SettingsManager.applied.connect(_on_settings_applied)
	apply_volume()


func apply_volume() -> void:
	_apply_volume()


func _ensure_vo_bus() -> void:
	if AudioServer.get_bus_index(VO_BUS) >= 0:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, VO_BUS)
	AudioServer.set_bus_send(idx, "Master")


func _on_settings_applied() -> void:
	vo_enabled = SettingsManager.vo_enabled
	vo_volume = SettingsManager.vo_volume
	_apply_volume()


func _apply_volume() -> void:
	var idx := AudioServer.get_bus_index(VO_BUS)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(vo_volume * SettingsManager.master_volume))


func stop() -> void:
	if _player.playing:
		_player.stop()
	_playing = false


func play_call_line(scenario: CallScenario, line_id: String, text: String) -> void:
	if not vo_enabled or text.strip_edges() == "":
		line_finished.emit()
		return

	stop()
	var stream := _load_vo_file(scenario.id, line_id)
	if stream == null:
		stream = ProceduralVoice.synthesize_line(text, scenario.voice_profile)

	_player.stream = stream
	_player.play()
	_playing = true
	line_started.emit(scenario.id, line_id)
	_apply_volume()


func _load_vo_file(scenario_id: String, line_id: String) -> AudioStream:
	var locale := LocaleManager.current_locale if LocaleManager else "en"
	for loc in [locale, "en"]:
		for ext in ["ogg", "wav"]:
			var path := "%s/%s/%s/%s.%s" % [VO_ROOT, loc, scenario_id, line_id, ext]
			if ResourceLoader.exists(path):
				return load(path) as AudioStream
	return null


func _on_finished() -> void:
	_playing = false
	line_finished.emit()
