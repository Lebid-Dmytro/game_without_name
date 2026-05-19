#!/usr/bin/env python3
"""
Generate VO files for Apartment Anomaly Hotline using macOS `say` + ffmpeg.
Output: audio/vo/{en|uk}/{scenario_id}/{line_id}.ogg
"""
from __future__ import annotations

import csv
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCENARIOS = ROOT / "dialogue" / "scenarios"
VO_ROOT = ROOT / "audio" / "vo"
UK_OVERRIDES = ROOT / "translations" / "calls_uk_overrides.json"
STRINGS_CSV = ROOT / "translations" / "strings.csv"

# voice_profile -> (say voice name, rate wpm-ish)
EN_VOICES = {
	"elderly_female": ("Samantha", 165),
	"elderly_male": ("Fred", 155),
	"middle_aged_male": ("Daniel", 175),
	"middle_aged_female": ("Samantha", 170),
	"young_male": ("Alex", 190),
	"young_female": ("Samantha", 195),
	"child_high": ("Junior", 210),
	"child": ("Junior", 210),
	"synthetic_calm": ("Alex", 160),
	"text_to_speech": ("Alex", 150),
	"radio_filtered": ("Daniel", 170),
	"distorted": ("Daniel", 140),
	"almost_human": ("Daniel", 165),
	"authoritative_male": ("Daniel", 155),
	"pleading": ("Samantha", 185),
	"giggling": ("Junior", 200),
	"whispering": ("Whisper", 140),
	"flat": ("Alex", 145),
	"anxious": ("Samantha", 200),
	"neutral": ("Daniel", 170),
	"embarrassed": ("Alex", 175),
	"irritated": ("Daniel", 180),
	"breathless": ("Alex", 195),
	"panicked": ("Samantha", 210),
	"whispering": ("Whisper", 135),
	"quiet": ("Samantha", 155),
	"calm": ("Daniel", 160),
	"giggling": ("Junior", 205),
}

UK_VOICE = ("Lesya", 170)


def load_uk_map() -> dict[str, str]:
	if UK_OVERRIDES.exists():
		with open(UK_OVERRIDES, encoding="utf-8") as f:
			return json.load(f)
	return {}


def load_csv_map() -> dict[str, dict[str, str]]:
	out = {"en": {}, "uk": {}}
	if not STRINGS_CSV.exists():
		return out
	with open(STRINGS_CSV, encoding="utf-8") as f:
		reader = csv.DictReader(f)
		for row in reader:
			key = row.get("keys", "").strip()
			if not key:
				continue
			out["en"][key] = row.get("en", "")
			out["uk"][key] = row.get("uk", "")
	return out


def collect_lines() -> list[dict]:
	uk_map = load_uk_map()
	csv_map = load_csv_map()
	lines: list[dict] = []

	for path in sorted(SCENARIOS.glob("*.json")):
		if path.name.startswith("SCENARIOS"):
			continue
		with open(path, encoding="utf-8") as f:
			data = json.load(f)
		sid = data["id"]
		profile = data.get("voice_profile", "neutral")

		def add(line_id: str, en_text: str, key_suffix: str) -> None:
			key = f"call.{sid}.{key_suffix}"
			en = csv_map["en"].get(key, en_text)
			uk = uk_map.get(key, csv_map["uk"].get(key, en_text))
			lines.append({
				"scenario_id": sid,
				"line_id": line_id,
				"profile": profile,
				"en": en.strip(),
				"uk": uk.strip(),
			})

		add("opening", data.get("opening_line", ""), "opening")
		for q in data.get("questions", []):
			qid = q["id"]
			add(f"q.{qid}", q.get("response", ""), f"q.{qid}.response")

	return lines


def phone_filter_args(extra: str = "") -> str:
	# Narrow band + light compression = handset feel
	base = "highpass=f=320,lowpass=f=3400,acompressor=threshold=-20dB:ratio=3:attack=5:release=50,volume=1.2"
	if extra:
		return f"{base},{extra}"
	return base


def profile_extra_af(profile: str) -> str:
	if profile == "radio_filtered":
		return "highpass=f=400,lowpass=f=2800,volume=1.1"
	if profile == "distorted":
		return "highpass=f=200,lowpass=f=4000,volume=1.4"
	if profile == "whispering":
		return "volume=0.75,highpass=f=400"
	if profile == "child_high" or profile == "child":
		return "asetrate=44100*1.08,aresample=44100"
	return ""


def synthesize(text: str, locale: str, profile: str, out_ogg: Path) -> bool:
	if not text:
		return False
	out_ogg.parent.mkdir(parents=True, exist_ok=True)
	aiff = out_ogg.with_suffix(".aiff")

	if locale == "uk":
		voice, rate = UK_VOICE
	else:
		voice, rate = EN_VOICES.get(profile, ("Daniel", 170))

	# say has limits; split very long lines
	safe = text.replace('"', '\\"')[:800]
	cmd_say = ["say", "-v", voice, "-r", str(rate), "-o", str(aiff), safe]
	try:
		subprocess.run(cmd_say, check=True, capture_output=True, text=True)
	except subprocess.CalledProcessError as e:
		print(f"  say failed: {e.stderr}", file=sys.stderr)
		return False

	af = phone_filter_args(profile_extra_af(profile))
	cmd_ff = [
		"ffmpeg", "-y", "-loglevel", "error",
		"-i", str(aiff),
		"-af", af,
		"-c:a", "libvorbis", "-q:a", "5",
		str(out_ogg),
	]
	try:
		subprocess.run(cmd_ff, check=True, capture_output=True)
	except subprocess.CalledProcessError as e:
		print(f"  ffmpeg failed: {e.stderr}", file=sys.stderr)
		aiff.unlink(missing_ok=True)
		return False

	aiff.unlink(missing_ok=True)
	return True


def main() -> None:
	if subprocess.run(["which", "say"], capture_output=True).returncode != 0:
		print("macOS `say` required for VO generation.", file=sys.stderr)
		sys.exit(1)
	if subprocess.run(["which", "ffmpeg"], capture_output=True).returncode != 0:
		print("ffmpeg required.", file=sys.stderr)
		sys.exit(1)

	lines = collect_lines()
	ok = 0
	fail = 0
	total = len(lines) * 2
	print(f"Generating {total} VO files ({len(lines)} lines × 2 locales)...")

	for entry in lines:
		sid = entry["scenario_id"]
		lid = entry["line_id"]
		profile = entry["profile"]
		for locale, text in [("en", entry["en"]), ("uk", entry["uk"])]:
			out = VO_ROOT / locale / sid / f"{lid}.ogg"
			if out.exists() and out.stat().st_size > 500:
				ok += 1
				continue
			print(f"  [{locale}] {sid}/{lid}.ogg")
			if synthesize(text, locale, profile, out):
				ok += 1
			else:
				fail += 1

	print(f"\nDone: {ok} ok, {fail} failed, output -> {VO_ROOT}")
	if fail:
		sys.exit(1)


if __name__ == "__main__":
	main()
