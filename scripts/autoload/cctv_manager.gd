extends Node
## CCTV feeds, camera switching, anomaly overlay state.

signal camera_changed(camera_id: String)
signal feed_updated(camera_id: String, feed_data: Dictionary)

var cameras: Dictionary = {}
var active_camera_id: String = ""
var _scenario_camera_hint: String = ""


func reset_for_shift() -> void:
	_build_default_cameras()
	active_camera_id = cameras.keys()[0] if cameras.size() > 0 else ""
	_scenario_camera_hint = ""
	camera_changed.emit(active_camera_id)


func _build_default_cameras() -> void:
	cameras = {
		"lobby": {
			"label": "CAM 01 — Lobby",
			"floor": 0,
			"description": "Empty reception. Flickering emergency sign.",
			"anomaly_visible": false,
			"corruption": 0.05,
		},
		"floor_2_corridor": {
			"label": "CAM 02 — Floor 2 Corridor",
			"floor": 2,
			"description": "Wet floor cone. Normal lighting.",
			"anomaly_visible": false,
			"corruption": 0.08,
		},
		"floor_4_corridor": {
			"label": "CAM 04 — Floor 4 Corridor",
			"floor": 4,
			"description": "Long corridor. One figure standing still.",
			"anomaly_visible": false,
			"corruption": 0.12,
		},
		"elevator": {
			"label": "CAM 05 — Elevator",
			"floor": -1,
			"description": "Elevator cab empty between floors.",
			"anomaly_visible": false,
			"corruption": 0.06,
		},
		"staircase": {
			"label": "CAM 06 — Stairwell B",
			"floor": -1,
			"description": "Concrete stairs. Handrail intact.",
			"anomaly_visible": false,
			"corruption": 0.1,
		},
	}


func set_scenario_hint(camera_id: String, anomaly_id: String) -> void:
	_scenario_camera_hint = camera_id
	_clear_anomalies()
	if camera_id in cameras:
		active_camera_id = camera_id
		camera_changed.emit(active_camera_id)

	var def := AnomalyRegistry.get_anomaly(anomaly_id)
	if def == null:
		return

	if anomaly_id == "duplicate_person":
		for cam_id in ["floor_2_corridor", "floor_4_corridor"]:
			if cam_id in cameras:
				cameras[cam_id]["anomaly_visible"] = true
				var hint := def.cctv_hint
				if LocaleManager:
					hint = LocaleManager.anomaly_field(anomaly_id, "cctv_hint", def.cctv_hint)
				cameras[cam_id]["description"] = hint
				feed_updated.emit(cam_id, get_feed(cam_id))
	elif camera_id in cameras:
		cameras[camera_id]["anomaly_visible"] = true
		var hint := def.cctv_hint
		if LocaleManager:
			hint = LocaleManager.anomaly_field(anomaly_id, "cctv_hint", def.cctv_hint)
		cameras[camera_id]["description"] = hint
		feed_updated.emit(camera_id, get_feed(camera_id))


func _clear_anomalies() -> void:
	for id in cameras:
		cameras[id]["anomaly_visible"] = false


func switch_camera(direction: int) -> void:
	var keys: Array = cameras.keys()
	if keys.is_empty():
		return
	var idx := keys.find(active_camera_id)
	if idx < 0:
		idx = 0
	idx = (idx + direction) % keys.size()
	if idx < 0:
		idx += keys.size()
	active_camera_id = keys[idx]
	camera_changed.emit(active_camera_id)
	feed_updated.emit(active_camera_id, get_feed(active_camera_id))


func select_camera(camera_id: String) -> void:
	if camera_id in cameras:
		active_camera_id = camera_id
		camera_changed.emit(active_camera_id)
		feed_updated.emit(active_camera_id, get_feed(camera_id))


func get_feed(camera_id: String = "") -> Dictionary:
	var id := camera_id if camera_id != "" else active_camera_id
	if id not in cameras:
		return {}
	return cameras[id].duplicate(true)


func get_active_feed() -> Dictionary:
	return get_feed(active_camera_id)
