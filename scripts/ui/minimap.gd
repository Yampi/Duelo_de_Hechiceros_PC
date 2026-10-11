class_name Minimap
extends Control

const MapConfig = preload("res://scripts/map_config.gd")
const IconRegistry = preload("res://scripts/ui/icon_registry.gd")
const UIConstants = preload("res://scripts/ui/ui_constants.gd")

signal open_world_map_requested

@export var radar_radius_meters: float = 75.0

var player_ref: Node3D = null
var is_hovered: bool = false

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

func set_player(player: Node3D) -> void:
	player_ref = player

func _process(_delta: float) -> void:
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
	
	queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		open_world_map_requested.emit()

func _draw() -> void:
	var center = size * 0.5
	var radius = min(size.x, size.y) * 0.46
	var scale_factor = radius / radar_radius_meters
	
	# Sombra suave exterior
	draw_circle(center + Vector2(2, 2), radius + 2.0, Color(0, 0, 0, 0.4))
	
	# Fondo circular de obsidiana
	draw_circle(center, radius, UIConstants.BG_DARKER)
	
	if player_ref and is_instance_valid(player_ref):
		var player_pos = player_ref.global_position
		var player_rot = player_ref.rotation.y
		
		# Tinte de zona actual
		var current_zone_id = MapConfig.get_zone_at_position(player_pos)
		var zone_cfg = MapConfig.get_zone_data(current_zone_id)
		var zone_tint = zone_cfg.get("color", Color.GREEN)
		zone_tint.a = 0.14
		draw_circle(center, radius - 2.0, zone_tint)
		
		# Dibujar sendas dentro del radar
		var road_color = Color(0.65, 0.6, 0.5, 0.5)
		for path in roads:
			for i in range(path.size() - 1):
				var p1 = path[i] as Vector3
				var p2 = path[i + 1] as Vector3
				var pt1_2d = center + _world_to_minimap_offset(p1 - player_pos, scale_factor)
				var pt2_2d = center + _world_to_minimap_offset(p2 - player_pos, scale_factor)
				if center.distance_to(pt1_2d) < radius or center.distance_to(pt2_2d) < radius:
					draw_line(pt1_2d, pt2_2d, road_color, 2.0)
		
		# Dibujar POIs descubiertos con iconos de IconRegistry (nunca emojis)
		for poi in GameManager.discovered_pois:
			var p_pos = poi.get("pos", Vector3.ZERO) as Vector3
			var diff = p_pos - player_pos
			var dist = Vector2(diff.x, diff.z).length()
			var poi_id = poi.get("id", "")
			var poi_icon_key = poi.get("icon", poi_id)
			var tex = IconRegistry.get_icon("poi", poi_icon_key)
			var pt = center + _world_to_minimap_offset(diff, scale_factor)
			
			if dist <= radar_radius_meters:
				draw_circle(pt, 7.0, Color(0.06, 0.08, 0.12, 0.9))
				draw_circle(pt, 5.5, Color(0.2, 0.85, 1.0, 0.35))
				if tex:
					var icon_rect_2d = Rect2(pt - Vector2(7, 7), Vector2(14, 14))
					draw_texture_rect(tex, icon_rect_2d, false)
				else:
					draw_circle(pt, 4.0, UIConstants.ARCANE_CYAN)
			else:
				# Fijar al borde
				var rim_dir = (pt - center).normalized()
				var rim_pt = center + rim_dir * (radius - 8.0)
				draw_circle(rim_pt, 3.5, Color(0.2, 0.85, 1.0, 0.8))
		
		# Niebla de guerra en minimapa: arco sutil de alcance de visión (20m)
		var reveal_px = 20.0 * scale_factor
		draw_arc(center, reveal_px, 0, TAU, 32, Color(0.35, 0.85, 1.0, 0.4), 1.0)
		
		# Enemigos visibles filtrados por radio de niebla de guerra (20m)
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(enemy) and enemy.is_inside_tree() and not enemy.get("is_dead"):
				var e_diff = enemy.global_position - player_pos
				var e_dist = Vector2(e_diff.x, e_diff.z).length()
				if e_dist <= 20.0:
					var is_vis = true
					if GameManager.fog_of_war:
						is_vis = GameManager.fog_of_war.is_point_visible(enemy.global_position)
					if is_vis:
						var e_pt = center + _world_to_minimap_offset(e_diff, scale_factor)
						var is_boss = enemy.get("is_boss") == true
						var dot_col = Color(1.0, 0.3, 0.85) if is_boss else UIConstants.DANGER_RED
						var dot_radius = 5.0 if is_boss else 3.2
						draw_circle(e_pt, dot_radius, dot_col)
						draw_circle(e_pt, dot_radius * 0.5, Color(1, 1, 1, 0.9))
		
		# Marcador de objetivo activo con pulso dinámico y flecha direccional
		if GameManager.active_objective_pos != Vector3.ZERO:
			var obj_diff = GameManager.active_objective_pos - player_pos
			var obj_dist = Vector2(obj_diff.x, obj_diff.z).length()
			var obj_col = UIConstants.GOLD_BRIGHT
			var pt = center + _world_to_minimap_offset(obj_diff, scale_factor)
			var pulse_val = sin(Time.get_ticks_msec() * 0.006)
			
			if obj_dist <= radar_radius_meters:
				draw_arc(pt, 6.0 + pulse_val * 2.0, 0, TAU, 20, obj_col, 2.0)
				draw_circle(pt, 3.5, obj_col)
			else:
				# Flecha direccional fijada al borde apuntando hacia el objetivo lejano
				var rim_dir = (pt - center).normalized()
				var rim_pt = center + rim_dir * (radius - 10.0)
				_draw_directional_arrow(rim_pt, rim_dir, 6.0, obj_col)
		
		# Icono del jugador (centro) con flecha de rumbo direccional
		var heading_dir = Vector2(sin(player_rot), -cos(player_rot))
		var arrow_tip = center + (heading_dir * 9.0)
		var arrow_left = center + (heading_dir.rotated(2.4) * 6.5)
		var arrow_right = center + (heading_dir.rotated(-2.4) * 6.5)
		var points: PackedVector2Array = [arrow_tip, arrow_left, center, arrow_right]
		draw_colored_polygon(points, UIConstants.ARCANE_CYAN)
		draw_polyline(PackedVector2Array([arrow_tip, arrow_left, arrow_right, arrow_tip]), Color(1, 1, 1, 0.95), 1.4)
	
	# Marco ornamental circular exterior (oro envejecido)
	draw_arc(center, radius, 0, TAU, 48, UIConstants.GOLD_BASE, 2.5)
	draw_arc(center, radius - 3.5, 0, TAU, 48, UIConstants.GOLD_DIM, 1.0)
	
	# Puntos cardinales (N, S, E, O)
	var north_pos = center + Vector2(0, -radius + 12)
	draw_string(ThemeDB.fallback_font, north_pos + Vector2(-4, 4), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, UIConstants.GOLD_BRIGHT)
	
	# Etiqueta de atajo en la parte inferior si se pasa el ratón
	if is_hovered:
		draw_circle(center + Vector2(0, radius - 10), 16.0, Color(0, 0, 0, 0.75))
		draw_string(ThemeDB.fallback_font, center + Vector2(-22, radius - 6), "[M] MAPA", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, UIConstants.GOLD_BRIGHT)

func _world_to_minimap_offset(diff: Vector3, scale_f: float) -> Vector2:
	return Vector2(diff.x * scale_f, diff.z * scale_f)

func _draw_directional_arrow(pos: Vector2, dir: Vector2, arrow_size: float, col: Color) -> void:
	var tip = pos + dir * arrow_size
	var left = pos + dir.rotated(2.3) * (arrow_size * 0.8)
	var right = pos + dir.rotated(-2.3) * (arrow_size * 0.8)
	var pts: PackedVector2Array = [tip, left, pos, right]
	draw_colored_polygon(pts, col)
