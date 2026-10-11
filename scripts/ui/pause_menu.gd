class_name PauseMenu
extends Control

signal resumed
signal menu_requested

@onready var btn_resume: Button = find_child("BtnResume", true, false)
@onready var btn_settings: Button = find_child("BtnSettings", true, false)
@onready var btn_menu: Button = find_child("BtnMenu", true, false)
@onready var panel: PanelContainer = find_child("Panel", true, false)
@onready var settings_modal: Control = find_child("SettingsModal", true, false)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	if btn_resume:
		btn_resume.pressed.connect(resume_game)
	if btn_settings:
		btn_settings.pressed.connect(_on_settings_pressed)
	if btn_menu:
		btn_menu.pressed.connect(_on_menu_pressed)
	if settings_modal and settings_modal.has_signal("settings_closed"):
		settings_modal.settings_closed.connect(func():
			if visible and btn_settings:
				btn_settings.grab_focus()
		)

func toggle_pause() -> void:
	if visible:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:
	get_tree().paused = true
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
	
	if btn_resume:
		btn_resume.grab_focus()

func resume_game() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if panel:
		tween.parallel().tween_property(panel, "scale", Vector2(0.92, 0.92), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		visible = false
		get_tree().paused = false
		resumed.emit()
	)
	
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("close")

func _on_settings_pressed() -> void:
	if settings_modal and settings_modal.has_method("open_modal"):
		settings_modal.open_modal()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	menu_requested.emit()
	GameManager.return_to_main_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if settings_modal and settings_modal.visible:
			return # Let settings modal handle its own close
		toggle_pause()
		get_viewport().set_input_as_handled()
