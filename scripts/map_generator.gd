class_name MapGenerator
extends Node3D

const MapConfig = preload("res://scripts/map_config.gd")

@export var map_size: float = 256.0
@export var num_shrines: int = 3

var place_of_power_scene: PackedScene = preload("res://scenes/PlaceOfPower.tscn")
var portal_scene: PackedScene = preload("res://scenes/Portal.tscn")
var pickup_scene: PackedScene = preload("res://scenes/Pickup.tscn")
var world_item_scene: PackedScene = preload("res://scenes/WorldItem.tscn")
var ancient_altar_scene: PackedScene = preload("res://scenes/AncientAltar.tscn")
var health_fountain_scene: PackedScene = preload("res://scenes/HealthFountain.tscn")
var fruit_tree_scene: PackedScene = preload("res://scenes/FruitTree.tscn")

var tree_common1_scene: PackedScene = preload("res://assets/environment/CommonTree_1.gltf")
var tree_common2_scene: PackedScene = preload("res://assets/environment/CommonTree_2.gltf")
var tree_pine1_scene: PackedScene = preload("res://assets/environment/Pine_1.gltf")
var tree_pine2_scene: PackedScene = preload("res://assets/environment/Pine_2.gltf")
var tree_twisted_scene: PackedScene = preload("res://assets/environment/TwistedTree_1.gltf")
var bush_scene: PackedScene = preload("res://assets/environment/Bush_Common.gltf")
var rock_m1_scene: PackedScene = preload("res://assets/environment/Rock_Medium_1.gltf")
var rock_m2_scene: PackedScene = preload("res://assets/environment/Rock_Medium_2.gltf")
var rock_m3_scene: PackedScene = preload("res://assets/environment/Rock_Medium_3.gltf")
var plant_big_scene: PackedScene = preload("res://assets/environment/Plant_1_Big.gltf")
var grass_scene: PackedScene = preload("res://assets/environment/Grass_Large.glb")
var column_scene: PackedScene = preload("res://assets/environment/Column_Round.glb")
var arch_scene: PackedScene = preload("res://assets/environment/Arch_Round_RoundColumn.glb")
var torch_scene: PackedScene = preload("res://assets/props/Torch_Metal.gltf")
var chest_scene: PackedScene = preload("res://assets/props/Chest_Wood.gltf")

var mushroom_scene: PackedScene = preload("res://assets/environment/Mushroom_Common.gltf")
var mushroom_orange_scene: PackedScene = preload("res://assets/environment/Mushroom_Laetiporus.gltf")
var flower_scene: PackedScene = preload("res://assets/environment/Flower_3_Group.gltf")
var clover_scene: PackedScene = preload("res://assets/environment/Clover_1.gltf")

var grass_material: Material = preload("res://assets/materials/mat_grass.tres")
var stone_material: Material = preload("res://assets/materials/mat_stone.tres")
var rock_material: Material = preload("res://assets/materials/mat_rock.tres")

var shrine_positions: Array[Vector3] = []
var player_spawn_point: Vector3 = MapConfig.PLAYER_SPAWN_POS
var portal_instance: Node3D = null

func generate_map() -> void:
	for child in get_children():
		child.queue_free()
	
	shrine_positions.clear()
	
	_create_ground()
	_create_boundaries()
	_create_perimeter_barriers()
	
	_build_road_network()
	
	_build_zone1_pradera()
	_build_zone2_bosque_exterior()
	_build_zone3_corazon_bosque()
	_build_zone4_ruinas_arcanas()
	
	_generate_pickups_and_reagents()
	
	if GameManager.current_mode == GameManager.GameMode.OBJECTIVE or GameManager.current_mode == GameManager.GameMode.EXPLORATION:
		_generate_portal()
	
	GameManager.total_shrines = shrine_positions.size()

func _create_ground() -> void:
	var ground = StaticBody3D.new()
	ground.name = "Ground"
	
	# Child 0: Baseline BoxShape3D to satisfy foundation and test requirements
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(MapConfig.MAP_SIZE, 1.0, MapConfig.MAP_SIZE)
	col_shape.shape = box
	col_shape.position = Vector3(0, -0.5, 0)
	ground.add_child(col_shape)
	
	# Child 1 & 2: Generate 3D Topographical Terrain Mesh with synchronized Trimesh Collision
	var res = 64 # 64x64 resolution across 256m = 4m grid intervals
	var half = MapConfig.HALF_SIZE
	var step = MapConfig.MAP_SIZE / float(res)
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for gz in range(res):
		for gx in range(res):
			var x0 = -half + float(gx) * step
			var x1 = x0 + step
			var z0 = -half + float(gz) * step
			var z1 = z0 + step
			
			var y00 = MapConfig.get_height_at(x0, z0)
			var y10 = MapConfig.get_height_at(x1, z0)
			var y01 = MapConfig.get_height_at(x0, z1)
			var y11 = MapConfig.get_height_at(x1, z1)
			
			var p00 = Vector3(x0, y00, z0)
			var p10 = Vector3(x1, y10, z0)
			var p01 = Vector3(x0, y01, z1)
			var p11 = Vector3(x1, y11, z1)
			
			var uv00 = Vector2(float(gx) / float(res) * 24.0, float(gz) / float(res) * 24.0)
			var uv10 = Vector2(float(gx + 1) / float(res) * 24.0, float(gz) / float(res) * 24.0)
			var uv01 = Vector2(float(gx) / float(res) * 24.0, float(gz + 1) / float(res) * 24.0)
			var uv11 = Vector2(float(gx + 1) / float(res) * 24.0, float(gz + 1) / float(res) * 24.0)
			
			# Triangle 1: p00, p10, p11
			surface_tool.set_uv(uv00)
			surface_tool.add_vertex(p00)
			surface_tool.set_uv(uv10)
			surface_tool.add_vertex(p10)
			surface_tool.set_uv(uv11)
			surface_tool.add_vertex(p11)
			
			# Triangle 2: p00, p11, p01
			surface_tool.set_uv(uv00)
			surface_tool.add_vertex(p00)
			surface_tool.set_uv(uv11)
			surface_tool.add_vertex(p11)
			surface_tool.set_uv(uv01)
			surface_tool.add_vertex(p01)
	
	surface_tool.generate_normals()
	var terrain_mesh = surface_tool.commit()
	
	# Visual terrain mesh instance
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = terrain_mesh
	mesh_inst.material_override = grass_material
	ground.add_child(mesh_inst)
	
	# Child 2: Synchronized Trimesh concave collider matching the topography 1:1
	var topo_shape = terrain_mesh.create_trimesh_shape()
	if topo_shape:
		var topo_col = CollisionShape3D.new()
		topo_col.shape = topo_shape
		ground.add_child(topo_col)
	
	add_child(ground)

func _create_boundaries() -> void:
	var half = MapConfig.HALF_SIZE
	var wall_h = MapConfig.WALL_HEIGHT
	var wall_configs = [
		{"pos": Vector3(0, wall_h * 0.5, -half), "size": Vector3(MapConfig.MAP_SIZE, wall_h, 3.0)}, # North
		{"pos": Vector3(0, wall_h * 0.5, half), "size": Vector3(MapConfig.MAP_SIZE, wall_h, 3.0)},  # South
		{"pos": Vector3(-half, wall_h * 0.5, 0), "size": Vector3(3.0, wall_h, MapConfig.MAP_SIZE)}, # West
		{"pos": Vector3(half, wall_h * 0.5, 0), "size": Vector3(3.0, wall_h, MapConfig.MAP_SIZE)}   # East
	]
	
	for cfg in wall_configs:
		var wall = StaticBody3D.new()
		wall.add_to_group("obstacle")
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = cfg["size"]
		col.shape = box
		col.position = cfg["pos"]
		wall.add_child(col)
		add_child(wall)

func _create_perimeter_barriers() -> void:
	var half = MapConfig.HALF_SIZE - 4.0
	var step = 8.0
	var perimeter_pts: Array[Vector3] = []
	
	# North and South rows
	var x = -half
	while x <= half:
		perimeter_pts.append(Vector3(x, MapConfig.get_height_at(x, -half), -half))
		perimeter_pts.append(Vector3(x, MapConfig.get_height_at(x, half), half))
		x += step
	
	# East and West rows
	var z = -half
	while z <= half:
		perimeter_pts.append(Vector3(-half, MapConfig.get_height_at(-half, z), z))
		perimeter_pts.append(Vector3(half, MapConfig.get_height_at(half, z), z))
		z += step
	
	for pt in perimeter_pts:
		var rock_roll = randi() % 3
		var rock_node: Node3D = null
		if rock_roll == 0:
			rock_node = rock_m1_scene.instantiate()
		elif rock_roll == 1:
			rock_node = rock_m2_scene.instantiate()
		else:
			rock_node = rock_m3_scene.instantiate()
		
		var r_scale = randf_range(1.6, 2.4)
		rock_node.scale = Vector3(r_scale, r_scale * 1.5, r_scale)
		_apply_visibility_cull(rock_node, 95.0)
		add_child(rock_node)
		var rx = pt.x + randf_range(-1.5, 1.5)
		var rz = pt.z + randf_range(-1.5, 1.5)
		var ry = MapConfig.get_height_at(rx, rz)
		rock_node.global_position = Vector3(rx, ry, rz)
		rock_node.rotation.y = randf() * TAU
		
		# Add tree behind rocks
		if randf() < 0.65:
			var pine = tree_pine1_scene.instantiate()
			pine.scale = Vector3(1.3, 1.3, 1.3)
			_apply_visibility_cull(pine, 100.0)
			add_child(pine)
			var px = pt.x + randf_range(-2.0, 2.0)
			var pz = pt.z + randf_range(-2.0, 2.0)
			var py = MapConfig.get_height_at(px, pz)
			pine.global_position = Vector3(px, py, pz)

func _build_road_network() -> void:
	# Main Road: From South (Z = 112) straight through to Ruinas Arcanas (Z = -98)
	var main_pts: Array[Vector3] = [
		Vector3(0, 0, 114), Vector3(0, 0, 96), Vector3(0, 0, 78), Vector3(-2, 0, 60),
		Vector3(-4, 0, 42), Vector3(-2, 0, 24), Vector3(0, 0, 8), Vector3(0, 0, -10),
		Vector3(0, 0, -28), Vector3(0, 0, -46), Vector3(0, 0, -64), Vector3(0, 0, -82),
		Vector3(0, 0, -98)
	]
	_render_continuous_path(main_pts, 3.4)
	
	# Eastern Detour in Zone 2: Branches at Z = 46 to Eastern Clearing at (38, 0, 32)
	var east_detour: Array[Vector3] = [
		Vector3(-4, 0, 46), Vector3(10, 0, 42), Vector3(24, 0, 36), Vector3(38, 0, 32)
	]
	_render_continuous_path(east_detour, 2.2)
	
	# Western Detour in Zone 3: Flanking route around the gorge
	var west_detour: Array[Vector3] = [
		Vector3(0, 0, -10), Vector3(-18, 0, -16), Vector3(-34, 0, -24),
		Vector3(-42, 0, -32), Vector3(-32, 0, -44), Vector3(-16, 0, -54),
		Vector3(0, 0, -64)
	]
	_render_continuous_path(west_detour, 2.2)

func _render_continuous_path(points: Array[Vector3], width: float) -> void:
	for i in range(points.size() - 1):
		var p_start = points[i]
		var p_end = points[i + 1]
		var dist = p_start.distance_to(p_end)
		var segments = max(1, int(dist / 2.2))
		
		for s in range(segments):
			var t = float(s) / float(segments)
			var pos = p_start.lerp(p_end, t)
			var pos_x = pos.x + randf_range(-0.25, 0.25)
			var pos_z = pos.z + randf_range(-0.25, 0.25)
			var pos_y = MapConfig.get_height_at(pos_x, pos_z)
			
			var slab = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = (width * 0.5) * randf_range(0.85, 1.15)
			cyl.bottom_radius = cyl.top_radius
			cyl.height = 0.04
			slab.mesh = cyl
			slab.material_override = stone_material
			slab.position = Vector3(pos_x, pos_y + 0.02, pos_z)
			slab.rotation.y = randf() * TAU
			add_child(slab)

# === ZONA 1: PRADERA INICIAL (Z = 64 to 128) ===
func _build_zone1_pradera() -> void:
	# Welcome plaza around player spawn
	var welcome_pos = Vector3(0, MapConfig.get_height_at(0, 96), 96)
	var circle_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 5.5
	cyl.bottom_radius = 5.5
	cyl.height = 0.06
	circle_mesh.mesh = cyl
	circle_mesh.material_override = stone_material
	circle_mesh.position = welcome_pos + Vector3(0, 0.02, 0)
	add_child(circle_mesh)
	
	# Health Fountain in the meadow
	var fountain = health_fountain_scene.instantiate()
	add_child(fountain)
	fountain.global_position = Vector3(16.0, MapConfig.get_height_at(16.0, 92.0), 92.0)
	
	# Fruit trees
	var ft1 = fruit_tree_scene.instantiate()
	add_child(ft1)
	ft1.global_position = Vector3(-18.0, MapConfig.get_height_at(-18.0, 86.0), 86.0)
	
	var ft2 = fruit_tree_scene.instantiate()
	add_child(ft2)
	ft2.global_position = Vector3(20.0, MapConfig.get_height_at(20.0, 74.0), 74.0)
	
	# Wooden chest near flowers
	var chest = chest_scene.instantiate()
	add_child(chest)
	chest.global_position = Vector3(-24.0, MapConfig.get_height_at(-24.0, 102.0), 102.0)
	chest.scale = Vector3(1.2, 1.2, 1.2)
	
	# Gentle tree groves flanking the field
	_spawn_tree_grove(Vector3(-34, 0, 90), 6, "common")
	_spawn_tree_grove(Vector3(34, 0, 90), 6, "common")
	_spawn_tree_grove(Vector3(-28, 0, 110), 5, "common")
	_spawn_tree_grove(Vector3(28, 0, 110), 5, "common")
	
	# Flowers, clovers and mushrooms
	for i in range(25):
		var fx = randf_range(-38.0, 38.0)
		var fz = randf_range(68.0, 120.0)
		if abs(fx) < 3.5 and abs(fz - 96.0) < 14.0:
			continue
		var fy = MapConfig.get_height_at(fx, fz)
		var f_pos = Vector3(fx, fy, fz)
		var fl = flower_scene.instantiate() if i % 2 == 0 else clover_scene.instantiate()
		fl.scale = Vector3(1.3, 1.3, 1.3)
		_apply_visibility_cull(fl, 50.0)
		add_child(fl)
		fl.global_position = f_pos
	
	# Ancient standing boundary stones framing the road into the forest (Z = 64)
	_spawn_rock_at(Vector3(-5.5, MapConfig.get_height_at(-5.5, 64.0), 64.0), 1.8)
	_spawn_rock_at(Vector3(5.5, MapConfig.get_height_at(5.5, 64.0), 64.0), 1.8)

# === ZONA 2: BOSQUE EXTERIOR (Z = 0 to 64) ===
func _build_zone2_bosque_exterior() -> void:
	# Groves of mixed pine and common trees
	_spawn_tree_grove(Vector3(-24, 0, 48), 7, "pine")
	_spawn_tree_grove(Vector3(-28, 0, 24), 8, "common")
	_spawn_tree_grove(Vector3(18, 0, 52), 6, "pine")
	_spawn_tree_grove(Vector3(22, 0, 16), 7, "common")
	
	# Eastern Secret Clearing at (38, 32)
	var clear_pos = Vector3(38.0, MapConfig.get_height_at(38.0, 32.0), 32.0)
	
	# Ancient towering pine in the center of the clearing
	var big_pine = tree_pine1_scene.instantiate()
	big_pine.scale = Vector3(1.8, 1.8, 1.8)
	add_child(big_pine)
	big_pine.global_position = clear_pos + Vector3(4.0, 0, -3.0)
	
	# Treasure chest in the clearing
	var clear_chest = chest_scene.instantiate()
	add_child(clear_chest)
	clear_chest.global_position = clear_pos
	clear_chest.scale = Vector3(1.3, 1.3, 1.3)
	
	# Fruit tree in the clearing
	var clear_ft = fruit_tree_scene.instantiate()
	add_child(clear_ft)
	clear_ft.global_position = clear_pos + Vector3(-4.0, 0, 4.0)
	
	# Encircling rocks around the secret clearing
	for i in range(7):
		var ang = (float(i) / 7.0) * TAU
		var rx = clear_pos.x + cos(ang) * 9.0
		var rz = clear_pos.z + sin(ang) * 9.0
		var r_pos = Vector3(rx, MapConfig.get_height_at(rx, rz), rz)
		_spawn_rock_at(r_pos, randf_range(1.2, 1.6))
	
	# Mid-forest rocks
	for i in range(8):
		var rx = randf_range(-42.0, -12.0) if i % 2 == 0 else randf_range(12.0, 42.0)
		var rz = randf_range(8.0, 56.0)
		var ry = MapConfig.get_height_at(rx, rz)
		_spawn_rock_at(Vector3(rx, ry, rz), randf_range(1.0, 1.5))
	
	# Gorge defile entrance rocks framing the descent (Z = 0)
	_spawn_rock_at(Vector3(-6.2, MapConfig.get_height_at(-6.2, 0.0), 0.0), 2.0)
	_spawn_rock_at(Vector3(6.2, MapConfig.get_height_at(6.2, 0.0), 0.0), 2.0)

# === ZONA 3: CORAZÓN DEL BOSQUE (Z = -64 to 0) ===
func _build_zone3_corazon_bosque() -> void:
	# Dense twisted trees and dark pines
	_spawn_tree_grove(Vector3(-18, 0, -14), 7, "twisted")
	_spawn_tree_grove(Vector3(22, 0, -18), 7, "twisted")
	_spawn_tree_grove(Vector3(-46, 0, -48), 8, "twisted")
	_spawn_tree_grove(Vector3(42, 0, -52), 8, "pine")
	
	# The Stone Arch Bridge across the Gorge at (0, -28)
	var bridge_pos = Vector3(0.0, MapConfig.get_height_at(0.0, -28.0), -28.0)
	var arch = arch_scene.instantiate()
	add_child(arch)
	arch.global_position = bridge_pos
	arch.scale = Vector3(1.2, 1.2, 1.2)
	
	# Gorge rock ridge along the arch
	for i in range(1, 6):
		var dist = 5.0 + (i * 3.8)
		var l_pos = Vector3(-dist, MapConfig.get_height_at(-dist, -28.0), -28.0)
		var r_pos = Vector3(dist, MapConfig.get_height_at(dist, -28.0), -28.0)
		_spawn_rock_at(l_pos, randf_range(1.4, 2.0))
		_spawn_rock_at(r_pos, randf_range(1.4, 2.0))
	
	# Western Ridge Overlook at (-38, -28) - High ground vantage overlooking the gorge and bridge
	var overlook_pos = Vector3(-38.0, MapConfig.get_height_at(-38.0, -28.0), -28.0)
	_spawn_ruin_column(overlook_pos + Vector3(-2.8, 0, 0), true)
	_spawn_ruin_column(overlook_pos + Vector3(2.8, 0, 0), true)
	_spawn_rock_at(overlook_pos + Vector3(0, 0, 2.2), 1.4)
	
	# Western Flanking Detour Outpost at (-44, -34)
	var detour_chest = chest_scene.instantiate()
	add_child(detour_chest)
	detour_chest.global_position = Vector3(-44.0, MapConfig.get_height_at(-44.0, -34.0), -34.0)
	detour_chest.scale = Vector3(1.2, 1.2, 1.2)
	
	# Place of Power 1 in Eastern Mystic Glade at (28, -42)
	var shrine1_pos = Vector3(28.0, MapConfig.get_height_at(28.0, -42.0), -42.0)
	_spawn_shrine_complex(shrine1_pos)
	shrine_positions.append(shrine1_pos)
	
	# Glowing mushrooms in the twisted woods
	for i in range(16):
		var mx = randf_range(-44.0, 44.0)
		var mz = randf_range(-60.0, -4.0)
		var my = MapConfig.get_height_at(mx, mz)
		var mush = mushroom_orange_scene.instantiate()
		mush.scale = Vector3(1.3, 1.3, 1.3)
		_apply_visibility_cull(mush, 50.0)
		add_child(mush)
		mush.global_position = Vector3(mx, my, mz)

# === ZONA 4: RUINAS ARCANAS (Z = -128 to -64) ===
func _build_zone4_ruinas_arcanas() -> void:
	# Grand plateau entrance archway (Z = -64) framing the ascent into the sacred precinct
	_spawn_ruin_column(Vector3(-6.8, MapConfig.get_height_at(-6.8, -64.0), -64.0), true)
	_spawn_ruin_column(Vector3(6.8, MapConfig.get_height_at(6.8, -64.0), -64.0), true)
	
	# Avenue of Columns & Iron Torches lining the road to the boss altar
	var avenue_z_pts = [-68.0, -76.0, -84.0, -92.0]
	for z_val in avenue_z_pts:
		_spawn_ruin_column(Vector3(-5.2, MapConfig.get_height_at(-5.2, z_val), z_val), true)
		_spawn_ruin_column(Vector3(5.2, MapConfig.get_height_at(5.2, z_val), z_val), true)
	
	# Place of Power 2 (Western Terrace) at (-36, -82)
	var shrine2_pos = Vector3(-36.0, MapConfig.get_height_at(-36.0, -82.0), -82.0)
	_spawn_shrine_complex(shrine2_pos)
	shrine_positions.append(shrine2_pos)
	
	# Place of Power 3 (Eastern Terrace) at (36, -82)
	var shrine3_pos = Vector3(36.0, MapConfig.get_height_at(36.0, -82.0), -82.0)
	_spawn_shrine_complex(shrine3_pos)
	shrine_positions.append(shrine3_pos)
	
	# Health fountain in the arcane precinct
	var fountain2 = health_fountain_scene.instantiate()
	add_child(fountain2)
	fountain2.global_position = Vector3(-18.0, MapConfig.get_height_at(-18.0, -74.0), -74.0)
	
	# Ancient Altar of Transmutation (Western Terrace POI)
	var ancient_altar = ancient_altar_scene.instantiate()
	add_child(ancient_altar)
	ancient_altar.global_position = Vector3(-36.0, MapConfig.get_height_at(-36.0, -68.0), -68.0)
	
	# Grand Boss Altar at (0, -98)
	var altar_pos = Vector3(MapConfig.BOSS_ALTAR_POS.x, MapConfig.get_height_at(MapConfig.BOSS_ALTAR_POS.x, MapConfig.BOSS_ALTAR_POS.z), MapConfig.BOSS_ALTAR_POS.z)
	var altar_base = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 12.0
	cyl.bottom_radius = 12.0
	cyl.height = 0.12
	altar_base.mesh = cyl
	altar_base.material_override = stone_material
	altar_base.position = altar_pos + Vector3(0, 0.04, 0)
	add_child(altar_base)
	
	# Colonnade encircling the northern rim of the Boss Altar
	for i in range(7):
		var ang = PI + (float(i) / 6.0) * PI
		var cx = altar_pos.x + cos(ang) * 11.0
		var cz = altar_pos.z + sin(ang) * 11.0
		var cy = MapConfig.get_height_at(cx, cz)
		var c_pos = Vector3(cx, cy, cz)
		_spawn_ruin_column(c_pos, i % 2 == 0)
	
	# Boss Arch behind the Altar
	var boss_arch = arch_scene.instantiate()
	add_child(boss_arch)
	boss_arch.global_position = Vector3(altar_pos.x, MapConfig.get_height_at(altar_pos.x, altar_pos.z - 9.0), altar_pos.z - 9.0)
	boss_arch.scale = Vector3(1.4, 1.4, 1.4)

func _spawn_shrine_complex(pos: Vector3) -> void:
	pos.y = MapConfig.get_height_at(pos.x, pos.z)
	var shrine = place_of_power_scene.instantiate()
	add_child(shrine)
	shrine.global_position = pos
	
	var base_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 7.5
	cyl.bottom_radius = 7.5
	cyl.height = 0.08
	base_mesh.mesh = cyl
	base_mesh.material_override = stone_material
	add_child(base_mesh)
	base_mesh.global_position = pos + Vector3(0, 0.02, 0)
	
	var num_cols = 6
	for i in range(num_cols):
		var col_angle = (float(i) / float(num_cols)) * TAU
		var cx = pos.x + cos(col_angle) * 5.8
		var cz = pos.z + sin(col_angle) * 5.8
		var cy = MapConfig.get_height_at(cx, cz)
		var col_pos = Vector3(cx, cy, cz)
		_spawn_ruin_column(col_pos, false)

func _spawn_ruin_column(pos: Vector3, with_torch: bool = false) -> void:
	pos.y = MapConfig.get_height_at(pos.x, pos.z)
	var col_node = column_scene.instantiate()
	_apply_visibility_cull(col_node, 110.0)
	add_child(col_node)
	col_node.global_position = pos
	col_node.scale = Vector3(0.85, 0.85, 0.85)
	col_node.rotation.y = randf() * TAU
	
	# Obstacle collider for column
	var trunk_body = StaticBody3D.new()
	trunk_body.add_to_group("obstacle")
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.7
	cyl.height = 5.0
	col.shape = cyl
	col.position = pos + Vector3(0, 2.5, 0)
	trunk_body.add_child(col)
	add_child(trunk_body)
	
	if with_torch:
		var torch = torch_scene.instantiate()
		_apply_visibility_cull(torch, 70.0)
		add_child(torch)
		torch.global_position = pos + Vector3(0, 1.6, 0.6)
		torch.scale = Vector3(0.8, 0.8, 0.8)
		
		var t_light = OmniLight3D.new()
		t_light.light_color = Color(1.0, 0.68, 0.28)
		t_light.light_energy = 2.4
		t_light.omni_range = 6.0
		torch.add_child(t_light)
		t_light.position = Vector3(0, 0.5, 0)

func _spawn_tree_grove(center: Vector3, count: int, type_pref: String) -> void:
	for i in range(count):
		var offset = Vector3(randf_range(-7.0, 7.0), 0, randf_range(-7.0, 7.0))
		var tree_pos = center + offset
		tree_pos.y = MapConfig.get_height_at(tree_pos.x, tree_pos.z)
		var tree_node: Node3D = null
		var col_radius = 0.5
		
		if type_pref == "pine":
			tree_node = tree_pine1_scene.instantiate() if i % 2 == 0 else tree_pine2_scene.instantiate()
			tree_node.scale = Vector3(1.15, 1.15, 1.15)
			col_radius = 0.45
		elif type_pref == "twisted":
			tree_node = tree_twisted_scene.instantiate()
			tree_node.scale = Vector3(0.65, 0.65, 0.65)
			col_radius = 0.7
		else:
			tree_node = tree_common1_scene.instantiate() if i % 2 == 0 else tree_common2_scene.instantiate()
			tree_node.scale = Vector3(1.05, 1.05, 1.05)
			col_radius = 0.5
		
		_apply_visibility_cull(tree_node, 100.0)
		add_child(tree_node)
		tree_node.global_position = tree_pos
		tree_node.rotation.y = randf() * TAU
		
		var trunk_body = StaticBody3D.new()
		trunk_body.add_to_group("obstacle")
		var col = CollisionShape3D.new()
		var cyl = CylinderShape3D.new()
		cyl.radius = col_radius
		cyl.height = 4.5
		col.shape = cyl
		col.position = tree_pos + Vector3(0, 2.25, 0)
		trunk_body.add_child(col)
		add_child(trunk_body)

func _spawn_rock_at(pos: Vector3, r_scale: float) -> void:
	pos.y = MapConfig.get_height_at(pos.x, pos.z)
	var rock_roll = randi() % 3
	var rock_node: Node3D = null
	if rock_roll == 0:
		rock_node = rock_m1_scene.instantiate()
	elif rock_roll == 1:
		rock_node = rock_m2_scene.instantiate()
	else:
		rock_node = rock_m3_scene.instantiate()
	
	rock_node.scale = Vector3(r_scale, r_scale, r_scale)
	_apply_visibility_cull(rock_node, 95.0)
	add_child(rock_node)
	rock_node.global_position = pos
	rock_node.rotation.y = randf() * TAU
	
	var rock_body = StaticBody3D.new()
	rock_body.add_to_group("obstacle")
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.4 * r_scale, 1.6 * r_scale, 2.2 * r_scale)
	col.shape = box
	col.position = pos + Vector3(0, 0.8 * r_scale, 0)
	rock_body.add_child(col)
	add_child(rock_body)

func _apply_visibility_cull(node: Node, max_dist: float) -> void:
	if node is VisualInstance3D:
		node.visibility_range_end = max_dist
	for child in node.get_children():
		_apply_visibility_cull(child, max_dist)

func _generate_pickups_and_reagents() -> void:
	# Contextual World Item placements linked to POIs and exploration
	var world_item_configs: Array[Dictionary] = [
		# Zone 1 (Pradera Inicial) - Safe starter exploration
		{"id": "potion_health", "amount": 2, "pos": Vector3(12.0, 0.4, 94.0)},   # Near Meadow Fountain
		{"id": "potion_mana", "amount": 1, "pos": Vector3(-22.0, 0.4, 100.0)},   # Near Meadow Chest
		{"id": "apple", "amount": 3, "pos": Vector3(-16.0, 0.4, 88.0)},         # Under fruit tree
		
		# Zone 2 (Bosque Exterior) - Detour and secrets
		{"id": "arcane_crystal", "amount": 1, "pos": Vector3(38.0, 0.4, 30.0)},  # Key Exploration Resource in East Clearing!
		{"id": "potion_health", "amount": 2, "pos": Vector3(38.0, 0.4, 34.0)},   # Clearing Chest
		{"id": "magic_scroll", "amount": 1, "pos": Vector3(26.0, 0.4, 46.0)},    # Roadside shrine
		{"id": "clover", "amount": 2, "pos": Vector3(-16.0, 0.4, 34.0)},         # Forest grove
		
		# Zone 3 (Corazón del Bosque) - Deep wilderness & detours
		{"id": "sulfur", "amount": 3, "pos": Vector3(-44.0, 0.4, -32.0)},        # West Detour Outpost Chest
		{"id": "potion_mana", "amount": 2, "pos": Vector3(28.0, 0.4, -40.0)},     # Place of Power 1 Glade
		{"id": "magic_scroll", "amount": 1, "pos": Vector3(-36.0, 0.4, -28.0)},   # Gorge arch flank
		
		# Zone 4 (Ruinas Arcanas) - High tier rewards
		{"id": "potion_mana", "amount": 2, "pos": Vector3(-36.0, 0.4, -80.0)},    # Shrine 2 Terrace
		{"id": "potion_health", "amount": 2, "pos": Vector3(36.0, 0.4, -80.0)},   # Shrine 3 Terrace
		{"id": "magic_scroll", "amount": 1, "pos": Vector3(-34.0, 0.4, -66.0)},   # Ancient Altar precinct
		{"id": "potion_health", "amount": 2, "pos": Vector3(0.0, 0.4, -92.0)}     # Avenue of columns before Altar
	]
	
	for cfg in world_item_configs:
		var item = world_item_scene.instantiate()
		add_child(item)
		var p = cfg["pos"]
		p.y = MapConfig.get_height_at(p.x, p.z) + 0.4
		item.global_position = p
		item.setup(cfg["id"], cfg.get("amount", 1))

func _generate_portal() -> void:
	# Portal situated right behind the Boss Altar in Zone 4
	var pz = -108.0
	var py = MapConfig.get_height_at(0.0, pz)
	var portal_pos = Vector3(0.0, py, pz)
	portal_instance = portal_scene.instantiate()
	add_child(portal_instance)
	portal_instance.global_position = portal_pos
