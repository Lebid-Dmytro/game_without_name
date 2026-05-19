extends SceneTree

## Headless smoke test — run: Godot --headless --script res://tools/smoke_test.gd

const VO_SAMPLE := "res://audio/vo/uk/faceless_01/opening.ogg"


func _initialize() -> void:
	var errors: Array[String] = []
	_check_autoloads(errors)
	_check_scenes(errors)
	_check_vo(errors)
	_check_translations(errors)
	_check_scenarios(errors)

	if errors.is_empty():
		print("SMOKE_TEST: PASS (all checks ok)")
	else:
		print("SMOKE_TEST: FAIL")
		for e in errors:
			print("  - ", e)
	quit(1 if not errors.is_empty() else 0)


func _check_autoloads(errors: Array[String]) -> void:
	var names := [
		"GameManager", "CallManager", "CctvManager", "ThreatManager",
		"DecisionManager", "SaveManager", "SettingsManager",
		"LocaleManager", "VoiceManager", "AnomalyRegistry", "AudioManager",
	]
	var root := get_root()
	for n in names:
		if root == null or not root.has_node(n):
			errors.append("Missing autoload: %s" % n)


func _check_scenes(errors: Array[String]) -> void:
	for path in [
		"res://scenes/main_menu.tscn",
		"res://scenes/office/office_root.tscn",
		"res://scenes/office/office_ui.tscn",
	]:
		if not ResourceLoader.exists(path):
			errors.append("Missing scene: %s" % path)
			continue
		var err := ResourceLoader.load(path)
		if err == null:
			errors.append("Failed to load: %s" % path)


func _check_vo(errors: Array[String]) -> void:
	if not ResourceLoader.exists(VO_SAMPLE):
		errors.append("Missing VO sample: %s" % VO_SAMPLE)
		return
	var stream: AudioStream = load(VO_SAMPLE)
	if stream == null:
		errors.append("VO sample did not load as AudioStream")


func _check_translations(errors: Array[String]) -> void:
	var locale_mgr = get_root().get_node_or_null("LocaleManager")
	if locale_mgr == null:
		errors.append("LocaleManager not on root")
		return
	var uk: String = locale_mgr.tr_key("ui.menu.start", "")
	if uk == "" or uk == "ui.menu.start":
		errors.append("UK translation missing for ui.menu.start")
	var en: String = locale_mgr.tr_key("call.faceless_01.opening", "fallback")
	if en == "fallback":
		errors.append("EN call line missing for faceless_01.opening")


func _check_scenarios(errors: Array[String]) -> void:
	var dir := DirAccess.open("res://dialogue/scenarios")
	if dir == null:
		errors.append("Cannot open dialogue/scenarios")
		return
	var count := 0
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".json") and not f.begins_with("SCENARIOS"):
			count += 1
		f = dir.get_next()
	dir.list_dir_end()
	if count < 20:
		errors.append("Expected 20 scenarios, found %d" % count)
