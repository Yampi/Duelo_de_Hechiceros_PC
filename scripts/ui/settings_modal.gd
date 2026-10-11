class_name SettingsModal
extends Control

const SettingsManager = preload("res://scripts/settings_manager.gd")
const UIConstants = preload("res://scripts/ui/ui_constants.gd")

signal settings_closed

@onready var slider_master: HSlider = find_child("SliderMaster", true, false)
@onready var lbl_master: Label = find_child("LblMasterVal", true, false)

@onready var slider_music: HSlider = find_child("SliderMusic", true, false)
@onready var lbl_music: Label = find_child("LblMusicVal", true, false)

@onready var slider_sfx: HSlider = find_child("SliderSFX", true, false)
@onready var lbl_sfx: Label = find_child("LblSFXVal", true, false)

@onready var slider_ui: HSlider = find_child("SliderUI", true, false)
@onready var lbl_ui: Label = find_child("LblUIVal", true, false)

@onready var check_fullscreen: CheckBox = find_child("CheckFullscreen", true, false)
@onready var check_shake: CheckBox = find_child("CheckShake", true, false)
@onready var check_flashes: CheckBox = find_child("CheckFlashes", true, false)
@onready var check_hints: CheckBox = find_child("CheckHints", true, false)

@onready var slider_scale: HSlider = find_child("SliderScale", true, false)
@onready var lbl_scale: Label = find_child("LblScaleVal", true, false)

@onready var btn_save: Button = find_child("BtnSave", true, false)
@onready var btn_close: Button = find_child("BtnClose", true, false)
@onready var panel: PanelContainer = find_child("Panel", true, false)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SettingsManager.init_settings()
	_sync_ui_from_settings()
	_connect_signals()
	visible = false

func _connect_signals() -> void:
	if slider_master:
		slider_master.value_changed.connect(func(v):
			lbl_master.text = "%d%%" % int(v * 100)
			SettingsManager.master_volume = v
			SettingsManager.apply_all()
		)
	if slider_music:
		slider_music.value_changed.connect(func(v):
			lbl_music.text = "%d%%" % int(v * 100)
			SettingsManager.music_volume = v
			SettingsManager.apply_all()
		)
	if slider_sfx:
		slider_sfx.value_changed.connect(func(v):
			lbl_sfx.text = "%d%%" % int(v * 100)
			SettingsManager.sfx_volume = v
			SettingsManager.apply_all()
		)
	if slider_ui:
		slider_ui.value_changed.connect(func(v):
			lbl_ui.text = "%d%%" % int(v * 100)
			SettingsManager.ui_volume = v
			SettingsManager.apply_all()
		)
	if slider_scale:
		slider_scale.value_changed.connect(func(v):
			lbl_scale.text = "%d%%" % int(v * 100)
			SettingsManager.ui_scale = v
		)
	
	if check_fullscreen:
		check_fullscreen.toggled.connect(func(t): SettingsManager.fullscreen = t; SettingsManager.apply_all())
	if check_shake:
		check_shake.toggled.connect(func(t): SettingsManager.reduce_shake = t)
	if check_flashes:
		check_flashes.toggled.connect(func(t): SettingsManager.reduce_flashes = t)
	if check_hints:
		check_hints.toggled.connect(func(t): SettingsManager.show_control_hints = t)
	
	if btn_save:
		btn_save.pressed.connect(_on_save_pressed)
	if btn_close:
		btn_close.pressed.connect(close_modal)

func _sync_ui_from_settings() -> void:
	if slider_master:
		slider_master.value = SettingsManager.master_volume
		if lbl_master: lbl_master.text = "%d%%" % int(SettingsManager.master_volume * 100)
	if slider_music:
		slider_music.value = SettingsManager.music_volume
		if lbl_music: lbl_music.text = "%d%%" % int(SettingsManager.music_volume * 100)
	if slider_sfx:
		slider_sfx.value = SettingsManager.sfx_volume
		if lbl_sfx: lbl_sfx.text = "%d%%" % int(SettingsManager.sfx_volume * 100)
	if slider_ui:
		slider_ui.value = SettingsManager.ui_volume
		if lbl_ui: lbl_ui.text = "%d%%" % int(SettingsManager.ui_volume * 100)
	if slider_scale:
		slider_scale.value = SettingsManager.ui_scale
		if lbl_scale: lbl_scale.text = "%d%%" % int(SettingsManager.ui_scale * 100)
	
	if check_fullscreen: check_fullscreen.button_pressed = SettingsManager.fullscreen
	if check_shake: check_shake.button_pressed = SettingsManager.reduce_shake
	if check_flashes: check_flashes.button_pressed = SettingsManager.reduce_flashes
	if check_hints: check_hints.button_pressed = SettingsManager.show_control_hints

func open_modal() -> void:
	_sync_ui_from_settings()
	visible = true
	modulate.a = 0.0
	if panel:
		panel.scale = Vector2(0.92, 0.92)
		panel.pivot_offset = panel.size * 0.5
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if panel:
		tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("open")
	
	if btn_save:
		btn_save.grab_focus()

func close_modal() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if panel:
		tween.parallel().tween_property(panel, "scale", Vector2(0.92, 0.92), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		visible = false
		settings_closed.emit()
	)
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("close")

func _on_save_pressed() -> void:
	SettingsManager.save_to_disk()
	close_modal()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		close_modal()
		get_viewport().set_input_as_handled()
