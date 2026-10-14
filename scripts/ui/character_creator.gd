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
@onready var container_eye_shape: GridContainer = find_child("GridEyeShape", true, false)
@onready var container_hair: GridContainer = find_child("GridHair", true, false)
@onready var container_beard: GridContainer = find_child("GridBeard", true, false)
@onready var container_trim: GridContainer = find_child("GridTrim", true, false)
@onready var container_gem: GridContainer = find_child("GridGem", true, false)
@onready var container_expr: VBoxContainer = find_child("VBoxExpr", true, false)

@onready var btn_tab_face: Button = find_child("BtnTabFace", true, false)
@onready var btn_tab_robes: Button = find_child("BtnTabRobes", true, false)
@onready var btn_tab_staff: Button = find_child("BtnTabStaff", true, false)
@onready var btn_tab_identity: Button = find_child("BtnTabIdentity", true, false)

@onready var page_face: VBoxContainer = find_child("PageFace", true, false)
@onready var page_robes: VBoxContainer = find_child("PageRobes", true, false)
@onready var page_staff: VBoxContainer = find_child("PageStaff", true, false)
@onready var page_identity: VBoxContainer = find_child("PageIdentity", true, false)

@onready var cam_3d: Camera3D = find_child("Camera3D", true, false)
@onready var btn_view_face: Button = find_child("BtnViewFace", true, false)
@onready var btn_view_body: Button = find_child("BtnViewBody", true, false)
@onready var btn_view_staff: Button = find_child("BtnViewStaff", true, false)

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

enum CreatorTab { FACE, ROBES, STAFF, IDENTITY }
var current_tab: CreatorTab = CreatorTab.FACE

enum CameraMode { FULL_BODY, FACE, STAFF }
var current_camera_mode: CameraMode = CameraMode.FULL_BODY

var current_config: Dictionary = {}
var auto_rotate: bool = false
var rotate_speed: float = 0.8
var manual_rot_target: float = 0.0

var cam_target_pos: Vector3 = Vector3(0.0, 1.05, 3.65)
var cam_target_fov: float = 38.0
var cam_target_look: Vector3 = Vector3(0.0, 1.05, 0.0)
var cam_current_look: Vector3 = Vector3(0.0, 1.05, 0.0)

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
	
	select_tab(CreatorTab.FACE, false)
	set_camera_view_full_body()
	if cam_3d:
		cam_3d.position = cam_target_pos
		cam_3d.fov = cam_target_fov
		cam_current_look = cam_target_look
		cam_3d.look_at(cam_current_look, Vector3.UP)
	
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
	
	if cam_3d:
		cam_3d.position = cam_3d.position.lerp(cam_target_pos, 7.0 * delta)
		cam_3d.fov = lerp(cam_3d.fov, cam_target_fov, 7.0 * delta)
		cam_current_look = cam_current_look.lerp(cam_target_look, 7.0 * delta)
		cam_3d.look_at(cam_current_look, Vector3.UP)

func select_tab(tab: CreatorTab, sync_camera: bool = true) -> void:
	current_tab = tab
	if page_face:
		page_face.visible = (tab == CreatorTab.FACE)
	if page_robes:
		page_robes.visible = (tab == CreatorTab.ROBES)
	if page_staff:
		page_staff.visible = (tab == CreatorTab.STAFF)
	if page_identity:
		page_identity.visible = (tab == CreatorTab.IDENTITY)
	
	_update_tab_button_styles()
	
	if sync_camera:
		match tab:
			CreatorTab.FACE:
				set_camera_view_face()
			CreatorTab.ROBES:
				set_camera_view_full_body()
			CreatorTab.STAFF:
				set_camera_view_staff()
			CreatorTab.IDENTITY:
				set_camera_view_full_body()

func _update_tab_button_styles() -> void:
	var tabs = [
		{"btn": btn_tab_face, "active": current_tab == CreatorTab.FACE},
		{"btn": btn_tab_robes, "active": current_tab == CreatorTab.ROBES},
		{"btn": btn_tab_staff, "active": current_tab == CreatorTab.STAFF},
		{"btn": btn_tab_identity, "active": current_tab == CreatorTab.IDENTITY}
	]
	for t in tabs:
		if t["btn"]:
			if t["active"]:
				t["btn"].add_theme_color_override("font_color", UIConstants.GOLD_BASE)
			else:
				t["btn"].remove_theme_color_override("font_color")

func set_camera_view_full_body() -> void:
	current_camera_mode = CameraMode.FULL_BODY
	cam_target_pos = Vector3(0.0, 1.05, 3.65)
	cam_target_fov = 38.0
	cam_target_look = Vector3(0.0, 1.05, 0.0)
	_update_view_button_highlights()

func set_camera_view_face() -> void:
	current_camera_mode = CameraMode.FACE
	cam_target_pos = Vector3(0.0, 1.74, 1.45)
	cam_target_fov = 28.0
	cam_target_look = Vector3(0.0, 1.74, 0.0)
	_update_view_button_highlights()

func set_camera_view_staff() -> void:
	current_camera_mode = CameraMode.STAFF
	cam_target_pos = Vector3(-0.45, 0.95, 1.55)
	cam_target_fov = 32.0
	cam_target_look = Vector3(-0.40, 0.95, 0.0)
	_update_view_button_highlights()

func _update_view_button_highlights() -> void:
	if btn_view_face:
		btn_view_face.add_theme_color_override("font_color", UIConstants.GOLD_BASE if current_camera_mode == CameraMode.FACE else Color.WHITE)
	if btn_view_body:
		btn_view_body.add_theme_color_override("font_color", UIConstants.GOLD_BASE if current_camera_mode == CameraMode.FULL_BODY else Color.WHITE)
	if btn_view_staff:
		btn_view_staff.add_theme_color_override("font_color", UIConstants.GOLD_BASE if current_camera_mode == CameraMode.STAFF else Color.WHITE)

func open_creator() -> void:
	visible = true
	current_config = CharacterAppearance.load_config()
	if edit_name:
		edit_name.text = current_config.get("character_name", "Cornelius")
	if lbl_status:
		lbl_status.text = ""
	
	select_tab(CreatorTab.FACE, false)
	
	# Start facing directly at the player with clean full body framing
	if turntable:
		turntable.rotation.y = 0.0
	manual_rot_target = 0.0
	auto_rotate = false
	set_camera_view_full_body()
	if cam_3d:
		cam_3d.position = cam_target_pos
		cam_3d.fov = cam_target_fov
		cam_current_look = cam_target_look
		cam_3d.look_at(cam_current_look, Vector3.UP)
	if btn_auto_rotate:
		btn_auto_rotate.text = "Giro Auto: OFF"
	
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
	# 1. Tez / Piel (Enfoca rostro)
	if container_skin:
		for child in container_skin.get_children():
			child.queue_free()
		for i in range(CharacterAppearance.SKIN_TONES.size()):
			var opt = CharacterAppearance.SKIN_TONES[i]
			var btn = _create_swatch_button(opt["name"], opt["color"], func():
				set_camera_view_face()
				current_config["skin_tone_idx"] = i
				_refresh_preview()
				_update_active_button_highlights()
			)
			container_skin.add_child(btn)

	# 2. Forma de Ojos (Enfoca rostro)
	if container_eye_shape:
		for child in container_eye_shape.get_children():
			child.queue_free()
		for i in range(CharacterAppearance.EYE_SHAPES.size()):
			var opt = CharacterAppearance.EYE_SHAPES[i]
			var btn = _create_text_option_button(opt["name"], func():
				set_camera_view_face()
				current_config["eye_shape_idx"] = i
				_refresh_preview()
				_update_active_button_highlights()
			)
			container_eye_shape.add_child(btn)

	# 3. Ojos / Mirada (Enfoca rostro)
	if container_eyes:
		for child in container_eyes.get_children():
			child.queue_free()
		for i in range(CharacterAppearance.EYE_COLORS.size()):
			var opt = CharacterAppearance.EYE_COLORS[i]
			var btn = _create_swatch_button(opt["name"], opt["color"], func():
				set_camera_view_face()
				current_config["eye_type_idx"] = i
				_refresh_preview()
				_update_active_button_highlights()
			)
			container_eyes.add_child(btn)

	# 4. Tinte de Cabello y Barba (Enfoca rostro)
	if container_hair:
		for child in container_hair.get_children():
			child.queue_free()
		for i in range(CharacterAppearance.HAIR_COLORS.size()):
			var opt = CharacterAppearance.HAIR_COLORS[i]
			var btn = _create_swatch_button(opt["name"], opt["color"], func():
				set_camera_view_face()
				current_config["hair_color_idx"] = i
				_refresh_preview()
				_update_active_button_highlights()
			)
			container_hair.add_child(btn)

	# 5. Estilo y Porte de Barba (Enfoca rostro)
	if container_beard:
		for child in container_beard.get_children():
			child.queue_free()
		for i in range(CharacterAppearance.BEARD_STYLES.size()):
			var opt = CharacterAppearance.BEARD_STYLES[i]
			var btn = _create_text_option_button(opt["name"], func():
				set_camera_view_face()
				current_config["beard_style_idx"] = i
				_refresh_preview()
				_update_active_button_highlights()
			)
			container_beard.add_child(btn)

	# 6. Túnica (Cuerpo completo)
	if container_robe:
		for child in container_robe.get_children():
			child.queue_free()
		for i in range(CharacterAppearance.ROBE_COLORS.size()):
			var opt = CharacterAppearance.ROBE_COLORS[i]
			var btn = _create_swatch_button(opt["name"], opt["color"], func():
				set_camera_view_full_body()
				current_config["robe_color_idx"] = i
				_refresh_preview()
				_update_active_button_highlights()
			)
			container_robe.add_child(btn)

	# 7. Hombreras / Acentos Metálicos (Cuerpo completo)
	if container_trim:
		for child in container_trim.get_children():
			child.queue_free()
		for i in range(CharacterAppearance.TRIM_COLORS.size()):
			var opt = CharacterAppearance.TRIM_COLORS[i]
			var btn = _create_swatch_button(opt["name"], opt["color"], func():
				set_camera_view_full_body()
				current_config["trim_color_idx"] = i
				_refresh_preview()
				_update_active_button_highlights()
			)
			container_trim.add_child(btn)

	# 8. Gema de Bastón (Enfoca bastón)
	if container_gem:
		for child in container_gem.get_children():
			child.queue_free()
		for i in range(CharacterAppearance.GEM_COLORS.size()):
			var opt = CharacterAppearance.GEM_COLORS[i]
			var btn = _create_swatch_button(opt["name"], opt["color"], func():
				set_camera_view_staff()
				current_config["staff_gem_idx"] = i
				_refresh_preview()
				_update_active_button_highlights()
			)
			container_gem.add_child(btn)

	# 9. Porte / Expresión (Cuerpo completo)
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
				set_camera_view_full_body()
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

func _create_text_option_button(label_text: String, on_click: Callable) -> Button:
	var btn = Button.new()
	btn.text = " " + label_text
	btn.custom_minimum_size = Vector2(170, 36)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func():
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_ui"):
			am.play_ui("click")
		on_click.call()
	)
	return btn

func _connect_controls() -> void:
	if btn_tab_face:
		btn_tab_face.pressed.connect(func(): select_tab(CreatorTab.FACE))
	if btn_tab_robes:
		btn_tab_robes.pressed.connect(func(): select_tab(CreatorTab.ROBES))
	if btn_tab_staff:
		btn_tab_staff.pressed.connect(func(): select_tab(CreatorTab.STAFF))
	if btn_tab_identity:
		btn_tab_identity.pressed.connect(func(): select_tab(CreatorTab.IDENTITY))

	if btn_view_face:
		btn_view_face.pressed.connect(set_camera_view_face)
	if btn_view_body:
		btn_view_body.pressed.connect(set_camera_view_full_body)
	if btn_view_staff:
		btn_view_staff.pressed.connect(set_camera_view_staff)

	# Secciones interactivas para enfocar cámara al hacer clic sobre títulos
	var sec_headers = [
		{"name": "LblSkin", "action": set_camera_view_face},
		{"name": "LblEyeShape", "action": set_camera_view_face},
		{"name": "LblEyes", "action": set_camera_view_face},
		{"name": "LblHair", "action": set_camera_view_face},
		{"name": "LblBeard", "action": set_camera_view_face},
		{"name": "LblRobe", "action": set_camera_view_full_body},
		{"name": "LblTrim", "action": set_camera_view_full_body},
		{"name": "LblGem", "action": set_camera_view_staff},
		{"name": "LblExpr", "action": set_camera_view_full_body}
	]
	for h in sec_headers:
		var lbl = find_child(h["name"], true, false) as Control
		if lbl:
			lbl.mouse_filter = Control.MOUSE_FILTER_STOP
			lbl.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			lbl.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					(h["action"] as Callable).call()
			)

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
	_highlight_selected_in_container(container_eye_shape, current_config.get("eye_shape_idx", 0))
	_highlight_selected_in_container(container_eyes, current_config.get("eye_type_idx", 0))
	_highlight_selected_in_container(container_hair, current_config.get("hair_color_idx", 0))
	_highlight_selected_in_container(container_beard, current_config.get("beard_style_idx", 0))
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
	current_config["eye_shape_idx"] = randi() % CharacterAppearance.EYE_SHAPES.size()
	current_config["eye_type_idx"] = randi() % CharacterAppearance.EYE_COLORS.size()
	current_config["hair_color_idx"] = randi() % CharacterAppearance.HAIR_COLORS.size()
	current_config["beard_style_idx"] = randi() % CharacterAppearance.BEARD_STYLES.size()
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
