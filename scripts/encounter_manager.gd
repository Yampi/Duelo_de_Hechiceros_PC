class_name EncounterManager
extends Node

const MapConfig = preload("res://scripts/map_config.gd")

signal zone_changed(zone_id: int, zone_data: Dictionary)
signal encounter_started(encounter_id: String, enemy_count: int)
signal boss_encounter_started

const MAX_ACTIVE_ENEMIES: int = 10
const MAX_LOCAL_ENEMIES_NEARBY: int = 3
const ENCOUNTER_RESPAWN_COOLDOWN: float = 150.0
const ENEMY_SCENE: PackedScene = preload("res://scenes/Enemy.tscn")
const RIVAL_WIZARD_SCENE: PackedScene = preload("res://scenes/RivalWizard.tscn")

var encounters: Array[Dictionary] = []
var active_enemies: Array[CharacterBody3D] = []
var current_zone: int = MapConfig.ZoneId.PRADERA_INICIAL
var player_ref: Node3D = null

func _init() -> void:
	_init_encounter_database()

func _ready() -> void:
	if encounters.is_empty():
		_init_encounter_database()

func set_player(p: Node3D) -> void:
	player_ref = p

func _init_encounter_database() -> void:
	encounters.clear()
	
	# === ZONA 1: PRADERA INICIAL (Safe, isolated weak scouts away from main road) ===
	encounters.append({
		"id": "z1_scout_east",
		"zone": MapConfig.ZoneId.PRADERA_INICIAL,
		"pos": Vector3(28.0, 0.0, 76.0), # Tucked into eastern grove, road is clear
		"archetypes": [0], # GOBLIN
		"count": 1,
		"trigger_dist": 18.0,
		"min_dist": 12.0,
		"is_unique": true,
		"is_cleared": false,
		"is_triggered": false,
		"cooldown": 300.0,
		"timer": 0.0,
		"spawned": []
	})
	encounters.append({
		"id": "z1_scout_west",
		"zone": MapConfig.ZoneId.PRADERA_INICIAL,
		"pos": Vector3(-28.0, 0.0, 68.0), # Tucked into western thicket
		"archetypes": [0], # GOBLIN
		"count": 1,
		"trigger_dist": 18.0,
		"min_dist": 12.0,
		"is_unique": true,
		"is_cleared": false,
		"is_triggered": false,
		"cooldown": 300.0,
		"timer": 0.0,
		"spawned": []
	})
	
	# === ZONA 2: BOSQUE EXTERIOR (Patrols and Secret Clearing Ambush) ===
	encounters.append({
		"id": "z2_path_patrol",
		"zone": MapConfig.ZoneId.BOSQUE_EXTERIOR,
		"pos": Vector3(-8.0, 0.0, 48.0),
		"archetypes": [0], # 2 GOBLINS
		"count": 2,
		"trigger_dist": 22.0,
		"min_dist": 14.0,
		"is_unique": false,
		"is_cleared": false,
		"is_triggered": false,
		"cooldown": 150.0, # Generous cooldown prevents immediate respawn harassment
		"timer": 0.0,
		"spawned": []
	})
	encounters.append({
		"id": "z2_east_clearing_guardian",
		"zone": MapConfig.ZoneId.BOSQUE_EXTERIOR,
		"pos": Vector3(38.0, 0.0, 32.0), # Secret Clearing protecting Arcane Crystal & Chest
		"archetypes": [1, 0], # SKELETON_SPEAR + GOBLIN AMBUSH
		"count": 2,
		"trigger_dist": 20.0,
		"min_dist": 13.0,
		"is_unique": true, # Unique rewarding ambush event
		"is_cleared": false,
		"is_triggered": false,
		"cooldown": 999.0,
		"timer": 0.0,
		"spawned": []
	})
	encounters.append({
		"id": "z2_deep_patrol",
		"zone": MapConfig.ZoneId.BOSQUE_EXTERIOR,
		"pos": Vector3(10.0, 0.0, 16.0),
		"archetypes": [1, 0], # SPEAR + GOBLIN
		"count": 2,
		"trigger_dist": 22.0,
		"min_dist": 14.0,
		"is_unique": false,
		"is_cleared": false,
		"is_triggered": false,
		"cooldown": 150.0,
		"timer": 0.0,
		"spawned": []
	})
	
	# === ZONA 3: CORAZÓN DEL BOSQUE (Strategic bridge and defile threats) ===
	encounters.append({
		"id": "z3_bridge_ambush",
		"zone": MapConfig.ZoneId.CORAZON_BOSQUE,
		"pos": Vector3(0.0, 0.0, -28.0), # Stone bridge gorge
		"archetypes": [1, 2], # SPEAR + ARCHER
		"count": 2,
		"trigger_dist": 24.0,
		"min_dist": 15.0,
		"is_unique": false,
		"is_cleared": false,
		"is_triggered": false,
		"cooldown": 180.0,
		"timer": 0.0,
		"spawned": []
	})
	encounters.append({
		"id": "z3_west_detour_flank",
		"zone": MapConfig.ZoneId.CORAZON_BOSQUE,
		"pos": Vector3(-42.0, 0.0, -32.0), # Western flanking defile guarding chest & sulfur
		"archetypes": [3, 2], # FIRE_IMP + ARCHER
		"count": 2,
		"trigger_dist": 22.0,
		"min_dist": 14.0,
		"is_unique": true,
		"is_cleared": false,
		"is_triggered": false,
		"cooldown": 999.0,
		"timer": 0.0,
		"spawned": []
	})
	encounters.append({
		"id": "z3_glade_swarm",
		"zone": MapConfig.ZoneId.CORAZON_BOSQUE,
		"pos": Vector3(22.0, 0.0, -48.0), # Guarding Place of Power 1
		"archetypes": [3, 1], # FIRE_IMP + SPEAR
		"count": 2,
		"trigger_dist": 24.0,
		"min_dist": 15.0,
		"is_unique": false,
		"is_cleared": false,
		"is_triggered": false,
		"cooldown": 180.0,
		"timer": 0.0,
		"spawned": []
	})
	
	# === ZONA 4: RUINAS ARCANAS (Sanctum guards and Boss) ===
	encounters.append({
		"id": "z4_avenue_guards",
		"zone": MapConfig.ZoneId.RUINAS_ARCANAS,
		"pos": Vector3(0.0, 0.0, -74.0), # Avenue of Columns
		"archetypes": [4, 2], # SHADOW_IMP + ARCHER
		"count": 2,
		"trigger_dist": 24.0,
		"min_dist": 15.0,
		"is_unique": false,
		"is_cleared": false,
		"is_triggered": false,
		"cooldown": 180.0,
		"timer": 0.0,
		"spawned": []
	})
	encounters.append({
		"id": "z4_ruins_sanctum_west",
		"zone": MapConfig.ZoneId.RUINAS_ARCANAS,
		"pos": Vector3(-32.0, 0.0, -92.0), # Guarding Ancient Altar & Terrace
		"archetypes": [1, 4], # SPEAR + SHADOW_IMP
		"count": 2,
		"trigger_dist": 22.0,
		"min_dist": 14.0,
		"is_unique": true,
		"is_cleared": false,
		"is_triggered": false,
		"cooldown": 999.0,
		"timer": 0.0,
		"spawned": []
	})
	encounters.append({
		"id": "z4_rival_wizard_duel",
		"zone": MapConfig.ZoneId.RUINAS_ARCANAS,
		"pos": Vector3(0.0, 0.0, -84.0), # Avenue of Columns
		"archetypes": [],
		"count": 1,
		"trigger_dist": 26.0,
		"min_dist": 15.0,
		"is_unique": true,
		"is_cleared": false,
		"is_triggered": false,
		"cooldown": 999.0,
		"timer": 0.0,
		"spawned": [],
		"is_rival_duel": true
	})
	encounters.append({
		"id": "z4_portal_boss",
		"zone": MapConfig.ZoneId.RUINAS_ARCANAS,
		"pos": MapConfig.BOSS_ALTAR_POS, # Boss altar at -98m
		"archetypes": [1, 4], # Boss spear + Shadow Imps
		"count": 3,
		"trigger_dist": 28.0,
		"min_dist": 16.0,
		"is_unique": true,
		"is_cleared": false,
		"is_triggered": false,
		"cooldown": 999.0,
		"timer": 0.0,
		"spawned": []
	})

func _process(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	
	var p_pos = player_ref.global_position
	var detected_zone = MapConfig.get_zone_at_position(p_pos)
	
	# Detect zone transition
	if detected_zone != current_zone:
		current_zone = detected_zone
		var z_data = MapConfig.get_zone_data(current_zone)
		zone_changed.emit(current_zone, z_data)
	
	# Purge invalid / dead enemies from active tracking
	_cleanup_active_enemies()
	
	# Process encounter triggers
	for enc in encounters:
		_process_single_encounter(enc, p_pos, delta)

func _cleanup_active_enemies() -> void:
	var valid_list: Array[CharacterBody3D] = []
	for e in active_enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion() and not e.get("is_dead"):
			valid_list.append(e)
	active_enemies = valid_list

func _process_single_encounter(enc: Dictionary, p_pos: Vector3, delta: float) -> void:
	# Clean up dead spawned enemies from this encounter
	var living_spawned: Array = []
	for e in enc["spawned"]:
		if is_instance_valid(e) and not e.is_queued_for_deletion() and not e.get("is_dead"):
			living_spawned.append(e)
	enc["spawned"] = living_spawned
	
	# Check if previously triggered encounter has been wiped
	if enc["is_triggered"]:
		if living_spawned.is_empty():
			if enc["is_unique"]:
				enc["is_cleared"] = true
				enc["is_triggered"] = false
			else:
				# Repeatable encounter starts respawn cooldown
				enc["timer"] += delta
				if enc["timer"] >= enc["cooldown"]:
					# Player must be far enough to respawn naturally
					if p_pos.distance_to(enc["pos"]) > 32.0:
						enc["is_triggered"] = false
						enc["timer"] = 0.0
		return
	
	if enc["is_cleared"]:
		return
	
	# Pacing: only activate encounters in current zone or direct adjacent forward zone
	var zone_diff = enc["zone"] - current_zone
	if zone_diff < 0 or zone_diff > 1:
		return
	
	var dist = Vector2(p_pos.x - enc["pos"].x, p_pos.z - enc["pos"].z).length()
	if dist <= enc["trigger_dist"]:
		var is_boss_encounter = enc["id"] == "z4_portal_boss" or enc.get("is_rival_duel", false)
		if not is_boss_encounter:
			# Local density check: prevent dogpiles if player is already engaged with >= 3 enemies nearby
			var nearby_active_count = 0
			for e in active_enemies:
				if is_instance_valid(e) and not e.is_queued_for_deletion() and not e.get("is_dead"):
					if Vector2(p_pos.x - e.global_position.x, p_pos.z - e.global_position.z).length() <= 28.0:
						nearby_active_count += 1
			if nearby_active_count >= 3:
				return
		
		if is_boss_encounter or (active_enemies.size() + enc["count"] <= MAX_ACTIVE_ENEMIES):
			_spawn_encounter_group(enc)

func _spawn_encounter_group(enc: Dictionary) -> void:
	enc["is_triggered"] = true
	var center = enc["pos"]
	var count = enc["count"]
	var is_boss_enc = enc["id"] == "z4_portal_boss"
	var is_bridge_enc = enc["id"] == "z3_bridge_ambush"
	var is_clearing_enc = enc["id"] == "z2_east_clearing_guardian"
	var is_z1_scout = enc["id"] in ["z1_scout_east", "z1_scout_west"]
	
	if enc.get("is_rival_duel", false):
		boss_encounter_started.emit()
		var rival = RIVAL_WIZARD_SCENE.instantiate() as CharacterBody3D
		var spawn_pos = center
		spawn_pos.y = MapConfig.get_height_at(spawn_pos.x, spawn_pos.z)
		get_parent().add_child(rival)
		rival.global_position = spawn_pos
		enc["spawned"].append(rival)
		active_enemies.append(rival)
		GameManager.spawn_damage_number(center + Vector3(0, 2.0, 0), "⚔️ ¡DUELO ARCANO: ARCHIMAGO MALAKOR!", Color(1.0, 0.1, 0.3), 1.5)
		encounter_started.emit(enc["id"], 1)
		return
	
	if is_boss_enc:
		boss_encounter_started.emit()
	
	for i in range(count):
		var enemy = ENEMY_SCENE.instantiate() as CharacterBody3D
		var offset = Vector3.ZERO
		
		# Intentional tactical positioning per encounter type
		if is_bridge_enc:
			# Choke point formation: Spearman blocks entrance, Archer snipes from opposite bridge end
			offset = Vector3(0.0, 0.0, 6.0) if i == 0 else Vector3(0.0, 0.0, -6.0)
		elif is_clearing_enc:
			# Ambush formation: Sentinel guards crystal dais, flanker lurks behind eastern rock ridge
			offset = Vector3(0.0, 0.0, -1.5) if i == 0 else Vector3(6.5, 0.0, 3.5)
		elif is_boss_enc:
			if i == 0:
				offset = Vector3.ZERO
			elif i == 1:
				offset = Vector3(-6.5, 0.0, 2.0)
			else:
				offset = Vector3(6.5, 0.0, 2.0)
		elif count > 1:
			var ang = (float(i) / float(count)) * TAU
			var rad = randf_range(2.0, 4.5)
			offset = Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		
		var spawn_pos = center + offset
		spawn_pos.y = MapConfig.get_height_at(spawn_pos.x, spawn_pos.z)
		get_parent().add_child(enemy)
		enemy.global_position = spawn_pos
		enemy.home_position = spawn_pos
		enemy.max_leash_distance = 24.0
		
		# Archetype assignment
		var arch_list = enc["archetypes"]
		var arch_type = arch_list[i % arch_list.size()]
		
		if is_boss_enc and i == 0:
			enemy.is_boss = true
			enemy.set_archetype(1) # Skeleton Spear Boss
		else:
			enemy.set_archetype(arch_type)
		
		if is_z1_scout and enemy.has_method("setup_as_scout"):
			enemy.setup_as_scout()
		elif is_clearing_enc and i == 1:
			# Flanker has staggered awareness to avoid instant simultaneous dogpiling
			enemy.alert_duration = 0.85
		
		enc["spawned"].append(enemy)
		active_enemies.append(enemy)
	
	if is_clearing_enc:
		GameManager.spawn_damage_number(center + Vector3(0, 1.8, 0), "🌲 ¡EMBOSCADA EN EL CLARO!", Color(1.0, 0.45, 0.2), 1.35)
	elif is_bridge_enc:
		GameManager.spawn_damage_number(center + Vector3(0, 1.8, 0), "🌉 ¡DESFILADERO DEL PUENTE!", Color(0.85, 0.45, 1.0), 1.35)
	
	encounter_started.emit(enc["id"], count)

func reset_encounters() -> void:
	for e in active_enemies:
		if is_instance_valid(e):
			e.queue_free()
	active_enemies.clear()
	_init_encounter_database()
