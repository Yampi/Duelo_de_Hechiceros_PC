class_name FogOfWar
extends RefCounted

## Niebla de Guerra (Fog of War) basada en cuadrícula 128x128
## Cobertura espacial: 256m x 256m (-128 a +128 en X y Z).
## Radio de visión / revelación: 20.0 metros.

const GRID_SIZE: int = 128
const MAP_SIZE: float = 256.0
const HALF_SIZE: float = 128.0
const CELL_SIZE: float = 2.0 # 256 / 128 = 2m por celda
const REVEAL_RADIUS: float = 20.0

# 0 = Inexplorado (negro total), 1 = Explorado (sombra tenue), 2 = Visible (despejado)
var explored_grid: PackedByteArray = PackedByteArray()
var visible_grid: PackedByteArray = PackedByteArray()

var fog_image: Image = null
var fog_texture: ImageTexture = null

var _last_player_cell: Vector2i = Vector2i(-999, -999)
var _is_dirty: bool = true

func _init() -> void:
	reset_fog()

func reset_fog() -> void:
	var total_cells = GRID_SIZE * GRID_SIZE
	explored_grid.resize(total_cells)
	visible_grid.resize(total_cells)
	explored_grid.fill(0)
	visible_grid.fill(0)
	
	fog_image = Image.create(GRID_SIZE, GRID_SIZE, false, Image.FORMAT_RGBA8)
	fog_image.fill(Color(0.02, 0.03, 0.05, 0.95)) # Negro total inicial
	fog_texture = ImageTexture.create_from_image(fog_image)
	
	_last_player_cell = Vector2i(-999, -999)
	_is_dirty = true

func world_to_grid(world_pos: Vector3) -> Vector2i:
	var gx = clampi(int((world_pos.x + HALF_SIZE) / CELL_SIZE), 0, GRID_SIZE - 1)
	var gz = clampi(int((world_pos.z + HALF_SIZE) / CELL_SIZE), 0, GRID_SIZE - 1)
	return Vector2i(gx, gz)

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	var wx = (grid_pos.x * CELL_SIZE) - HALF_SIZE + (CELL_SIZE * 0.5)
	var wz = (grid_pos.y * CELL_SIZE) - HALF_SIZE + (CELL_SIZE * 0.5)
	return Vector3(wx, 0.0, wz)

func _get_cell_index(gx: int, gz: int) -> int:
	return gz * GRID_SIZE + gx

func is_point_explored(world_pos: Vector3) -> bool:
	var gp = world_to_grid(world_pos)
	var idx = _get_cell_index(gp.x, gp.y)
	return explored_grid[idx] > 0

func is_point_visible(world_pos: Vector3) -> bool:
	var gp = world_to_grid(world_pos)
	var idx = _get_cell_index(gp.x, gp.y)
	return visible_grid[idx] > 0

func update_player_position(player_pos: Vector3) -> void:
	var center = world_to_grid(player_pos)
	var cell_radius = int(ceil(REVEAL_RADIUS / CELL_SIZE)) # ~10 celdas
	var r_sq = (REVEAL_RADIUS / CELL_SIZE) * (REVEAL_RADIUS / CELL_SIZE)
	
	# Limpiar estado visible anterior
	visible_grid.fill(0)
	
	var min_x = maxi(0, center.x - cell_radius)
	var max_x = mini(GRID_SIZE - 1, center.x + cell_radius)
	var min_z = maxi(0, center.y - cell_radius)
	var max_z = mini(GRID_SIZE - 1, center.y + cell_radius)
	
	for gz in range(min_z, max_z + 1):
		for gx in range(min_x, max_x + 1):
			var dx = float(gx - center.x)
			var dz = float(gz - center.y)
			var dist_sq = dx * dx + dz * dz
			if dist_sq <= r_sq:
				var idx = _get_cell_index(gx, gz)
				visible_grid[idx] = 1
				explored_grid[idx] = 1
	
	_last_player_cell = center
	_update_fog_texture()

func _update_fog_texture() -> void:
	if not fog_image:
		return
	
	# Actualizar píxeles del mapa de niebla
	for gz in range(GRID_SIZE):
		for gx in range(GRID_SIZE):
			var idx = _get_cell_index(gx, gz)
			var is_vis = visible_grid[idx] > 0
			var is_exp = explored_grid[idx] > 0
			
			var pixel_color: Color
			if is_vis:
				pixel_color = Color(0.0, 0.0, 0.0, 0.0) # Transparente / visible
			elif is_exp:
				pixel_color = Color(0.04, 0.05, 0.08, 0.62) # Visto antes / en sombra
			else:
				pixel_color = Color(0.02, 0.03, 0.05, 0.96) # Desconocido / opaco
			
			fog_image.set_pixel(gx, gz, pixel_color)
	
	if fog_texture:
		fog_texture.update(fog_image)

func get_fog_texture() -> ImageTexture:
	return fog_texture
