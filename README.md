# Apartment Anomaly Hotline

**Жанр:** psychological horror / anomaly detection / dispatcher simulator  
**Движок:** Godot 4.3+  
**Платформа:** PC (Windows / macOS / Linux через Godot export)

> *"Less content, more tension."*

## Гра готова до запуску

Повний **MVP playable build** у редакторі Godot:

- 20 сценаріїв дзвінків, 6 типів аномалій  
- **178 файлів озвучки** (EN + UK), телефонний фільтр  
- Локалізація UI + діалогів  
- 3D office + CCTV + anomaly meter + збереження  

**→ Покрокова інструкція: [PLAY.md](PLAY.md)**

```bash
# Godot 4.3+ → Import project → F5
```

## Що вже реалізовано

| Система | Статус |
|---------|--------|
| Core loop (дзвінок → CCTV → рішення) | ✓ |
| 20 call scenarios | ✓ |
| EN / UK локалізація | ✓ |
| VO (89 ліній × 2 мови) | ✓ |
| 3D office first-person | ✓ |
| Audio (ambient, phone, drone) | ✓ |
| CRT CCTV | ✓ |
| Settings, pause, save | ✓ |

## Озвучка

Файли: `audio/vo/{en|uk}/{scenario_id}/{line_id}.ogg`

- Згенеровано скриптом `tools/generate_vo.py` (macOS `say` + ffmpeg)  
- Різні голоси EN за `voice_profile`; UK — **Lesya**  
- Якщо файл відсутній — procedural fallback  

Перегенерація після зміни текстів:

```bash
python3 tools/build_uk_overrides.py   # якщо змінював UK текст
python3 tools/generate_translations.py
python3 tools/generate_vo.py          # macOS only
```

Деталі: [audio/vo/README.md](audio/vo/README.md)

## Локалізація

- CSV: `translations/strings.csv`  
- UK діалоги: `translations/calls_uk_overrides.json`  
- Settings → **Language**

## Структура

```
scenes/           main_menu, office_root (3D), office_ui
scripts/autoload/ managers (game, call, cctv, voice, locale…)
dialogue/         scenarios JSON
audio/vo/         озвучка en + uk
translations/     strings.csv
tools/            generate_vo, translations
```

## Roadmap

| Фаза | Статус |
|------|--------|
| Core + 20 scenarios | ✓ |
| Atmosphere (audio, CRT) | ✓ |
| 3D office | ✓ |
| Localization + VO | ✓ |
| **4** — PS1 art import, polish, Steam page | Далі |
| Nights 2–3, meta progression | Пізніше |

## Заміна TTS на живі голоси

Запиши OGG у ті самі шляхи — гра підхопить автоматично. Див. `audio/vo/README.md`.

## Референси

Papers Please · I'm on Observation Duty · The Exit 8 · SOMA · Voices of the Void
