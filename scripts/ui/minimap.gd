class_name Minimap
extends Control

const MapConfig = preload("res://scripts/map_config.gd")
const IconRegistry = preload("res://scripts/ui/icon_registry.gd")
const UIConstants = preload("res://scripts/ui/ui_constants.gd")

signal open_world_map_requested

@export var radar_radius_meters: float = 75.0

var player_ref: Node3D = null
var is_hovered: bool = false

# Capas desacopladas para renderizado estratificado con Fog of War
var bg_layer: Control = null
var fog_overlay: ColorRect = null
var fg_layer: Control = null
var fog_mat: ShaderMaterial = null

# Road network cache (world points)
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
	custom_minimum_size = Vector2(170, 170)
	clip_contents = true
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(func(): is_hovered = true)
	mouse_exited.connect(func(): is_hovered = false)
	
	_setup_layers()

func _setup_layers() -> void:
	# 1. Capa inferior: Fondo, bioma y sendas del mundo
	bg_layer = Control.new()
	bg_layer.name = "BackgroundLayer"
	bg_layer.set_anchors_preset(PRESET_FULL_RECT)
	bg_layer.mouse_filter = MOUSE_FILTER_IGNORE
	bg_layer.draw.connect(_draw_background)
	add_child(bg_layer)
	
	# 2. Capa intermedia: Shader de Niebla de Guerra GPU (oculta sendas y zonas no exploradas)
	fog_overlay = ColorRect.new()
	fog_overlay.name = "FogOverlay"
	fog_overlay.set_anchors_preset(PRESET_FULL_RECT)
	fog_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	
	var shader = preload("res://shaders/fog_minimap.gdshader")
	fog_mat = ShaderMaterial.new()
	fog_mat.shader = shader
	fog_overlay.material = fog_mat
	add_child(fog_overlay)
	
	# 3. Capa superior: Puntos de Interés visibles, enemigos en radar, héroe y marco dorado
	fg_layer = Control.new()
	fg_layer.name = "ForegroundLayer"
	fg_layer.set_anchors_preset(PRESET_FULL_RECT)
	fg_layer.mouse_filter = MOUSE_FILTER_IGNORE
	fg_layer.draw.connect(_draw_foreground)
	add_child(fg_layer)

func set_player(player: Node3D) -> void:
	player_ref = player

func _process(_delta: float) -> void:
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
	
	if fog_mat and player_ref and is_instance_valid(player_ref):
		var p_pos = player_ref.global_position
		fog_mat.set_shader_parameter("player_pos", Vector2(p_pos.x, p_pos.z))
		fog_mat.set_shader_parameter("radar_radius", radar_radius_meters)
		fog_mat.set_shader_parameter("reveal_radius", 20.0)
		if GameManager.fog_of_war:
			fog_mat.set_shader_parameter("fog_texture", GameManager.fog_of_war.get_fog_texture())
	
	if bg_layer:
		bg_layer.queue_redraw()
	if fg_layer:
		fg_layer.queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		open_world_map_requested.emit()

func _draw_background() -> void:
	var center = size * 0.5
	var radius = min(size.x, size.y) * 0.46
	var scale_factor = radius / radar_radius_meters
	
	# Sombra suave exterior
	bg_layer.draw_circle(center + Vector2(2, 2), radius + 2.0, Color(0, 0, 0, 0.4))
	
	# Fondo circular de obsidiana
	bg_layer.draw_circle(center, radius, UIConstants.BG_DARKER)
	
	if player_ref and is_instance_valid(player_ref):
		var player_pos = player_ref.global_position
		
		# Tinte de zona actual
		var current_zone_id = MapConfig.get_zone_at_position(player_pos)
		var zone_cfg = MapConfig.get_zone_data(current_zone_id)
		var zone_tint = zone_cfg.get("color", Color.GREEN)
		zone_tint.a = 0.16
		bg_layer.draw_circle(center, radius - 2.0, zone_tint)
		
		# Dibujar sendas dentro del radar (la niebla de guerra las ocultará en zonas inexploradas)
		var road_color = Color(0.72, 0.68, 0.58, 0.65)
		for path in roads:
			for i in range(path.size() - 1):
				var p1 = path[i] as Vector3
				var p2 = path[i + 1] as Vector3
				var pt1_2d = center + _world_to_minimap_offset(p1 - player_pos, scale_factor)
				var pt2_2d = center + _world_to_minimap_offset(p2 - player_pos, scale_factor)
				if center.distance_to(pt1_2d) < radius or center.distance_to(pt2_2d) < radius:
					bg_layer.draw_line(pt1_2d, pt2_2d, road_color, 2.8)

func _draw_foreground() -> void:
	var center = size * 0.5
	var radius = min(size.x, size.y) * 0.46
	var scale_factor = radius / radar_radius_meters
	
	if player_ref and is_instance_valid(player_ref):
		var player_pos = player_ref.global_position
		var player_rot = player_ref.rotation.y
		
		# Dibujar POIs descubiertos con iconos de IconRegistry (nunca emojis)
		for poi in GameManager.discovered_pois:
			var p_pos = poi.get("pos", Vector3.ZERO) as Vector3
			# Filtrar por Fog of War: si no está explorado, no mostrar
			if GameManager.fog_of_war and not GameManager.fog_of_war.is_point_explored(p_pos):
				continue
				
			var diff = p_pos - player_pos
			var dist = Vector2(diff.x, diff.z).length()
			var poi_id = poi.get("id", "")
			var poi_icon_key = poi.get("icon", poi_id)
			var tex = IconRegistry.get_icon("poi", poi_icon_key)
			var pt = center + _world_to_minimap_offset(diff, scale_factor)
			
			if dist <= radar_radius_meters:
				fg_layer.draw_circle(pt, 7.0, Color(0.06, 0.08, 0.12, 0.92))
				fg_layer.draw_circle(pt, 5.5, Color(0.2, 0.85, 1.0, 0.35))
				if tex:
					var icon_rect_2d = Rect2(pt - Vector2(7, 7), Vector2(14, 14))
					fg_layer.draw_texture_rect(tex, icon_rect_2d, false)
				else:
					fg_layer.draw_circle(pt, 4.0, UIConstants.ARCANE_CYAN)
			else:
				# Fijar al borde
				var rim_dir = (pt - center).normalized()
				var rim_pt = center + rim_dir * (radius - 8.0)
				fg_layer.draw_circle(rim_pt, 3.5, Color(0.2, 0.85, 1.0, 0.8))
		
		# Enemigos visibles filtrados por Fog of War (solo dentro de visión activa)
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(enemy) and enemy.is_inside_tree() and not enemy.get("is_dead"):
				var is_vis = false
				if GameManager.fog_of_war:
					is_vis = GameManager.fog_of_war.is_point_visible(enemy.global_position)
				else:
					is_vis = enemy.global_position.distance_to(player_pos) <= 20.0
					
				if is_vis:
					var e_diff = enemy.global_position - player_pos
					var e_pt = center + _world_to_minimap_offset(e_diff, scale_factor)
					var is_boss = enemy.get("is_boss") == true
					var dot_col = Color(1.0, 0.3, 0.85) if is_boss else UIConstants.DANGER_RED
					var dot_radius = 5.2 if is_boss else 3.4
					fg_layer.draw_circle(e_pt, dot_radius, dot_col)
					fg_layer.draw_circle(e_pt, dot_radius * 0.5, Color(1, 1, 1, 0.95))
		
		# Marcador de objetivo activo con pulso dinámico y flecha direccional
		if GameManager.active_objective_pos != Vector3.ZERO:
			var obj_diff = GameManager.active_objective_pos - player_pos
			var obj_dist = Vector2(obj_diff.x, obj_diff.z).length()
			var obj_col = UIConstants.GOLD_BRIGHT
			var pt = center + _world_to_minimap_offset(obj_diff, scale_factor)
			var pulse_val = sin(Time.get_ticks_msec() * 0.006)
			
			if obj_dist <= radar_radius_meters:
				fg_layer.draw_arc(pt, 6.0 + pulse_val * 2.0, 0, TAU, 20, obj_col, 2.0)
				fg_layer.draw_circle(pt, 3.5, obj_col)
			else:
				var rim_dir = (pt - center).normalized()
				var rim_pt = center + rim_dir * (radius - 10.0)
				_draw_directional_arrow(rim_pt, rim_dir, 6.0, obj_col)
		
		# Icono del jugador (centro) con flecha de rumbo direccional
		var heading_dir = Vector2(sin(player_rot), -cos(player_rot))
		var arrow_tip = center + (heading_dir * 9.0)
		var arrow_left = center + (heading_dir.rotated(2.4) * 6.5)
		var arrow_right = center + (heading_dir.rotated(-2.4) * 6.5)
		var points: PackedVector2Array = [arrow_tip, arrow_left, center, arrow_right]
		fg_layer.draw_colored_polygon(points, UIConstants.ARCANE_CYAN)
		fg_layer.draw_polyline(PackedVector2Array([arrow_tip, arrow_left, arrow_right, arrow_tip]), Color(1, 1, 1, 0.95), 1.4)
	
	# Marco ornamental circular exterior (oro envejecido con gemas de cuadrante)
	fg_layer.draw_arc(center, radius, 0, TAU, 48, UIConstants.GOLD_BASE, 2.5)
	fg_layer.draw_arc(center, radius - 3.5, 0, TAU, 48, UIConstants.GOLD_DIM, 1.0)
	
	# Puntos cardinales (N, S, E, O)
	var north_pos = center + Vector2(0, -radius + 12)
	fg_layer.draw_string(ThemeDB.fallback_font, north_pos + Vector2(-4, 4), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, UIConstants.GOLD_BRIGHT)
	
	# Etiqueta de atajo en la parte inferior si se pasa el ratón
	if is_hovered:
		fg_layer.draw_circle(center + Vector2(0, radius - 10), 16.0, Color(0, 0, 0, 0.8))
		fg_layer.draw_string(ThemeDB.fallback_font, center + Vector2(-22, radius - 6), "[M] MAPA", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, UIConstants.GOLD_BRIGHT)

func _world_to_minimap_offset(diff: Vector3, scale_f: float) -> Vector2:
	return Vector2(diff.x * scale_f, diff.z * scale_f)

func _draw_directional_arrow(pos: Vector2, dir: Vector2, arrow_size: float, col: Color) -> void:
	var tip = pos + dir * arrow_size
	var left = pos + dir.rotated(2.3) * (arrow_size * 0.8)
	var right = pos + dir.rotated(-2.3) * (arrow_size * 0.8)
	var pts: PackedVector2Array = [tip, left, pos, right]
	if fg_layer:
		fg_layer.draw_colored_polygon(pts, col)
