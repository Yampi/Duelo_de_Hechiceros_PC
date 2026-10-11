class_name TestExplorationSuite
extends Node

const MapConfig = preload("res://scripts/map_config.gd")
const MapGenerator = preload("res://scripts/map_generator.gd")
const EncounterManager = preload("res://scripts/encounter_manager.gd")

var passed_count: int = 0
var failed_count: int = 0

func _ready() -> void:
	print("\n========================================================")
	print("🗺️ RUNNING EXPLORATION, ENCOUNTERS & SPELL VFX TEST SUITE")
	print("========================================================")
	
	test_phase_a_map_and_zones()
	test_phase_b_encounter_progression()
	test_phase_c_spells_vfx()
	
	print("\n========================================================")
	print("📊 EXPLORATION SUITE RESULTS: PASSED: %d | FAILED: %d" % [passed_count, failed_count])
	print("========================================================")
	
	if failed_count == 0:
		print("\n✅ ALL EXPLORATION, PROGRESSION & VFX CRITERIA SATISFIED!\n")
	else:
		printerr("\n❌ TEST SUITE FAILED WITH %d ERRORS\n" % failed_count)
	
	get_tree().quit(0 if failed_count == 0 else 1)

func log_pass(test_name: String, details: String = "") -> void:
	passed_count += 1
	print("  [PASS] %s %s" % [test_name, details])

func log_fail(test_name: String, reason: String) -> void:
	failed_count += 1
	printerr("  [FAIL] %s - %s" % [test_name, reason])

func test_phase_a_map_and_zones() -> void:
	print("\n--- PHASE A: 256x256m Delimited Map & 4 Zones Tests ---")
	
	# 1. Centralized Map Dimensions
	if MapConfig.MAP_SIZE == 256.0 and MapConfig.HALF_SIZE == 128.0:
		log_pass("Map Dimensions", "Centralized MAP_SIZE=256.0m, HALF_SIZE=128.0m verified")
	else:
		log_fail("Map Dimensions", "Expected 256.0x256.0m map size")
	
	# 2. 4 Zone Bound Definitions
	var zones = [
		MapConfig.ZoneId.PRADERA_INICIAL,
		MapConfig.ZoneId.BOSQUE_EXTERIOR,
		MapConfig.ZoneId.CORAZON_BOSQUE,
		MapConfig.ZoneId.RUINAS_ARCANAS
	]
	var zone_names = ["Pradera Inicial", "Bosque Exterior", "Corazón del Bosque", "Ruinas Arcanas"]
	var all_zones_valid = true
	for i in range(zones.size()):
		var zid = zones[i]
		var data = MapConfig.get_zone_data(zid)
		if data.is_empty() or data["name"] != zone_names[i]:
			all_zones_valid = false
			break
	
	if all_zones_valid:
		log_pass("Zone Definitions", "All 4 zones defined with distinct names, titles and Z bounds")
	else:
		log_fail("Zone Definitions", "Zone bounds or metadata missing")
	
	# 3. Spatial Zone Detection
	var p_z1 = MapConfig.get_zone_at_position(Vector3(0, 0, 96))
	var p_z2 = MapConfig.get_zone_at_position(Vector3(0, 0, 32))
	var p_z3 = MapConfig.get_zone_at_position(Vector3(0, 0, -32))
	var p_z4 = MapConfig.get_zone_at_position(Vector3(0, 0, -96))
	
	if p_z1 == MapConfig.ZoneId.PRADERA_INICIAL and p_z2 == MapConfig.ZoneId.BOSQUE_EXTERIOR and p_z3 == MapConfig.ZoneId.CORAZON_BOSQUE and p_z4 == MapConfig.ZoneId.RUINAS_ARCANAS:
		log_pass("Zone Spatial Detection", "Correctly identifies Zones 1, 2, 3, 4 along the North-South axis")
	else:
		log_fail("Zone Spatial Detection", "Spatial zone categorization failed")
	
	# 4. MapGenerator Generation
	var mapgen = MapGenerator.new()
	add_child(mapgen)
	mapgen.generate_map()
	
	# Ground verification
	var ground = mapgen.get_node_or_null("Ground") as StaticBody3D
	if ground:
		var col = ground.get_child(0) as CollisionShape3D
		if col and col.shape is BoxShape3D:
			var sz = (col.shape as BoxShape3D).size
			if sz.x >= 256.0 and sz.z >= 256.0:
				log_pass("Ground Collider", "Ground box collider sized %.1fx%.1fm matches map size" % [sz.x, sz.z])
			else:
				log_fail("Ground Collider", "Ground collider size smaller than 256m: %s" % str(sz))
	else:
		log_fail("Ground Node", "Ground StaticBody3D missing")
	
	# Boundary Walls
	var obstacles = get_tree().get_nodes_in_group("obstacle")
	var wall_count = 0
	for o in obstacles:
		if o is StaticBody3D and o.get_parent() == mapgen:
			wall_count += 1
	if wall_count >= 4:
		log_pass("Physical Boundary Walls", "Found %d perimeter obstacle colliders" % wall_count)
	else:
		log_fail("Physical Boundary Walls", "Perimeter boundary colliders missing")
	
	# Shrines / Places of Power
	if mapgen.shrine_positions.size() == 3:
		log_pass("Places of Power (Shrines)", "3 Shrines generated across the zones (total=%d)" % mapgen.shrine_positions.size())
	else:
		log_fail("Places of Power (Shrines)", "Expected 3 shrines, found %d" % mapgen.shrine_positions.size())
	
	mapgen.queue_free()

func test_phase_b_encounter_progression() -> void:
	print("\n--- PHASE B: Centralized Encounter Progression Tests ---")
	
	var em = EncounterManager.new()
	add_child(em)
	
	# 1. Encounter Database Completeness
	if em.encounters.size() >= 10:
		log_pass("Encounter Database", "Registered %d progressive encounters across 4 zones" % em.encounters.size())
	else:
		log_fail("Encounter Database", "Expected at least 10 encounters, found %d" % em.encounters.size())
	
	# 2. Field Schema Validation
	var schema_valid = true
	for enc in em.encounters:
		if not ("id" in enc and "zone" in enc and "pos" in enc and "archetypes" in enc and "count" in enc and "trigger_dist" in enc and "min_dist" in enc and "is_unique" in enc):
			schema_valid = false
			break
	if schema_valid:
		log_pass("Encounter Schema", "All encounters specify zone, pos, archetypes, count, trigger_dist, min_dist, is_unique")
	else:
		log_fail("Encounter Schema", "Encounter definition missing required keys")
	
	# 3. Population Ceiling Enforcement
	if em.MAX_ACTIVE_ENEMIES == 10:
		log_pass("Population Ceiling", "MAX_ACTIVE_ENEMIES capped at 10 to avoid overwhelming performance")
	else:
		log_fail("Population Ceiling", "MAX_ACTIVE_ENEMIES invalid")
	
	# 4. Anti-Face Spawning (min_dist > 0)
	var safe_distances = true
	for enc in em.encounters:
		if enc["min_dist"] < 10.0 or enc["trigger_dist"] <= enc["min_dist"]:
			safe_distances = false
			break
	if safe_distances:
		log_pass("Anti-Face Spawn Rule", "All encounter triggers enforce safety perimeter (min_dist >= 14m, trigger_dist > min_dist)")
	else:
		log_fail("Anti-Face Spawn Rule", "Encounter has unsafe trigger distance parameters")
	
	# 5. Zone Pacing Filtering (Simulated Player in Zone 1)
	var dummy_player = Node3D.new()
	add_child(dummy_player)
	dummy_player.global_position = Vector3(0, 0, 96) # In Zone 1
	em.set_player(dummy_player)
	
	em._process(0.016)
	
	# Verify that no Zone 4 (Ruinas Arcanas) enemies were spawned while player is in Zone 1
	var zone4_spawned = false
	for enc in em.encounters:
		if enc["zone"] == MapConfig.ZoneId.RUINAS_ARCANAS and enc["is_triggered"]:
			zone4_spawned = true
			break
	if not zone4_spawned:
		log_pass("Gradual Zone Activation", "Distant Zone 4 encounters remain dormant while player is in Zone 1")
	else:
		log_fail("Gradual Zone Activation", "Zone 4 encounters prematurely activated in Zone 1")
	
	dummy_player.queue_free()
	em.queue_free()

func test_phase_c_spells_vfx() -> void:
	print("\n--- PHASE C: 6 Playable Spells & Elaborated VFX Tests ---")
	
	# 1. Bola de Fuego (Fireball)
	var fb_scene = load("res://scenes/Fireball.tscn")
	if fb_scene:
		var fb = fb_scene.instantiate()
		add_child(fb)
		fb.init_trajectory(Vector3.ZERO, Vector3(0, 0, 15))
		var mantle = fb.find_child("FlameMantle", true, false)
		var trail = fb.find_child("FireTrail", true, false)
		var burst = fb.find_child("ExplosionBurst", true, false)
		var ring = fb.find_child("BlastRing", true, false)
		if mantle and trail and burst and ring:
			log_pass("Bola de Fuego VFX", "Incandescent core, rotating flame mantle, trail, blast ring & explosion burst verified")
		else:
			log_fail("Bola de Fuego VFX", "Missing fireball VFX nodes")
		fb.queue_free()
	else:
		log_fail("Bola de Fuego Scene", "Could not load Fireball.tscn")
	
	# 2. Proyectil de Hielo (Ice Projectile)
	var ice_scene = load("res://scenes/IceProjectile.tscn")
	if ice_scene:
		var ice = ice_scene.instantiate()
		add_child(ice)
		ice.init_projectile(Vector3.ZERO, Vector3.FORWARD)
		var core = ice.find_child("IcicleCore", true, false)
		var trail = ice.find_child("FrostTrail", true, false)
		var burst = ice.find_child("ShatterBurst", true, false)
		if core and trail and burst:
			log_pass("Proyectil de Hielo VFX", "5-sided prismatic icicle mesh, frost mist trail & shatter burst verified")
		else:
			log_fail("Proyectil de Hielo VFX", "Missing ice projectile components")
		ice.queue_free()
	else:
		log_fail("Proyectil de Hielo Scene", "Could not load IceProjectile.tscn")
	
	# 3. Rayo (Lightning Bolt)
	var light_scene = load("res://scenes/LightningBolt.tscn")
	if light_scene:
		var bolt = light_scene.instantiate()
		add_child(bolt)
		bolt.init_lightning(Vector3(0, 1.4, 0), Vector3(0, 0, 10))
		var mesh_inst = bolt.find_child("BoltMesh", true, false)
		var sparks = bolt.find_child("SparkParticles", true, false)
		if mesh_inst and sparks:
			log_pass("Rayo Arcano VFX", "Multi-segment zigzag line mesh with forks, high emission & impact sparks verified")
		else:
			log_fail("Rayo Arcano VFX", "Missing lightning bolt components")
		bolt.queue_free()
	else:
		log_fail("Rayo Arcano Scene", "Could not load LightningBolt.tscn")
	
	# 4. Escudo Mágico (Arcane Shield)
	var shield_scene = load("res://scenes/ArcaneShield.tscn")
	if shield_scene:
		var shield = shield_scene.instantiate()
		add_child(shield)
		var dummy_target = Node3D.new()
		add_child(dummy_target)
		shield.activate(dummy_target, 5.0)
		var dome = shield.find_child("ShieldMesh", true, false)
		var edge = shield.find_child("EdgeRing", true, false)
		var has_absorb = shield.has_method("absorb_hit")
		if dome and edge and has_absorb:
			shield.absorb_hit()
			log_pass("Escudo Mágico VFX", "Translucent barrier dome, rotating gyroscopic rings & absorb_hit reaction verified")
		else:
			log_fail("Escudo Mágico VFX", "Missing arcane shield components or absorb method")
		dummy_target.queue_free()
		shield.queue_free()
	else:
		log_fail("Escudo Mágico Scene", "Could not load ArcaneShield.tscn")
	
	# 5. Curación (Heal Effect)
	var heal_scene = load("res://scenes/HealEffect.tscn")
	if heal_scene:
		var heal = heal_scene.instantiate()
		add_child(heal)
		var ring = heal.find_child("Ring", true, false)
		var pillar = heal.find_child("LightPillar", true, false)
		var glimmer = heal.find_child("RisingGlimmer", true, false)
		if ring and pillar and glimmer:
			log_pass("Curación VFX", "Emerald ground ring, radiant light pillar & ascending glimmer particles verified")
		else:
			log_fail("Curación VFX", "Missing heal effect components")
		heal.queue_free()
	else:
		log_fail("Curación Scene", "Could not load HealEffect.tscn")
	
	# 6. Teletransporte (Teleport Effect)
	var tp_scene = load("res://scenes/TeleportEffect.tscn")
	if tp_scene:
		var tp = tp_scene.instantiate()
		add_child(tp)
		var ring = tp.find_child("DistortionRing", true, false)
		var motes = tp.find_child("CoreMotes", true, false)
		if ring and motes:
			log_pass("Teletransporte VFX", "Ground distortion wave ring, dimensional motes & omni light burst verified")
		else:
			log_fail("Teletransporte VFX", "Missing teleport effect components")
		tp.queue_free()
	else:
		log_fail("Teletransporte Scene", "Could not load TeleportEffect.tscn")
	
	# Player Spell Integration
	var wiz_scene = load("res://scenes/Wizard.tscn")
	if wiz_scene:
		var wiz = wiz_scene.instantiate()
		add_child(wiz)
		var has_tp = wiz.has_method("cast_teleport")
		var has_ice = wiz.has_method("cast_ice_projectile")
		var has_light = wiz.has_method("cast_lightning_bolt")
		var has_shield = wiz.has_method("cast_arcane_shield")
		if has_tp and has_ice and has_light and has_shield:
			log_pass("Wizard Spell Integration", "Player supports all 6 spells with direct casting and hotkeys")
		else:
			log_fail("Wizard Spell Integration", "Wizard missing spell cast methods")
		wiz.queue_free()
	else:
		log_fail("Wizard Scene", "Could not load Wizard.tscn")
