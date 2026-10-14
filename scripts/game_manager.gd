extends Node

enum GameMode { SURVIVAL, EXPLORATION, OBJECTIVE }

const InventoryManager = preload("res://scripts/inventory/inventory_manager.gd")
const ItemDB = preload("res://scripts/inventory/item_db.gd")
const FogOfWar = preload("res://scripts/fog/fog_of_war.gd")
const CraftingManager = preload("res://scripts/crafting/crafting_manager.gd")
const LoreManager = preload("res://scripts/lore/lore_manager.gd")

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
var fog_of_war: FogOfWar = null

# Inventory & Crafting System (Session Persistent)
var inventory: InventoryManager = null
var crafting: CraftingManager = null
var lore: LoreManager = null

# Reagents compatibility dictionary (Magic & Mayhem alchemy)
var reagents: Dictionary = {
	"apple": 0,
	"sulfur": 0,
	"clover": 0,
	"scroll": 0,
	"core": 0
}

# Bestiary repository (discovered monster weaknesses and resistances)
var bestiary_discovered: Dictionary = {}

func record_bestiary_entry(monster_name: String, element: String, is_weakness: bool) -> void:
	if not bestiary_discovered.has(monster_name):
		bestiary_discovered[monster_name] = {
			"weaknesses": [],
			"resistances": []
		}
	var cat = "weaknesses" if is_weakness else "resistances"
	if not element in bestiary_discovered[monster_name][cat]:
		bestiary_discovered[monster_name][cat].append(element)

func get_bestiary_entry(monster_name: String) -> Dictionary:
	return bestiary_discovered.get(monster_name, {"weaknesses": [], "resistances": []})

# Catálogo completo de los 11 hechizos arcanos
var spell_catalog: Dictionary = {
	"magic_bolt": {
		"id": "magic_bolt",
		"name": "Centella Arcana",
		"cost": 8.0,
		"cooldown": 0.6,
		"windup": 0.15,
		"icon": "magic_bolt",
		"desc": "Proyectil rápido de energía pura"
	},
	"fireball": {
		"id": "fireball",
		"name": "Bola de Fuego",
		"cost": 20.0,
		"cooldown": 2.0,
		"windup": 0.55,
		"icon": "fireball",
		"desc": "Explosión ígnea en área con empuje y quemadura DoT"
	},
	"summon_goblin": {
		"id": "summon_goblin",
		"name": "Invocar Duende",
		"cost": 30.0,
		"cooldown": 8.0,
		"windup": 0.75,
		"icon": "summon_goblin",
		"desc": "Invoca un duende aliado que combate contigo"
	},
	"shockwave": {
		"id": "shockwave",
		"name": "Onda Expansiva",
		"cost": 18.0,
		"cooldown": 3.0,
		"windup": 0.50,
		"icon": "shockwave",
		"desc": "Onda sísmica que repele y aturde 1.0s a enemigos"
	},
	"heal": {
		"id": "heal",
		"name": "Fuente de Vida",
		"cost": 25.0,
		"cooldown": 5.0,
		"windup": 0.85,
		"icon": "heal",
		"desc": "Restaura 40 puntos de Salud al instante"
	},
	"teleport": {
		"id": "teleport",
		"name": "Teletransporte",
		"cost": 15.0,
		"cooldown": 3.0,
		"windup": 0.20,
		"icon": "teleport",
		"desc": "Parpadeo dimensional instantáneo [Espacio / 6]"
	},
	"ice_projectile": {
		"id": "ice_projectile",
		"name": "Proyectil de Hielo",
		"cost": 12.0,
		"cooldown": 1.2,
		"windup": 0.25,
		"icon": "ice_projectile",
		"desc": "Estalactita de escarcha. 3 impactos congelan 2.0s"
	},
	"lightning": {
		"id": "lightning",
		"name": "Rayo Arcano",
		"cost": 24.0,
		"cooldown": 2.8,
		"windup": 0.30,
		"icon": "lightning",
		"desc": "Descarga instantánea que aturde y encadena 2 objetivos"
	},
	"arcane_shield": {
		"id": "arcane_shield",
		"name": "Escudo Mágico",
		"cost": 20.0,
		"cooldown": 6.0,
		"windup": 0.35,
		"icon": "arcane_shield",
		"desc": "Barrera arcana que absorbe daño [C / 9]"
	},
	"earth_fissure": {
		"id": "earth_fissure",
		"name": "Fisura de Tierra",
		"cost": 22.0,
		"cooldown": 2.5,
		"windup": 0.35,
		"icon": "earth_fissure",
		"desc": "Pantano de fango de 4m. Hunde y ralentiza 70% por 4s"
	},
	"arcane_vines": {
		"id": "arcane_vines",
		"name": "Enredaderas Arcanas",
		"cost": 25.0,
		"cooldown": 3.5,
		"windup": 0.40,
		"icon": "arcane_vines",
		"desc": "Zarzas mágicas de 3m. Inmoviliza enemigos por 3.0s"
	}
}

# 9 ranuras activas equipadas (Grimorio)
var equipped_spell_ids: Array[String] = [
	"magic_bolt",
	"fireball",
	"summon_goblin",
	"shockwave",
	"heal",
	"teleport",
	"ice_projectile",
	"lightning",
	"arcane_shield"
]

var spells: Dictionary = {}

signal grimorio_updated

func equip_spell(slot_idx: int, spell_id: String) -> void:
	if slot_idx >= 1 and slot_idx <= 9 and spell_catalog.has(spell_id):
		equipped_spell_ids[slot_idx - 1] = spell_id
		_rebuild_spells_dictionary()
		save_grimorio()
		grimorio_updated.emit()

func _rebuild_spells_dictionary() -> void:
	spells.clear()
	for i in range(equipped_spell_ids.size()):
		var slot = i + 1
		var s_id = equipped_spell_ids[i]
		if spell_catalog.has(s_id):
			spells[slot] = spell_catalog[s_id]

func save_grimorio() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("grimorio", "equipped_spells", equipped_spell_ids)
	cfg.save("user://grimorio.cfg")

func load_grimorio() -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load("user://grimorio.cfg")
	if err == OK:
		var loaded = cfg.get_value("grimorio", "equipped_spells", [])
		if loaded is Array and loaded.size() == 9:
			var valid = true
			for s in loaded:
				if not spell_catalog.has(s):
					valid = false
					break
			if valid:
				equipped_spell_ids = loaded
	_rebuild_spells_dictionary()

func _ready() -> void:
	ItemDB.init_db()
	load_grimorio()
	if not inventory:
		inventory = InventoryManager.new()
		inventory.inventory_updated.connect(_on_inventory_updated)
		inventory.item_added.connect(_on_item_added)
	if not crafting:
		crafting = CraftingManager.new()
	if not lore:
		lore = LoreManager.new()
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
	
	# Reset discovery and fog of war
	discovered_zones = [1]
	discovered_pois.clear()
	if not fog_of_war:
		fog_of_war = FogOfWar.new()
	else:
		fog_of_war.reset_fog()
	
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
	
	if not crafting:
		crafting = CraftingManager.new()
	
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
