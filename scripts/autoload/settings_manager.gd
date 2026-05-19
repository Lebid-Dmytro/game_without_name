extends Node
## Steam-ready settings: display, audio, subtitles.

signal applied

const SETTINGS_PATH := "user://settings.json"

var fullscreen: bool = false
var master_volume: float = 0.8
var sfx_volume: float = 0.8
var music_volume: float = 0.5
var subtitles_enabled: bool = true
var mouse_sensitivity: float = 1.0
var locale: String = "uk"
var vo_enabled: bool = true
var vo_volume: float = 0.85


func _ready() -> void:
	load_settings()
	apply_all()


func apply_all() -> void:
	_apply_display()
	_apply_audio()
	if LocaleManager:
		LocaleManager.set_locale(locale)
	applied.emit()


func _apply_display() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _apply_audio() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	var amb := AudioServer.get_bus_index("Ambient")
	var sfx := AudioServer.get_bus_index("SFX")
	var mus := AudioServer.get_bus_index("Music")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume))
	if amb >= 0:
		AudioServer.set_bus_volume_db(amb, linear_to_db(sfx_volume * 0.7))
	if sfx >= 0:
		AudioServer.set_bus_volume_db(sfx, linear_to_db(sfx_volume))
	if mus >= 0:
		AudioServer.set_bus_volume_db(mus, linear_to_db(music_volume))
	if VoiceManager:
		VoiceManager.apply_volume()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_display()
	save_settings()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	applied.emit()
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	applied.emit()
	save_settings()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	applied.emit()
	save_settings()


func set_locale(new_locale: String) -> void:
	locale = new_locale if new_locale in ["en", "uk"] else "en"
	if LocaleManager:
		LocaleManager.set_locale(locale)
	save_settings()


func set_vo_enabled(enabled: bool) -> void:
	vo_enabled = enabled
	if VoiceManager:
		VoiceManager.vo_enabled = enabled
	applied.emit()
	save_settings()


func set_vo_volume(value: float) -> void:
	vo_volume = clampf(value, 0.0, 1.0)
	if VoiceManager:
		VoiceManager.vo_volume = vo_volume
	_apply_audio()
	applied.emit()
	save_settings()


func save_settings() -> void:
	var payload := {
		"fullscreen": fullscreen,
		"master_volume": master_volume,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
		"subtitles_enabled": subtitles_enabled,
		"mouse_sensitivity": mouse_sensitivity,
		"locale": locale,
		"vo_enabled": vo_enabled,
		"vo_volume": vo_volume,
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload, "\t"))
		file.close()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	fullscreen = parsed.get("fullscreen", false)
	master_volume = parsed.get("master_volume", 0.8)
	sfx_volume = parsed.get("sfx_volume", 0.8)
	music_volume = parsed.get("music_volume", 0.5)
	subtitles_enabled = parsed.get("subtitles_enabled", true)
	mouse_sensitivity = parsed.get("mouse_sensitivity", 1.0)
	locale = parsed.get("locale", "en")
	vo_enabled = parsed.get("vo_enabled", true)
	vo_volume = parsed.get("vo_volume", 0.85)
