#!/usr/bin/env python3
"""Regenerate translation CSV from scenario JSON + embedded UK strings."""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCENARIOS = ROOT / "dialogue" / "scenarios"
OUT = ROOT / "translations"

# Shared UI / system strings: key -> (en, uk)
UI_STRINGS = {
    "ui.menu.title": ("APARTMENT ANOMALY HOTLINE", "ГАРЯЧА ЛІНІЯ АНОМАЛІЙ БУДИНКУ"),
    "ui.menu.subtitle": ("Night shift prototype — Less content, more tension.", "Нічна зміна — менше контенту, більше напруги."),
    "ui.menu.start": ("Start Night 1", "Почати ніч 1"),
    "ui.menu.settings": ("Settings", "Налаштування"),
    "ui.menu.quit": ("Quit", "Вихід"),
    "ui.settings.title": ("Settings", "Налаштування"),
    "ui.settings.fullscreen": ("Fullscreen", "Повний екран"),
    "ui.settings.master": ("Master volume", "Загальна гучність"),
    "ui.settings.sfx": ("SFX volume", "Гучність ефектів"),
    "ui.settings.music": ("Music / ambient drone", "Музика / ambient"),
    "ui.settings.vo": ("Voice volume", "Гучність голосу"),
    "ui.settings.vo_enabled": ("Caller voice (VO)", "Голос абонентів (VO)"),
    "ui.settings.subtitles": ("Subtitles", "Субтитри"),
    "ui.settings.language": ("Language", "Мова"),
    "ui.settings.lang_en": ("English", "English"),
    "ui.settings.lang_uk": ("Ukrainian", "Українська"),
    "ui.settings.back": ("Back", "Назад"),
    "ui.office.shift": ("SHIFT", "ЗМІНА"),
    "ui.office.anomaly": ("ANOMALY", "АНОМАЛІЯ"),
    "ui.office.cctv": ("CCTV — Left monitor", "CCTV — лівий монітор"),
    "ui.office.cam_prev": ("< CAM", "< КАМ"),
    "ui.office.cam_next": ("CAM >", "КАМ >"),
    "ui.office.phone_idle": ("Phone idle", "Телефон очікує"),
    "ui.office.answer": ("Answer call", "Відповісти"),
    "ui.office.ringing": ("[Phone ringing...]", "[Дзвінок...]"),
    "ui.office.static": ("[static hum]", "[шум лінії]"),
    "ui.office.incoming": ("INCOMING", "ВХІДНИЙ"),
    "ui.office.line_closed": ("Line closed. Next call pending...", "Лінію закрито. Очікується наступний дзвінок..."),
    "ui.office.awaiting_call": ("Awaiting incoming call...", "Очікування вхідного дзвінка..."),
    "ui.office.queue": ("Calls in queue", "Дзвінків у черзі"),
    "ui.office.tenant_db": ("Tenant database", "База мешканців"),
    "ui.office.no_call": ("— NO ACTIVE CALL —", "— НЕМАЄ АКТИВНОГО ДЗВІНКА —"),
    "ui.office.awaiting_data": ("Awaiting caller data.", "Очікування даних абонента."),
    "ui.office.dispatch": ("Dispatch protocols", "Протоколи реагування"),
    "ui.office.log_ready": ("System log ready.", "Системний журнал готовий."),
    "ui.office.paused": ("Paused", "Пауза"),
    "ui.office.resume": ("Resume", "Продовжити"),
    "ui.office.main_menu": ("Main menu", "Головне меню"),
    "ui.office.return_menu": ("Return to menu", "У головне меню"),
    "ui.question.location": ("Ask location", "Запитати локацію"),
    "ui.question.appearance": ("Ask appearance", "Запитати зовнішність"),
    "ui.question.timeline": ("Ask timeline", "Запитати час"),
    "ui.question.camera": ("Request camera check", "Перевірити камеру"),
    "ui.truth.verified": ("VERIFIED", "ПІДТВЕРДЖЕНО"),
    "ui.truth.unverified": ("UNVERIFIED", "НЕ ПІДТВЕРДЖЕНО"),
    "ui.tenant.voice": ("Voice", "Голос"),
    "ui.tenant.state": ("State", "Стан"),
    "ui.tenant.truth": ("Truth", "Достовірність"),
    "ui.tenant.note": ("Internal note", "Внутрішня примітка"),
    "ui.band.low": ("LOW", "НИЗЬКИЙ"),
    "ui.band.medium": ("MEDIUM", "СЕРЕДНІЙ"),
    "ui.band.high": ("HIGH", "ВИСОКИЙ"),
    "ui.band.critical": ("CRITICAL", "КРИТИЧНИЙ"),
    "ui.action.ignore": ("Ignore", "Ігнорувати"),
    "ui.action.dispatch": ("Dispatch", "Відправити охорону"),
    "ui.action.lock_floor": ("Lock floor", "Заблокувати поверх"),
    "ui.action.evacuate": ("Evacuate", "Евакуація"),
    "ui.action.quarantine": ("Quarantine", "Карантин"),
    "ui.action.cut_power": ("Cut power", "Вимкнути живлення"),
    "game.death": ("Resident status: DECEASED. Incident logged.", "Статус мешканця: ЗАГИБЕЛЬ. Інцидент зафіксовано."),
    "game.end.good": ("SHIFT END — Containment successful.\nBuilding status: STABLE.", "КІНЕЦЬ ЗМІНИ — Стримування успішне.\nСтатус будинку: СТАБІЛЬНИЙ."),
    "game.end.bad": ("SHIFT END — Reality collapse.\nBuilding status: COMPROMISED.", "КІНЕЦЬ ЗМІНИ — Колапс реальності.\nСтатус будинку: СКОМПРОМЕТОВАНО."),
    "game.end.neutral": ("SHIFT END — You survived.\nBuilding status: UNSTABLE.", "КІНЕЦЬ ЗМІНИ — Ви вижили.\nСтатус будинку: НЕСТАБІЛЬНИЙ."),
    "game.end.default": ("SHIFT END — Report filed.", "КІНЕЦЬ ЗМІНИ — Звіт подано."),
    "ui.office.shift_hold": (
        "All calls received. Hold position — monitor CCTV until shift end.",
        "Усі дзвінки отримано. Тримай позицію — стеж за CCTV до кінця зміни.",
    ),
    "ui.office.queue_done": ("Queue: complete", "Черга: завершено"),
    "game.shift.all_calls_done": (
        "All scheduled calls processed. Anomaly level may still rise. Survive until shift end.",
        "Усі заплановані дзвінки оброблено. Рівень аномалії ще може зростати. Витримай до кінця зміни.",
    ),
    "game.threat.warning": (
        "WARNING: Anomaly 80%+. Collapse imminent at 90%.",
        "УВАГА: Аномалія 80%+. Колапс о 90%.",
    ),
    "game.threat.collapse": (
        "CRITICAL: Reality collapse. Shift terminated.",
        "КРИТИЧНО: Колапс реальності. Зміну завершено.",
    ),
    "game.msg.answer_first": ("Answer the line before issuing protocols.", "Спочатку відповідайте на лінію, потім протокол."),
    "game.msg.no_call": ("No active call. Action logged locally.", "Немає активного дзвінка. Дію зафіксовано локально."),
    "cctv.anomaly": ("ANOMALY DETECTED", "ВИЯВЛЕНО АНОМАЛІЮ"),
    "decision.invalid": ("Invalid protocol selected.", "Обрано невірний протокол."),
    "decision.unknown_anomaly": ("Unknown anomaly reference in scenario.", "Невідома аномалія в сценарії."),
    "decision.ignore_ok": ("Call closed. No further action required.", "Дзвінок закрито. Додаткових дій не потрібно."),
    "decision.ignore_bad": ("Incident ignored. Sensors report spread on affected floor.", "Інцидент проігноровано. Датчики фіксують поширення на поверсі."),
    "decision.no_guards": ("No guard units available.", "Немає вільних охоронців."),
    "decision.dispatch_busy": ("Dispatch channel busy. Wait for confirmation.", "Канал диспетчеризації зайнятий. Очікуйте підтвердження."),
    "decision.dispatch_ok": ("Guard dispatched. Floor sweep in progress. Anomaly contained.", "Охорону відправлено. Обстеження поверху. Аномалію стримано."),
    "decision.dispatch_bad": ("Guard team reported contact loss. Wrong assessment.", "Група втратила зв'язок. Хибна оцінка ситуації."),
    "decision.lock_ok": ("Floor isolated. Access panels sealed.", "Поверх ізольовано. Панелі доступу запечатано."),
    "decision.lock_bad": ("Isolation triggered on wrong sector. Residents trapped with entity.", "Ізоляцію активовано на хибному секторі. Мешканців замкнено з сутністю."),
    "decision.evac_ok": ("Partial evacuation complete. Casualties minimal.", "Часткову евакуацію завершено. Мінімальні втрати."),
    "decision.evac_bad": ("Evacuation route compromised. Panic logged.", "Маршрут евакуації скомпрометовано. Зафіксовано паніку."),
    "decision.quar_ok": ("Quarantine protocol active. Biological scan pending.", "Протокол карантину активний. Очікується біосканування."),
    "decision.quar_bad": ("Quarantine applied to clean unit. Complaints flooding in.", "Карантин на чистій квартирі. Потік скарг."),
    "decision.power_ok": ("Sector power cut. Motion sensors offline.", "Живлення сектору відключено. Датчики руху офлайн."),
    "decision.power_bad": ("Blackout spread to emergency systems. Elevators stalled.", "Блекаут поширився на аварійні системи. Ліфти зупинено."),
    "call.static_fail": ("[static] ...could not verify.", "[шум] ...не вдалося перевірити."),
    "anomaly.faceless_tenant.cctv_hint": (
        "CAM: Figure facing camera. Face region flat / absent.",
        "CAM: Фігура дивиться в камеру. Область обличчя плоска / відсутня.",
    ),
    "anomaly.wrong_apartment_number.cctv_hint": (
        "CAM: Unit label reads 4B but directory shows 4C.",
        "CAM: Табличка 4B, у довіднику — 4C.",
    ),
    "anomaly.endless_staircase.cctv_hint": (
        "CAM: Same landing appears twice in one feed.",
        "CAM: Той самий майданчик двічі на одному відео.",
    ),
    "anomaly.duplicate_person.cctv_hint": (
        "CAM: Identical clothing on Floor 2 and Floor 4.",
        "CAM: Однаковий одяг на 2 і 4 поверсі.",
    ),
    "anomaly.corridor_expansion.cctv_hint": (
        "CAM: Corridor vanishing point farther than yesterday.",
        "CAM: Точка зникнення коридору далі, ніж учора.",
    ),
    "anomaly.fake_child_voice.cctv_hint": (
        "CAM: Small figure. Movement pattern non-childlike.",
        "CAM: Мала фігура. Рух не схожий на дитячий.",
    ),
}

# UK overrides for call lines — keyed same as auto keys; missing = keep EN from JSON
UK_OVERRIDES = {
    # Populated by merge: if key in UK_OVERRIDES use it else auto-translate placeholder
}


def load_uk_overrides_from_json_translations():
    """Load hand-maintained uk file if present."""
    uk_path = ROOT / "translations" / "calls_uk_overrides.json"
    if uk_path.exists():
        with open(uk_path, encoding="utf-8") as f:
            UK_OVERRIDES.update(json.load(f))


def collect_call_keys():
    rows = {}
    for path in sorted(SCENARIOS.glob("*.json")):
        if path.name.startswith("SCENARIOS"):
            continue
        with open(path, encoding="utf-8") as f:
            d = json.load(f)
        sid = d["id"]
        rows[f"call.{sid}.opening"] = d.get("opening_line", "")
        rows[f"call.{sid}.caller_name"] = d.get("caller_name", "")
        rows[f"call.{sid}.notes"] = d.get("notes_for_player", "")
        for q in d.get("questions", []):
            qid = q["id"]
            lk = f"call.{sid}.q.{qid}.label"
            rk = f"call.{sid}.q.{qid}.response"
            # Prefer shared UI keys for standard questions
            label = q.get("label", "")
            if label == "Ask location":
                rows[lk] = ("__ui__", "ui.question.location")
            elif label == "Ask appearance":
                rows[lk] = ("__ui__", "ui.question.appearance")
            elif label == "Ask timeline":
                rows[lk] = ("__ui__", "ui.question.timeline")
            elif label == "Request camera check":
                rows[lk] = ("__ui__", "ui.question.camera")
            else:
                rows[lk] = label
            rows[rk] = q.get("response", "")
    return rows


def write_csv(path, entries):
    with open(path, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["keys", "en", "uk"])
        for key in sorted(entries.keys()):
            en, uk = entries[key]
            w.writerow([key, en, uk])


def main():
    load_uk_overrides_from_json_translations()
    OUT.mkdir(exist_ok=True)

    all_entries = {}
    for key, (en, uk) in UI_STRINGS.items():
        all_entries[key] = (en, uk)

    call_rows = collect_call_keys()
    for key, val in call_rows.items():
        if isinstance(val, tuple) and val[0] == "__ui__":
            continue  # labels use ui.* keys directly
        en = val if isinstance(val, str) else val[0]
        uk = UK_OVERRIDES.get(key, en)  # fallback EN until override file filled
        all_entries[key] = (en, uk)

    write_csv(OUT / "strings.csv", all_entries)
    print(f"Wrote {len(all_entries)} entries to {OUT / 'strings.csv'}")


if __name__ == "__main__":
    main()
