extends Control

@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var volume_slider: HSlider = %VolumeSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var vo_slider: HSlider = %VoSlider
@onready var vo_check: CheckButton = %VoCheck
@onready var subtitles_check: CheckButton = %SubtitlesCheck
@onready var language_option: OptionButton = %LanguageOption
@onready var back_button: Button = %SettingsBackButton
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var settings_title: Label = %SettingsTitle


func _ready() -> void:
	start_button.pressed.connect(_on_start)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	back_button.pressed.connect(_on_settings_back)
	fullscreen_check.toggled.connect(_on_fullscreen)
	volume_slider.value_changed.connect(_on_volume)
	sfx_slider.value_changed.connect(_on_sfx)
	music_slider.value_changed.connect(_on_music)
	vo_slider.value_changed.connect(_on_vo_volume)
	vo_check.toggled.connect(_on_vo_enabled)
	subtitles_check.toggled.connect(_on_subtitles)
	language_option.item_selected.connect(_on_language_selected)

	_setup_language_option()
	_load_settings_to_ui()
	_apply_menu_text()
	settings_panel.hide()

	if LocaleManager:
		LocaleManager.locale_changed.connect(_apply_menu_text)


func _tr(key: String) -> String:
	return LocaleManager.tr_ui(key) if LocaleManager else key


func _setup_language_option() -> void:
	language_option.clear()
	language_option.add_item(_tr("ui.settings.lang_en"), 0)
	language_option.set_item_metadata(0, "en")
	language_option.add_item(_tr("ui.settings.lang_uk"), 1)
	language_option.set_item_metadata(1, "uk")
	language_option.selected = 0 if SettingsManager.locale == "en" else 1


func _load_settings_to_ui() -> void:
	fullscreen_check.button_pressed = SettingsManager.fullscreen
	volume_slider.value = SettingsManager.master_volume
	sfx_slider.value = SettingsManager.sfx_volume
	music_slider.value = SettingsManager.music_volume
	vo_slider.value = SettingsManager.vo_volume
	vo_check.button_pressed = SettingsManager.vo_enabled
	subtitles_check.button_pressed = SettingsManager.subtitles_enabled


func _apply_menu_text() -> void:
	title_label.text = _tr("ui.menu.title")
	subtitle_label.text = _tr("ui.menu.subtitle")
	start_button.text = _tr("ui.menu.start")
	settings_button.text = _tr("ui.menu.settings")
	quit_button.text = _tr("ui.menu.quit")
	settings_title.text = _tr("ui.settings.title")
	fullscreen_check.text = _tr("ui.settings.fullscreen")
	%VolumeLabel.text = _tr("ui.settings.master")
	%SfxLabel.text = _tr("ui.settings.sfx")
	%MusicLabel.text = _tr("ui.settings.music")
	%VoLabel.text = _tr("ui.settings.vo")
	vo_check.text = _tr("ui.settings.vo_enabled")
	%LanguageLabel.text = _tr("ui.settings.language")
	subtitles_check.text = _tr("ui.settings.subtitles")
	back_button.text = _tr("ui.settings.back")
	_setup_language_option()


func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/office/office_root.tscn")


func _on_settings() -> void:
	settings_panel.show()


func _on_settings_back() -> void:
	settings_panel.hide()


func _on_quit() -> void:
	get_tree().quit()


func _on_fullscreen(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)


func _on_volume(value: float) -> void:
	SettingsManager.set_master_volume(value)


func _on_sfx(value: float) -> void:
	SettingsManager.set_sfx_volume(value)


func _on_music(value: float) -> void:
	SettingsManager.set_music_volume(value)


func _on_vo_volume(value: float) -> void:
	SettingsManager.set_vo_volume(value)


func _on_vo_enabled(enabled: bool) -> void:
	SettingsManager.set_vo_enabled(enabled)


func _on_subtitles(enabled: bool) -> void:
	SettingsManager.subtitles_enabled = enabled
	SettingsManager.save_settings()


func _on_language_selected(index: int) -> void:
	var locale: String = language_option.get_item_metadata(index)
	SettingsManager.set_locale(locale)
