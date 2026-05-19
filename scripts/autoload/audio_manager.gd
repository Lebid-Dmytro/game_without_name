extends Node
## Ambient layers, phone SFX, threat-reactive drone.

var _ambient: AudioStreamPlayer
var _music: AudioStreamPlayer
var _ring_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _ringing: bool = false
var _distant_timer: float = 0.0


func _ready() -> void:
	_ambient = _make_player("Ambient")
	_music = _make_player("Music")
	_ring_player = _make_player("SFX")
	for i in 4:
		_sfx_players.append(_make_player("SFX"))

	_ambient.stream = ProceduralSfx.ambient_hum()
	_ambient.volume_db = -8.0
	_ambient.play()

	_update_drone(0.12)
	_connect_signals()
	_apply_volumes()


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _connect_signals() -> void:
	CallManager.incoming_call.connect(_on_incoming_call)
	CallManager.call_updated.connect(_on_call_updated)
	CallManager.call_ended.connect(_on_call_ended)
	CctvManager.camera_changed.connect(_on_camera_changed)
	ThreatManager.level_changed.connect(_on_threat_changed)
	GameManager.consequence_message.connect(_on_consequence)
	SettingsManager.applied.connect(_apply_volumes)


func _process(delta: float) -> void:
	if not GameManager.is_shift_active:
		return
	_distant_timer -= delta
	if _distant_timer <= 0.0:
		_distant_timer = randf_range(18.0, 45.0)
		if randf() < 0.35 + ThreatManager.level * 0.004:
			_play_sfx(ProceduralSfx.distant_thud(), -6.0)


func _apply_volumes() -> void:
	var master := AudioServer.get_bus_index("Master")
	var amb := AudioServer.get_bus_index("Ambient")
	var sfx := AudioServer.get_bus_index("SFX")
	var mus := AudioServer.get_bus_index("Music")
	if master >= 0:
		AudioServer.set_bus_volume_db(master, linear_to_db(SettingsManager.master_volume))
	if amb >= 0:
		AudioServer.set_bus_volume_db(amb, linear_to_db(SettingsManager.sfx_volume * 0.7))
	if sfx >= 0:
		AudioServer.set_bus_volume_db(sfx, linear_to_db(SettingsManager.sfx_volume))
	if mus >= 0:
		AudioServer.set_bus_volume_db(mus, linear_to_db(SettingsManager.music_volume))


func _on_incoming_call(_scenario: CallScenario) -> void:
	_ringing = true
	_ring_player.stream = ProceduralSfx.phone_ring_loop()
	_ring_player.volume_db = -4.0
	_ring_player.play()


func stop_ring() -> void:
	if _ringing:
		_ringing = false
		_ring_player.stop()
		_play_sfx(ProceduralSfx.phone_static_burst(0.2, 0.28), -2.0)


func _on_call_updated(_line: String, _speaker: String) -> void:
	if randf() < 0.4:
		_play_sfx(ProceduralSfx.phone_static_burst(0.08, 0.12), -12.0)


func _on_call_ended() -> void:
	stop_ring()
	_play_sfx(ProceduralSfx.phone_static_burst(0.15, 0.18), -8.0)


func _on_camera_changed(_camera_id: String) -> void:
	_play_sfx(ProceduralSfx.cam_switch_click(), -6.0)
	_play_sfx(ProceduralSfx.white_noise(0.06, 0.2), -14.0)


func _on_threat_changed(level: float, _band: String) -> void:
	_update_drone(level / 100.0)
	_ambient.volume_db = -8.0 + level * 0.03


func _on_consequence(text: String) -> void:
	var negative := "DECEASED" in text or "loss" in text.to_lower() or "collapse" in text.to_lower() or "spread" in text.to_lower()
	_play_sfx(ProceduralSfx.consequence_sting(negative), -4.0 if negative else -8.0)


func play_ui_tick() -> void:
	_play_sfx(ProceduralSfx.ui_tick(), -14.0)


func _update_drone(threat_norm: float) -> void:
	var was_playing := _music.playing
	var pos := _music.get_playback_position() if was_playing else 0.0
	_music.stream = ProceduralSfx.ambient_drone(threat_norm)
	_music.volume_db = -14.0 + threat_norm * 6.0
	if was_playing:
		_music.play(pos)
	else:
		_music.play()


func _play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return
	# All busy — reuse first
	_sfx_players[0].stream = stream
	_sfx_players[0].volume_db = volume_db
	_sfx_players[0].play()
