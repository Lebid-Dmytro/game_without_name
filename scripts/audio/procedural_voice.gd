class_name ProceduralVoice
extends RefCounted
## Placeholder VO until real recordings — syllable bursts from text + profile.

const SAMPLE_RATE := 22050

static var _profile_pitch := {
	"elderly_female": 0.75,
	"elderly_male": 0.7,
	"middle_aged_male": 0.85,
	"middle_aged_female": 0.9,
	"young_male": 1.05,
	"young_female": 1.1,
	"child_high": 1.35,
	"child": 1.35,
	"synthetic_calm": 0.95,
	"text_to_speech": 1.0,
	"radio_filtered": 0.88,
	"distorted": 0.8,
	"almost_human": 0.92,
	"authoritative_male": 0.82,
	"pleading": 1.0,
	"giggling": 1.25,
	"whispering": 0.78,
	"flat": 0.9,
	"anxious": 0.95,
}


static func synthesize_line(text: String, voice_profile: String, duration_cap: float = 4.5) -> AudioStreamWAV:
	var pitch: float = _profile_pitch.get(voice_profile, 0.9)
	var word_count: int = maxi(1, text.split(" ", false).size())
	var duration: float = clampf(word_count * 0.14, 0.6, duration_cap)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	var count := int(duration * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	stream.data = data

	var base_freq := 140.0 * pitch
	var syllables := maxi(2, word_count)
	var syl_len: float = duration / float(syllables)

	for i in count:
		var t := float(i) / SAMPLE_RATE
		var syl_idx := int(t / syl_len)
		var syl_t := fmod(t, syl_len)
		var env := sin((syl_t / syl_len) * PI) * exp(-syl_t * 2.5)
		var freq := base_freq + float(syl_idx % 3) * 18.0
		var sample := sin(t * TAU * freq) * 0.22 * env
		sample += sin(t * TAU * freq * 2.0) * 0.06 * env
		if voice_profile in ["radio_filtered", "distorted", "almost_human"]:
			sample += randf_range(-0.04, 0.04) * env
		if voice_profile == "whispering":
			sample *= 0.55
		_write_sample(data, i, sample)

	return stream


static func _write_sample(data: PackedByteArray, index: int, value: float) -> void:
	var s := int(clampf(value * 32767.0, -32768.0, 32767.0))
	data[index * 2] = s & 0xFF
	data[index * 2 + 1] = (s >> 8) & 0xFF
