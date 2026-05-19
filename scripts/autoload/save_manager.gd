extends Node
## Autosave between nights, progression flags.

const SAVE_PATH := "user://savegame.json"

var data: Dictionary = {
	"night_unlocked": 1,
	"shifts_completed": 0,
	"endings_seen": [],
	"anomalies_unlocked": [],
	"best_threat_level": 100.0,
}


func _ready() -> void:
	load_game()


func record_shift_complete(night: int, ending_id: String, threat: float) -> void:
	data.shifts_completed = int(data.get("shifts_completed", 0)) + 1
	data.night_unlocked = maxi(int(data.get("night_unlocked", 1)), night + 1)
	data.best_threat_level = minf(float(data.get("best_threat_level", 100.0)), threat)

	var endings: Array = data.get("endings_seen", [])
	if ending_id not in endings:
		endings.append(ending_id)
	data.endings_seen = endings

	save_game()


func unlock_anomaly(anomaly_id: String) -> void:
	var list: Array = data.get("anomalies_unlocked", [])
	if anomaly_id not in list:
		list.append(anomaly_id)
	data.anomalies_unlocked = list
	save_game()


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		data = parsed
