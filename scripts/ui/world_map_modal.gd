class_name WorldMapModal
extends Control

const MapConfig = preload("res://scripts/map_config.gd")
const IconRegistry = preload("res://scripts/ui/icon_registry.gd")
const UIConstants = preload("res://scripts/ui/ui_constants.gd")

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var panel: Control = $CenterContainer/Panel
@onready var title_label: Label = $CenterContainer/Panel/VBox/TopRow/Title
@onready var map_canvas: Control = $CenterContainer/Panel/VBox/BodyHBox/MapCanvas
@onready var btn_close: Button = $CenterContainer/Panel/VBox/TopRow/BtnClose
@onready var btn_close_bottom: Button = $CenterContainer/Panel/VBox/BodyHBox/RightSection/BtnCloseModal
@onready var lbl_current_zone: Label = $CenterContainer/Panel/VBox/BodyHBox/RightSection/LblCurrentZone
@onready var lbl_objective: Label = $CenterContainer/Panel/VBox/BodyHBox/RightSection/LblObjective
@onready var legend_container: Control = $CenterContainer/Panel/VBox/BodyHBox/RightSection/LegendContent

var player_ref: Node3D = null
var _is_animating: bool = false

# Interactive Zoom & Pan
var zoom_level: float = 1.0
var pan_offset: Vector2 = Vector2.ZERO
var is_panning: bool = false
var pan_drag_start: Vector2 = Vector2.ZERO
var pan_initial_offset: Vector2 = Vector2.ZERO

# Real world road networks
var roads: Array[Array] = [
	# Main Road
	[
		Vector3(0, 0, 114), Vector3(0, 0, 96), Vector3(0, 0, 78), Vector3(-2, 0, 60),
		Vector3(-4, 0, 42), Vector3(-2, 0, 24), Vector3(0, 0, 8), Vector3(0, 0, -10),
		Vector3(0, 0, -28), Vector3(0, 0, -46), Vector3(0, 0, -64), Vector3(0, 0, -82),
		Vector3(0, 0, -98)
	],
	# East Detour
	[
		Vector3(-4, 0, 46), Vector3(10, 0, 42), Vector3(24, 0, 36), Vector3(38, 0, 32)
	],
	# West Detour
	[
		Vector3(0, 0, -10), Vector3(-18, 0, -16), Vector3(-34, 0, -24),
		Vector3(-42, 0, -32), Vector3(-32, 0, -44), Vector3(-16, 0, -54),
		Vector3(0, 0, -64)
	]
]

func _ready() -> void:
	visible = false
	panel.pivot_offset = panel.custom_minimum_size * 0.5
	
	var cinzel_font = load("res://assets/ui/fonts/Cinzel.ttf")
	if cinzel_font and title_label:
		title_label.add_theme_font_override("font", cinzel_font)
		title_label.add_theme_font_size_override("font_size", 20)
	
	if btn_close:
		btn_close.pressed.connect(close_map)
	if btn_close_bottom:
		btn_close_bottom.pressed.connect(close_map)
	
	if map_canvas:
		map_canvas.clip_contents = true
		map_canvas.draw.connect(_on_map_canvas_draw)
		map_canvas.gui_input.connect(_on_map_canvas_gui_input)
		_setup_map_controls()
	
	_setup_legend()

func _setup_map_controls() -> void:
	# Mini floating overlay on map canvas for Zoom In, Zoom Out, and Center
	var ctrl_bar = HBoxContainer.new()
	ctrl_bar.name = "MapControls"
	ctrl_bar.position = Vector2(10, 10)
	ctrl_bar.add_theme_constant_override("separation", 6)
	
	var btn_zoom_in = Button.new()
	btn_zoom_in.text = "＋"
	btn_zoom_in.custom_minimum_size = Vector2(28, 28)
	btn_zoom_in.tooltip_text = "Acercar Mapa"
	btn_zoom_in.pressed.connect(func(): _adjust_zoom(0.25))
	ctrl_bar.add_child(btn_zoom_in)
	
	var btn_zoom_out = Button.new()
	btn_zoom_out.text = "－"
	btn_zoom_out.custom_minimum_size = Vector2(28, 28)
	btn_zoom_out.tooltip_text = "Alejar Mapa"
	btn_zoom_out.pressed.connect(func(): _adjust_zoom(-0.25))
	ctrl_bar.add_child(btn_zoom_out)
	
	var btn_center = Button.new()
	btn_center.text = "🎯 Centrar"
	btn_center.custom_minimum_size = Vector2(80, 28)
	btn_center.tooltip_text = "Centrar vista en el mago"
	btn_center.pressed.connect(center_on_player)
	ctrl_bar.add_child(btn_center)
	
	map_canvas.add_child(ctrl_bar)

func set_player(player: Node3D) -> void:
	player_ref = player

func _adjust_zoom(delta: float) -> void:
	zoom_level = clamp(zoom_level + delta, 0.8, 2.5)
	if map_canvas:
		map_canvas.queue_redraw()

func center_on_player() -> void:
	zoom_level = 1.0
	if player_ref and is_instance_valid(player_ref) and map_canvas:
		var c_size = map_canvas.size
		var nx = clamp((player_ref.global_position.x + 128.0) / 256.0, 0.0, 1.0)
		var ny = clamp((player_ref.global_position.z + 128.0) / 256.0, 0.0, 1.0)
		var base_pt = Vector2(nx * c_size.x, ny * c_size.y)
		var center = c_size * 0.5
		pan_offset = center - base_pt
	else:
		pan_offset = Vector2.ZERO
	if map_canvas:
		map_canvas.queue_redraw()

func _on_map_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_adjust_zoom(0.15)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_adjust_zoom(-0.15)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				pan_drag_start = event.position
				pan_initial_offset = pan_offset
			else:
				is_panning = false
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			center_on_player()
			accept_event()
	
	elif event is InputEventMouseMotion and is_panning:
		var delta = event.position - pan_drag_start
		pan_offset = pan_initial_offset + delta
		if map_canvas:
			map_canvas.queue_redraw()
		accept_event()

func _process(_delta: float) -> void:
	if not visible:
		return
	
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
	
	if player_ref and is_instance_valid(player_ref):
		var z_id = MapConfig.get_zone_at_position(player_ref.global_position)
		var z_data = MapConfig.get_zone_data(z_id)
		if lbl_current_zone:
			lbl_current_zone.text = "Zona Actual: %s" % z_data.get("name", "Desconocida")
	
	if lbl_objective:
		lbl_objective.text = GameManager.active_objective if not GameManager.active_objective.is_empty() else "Explora el mundo arcano"
	
	if map_canvas:
		map_canvas.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			toggle_map()
			get_viewport().set_input_as_handled()
		elif (event.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel")) and visible:
			close_map()
			get_viewport().set_input_as_handled()

func toggle_map() -> void:
	if visible:
		close_map()
	else:
		open_map()

func open_map() -> void:
	if _is_animating:
		return
	
	visible = true
	_is_animating = true
	
	# Intro animation: scale 0.92 to 1.0, fade in
	dim_overlay.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	panel.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(dim_overlay, "modulate:a", 0.65, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func():
		_is_animating = false
		if btn_close_bottom:
			btn_close_bottom.grab_focus()
	)
	
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("open")
	
	if map_canvas:
		map_canvas.queue_redraw()

func close_map() -> void:
	if _is_animating or not visible:
		return
	
	_is_animating = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(dim_overlay, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "scale", Vector2(0.94, 0.94), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		visible = false
		_is_animating = false
	)
	
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("close")

func _world_to_canvas(world_pos: Vector3, canvas_size: Vector2) -> Vector2:
	# World: X in [-128, 128], Z in [-128, 128]
	# Map: Top is North (Z = -128), Bottom is South (Z = 128)
	var nx = clamp((world_pos.x + 128.0) / 256.0, 0.0, 1.0)
	var ny = clamp((world_pos.z + 128.0) / 256.0, 0.0, 1.0)
	var base_pt = Vector2(nx * canvas_size.x, ny * canvas_size.y)
	var center = canvas_size * 0.5
	return (base_pt - center) * zoom_level + center + pan_offset

func _on_map_canvas_draw() -> void:
	var c_size = map_canvas.size
	
	# Base dark slate background
	map_canvas.draw_rect(Rect2(Vector2.ZERO, c_size), Color(0.04, 0.05, 0.08, 0.98))
	
	# Draw subtle topographical grid lines
	var grid_step = 40.0 * zoom_level
	var grid_col = Color(0.18, 0.22, 0.30, 0.25)
	var offset_x = fmod(pan_offset.x, grid_step)
	var offset_y = fmod(pan_offset.y, grid_step)
	
	var x = offset_x
	while x < c_size.x:
		map_canvas.draw_line(Vector2(x, 0), Vector2(x, c_size.y), grid_col, 1.0)
		x += grid_step
	var y = offset_y
	while y < c_size.y:
		map_canvas.draw_line(Vector2(0, y), Vector2(c_size.x, y), grid_col, 1.0)
		y += grid_step
	
	# 4 Zones bounds and ambient washes
	var zone_slices = [
		{"id": 4, "z_min": -128.0, "z_max": -64.0, "cfg": MapConfig.ZONE_BOUNDS[MapConfig.ZoneId.RUINAS_ARCANAS]},
		{"id": 3, "z_min": -64.0, "z_max": 0.0, "cfg": MapConfig.ZONE_BOUNDS[MapConfig.ZoneId.CORAZON_BOSQUE]},
		{"id": 2, "z_min": 0.0, "z_max": 64.0, "cfg": MapConfig.ZONE_BOUNDS[MapConfig.ZoneId.BOSQUE_EXTERIOR]},
		{"id": 1, "z_min": 64.0, "z_max": 128.0, "cfg": MapConfig.ZONE_BOUNDS[MapConfig.ZoneId.PRADERA_INICIAL]}
	]
	
	for slice in zone_slices:
		var z_id = slice["id"] as int
		var p_top_left = _world_to_canvas(Vector3(-128.0, 0, slice["z_min"]), c_size)
		var p_bottom_right = _world_to_canvas(Vector3(128.0, 0, slice["z_max"]), c_size)
		var zone_rect = Rect2(p_top_left, p_bottom_right - p_top_left)
		
		var is_known = z_id in GameManager.discovered_zones
		
		if is_known:
			var base_col = slice["cfg"]["color"] as Color
			base_col.a = 0.22
			map_canvas.draw_rect(zone_rect, base_col)
			
			var z_title = (slice["cfg"]["name"] as String).to_upper()
			map_canvas.draw_string(ThemeDB.fallback_font, p_top_left + Vector2(16, 24), z_title, HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * clamp(zoom_level, 0.9, 1.3)), Color(1, 0.9, 0.6, 0.85))
		else:
			# Fog of war for unknown zones
			map_canvas.draw_rect(zone_rect, Color(0.06, 0.07, 0.11, 0.88))
			map_canvas.draw_string(ThemeDB.fallback_font, p_top_left + Vector2(16, 24), "🔒 ZONA INEXPLORADA", HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * clamp(zoom_level, 0.9, 1.2)), Color(0.55, 0.55, 0.6, 0.65))
		
		# Boundary dividing line
		map_canvas.draw_line(Vector2(p_top_left.x, p_top_left.y), Vector2(p_bottom_right.x, p_top_left.y), Color(0.85, 0.72, 0.35, 0.4), 1.0)
	
	# Draw Roads across discovered zones
	var road_color = Color(0.78, 0.70, 0.52, 0.7)
	for path in roads:
		for i in range(path.size() - 1):
			var p1 = path[i] as Vector3
			var p2 = path[i + 1] as Vector3
			var z1_id = MapConfig.get_zone_at_position(p1)
			var z2_id = MapConfig.get_zone_at_position(p2)
			
			if (z1_id in GameManager.discovered_zones) or (z2_id in GameManager.discovered_zones):
				var pt1 = _world_to_canvas(p1, c_size)
				var pt2 = _world_to_canvas(p2, c_size)
				map_canvas.draw_line(pt1, pt2, road_color, 3.0 * zoom_level)
	
	# Draw Fog of War overlay layer
	if GameManager.fog_of_war and GameManager.fog_of_war.get_fog_texture():
		var p_fog_tl = _world_to_canvas(Vector3(-128.0, 0, -128.0), c_size)
		var p_fog_br = _world_to_canvas(Vector3(128.0, 0, 128.0), c_size)
		var fog_rect = Rect2(p_fog_tl, p_fog_br - p_fog_tl)
		var f_tex = GameManager.fog_of_war.get_fog_texture()
		map_canvas.draw_texture_rect(f_tex, fog_rect, false)
	
	# Draw Discovered POIs (only in explored territory)
	for poi in GameManager.discovered_pois:
		var p_pos = poi.get("pos", Vector3.ZERO) as Vector3
		if GameManager.fog_of_war and not GameManager.fog_of_war.is_point_explored(p_pos):
			continue
		var pt = _world_to_canvas(p_pos, c_size)
		var p_name = poi.get("name", "Punto de Interés")
		var poi_id = poi.get("id", "")
		var poi_icon_key = poi.get("icon", poi_id)
		var tex = IconRegistry.get_icon("poi", poi_icon_key)
		
		var radius = 13.0 * clamp(zoom_level, 0.8, 1.3)
		map_canvas.draw_circle(pt, radius, Color(0.06, 0.08, 0.12, 0.92))
		map_canvas.draw_arc(pt, radius, 0, TAU, 24, Color(0.85, 0.72, 0.45, 0.8), 1.2)
		if tex:
			var icon_size = Vector2(20, 20) * clamp(zoom_level, 0.8, 1.3)
			var icon_rect_2d = Rect2(pt - (icon_size * 0.5), icon_size)
			map_canvas.draw_texture_rect(tex, icon_rect_2d, false)
		else:
			map_canvas.draw_circle(pt, 6.0, Color(0.2, 0.95, 1.0))
		
		map_canvas.draw_string(ThemeDB.fallback_font, pt + Vector2(radius + 4, 4), p_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.9))
	
	# Draw Active Objective Marker
	if GameManager.active_objective_pos != Vector3.ZERO:
		var obj_pt = _world_to_canvas(GameManager.active_objective_pos, c_size)
		var pulse = (sin(Time.get_ticks_msec() * 0.007) + 1.0) * 0.5
		var outer_r = (10.0 + (pulse * 4.0)) * zoom_level
		map_canvas.draw_arc(obj_pt, outer_r, 0, TAU, 24, Color(1.0, 0.85, 0.2, 0.9), 2.2)
		map_canvas.draw_circle(obj_pt, 5.0 * zoom_level, Color(1.0, 0.85, 0.2))
		map_canvas.draw_string(ThemeDB.fallback_font, obj_pt + Vector2(outer_r + 6, 4), "OBJETIVO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.85, 0.2))
	
	# Draw Player position and heading arrow
	if player_ref and is_instance_valid(player_ref):
		var p_pos = player_ref.global_position
		var p_rot = player_ref.rotation.y
		var player_pt = _world_to_canvas(p_pos, c_size)
		
		var heading_dir = Vector2(sin(p_rot), -cos(p_rot))
		var tip = player_pt + (heading_dir * 12.0 * zoom_level)
		var left = player_pt + (heading_dir.rotated(2.4) * 9.0 * zoom_level)
		var right = player_pt + (heading_dir.rotated(-2.4) * 9.0 * zoom_level)
		
		map_canvas.draw_circle(player_pt, 7.0 * zoom_level, Color(0.2, 0.95, 1.0, 0.9))
		map_canvas.draw_colored_polygon(PackedVector2Array([tip, left, player_pt, right]), Color(1.0, 1.0, 1.0))
		map_canvas.draw_polyline(PackedVector2Array([tip, left, right, tip]), Color(0.1, 0.85, 1.0), 1.5)
	
	# Coordinate boundary outer frame
	map_canvas.draw_rect(Rect2(Vector2.ZERO, c_size), Color(0.85, 0.72, 0.35, 0.85), false, 2.0)

func _setup_legend() -> void:
	if not legend_container or not (legend_container is VBoxContainer):
		return
	for c in legend_container.get_children():
		c.queue_free()
	
	var entries = [
		{"icon": IconRegistry.get_icon("ui", "target_reticule"), "text": "Marcador de Objetivo Activo", "tip": "Objetivo de misión"},
		{"icon": IconRegistry.get_icon("poi", "shrine"), "text": "Santuarios de Poder Territorial", "tip": "Incrementan el maná máximo"},
		{"icon": IconRegistry.get_icon("poi", "fuente_ruinas"), "text": "Fuente de Renovación Vital", "tip": "Regenera salud"},
		{"icon": IconRegistry.get_icon("poi", "altar_transmutacion"), "text": "Altar de Transmutación Arcana", "tip": "Mejora habilidades con cristal"},
		{"icon": IconRegistry.get_icon("poi", "mirador_occidental"), "text": "Miradores y Enclaves de Visión", "tip": "Puntos de observación"},
		{"icon": IconRegistry.get_icon("poi", "puente_arco"), "text": "Pasos y Puentes de Conexión", "tip": "Cruce territorial"},
		{"icon": IconRegistry.get_icon("ui", "ability_locked"), "text": "Niebla de Territorio Inexplorado", "tip": "Zonas aún no descubiertas"}
	]
	
	for entry in entries:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(18, 18)
		icon_rect.texture = entry["icon"]
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = Control.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon_rect.tooltip_text = entry["tip"]
		row.add_child(icon_rect)
		
		var lbl = Label.new()
		lbl.text = entry["text"]
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.9, 0.95))
		lbl.tooltip_text = entry["tip"]
		row.add_child(lbl)
		
		legend_container.add_child(row)
