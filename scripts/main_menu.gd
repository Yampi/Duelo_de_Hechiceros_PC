extends Control

const SettingsManager = preload("res://scripts/settings_manager.gd")
const UIConstants = preload("res://scripts/ui/ui_constants.gd")

@onready var title_label: Label = find_child("Title", true, false)
@onready var subtitle_label: Label = find_child("Subtitle", true, false)
@onready var main_nav: VBoxContainer = find_child("MainNav", true, false)
@onready var modes_panel: PanelContainer = find_child("ModesPanel", true, false)

@onready var btn_play: Button = find_child("BtnPlay", true, false)
@onready var btn_settings: Button = find_child("BtnSettings", true, false)
@onready var btn_credits: Button = find_child("BtnCredits", true, false)
@onready var btn_quit: Button = find_child("BtnQuit", true, false)

@onready var btn_survival: Button = find_child("BtnSurvival", true, false)
@onready var btn_exploration: Button = find_child("BtnExploration", true, false)
@onready var btn_objective: Button = find_child("BtnObjective", true, false)
@onready var btn_back_modes: Button = find_child("BtnBackModes", true, false)

@onready var settings_modal: Control = find_child("SettingsModal", true, false)
@onready var credits_modal: Control = find_child("CreditsModal", true, false)
@onready var btn_close_credits: Button = find_child("BtnCloseCredits", true, false)

@onready var wizard_model: Node3D = find_child("WizardModel", true, false)
@onready var cam_3d: Camera3D = find_child("MenuCamera", true, false)

var _time: float = 0.0

func _ready() -> void:
	SettingsManager.init_settings()
	
	# Start main menu music
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_music"):
		am.play_music("exploration", 1.2)
	
	_connect_buttons()
	_setup_3d_wizard()
	_animate_staggered_entrance()

func _setup_3d_wizard() -> void:
	if wizard_model:
		var anim = wizard_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim:
			if anim.has_animation("CharacterArmature|Idle"):
				anim.play("CharacterArmature|Idle")
			elif anim.has_animation("Idle"):
				anim.play("Idle")

func _connect_buttons() -> void:
	if btn_play:
		btn_play.pressed.connect(_show_mode_selection)
	if btn_settings:
		btn_settings.pressed.connect(_on_settings_pressed)
	if btn_credits:
		btn_credits.pressed.connect(_on_credits_pressed)
	if btn_quit:
		btn_quit.pressed.connect(func(): get_tree().quit())
	
	if btn_survival:
		btn_survival.pressed.connect(func(): _start_game(GameManager.GameMode.SURVIVAL))
	if btn_exploration:
		btn_exploration.pressed.connect(func(): _start_game(GameManager.GameMode.EXPLORATION))
	if btn_objective:
		btn_objective.pressed.connect(func(): _start_game(GameManager.GameMode.OBJECTIVE))
	if btn_back_modes:
		btn_back_modes.pressed.connect(_hide_mode_selection)
	
	if btn_close_credits:
		btn_close_credits.pressed.connect(func():
			if credits_modal: credits_modal.visible = false
			if btn_credits: btn_credits.grab_focus()
		)
	
	if settings_modal and settings_modal.has_signal("settings_closed"):
		settings_modal.settings_closed.connect(func():
			if btn_settings: btn_settings.grab_focus()
		)

func _animate_staggered_entrance() -> void:
	if modes_panel:
		modes_panel.visible = false
	if credits_modal:
		credits_modal.visible = false
	
	# Title pop
	if title_label:
		title_label.modulate.a = 0.0
		var t_tween = create_tween()
		t_tween.tween_property(title_label, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Staggered button slide
	if main_nav:
		var buttons = main_nav.get_children()
		for i in range(buttons.size()):
			var btn = buttons[i] as Control
			if btn:
				btn.modulate.a = 0.0
				var orig_x = btn.position.x
				btn.position.x = orig_x - 30.0
				var b_tween = create_tween()
				b_tween.tween_interval(0.12 * (i + 1))
				b_tween.tween_property(btn, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD)
				b_tween.parallel().tween_property(btn, "position:x", orig_x, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if btn_play:
		btn_play.grab_focus()

func _show_mode_selection() -> void:
	if main_nav:
		var t = create_tween()
		t.tween_property(main_nav, "modulate:a", 0.0, 0.15)
		t.tween_callback(func(): main_nav.visible = false)
	
	if modes_panel:
		modes_panel.visible = true
		modes_panel.modulate.a = 0.0
		modes_panel.scale = Vector2(0.92, 0.92)
		modes_panel.pivot_offset = modes_panel.size * 0.5
		var t = create_tween()
		t.tween_interval(0.12)
		t.tween_property(modes_panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(modes_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if btn_survival:
			btn_survival.grab_focus()

func _hide_mode_selection() -> void:
	if modes_panel:
		var t = create_tween()
		t.tween_property(modes_panel, "modulate:a", 0.0, 0.15)
		t.tween_callback(func():
			modes_panel.visible = false
			if main_nav:
				main_nav.visible = true
				var t_nav = create_tween()
				t_nav.tween_property(main_nav, "modulate:a", 1.0, 0.2)
				if btn_play: btn_play.grab_focus()
		)

func _start_game(mode: GameManager.GameMode) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("click")
	
	# Smooth fade out before loading
	var fade = find_child("ScreenFade", true, false)
	if fade:
		fade.modulate.a = 0.0
		var t = create_tween()
		t.tween_property(fade, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_callback(func(): GameManager.start_game(mode))
	else:
		GameManager.start_game(mode)

func _on_settings_pressed() -> void:
	if settings_modal and settings_modal.has_method("open_modal"):
		settings_modal.open_modal()

func _on_credits_pressed() -> void:
	if credits_modal:
		credits_modal.visible = true
		credits_modal.modulate.a = 0.0
		var t = create_tween()
		t.tween_property(credits_modal, "modulate:a", 1.0, 0.2)
		if btn_close_credits:
			btn_close_credits.grab_focus()

func _process(delta: float) -> void:
	_time += delta
	
	# Shimmer pulse on title
	if title_label:
		var shine = (sin(_time * 2.0) + 1.0) * 0.5
		var col = lerp(Color(1.0, 0.88, 0.45), Color(1.2, 1.05, 0.7), shine)
		title_label.add_theme_color_override("font_color", col)
	
	# Gentle slow camera floating
	if cam_3d:
		cam_3d.position.x = sin(_time * 0.4) * 0.2
		cam_3d.position.y = 1.35 + (cos(_time * 0.5) * 0.08)
	
	# Subtle slow rotation of wizard
	if wizard_model:
		wizard_model.rotation.y = sin(_time * 0.3) * 0.15
