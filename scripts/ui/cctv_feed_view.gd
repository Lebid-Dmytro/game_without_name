extends Control
## Procedural CCTV feed — improved depth, doors, floor tags, anomaly silhouettes.

const FPS_LIMIT := 8.0

var _frame_accum: float = 0.0
var _glitch_offset: float = 0.0
var _flicker: float = 1.0


func _ready() -> void:
	CctvManager.camera_changed.connect(func(_id): queue_redraw())
	CctvManager.feed_updated.connect(func(_id, _f): queue_redraw())
	ThreatManager.level_changed.connect(func(_l, _b): queue_redraw())


func _process(delta: float) -> void:
	_frame_accum += delta
	_flicker = 0.92 + sin(Time.get_ticks_msec() * 0.004) * 0.08
	if _frame_accum >= 1.0 / FPS_LIMIT:
		_frame_accum = 0.0
		if randf() < 0.1 + ThreatManager.level * 0.002:
			_glitch_offset = randf_range(-18.0, 18.0)
		else:
			_glitch_offset *= 0.4
		queue_redraw()


func _draw() -> void:
	var feed := CctvManager.get_active_feed()
	var corruption: float = feed.get("corruption", 0.1)
	var anomaly: bool = feed.get("anomaly_visible", false)
	var cam_id: String = CctvManager.active_camera_id

	var base_col := Color(0.05, 0.08, 0.05) if not anomaly else Color(0.11, 0.04, 0.04)
	draw_rect(Rect2(Vector2.ZERO, size), base_col)

	_draw_floor_tag(cam_id, feed)
	_draw_scene(cam_id, anomaly, feed)
	_draw_scanlines()
	_draw_vignette()
	_draw_noise()
	_draw_timestamp()
	_draw_rec_indicator()

	if corruption > 0.08 or ThreatManager.level > 45.0:
		_draw_corruption(corruption + ThreatManager.level * 0.001)


func _draw_floor_tag(cam_id: String, feed: Dictionary) -> void:
	var label: String = feed.get("label", "CAM")
	draw_rect(Rect2(4, 4, size.x * 0.55, 18), Color(0, 0, 0, 0.55))
	draw_string(ThemeDB.fallback_font, Vector2(8, 16), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.95, 0.7, 0.9))


func _draw_scene(cam_id: String, anomaly: bool, feed: Dictionary) -> void:
	var cx := size.x * 0.5 + _glitch_offset
	var floor_col := Color(0.09, 0.12, 0.09) * _flicker
	var wall_col := Color(0.13, 0.17, 0.12) * _flicker
	var ceil_col := Color(0.07, 0.09, 0.08)

	# Ceiling
	draw_rect(Rect2(0, 0, size.x, size.y * 0.12), ceil_col)

	match cam_id:
		"lobby":
			_draw_lobby(cx, floor_col, wall_col, anomaly)
		"elevator":
			_draw_elevator(cx, anomaly)
		"staircase":
			_draw_staircase(anomaly)
		_:
			_draw_corridor(cx, floor_col, wall_col, cam_id, anomaly, feed)


func _draw_corridor(cx: float, floor_col: Color, wall_col: Color, cam_id: String, anomaly: bool, _feed: Dictionary) -> void:
	var stretch := _active_anomaly() == "corridor_expansion"
	var vanish_x := cx if not stretch else cx - size.x * 0.08
	var vanish_y := size.y * 0.14

	# Floor perspective
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0, size.y * 0.55),
			Vector2(size.x, size.y * 0.55),
			Vector2(vanish_x + size.x * 0.18, vanish_y),
			Vector2(vanish_x - size.x * 0.18, vanish_y),
		]),
		floor_col
	)
	# Left wall
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0, size.y * 0.12),
			Vector2(0, size.y * 0.55),
			Vector2(vanish_x - size.x * 0.18, vanish_y),
			Vector2(vanish_x - size.x * 0.12, vanish_y),
		]),
		wall_col
	)
	# Right wall
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(size.x, size.y * 0.12),
			Vector2(size.x, size.y * 0.55),
			Vector2(vanish_x + size.x * 0.18, vanish_y),
			Vector2(vanish_x + size.x * 0.12, vanish_y),
		]),
		wall_col
	)
	# Center dark end
	draw_rect(Rect2(vanish_x - size.x * 0.1, vanish_y - 4, size.x * 0.2, size.y * 0.42), Color(0.02, 0.03, 0.02))

	# Ceiling lights along corridor
	for i in 4:
		var lx := size.x * (0.2 + i * 0.18)
		draw_rect(Rect2(lx, size.y * 0.08, size.x * 0.04, 3), Color(0.5, 0.55, 0.45, 0.35 * _flicker))

	# Doors
	var door_labels: Array[String] = ["4A", "4B", "4C", "4D"]
	for i in 4:
		var dx := size.x * (0.28 + i * 0.14)
		var dy := size.y * 0.36
		var wrong := anomaly and _active_anomaly() == "wrong_apartment_number" and i == 1
		var lbl: String = "4C" if wrong else door_labels[i]
		_draw_door_unit(dx, dy, lbl, wrong)

	# Wet floor cone
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(size.x * 0.15, size.y * 0.54),
			Vector2(size.x * 0.22, size.y * 0.54),
			Vector2(size.x * 0.2, size.y * 0.5),
		]),
		Color(0.12, 0.14, 0.11, 0.8)
	)

	if _should_show_figure(cam_id, anomaly):
		var kind := _anomaly_visual_kind()
		_draw_figure(cx, size.y * 0.4, anomaly, kind)
		if kind == "duplicate":
			_draw_figure(cx + size.x * 0.22, size.y * 0.41, true, "faceless")


func _draw_lobby(cx: float, floor_col: Color, wall_col: Color, anomaly: bool) -> void:
	draw_rect(Rect2(0, size.y * 0.5, size.x, size.y * 0.5), floor_col)
	draw_rect(Rect2(size.x * 0.08, size.y * 0.15, size.x * 0.22, size.y * 0.38), wall_col)
	draw_rect(Rect2(size.x * 0.7, size.y * 0.15, size.x * 0.22, size.y * 0.38), wall_col)
	# Revolving doors (glass)
	draw_rect(Rect2(size.x * 0.38, size.y * 0.22, size.x * 0.24, size.y * 0.32), Color(0.08, 0.1, 0.09, 0.9))
	draw_line(Vector2(size.x * 0.5, size.y * 0.24), Vector2(size.x * 0.5, size.y * 0.52), Color(0.25, 0.3, 0.28, 0.5), 2.0)
	draw_rect(Rect2(size.x * 0.35, size.y * 0.58, size.x * 0.3, size.y * 0.06), Color(0.14, 0.12, 0.1))
	if anomaly:
		_draw_figure(cx, size.y * 0.38, true, "faceless")


func _draw_elevator(cx: float, anomaly: bool) -> void:
	draw_rect(Rect2(size.x * 0.32, size.y * 0.06, size.x * 0.36, size.y * 0.9), Color(0.07, 0.08, 0.07))
	draw_rect(Rect2(size.x * 0.36, size.y * 0.12, size.x * 0.28, size.y * 0.78), Color(0.1, 0.12, 0.1))
	# Floor indicator
	draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.4, size.y * 0.2), "8|9", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.7, 0.6))
	draw_line(Vector2(size.x * 0.36, size.y * 0.25), Vector2(size.x * 0.64, size.y * 0.25), Color(0.2, 0.22, 0.2), 2.0)
	if anomaly:
		# Figure on roof of cab
		draw_rect(Rect2(cx - 18, size.y * 0.08, 36, 8), Color(0.25, 0.1, 0.1))
		_draw_figure(cx, size.y * 0.22, true, "faceless")


func _draw_staircase(anomaly: bool) -> void:
	for i in 8:
		var y := size.y * 0.15 + i * size.y * 0.09
		var inset := i * 6.0
		draw_line(
			Vector2(size.x * 0.15 + inset, y),
			Vector2(size.x * 0.85 - inset, y + 6),
			Color(0.15, 0.18, 0.14),
			3.0
		)
	# Handrail
	draw_line(Vector2(size.x * 0.2, size.y * 0.15), Vector2(size.x * 0.2, size.y * 0.88), Color(0.22, 0.24, 0.2), 2.0)
	if anomaly:
		for i in 3:
			var ry := size.y * (0.35 + i * 0.12)
			draw_rect(Rect2(size.x * 0.42, ry, size.x * 0.16, 3), Color(0.95, 0.25, 0.15, 0.85))


func _draw_door_unit(x: float, y: float, label: String, wrong: bool) -> void:
	var col := Color(0.1, 0.08, 0.08) if not wrong else Color(0.18, 0.08, 0.08)
	draw_rect(Rect2(x - 14, y, 28, 42), col)
	draw_rect(Rect2(x - 12, y + 18, 24, 24), Color(0.06, 0.07, 0.06))
	var lc := Color(0.75, 0.9, 0.75) if not wrong else Color(0.95, 0.3, 0.25)
	draw_string(ThemeDB.fallback_font, Vector2(x - 10, y + 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, lc)


func _active_anomaly() -> String:
	if CallManager.active_scenario:
		return CallManager.active_scenario.anomaly_id
	return ""


func _should_show_figure(cam_id: String, anomaly: bool) -> bool:
	if not anomaly:
		return cam_id.begins_with("floor") and randf() > 0.82
	var aid := _active_anomaly()
	if aid == "duplicate_person":
		return cam_id == "floor_2_corridor" or cam_id == "floor_4_corridor"
	return true


func _anomaly_visual_kind() -> String:
	match _active_anomaly():
		"faceless_tenant":
			return "faceless"
		"wrong_apartment_number":
			return "door"
		"duplicate_person":
			return "duplicate"
		"corridor_expansion":
			return "stretch"
		"fake_child_voice":
			return "small"
		_:
			return "faceless"


func _draw_figure(x: float, y: float, anomaly: bool, kind: String) -> void:
	if kind == "door":
		return
	var scale := 0.65 if kind == "small" else 1.0
	var body_col := Color(0.18, 0.22, 0.18) if not anomaly else Color(0.42, 0.14, 0.14)
	var h := 72.0 * scale
	# Shadow
	draw_ellipse(Vector2(x, y + h), size.x * 0.06 * scale, 6.0, Color(0, 0, 0, 0.35))
	# Body
	draw_rect(Rect2(x - 13 * scale, y, 26 * scale, h), body_col)
	# Head
	if kind == "faceless":
		draw_rect(Rect2(x - 15 * scale, y - 24 * scale, 30 * scale, 24 * scale), Color(0.32, 0.1, 0.12))
		# Empty face — darker oval
		draw_ellipse(Vector2(x, y - 12 * scale), 10 * scale, 8 * scale, Color(0.08, 0.02, 0.02))
	elif kind == "small":
		draw_circle(Vector2(x, y - 10 * scale), 11 * scale, Color(0.35, 0.12, 0.14))
	else:
		draw_circle(Vector2(x, y - 10 * scale), 12 * scale, Color(0.2, 0.24, 0.2))


func _draw_scanlines() -> void:
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0, 0, 0, 0.1), 1.0)
		y += 2.0


func _draw_vignette() -> void:
	var steps := 8
	for i in steps:
		var a := 0.04 + i * 0.025
		var m := float(i) * 6.0
		draw_rect(Rect2(0, 0, size.x, m), Color(0, 0, 0, a))
		draw_rect(Rect2(0, size.y - m, size.x, m), Color(0, 0, 0, a))
		draw_rect(Rect2(0, 0, m, size.y), Color(0, 0, 0, a))
		draw_rect(Rect2(size.x - m, 0, m, size.y), Color(0, 0, 0, a))


func _draw_noise() -> void:
	for i in 40:
		var px := randf() * size.x
		var py := randf() * size.y
		draw_rect(Rect2(px, py, 1, 1), Color(1, 1, 1, randf_range(0.02, 0.07)))


func _draw_timestamp() -> void:
	var t := Time.get_time_dict_from_system()
	var txt := "REC %02d:%02d:%02d" % [t.hour, t.minute, t.second]
	draw_string(ThemeDB.fallback_font, Vector2(8, size.y - 10), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.75, 0.9, 0.75, 0.85))


func _draw_rec_indicator() -> void:
	var blink := int(Time.get_ticks_msec() / 500) % 2 == 0
	if blink:
		draw_circle(Vector2(size.x - 14, size.y - 14), 5, Color(0.95, 0.15, 0.12, 0.95))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 52, size.y - 10), "REC", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.35, 0.3))


func _draw_corruption(amount: float) -> void:
	var bands := int(4 + amount * 10)
	for i in bands:
		var y := randf() * size.y
		var h := randf_range(2.0, 10.0 + amount * 18.0)
		var ox := randf_range(-24.0, 24.0) * amount
		draw_rect(Rect2(ox, y, size.x, h), Color(1, 1, 1, 0.05 + amount * 0.07))
