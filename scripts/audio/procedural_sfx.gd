class_name ProceduralSfx
extends RefCounted
## Runtime-generated audio — no external files needed for prototype.

const SAMPLE_RATE := 22050


static func _write_sample(data: PackedByteArray, index: int, value: float) -> void:
	var s := int(clampf(value * 32767.0, -32768.0, 32767.0))
	data[index * 2] = s & 0xFF
	data[index * 2 + 1] = (s >> 8) & 0xFF


static func _make_stream(duration: float, stereo: bool = false) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = stereo
	var count := int(duration * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	stream.data = data
	return stream


static func white_noise(duration: float, volume: float = 0.25) -> AudioStreamWAV:
	var stream := _make_stream(duration)
	var count := int(duration * SAMPLE_RATE)
	for i in count:
		_write_sample(stream.data, i, randf_range(-volume, volume))
	return stream


static func phone_ring_loop() -> AudioStreamWAV:
	var duration := 2.4
	var stream := _make_stream(duration)
	var count := int(duration * SAMPLE_RATE)
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var ring := fmod(t, 0.8) < 0.4
		var tone := 0.0
		if ring:
			tone = sin(t * TAU * 440.0) * 0.22 + sin(t * TAU * 480.0) * 0.18
		_write_sample(stream.data, i, tone)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream


static func phone_static_burst(duration: float = 0.35, volume: float = 0.35) -> AudioStreamWAV:
	var stream := _make_stream(duration)
	var count := int(duration * SAMPLE_RATE)
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var env := 1.0 - t / duration
		var n := randf_range(-volume, volume) * env
		_write_sample(stream.data, i, n)
	return stream


static func cam_switch_click() -> AudioStreamWAV:
	var duration := 0.12
	var stream := _make_stream(duration)
	var count := int(duration * SAMPLE_RATE)
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var env := 1.0 - t / duration
		var click := sin(t * TAU * 120.0) * 0.4 * env + randf_range(-0.15, 0.15) * env
		_write_sample(stream.data, i, click)
	return stream


static func ui_tick() -> AudioStreamWAV:
	var duration := 0.05
	var stream := _make_stream(duration)
	var count := int(duration * SAMPLE_RATE)
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var env := 1.0 - t / duration
		_write_sample(stream.data, i, sin(t * TAU * 880.0) * 0.12 * env)
	return stream


static func consequence_sting(negative: bool = true) -> AudioStreamWAV:
	var duration := 0.9
	var stream := _make_stream(duration)
	var count := int(duration * SAMPLE_RATE)
	var base_freq := 180.0 if negative else 320.0
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 3.5)
		var freq := base_freq + t * (40.0 if negative else -20.0)
		var tone := sin(t * TAU * freq) * 0.35 * env
		var noise := randf_range(-0.08, 0.08) * env if negative else 0.0
		_write_sample(stream.data, i, tone + noise)
	return stream


static func ambient_hum() -> AudioStreamWAV:
	var duration := 4.0
	var stream := _make_stream(duration)
	var count := int(duration * SAMPLE_RATE)
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var hum := sin(t * TAU * 58.0) * 0.08 + sin(t * TAU * 60.0) * 0.06
		var vent := sin(t * TAU * 0.7) * 0.02
		var buzz := sin(t * TAU * 400.0) * 0.015 * (sin(t * 3.1) * 0.5 + 0.5)
		var n := randf_range(-0.012, 0.012)
		_write_sample(stream.data, i, hum + vent + buzz + n)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream


static func ambient_drone(threat_norm: float) -> AudioStreamWAV:
	var duration := 6.0
	var stream := _make_stream(duration)
	var count := int(duration * SAMPLE_RATE)
	var base := 55.0 + threat_norm * 25.0
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var hum := sin(t * TAU * base) * (0.06 + threat_norm * 0.04)
		hum += sin(t * TAU * (base * 1.5)) * 0.03
		var pulse := (sin(t * TAU * 0.15) * 0.5 + 0.5) * 0.02
		_write_sample(stream.data, i, hum + pulse)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream


static func distant_thud() -> AudioStreamWAV:
	var duration := 0.5
	var stream := _make_stream(duration)
	var count := int(duration * SAMPLE_RATE)
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 8.0)
		_write_sample(stream.data, i, sin(t * TAU * 45.0) * 0.5 * env + randf_range(-0.05, 0.05) * env)
	return stream
