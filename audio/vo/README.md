# Voice-over (VO) files

**У проєкті вже є 178 OGG** (20 сценаріїв × ~4–5 реплік × EN + UK), згенерованих `tools/generate_vo.py`.

Place human recordings here to replace TTS — same paths. The game loads **OGG** or **WAV** per line.

## Folder layout

```
audio/vo/
  en/
    faceless_01/
      opening.ogg
      q.location.ogg
      q.appearance.ogg
      ...
  uk/
    faceless_01/
      opening.ogg
      ...
```

- **Locale folder:** `en` or `uk` (must match Settings → Language)
- **Scenario folder:** same `id` as in `dialogue/scenarios/*.json` (e.g. `faceless_01`)
- **File name:** line id + extension

## Line IDs

| File | When played |
|------|-------------|
| `opening.ogg` | After player answers the call |
| `q.location.ogg` | Question: location |
| `q.appearance.ogg` | Question: appearance |
| `q.timeline.ogg` | Question: timeline |
| `q.camera.ogg` | Request camera check |
| `static_fail.ogg` | Optional — failed question |

## Recording tips (from TZ)

- Dry, bureaucratic, unsettling tone — not monster exposition
- Phone band: 300 Hz–3.4 kHz feel, light compression
- Export: **mono**, 44.1 kHz or 22.05 kHz, OGG Vorbis q=4–6
- Keep levels consistent (−18 to −12 LUFS integrated)

## Fallback

If a file is missing, **procedural placeholder VO** plays (syllable bursts by `voice_profile` in JSON).

Disable VO in Settings → **Caller voice (VO)**.

## Regenerating text after script edits

1. Edit `dialogue/scenarios/*.json` (English source)
2. Update `tools/build_uk_overrides.py` Ukrainian strings
3. Run: `python3 tools/build_uk_overrides.py && python3 tools/generate_translations.py`
