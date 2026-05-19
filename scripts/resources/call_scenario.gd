class_name CallScenario
extends Resource

enum CallType { NORMAL, SUSPICIOUS, ACTIVE_ANOMALY, MIMIC }

@export var id: String = ""
@export var call_type: CallType = CallType.SUSPICIOUS
@export var caller_name: String = ""
@export var caller_unit: String = ""
@export var voice_profile: String = ""
@export var emotional_state: String = ""
@export var truth_value: bool = true
@export var opening_line: String = ""
@export var anomaly_id: String = ""
@export var cctv_camera_id: String = ""
@export var correct_actions: Array[String] = []
@export var questions: Array[Dictionary] = []
@export var notes_for_player: String = ""
