extends Node

enum GameMode { SURVIVAL, EXPLORATION, OBJECTIVE }

const InventoryManager = preload("res://scripts/inventory/inventory_manager.gd")
const ItemDB = preload("res://scripts/inventory/item_db.gd")

signal reagents_updated
signal shrines_updated
signal poi_discovered(poi_data: Dictionary)
signal zone_discovered(zone_id: int)
signal objective_updated(desc: String, pos: Vector3)
signal loot_collected(item_id: String, amount: int)

var _game_initialized: bool = false
var current_mode: GameMode = GameMode.EXPLORATION

var score: int = 0
var wave: int = 1
var survival_time: float = 0.0
var enemies_defeated: int = 0
var active_shrines: int = 0
var total_shrines: int = 3
var boss_spawned: bool = false
var boss_defeated: bool = false
var level_cleared: bool = false

# Player stats and territorial mana economy
var player_max_health: float = 100.0
var player_health: float = 100.0

var base_mana_cap: float = 75.0
var mana_cap_per_shrine: float = 25.0
var player_max_mana: float = 75.0
var player_mana: float = 50.0

var base_mana_regen: float = 2.0
var regen_per_shrine: float = 3.5
var mana_regen_rate: float = 2.0

# Arcana Altar empowerment status
var arcana_empowered: bool = false

# Exploration and discovery tracking
var discovered_zones: Array[int] = [1] # Zone 1 is known from the start
var discovered_pois: Array[Dictionary] = []
var active_objective: String = ""
var active_objective_pos: Vector3 = Vector3.ZERO

# Inventory System (Session Persistent)
var inventory: InventoryManager = null

# Reagents compatibility dictionary (Magic & Mayhem alchemy)
var reagents: Dictionary = {
	"apple": 0,
	"sulfur": 0,
	"clover": 0,
	"scroll": 0,
	"core": 0
}

# 9 Spell definitions (Hotkeys 1 to 9)
var spells: Dictionary = {
	1: {
		"id": "magic_bolt",
		"name": "Centella Arcana",
		"cost": 5.0,
		"icon": "magic_bolt",
		"desc": "Proyectil rápido de energía pura"
	},
	2: {
		"id": "fireball",
		"name": "Bola de Fuego",
		"cost": 20.0,
		"icon": "fireball",
		"desc": "Explosión ígnea en área con empuje"
	},
	3: {
		"id": "summon_goblin",
		"name": "Invocar Duende",
		"cost": 30.0,
		"icon": "summon_goblin",
		"desc": "Invoca un duende aliado que combate contigo"
	},
	4: {
		"id": "shockwave",
		"name": "Onda Expansiva",
		"cost": 25.0,
		"icon": "shockwave",
		"desc": "Onda sísmica que repele a los enemigos"
	},
	5: {
		"id": "heal",
		"name": "Fuente de Vida",
		"cost": 35.0,
		"icon": "heal",
		"desc": "Restaura 40 puntos de Salud al instante"
	},
	6: {
		"id": "teleport",
		"name": "Teletransporte",
		"cost": 15.0,
		"icon": "teleport",
		"desc": "Parpadeo dimensional instantáneo [Espacio / 6]"
	},
	7: {
		"id": "ice_projectile",
		"name": "Proyectil de Hielo",
		"cost": 12.0,
		"icon": "ice_projectile",
		"desc": "Estalactita afilada de escarcha [T]"
	},
	8: {
		"id": "lightning",
		"name": "Rayo Arcano",
		"cost": 18.0,
		"icon": "lightning",
		"desc": "Descarga eléctrica instantánea en arco [R]"
	},
	9: {
		"id": "arcane_shield",
		"name": "Escudo Mágico",
		"cost": 20.0,
		"icon": "arcane_shield",
		"desc": "Barrera arcana que absorbe daño [C]"
	}
}

func _ready() -> void:
	ItemDB.init_db()
	if not inventory:
		inventory = InventoryManager.new()
		inventory.inventory_updated.connect(_on_inventory_updated)
		inventory.item_added.connect(_on_item_added)
	reset_for_new_game(current_mode)
	_game_initialized = true

func _on_item_added(item_id: String, amount: int) -> void:
	if _game_initialized:
		loot_collected.emit(item_id, amount)

func _on_inventory_updated() -> void:
	if inventory:
		reagents["apple"] = inventory.get_item_count("apple")
		reagents["sulfur"] = inventory.get_item_count("sulfur")
		reagents["clover"] = inventory.get_item_count("clover")
		reagents["scroll"] = inventory.get_item_count("magic_scroll")
		reagents_updated.emit()

func add_reagent(type: String, count: int = 1) -> void:
	var item_id = type
	if type == "scroll":
		item_id = "magic_scroll"
	if inventory:
		inventory.add_item(item_id, count)
	if reagents.has(type):
		reagents[type] += count
		reagents_updated.emit()

func discover_zone(zone_id: int) -> void:
	if not zone_id in discovered_zones:
		discovered_zones.append(zone_id)
		zone_discovered.emit(zone_id)

func discover_poi(poi_id: String, poi_name: String, pos: Vector3, icon: String = "◆") -> void:
	for p in discovered_pois:
		if p.get("id") == poi_id:
			return
	var data = {
		"id": poi_id,
		"name": poi_name,
		"pos": pos,
		"icon": icon
	}
	discovered_pois.append(data)
	poi_discovered.emit(data)

func is_poi_discovered(poi_id: String) -> bool:
	for p in discovered_pois:
		if p.get("id") == poi_id:
			return true
	return false

func set_objective(desc: String, pos: Vector3 = Vector3.ZERO) -> void:
	active_objective = desc
	active_objective_pos = pos
	objective_updated.emit(desc, pos)

func empower_arcana() -> void:
	if arcana_empowered:
		return
	arcana_empowered = true
	base_mana_cap += 25.0
	base_mana_regen += 1.5
	update_mana_capacity()
	player_mana = player_max_mana
	
	# Enhance Centella Arcana definition
	spells[1]["name"] = "Centella Sobrecargada"
	spells[1]["desc"] = "Proyectil acelerado de alto impacto con daño potenciado (+60%)"

func update_mana_capacity() -> void:
	var shrine_bonus = active_shrines * mana_cap_per_shrine
	var empowered_bonus = 25.0 if arcana_empowered else 0.0
	player_max_mana = base_mana_cap + shrine_bonus
	mana_regen_rate = base_mana_regen + (active_shrines * regen_per_shrine)
	player_mana = clamp(player_mana, 0.0, player_max_mana)
	shrines_updated.emit()

func reset_for_new_game(mode: GameMode) -> void:
	current_mode = mode
	score = 0
	wave = 1
	survival_time = 0.0
	enemies_defeated = 0
	active_shrines = 0
	total_shrines = 3
	boss_spawned = false
	boss_defeated = false
	level_cleared = false
	player_health = player_max_health
	base_mana_cap = 75.0
	base_mana_regen = 2.0
	arcana_empowered = false
	
	# Reset discovery
	discovered_zones = [1]
	discovered_pois.clear()
	
	# Default starter objective
	active_objective = "Explora el Bosque y encuentra el Cristal Arcano"
	active_objective_pos = Vector3(38.0, 0.0, 32.0) # Eastern Clearing
	
	var prev_init = _game_initialized
	_game_initialized = false
	if not inventory:
		inventory = InventoryManager.new()
		inventory.inventory_updated.connect(_on_inventory_updated)
		inventory.item_added.connect(_on_item_added)
	else:
		inventory.clear()
	
	# Starter items for smooth initial onboarding
	inventory.add_item("potion_health", 2)
	inventory.add_item("potion_mana", 1)
	_game_initialized = prev_init
	
	reagents = {
		"apple": 0,
		"sulfur": 0,
		"clover": 0,
		"scroll": 0,
		"core": 0
	}
	
	update_mana_capacity()
	player_mana = player_max_mana * 0.7

func start_game(mode: GameMode) -> void:
	reset_for_new_game(mode)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func return_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

var damage_number_scene: PackedScene = preload("res://scenes/DamageNumber.tscn")
var _damage_number_pool: Array[Node3D] = []
const MAX_DAMAGE_NUMBER_POOL_SIZE: int = 40

func shake_camera(amount: float = 0.35) -> void:
	get_tree().call_group("camera", "add_trauma", amount)

func spawn_damage_number(world_pos: Vector3, text: String, color: Color = Color.WHITE, scale_mult: float = 1.0) -> void:
	var root = get_tree().current_scene
	if not root:
		return
	
	var dn: Node3D = null
	while _damage_number_pool.size() > 0:
		var candidate = _damage_number_pool.pop_back()
		if is_instance_valid(candidate) and candidate.is_inside_tree():
			dn = candidate
			break
	
	if not dn:
		dn = damage_number_scene.instantiate()
		dn.in_pool = true
		dn.finished.connect(_on_damage_number_finished)
		root.add_child(dn)
	
	dn.global_position = world_pos + Vector3(0, 1.2, 0)
	dn.setup(text, color, scale_mult)

func _on_damage_number_finished(dn: Node3D) -> void:
	if is_instance_valid(dn) and _damage_number_pool.size() < MAX_DAMAGE_NUMBER_POOL_SIZE:
		_damage_number_pool.append(dn)
	elif is_instance_valid(dn):
		dn.queue_free()
