extends Node
## Runtime localization: EN + UK from translations/strings.csv

signal locale_changed(locale: String)

const LOCALES := ["en", "uk"]
const CSV_PATH := "res://translations/strings.csv"

var current_locale: String = "en"
var _by_locale: Dictionary = {}  # locale -> { key -> text }


func _ready() -> void:
	_load_csv()
	if SettingsManager:
		set_locale(SettingsManager.locale)
	else:
		set_locale("en")


func _load_csv() -> void:
	_by_locale = {"en": {}, "uk": {}}
	if not FileAccess.file_exists(CSV_PATH):
		push_warning("LocaleManager: missing %s" % CSV_PATH)
		return
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		return
	var header := file.get_csv_line()
	if header.size() < 3:
		return
	var col_en := header.find("en")
	var col_uk := header.find("uk")
	if col_en < 0:
		col_en = 1
	if col_uk < 0:
		col_uk = 2
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 3:
			continue
		var key := row[0].strip_edges()
		if key == "" or key == "keys":
			continue
		_by_locale["en"][key] = row[col_en]
		_by_locale["uk"][key] = row[col_uk]


func set_locale(locale: String) -> void:
	if locale not in LOCALES:
		locale = "en"
	current_locale = locale
	TranslationServer.set_locale(locale)
	_apply_translation_server()
	locale_changed.emit(locale)


func _apply_translation_server() -> void:
	TranslationServer.clear()
	var tr := Translation.new()
	tr.locale = current_locale
	var table: Dictionary = _by_locale.get(current_locale, {})
	for key in table:
		tr.add_message(key, table[key])
	TranslationServer.add_translation(tr)
	TranslationServer.set_locale(current_locale)


func tr_key(key: String, fallback: String = "") -> String:
	if key == "":
		return fallback
	var table: Dictionary = _by_locale.get(current_locale, {})
	if table.has(key) and table[key] != "":
		return table[key]
	if current_locale != "en":
		var en: Dictionary = _by_locale.get("en", {})
		if en.has(key) and en[key] != "":
			return en[key]
	return fallback if fallback != "" else key


func tr_ui(key: String) -> String:
	return tr_key(key, key)


# --- Call dialogue helpers ---

func call_line(scenario_id: String, suffix: String, fallback: String) -> String:
	return tr_key("call.%s.%s" % [scenario_id, suffix], fallback)


func call_question_label(scenario_id: String, question_id: String, fallback: String) -> String:
	var shared := "ui.question.%s" % question_id
	var shared_text := tr_key(shared, "")
	if shared_text != shared and shared_text != "":
		return shared_text
	return tr_key("call.%s.q.%s.label" % [scenario_id, question_id], fallback)


func call_question_response(scenario_id: String, question_id: String, fallback: String) -> String:
	return tr_key("call.%s.q.%s.response" % [scenario_id, question_id], fallback)


func anomaly_field(anomaly_id: String, field: String, fallback: String) -> String:
	return tr_key("anomaly.%s.%s" % [anomaly_id, field], fallback)
