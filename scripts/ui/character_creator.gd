class_name CharacterCreator
extends Control

signal appearance_saved(config: Dictionary)
signal creator_closed

const UIConstants = preload("res://scripts/ui/ui_constants.gd")
const CharacterAppearance = preload("res://scripts/character_appearance.gd")

@onready var turntable: Node3D = find_child("Turntable", true, false)
@onready var preview_model: Node3D = find_child("WizardModel", true, false)
@onready var anim_player: AnimationPlayer = null

@onready var edit_name: LineEdit = find_child("EditName", true, false)

@onready var container_robe: GridContainer = find_child("GridRobe", true, false)
@onready var container_skin: GridContainer = find_child("GridSkin", true, false)
@onready var container_eyes: GridContainer = find_child("GridEyes", true, false)
@onready var container_trim: GridContainer = find_child("GridTrim", true, false)
@onready var container_gem: GridContainer = find_child("GridGem", true, false)
@onready var container_expr: VBoxContainer = find_child("VBoxExpr", true, false)

@onready var btn_auto_rotate: Button = find_child("BtnAutoRotate", true, false)
@onready var btn_rot_left: Button = find_child("BtnRotLeft", true, false)
@onready var btn_rot_right: Button = find_child("BtnRotRight", true, false)

@onready var btn_anim_idle: Button = find_child("BtnAnimIdle", true, false)
@onready var btn_anim_cast: Button = find_child("BtnAnimCast", true, false)
@onready var btn_anim_run: Button = find_child("BtnAnimRun", true, false)
@onready var btn_anim_hit: Button = find_child("BtnAnimHit", true, false)

@onready var btn_random: Button = find_child("BtnRandom", true, false)
@onready var btn_reset: Button = find_child("BtnReset", true, false)
@onready var btn_save: Button = find_child("BtnSave", true, false)
@onready var btn_back: Button = find_child("BtnBack", true, false)
@onready var lbl_status: Label = find_child("LblStatus", true, false)

var current_config: Dictionary = {}
var auto_rotate: bool = true
var rotate_speed: float = 0.8
var manual_rot_target: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if preview_model:
		anim_player = preview_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim_player:
			_play_preview_anim("Idle")
	
	current_config = CharacterAppearance.load_config()
	if edit_name:
		edit_name.text = current_config.get("character_name", "Cornelius")
		edit_name.text_changed.connect(func(new_text: String): current_config["character_name"] = new_text)
	
	_setup_option_buttons()
	_connect_controls()
	_refresh_preview()

func _process(delta: float) -> void:
	if not visible:
		return
	
	if turntable:
		if auto_rotate:
			turntable.rotation.y += rotate_speed * delta
		else:
			turntable.rotation.y = lerp_angle(turntable.rotation.y, manual_rot_target, 10.0 * delta)

func open_creator() -> void:
	visible = true
	current_config = CharacterAppearance.load_config()
	if edit_name:
		edit_name.text = current_config.get("character_name", "Cornelius")
	if lbl_status:
		lbl_status.text = ""
	_refresh_preview()
	_update_active_button_highlights()
	
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("open")

func close_creator() -> void:
	visible = false
	creator_closed.emit()
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("close")

func _setup_option_buttons() -> void:
	# 1. Túnica
	if container_robe:
		for child in container_robe.get_children():
			child.queue_free()
		for i in range(CharacterAppearance.ROBE_COLORS.size()):
			var opt = CharacterAppearance.ROBE_COLORS[i]
			var btn = _create_swatch_button(opt["name"], opt["color"], func():
				current_config["robe_color_idx"] = i
				_refresh_preview()
				_update_active_button_highlights()
			)
			container_robe.add_child(btn)
	
	# 2. Tez / Piel
	if container_skin:
		for child in container_skin.get_children():
			child.queue_free()
		for i in range(CharacterAppearance.SKIN_TONES.size()):
			var opt = CharacterAppearance.SKIN_TONES[i]
			var btn = _create_swatch_button(opt["name"], opt["color"], func():
				current_config["skin_tone_idx"] = i
				_refresh_preview()
				_update_active_button_highlights()
			)
			container_skin.add_child(btn)
	
	# 3. Ojos / Mirada
	if container_eyes:
		for child in container_eyes.get_children():
			child.queue_free()
		for i in range(CharacterAppearance.EYE_COLORS.size()):
			var opt = CharacterAppearance.EYE_COLORS[i]
			var btn = _create_swatch_button(opt["name"], opt["color"], func():
				current_config["eye_type_idx"] = i
				_refresh_preview()
				_update_active_button_highlights()
			)
			container_eyes.add_child(btn)
	
	# 4. Hombreras / Acentos Metálicos
	if container_trim:
		for child in container_trim.get_children():
			child.queue_free()
		for i in range(CharacterAppearance.TRIM_COLORS.size()):
			var opt = CharacterAppearance.TRIM_COLORS[i]
			var btn = _create_swatch_button(opt["name"], opt["color"], func():
				current_config["trim_color_idx"] = i
				_refresh_preview()
				_update_active_button_highlights()
			)
			container_trim.add_child(btn)
	
	# 5. Gema de Bastón
	if container_gem:
		for child in container_gem.get_children():
			child.queue_free()
		for i in range(CharacterAppearance.GEM_COLORS.size()):
			var opt = CharacterAppearance.GEM_COLORS[i]
			var btn = _create_swatch_button(opt["name"], opt["color"], func():
				current_config["staff_gem_idx"] = i
				_refresh_preview()
				_update_active_button_highlights()
			)
			container_gem.add_child(btn)
	
	# 6. Porte / Expresión
	if container_expr:
		for child in container_expr.get_children():
			child.queue_free()
		for i in range(CharacterAppearance.EXPRESSION_STYLES.size()):
			var opt = CharacterAppearance.EXPRESSION_STYLES[i]
			var btn = Button.new()
			btn.text = "✦ " + opt["name"] + " — " + opt["desc"]
			btn.custom_minimum_size = Vector2(0, 34)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.pressed.connect(func():
				current_config["expression_idx"] = i
				_refresh_preview()
				_update_active_button_highlights()
			)
			container_expr.add_child(btn)

func _create_swatch_button(label_text: String, col: Color, on_click: Callable) -> Button:
	var btn = Button.new()
	btn.text = " " + label_text
	btn.custom_minimum_size = Vector2(170, 36)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Generar mini icono de color
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(col)
	var tex = ImageTexture.create_from_image(img)
	btn.icon = tex
	btn.pressed.connect(func():
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_ui"):
			am.play_ui("click")
		on_click.call()
	)
	return btn

func _connect_controls() -> void:
	if btn_auto_rotate:
		btn_auto_rotate.pressed.connect(func():
			auto_rotate = not auto_rotate
			btn_auto_rotate.text = "Giro Auto: ON" if auto_rotate else "Giro Auto: OFF"
			if not auto_rotate and turntable:
				manual_rot_target = turntable.rotation.y
		)
	
	if btn_rot_left:
		btn_rot_left.pressed.connect(func():
			auto_rotate = false
			if btn_auto_rotate: btn_auto_rotate.text = "Giro Auto: OFF"
			manual_rot_target -= deg_to_rad(45.0)
		)
	
	if btn_rot_right:
		btn_rot_right.pressed.connect(func():
			auto_rotate = false
			if btn_auto_rotate: btn_auto_rotate.text = "Giro Auto: OFF"
			manual_rot_target += deg_to_rad(45.0)
		)
	
	# Botones de animación de prueba
	if btn_anim_idle:
		btn_anim_idle.pressed.connect(func(): _play_preview_anim("Idle"))
	if btn_anim_cast:
		btn_anim_cast.pressed.connect(func(): _play_preview_anim("Spell1"))
	if btn_anim_run:
		btn_anim_run.pressed.connect(func(): _play_preview_anim("Run"))
	if btn_anim_hit:
		btn_anim_hit.pressed.connect(func(): _play_preview_anim("RecieveHit"))
	
	# Botones de acción principales
	if btn_random:
		btn_random.pressed.connect(_on_randomize)
	if btn_reset:
		btn_reset.pressed.connect(_on_reset)
	if btn_save:
		btn_save.pressed.connect(_on_save)
	if btn_back:
		btn_back.pressed.connect(close_creator)

func _play_preview_anim(anim_name: String) -> void:
	if not anim_player:
		return
	var full_name = "CharacterArmature|" + anim_name
	if anim_player.has_animation(full_name):
		anim_player.play(full_name)
	elif anim_player.has_animation(anim_name):
		anim_player.play(anim_name)

func _refresh_preview() -> void:
	if preview_model:
		CharacterAppearance.apply_to_model(preview_model, current_config)

func _update_active_button_highlights() -> void:
	_highlight_selected_in_container(container_robe, current_config.get("robe_color_idx", 0))
	_highlight_selected_in_container(container_skin, current_config.get("skin_tone_idx", 0))
	_highlight_selected_in_container(container_eyes, current_config.get("eye_type_idx", 0))
	_highlight_selected_in_container(container_trim, current_config.get("trim_color_idx", 0))
	_highlight_selected_in_container(container_gem, current_config.get("staff_gem_idx", 0))
	_highlight_selected_in_container(container_expr, current_config.get("expression_idx", 0))

func _highlight_selected_in_container(container: Container, selected_idx: int) -> void:
	if not container:
		return
	var children = container.get_children()
	for i in range(children.size()):
		var btn = children[i] as Button
		if btn:
			if i == selected_idx:
				btn.add_theme_color_override("font_color", UIConstants.GOLD_BASE)
			else:
				btn.remove_theme_color_override("font_color")

func _on_randomize() -> void:
	current_config["robe_color_idx"] = randi() % CharacterAppearance.ROBE_COLORS.size()
	current_config["skin_tone_idx"] = randi() % CharacterAppearance.SKIN_TONES.size()
	current_config["eye_type_idx"] = randi() % CharacterAppearance.EYE_COLORS.size()
	current_config["trim_color_idx"] = randi() % CharacterAppearance.TRIM_COLORS.size()
	current_config["staff_gem_idx"] = randi() % CharacterAppearance.GEM_COLORS.size()
	current_config["expression_idx"] = randi() % CharacterAppearance.EXPRESSION_STYLES.size()
	
	_refresh_preview()
	_update_active_button_highlights()
	
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("click")

func _on_reset() -> void:
	current_config = CharacterAppearance.get_default_config()
	if edit_name:
		edit_name.text = current_config["character_name"]
	_refresh_preview()
	_update_active_button_highlights()
	
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("click")

func _on_save() -> void:
	if edit_name:
		current_config["character_name"] = edit_name.text.strip_edges()
	
	var ok = CharacterAppearance.save_config(current_config)
	if ok:
		if lbl_status:
			lbl_status.text = "✓ ¡Apariencia de " + current_config["character_name"] + " guardada con éxito!"
			lbl_status.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_ui"):
			am.play_ui("loot")
		
		appearance_saved.emit(current_config)
	else:
		if lbl_status:
			lbl_status.text = "✕ Error al guardar archivo de configuración."
			lbl_status.add_theme_color_override("font_color", UIConstants.DANGER_RED)
