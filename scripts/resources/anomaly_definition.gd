class_name AnomalyDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var cctv_hint: String = ""
@export var threat_on_ignore: float = 8.0
@export var threat_on_wrong_action: float = 12.0
@export var threat_on_correct: float = -4.0
