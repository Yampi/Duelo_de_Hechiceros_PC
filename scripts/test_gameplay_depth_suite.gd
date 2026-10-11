extends Node

const ItemDB = preload("res://scripts/inventory/item_db.gd")
const InventoryManager = preload("res://scripts/inventory/inventory_manager.gd")
const MapConfig = preload("res://scripts/map_config.gd")
const EncounterManager = preload("res://scripts/encounter_manager.gd")

var total_passed: int = 0
var total_failed: int = 0

func _ready() -> void:
	print("\n========================================================")
	print("🛡️ AUTOMATED TEST SUITE: GAMEPLAY DEPTH & ENEMY AI")
	print("========================================================\n")
	
	_test_speed_differential_and_escapability()
	await _test_perception_and_spatial_detection()
	await _test_leash_boundary_and_territory_return()
	await _test_attack_windup_and_interruption()
	_test_separation_and_anti_overlap()
	await _test_empowered_magic_bolt_depth()
	_test_zone1_peaceful_road_exploration()
	_test_encounter_density_and_respawn_cooldowns()
	_test_portal_exploration_victory_integration()
	_test_ice_projectile_chill_mechanic()
	_test_boss_earthquake_and_vulnerability_window()
	_test_3d_terrain_elevation_profile()
	
	print("\n========================================================")
	print("📊 GAMEPLAY DEPTH RESULTS: PASSED: %d | FAILED: %d" % [total_passed, total_failed])
	print("========================================================")
	
	if total_failed == 0:
		print("✅ ALL GAMEPLAY DEPTH ACCEPTANCE CRITERIA SATISFIED!\n")
	else:
		print("❌ SOME GAMEPLAY DEPTH TESTS FAILED!\n")
	
	get_tree().quit(0 if total_failed == 0 else 1)

func assert_test(condition: bool, test_name: String, details: String = "") -> void:
	if condition:
		total_passed += 1
		print("  [PASS] %s %s" % [test_name, ("(" + details + ")") if not details.is_empty() else ""])
	else:
		total_failed += 1
		print("  [FAIL] %s %s" % [test_name, ("(" + details + ")") if not details.is_empty() else ""])

# 1. Test Player vs Enemy Movement Speeds
func _test_speed_differential_and_escapability() -> void:
	print("--- 1. Speed Differential & Deliberate Escape Tests ---")
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var player_speed = 7.5 # Player standard movement speed
	
	var archetypes = [
		{"type": 0, "name": "Goblin Scout", "expected_max_chase": 4.5},
		{"type": 1, "name": "Skeleton Spear", "expected_max_chase": 4.0},
		{"type": 2, "name": "Skeleton Archer", "expected_max_chase": 3.8},
		{"type": 3, "name": "Fire Imp", "expected_max_chase": 4.8},
		{"type": 4, "name": "Shadow Imp", "expected_max_chase": 5.0}
	]
	
	for arch in archetypes:
		var enemy = enemy_scene.instantiate()
		add_child(enemy)
		enemy.set_archetype(arch["type"])
		
		var chase_speed = enemy.move_speed
		var speed_diff = player_speed - chase_speed
		assert_test(chase_speed <= arch["expected_max_chase"],
			"%s Chase Speed Tuned Below Player" % arch["name"],
			"Speed: %.1f m/s (Limit: %.1f m/s)" % [chase_speed, arch["expected_max_chase"]])
		assert_test(speed_diff >= 2.5,
			"%s Allows Player Escape Margin (>= 2.5 m/s)" % arch["name"],
			"Delta: +%.1f m/s" % speed_diff)
		
		enemy.queue_free()

# 2. Test Spatial Perception vs Global Detection
func _test_perception_and_spatial_detection() -> void:
	print("\n--- 2. Enemy Spatial Perception & Detection Radius Tests ---")
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var dummy_player = Node3D.new()
	dummy_player.name = "Player"
	dummy_player.add_to_group("player")
	add_child(dummy_player)
	dummy_player.global_position = Vector3(0, 0, 0)
	
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.set_archetype(0) # Goblin (detection_radius = 16.0)
	enemy.home_position = Vector3(0, 0, 35.0)
	enemy.global_position = Vector3(0, 0, 35.0)
	enemy.current_state = enemy.AIState.IDLE
	
	# Far player: 35m > 16m radius
	var detected_far = enemy.detect_player()
	assert_test(detected_far == null, "Enemy Ignores Player Beyond Detection Radius (Dist: 35m > 16m)")
	assert_test(enemy.current_state == enemy.AIState.IDLE, "Enemy Remains in IDLE State")
	
	# Close player: 12m < 16m radius
	dummy_player.global_position = Vector3(0, 0, 23.0)
	var detected_close = enemy.detect_player()
	assert_test(detected_close == dummy_player, "Enemy Detects Player Within Perception Radius (Dist: 12m < 16m)")
	
	# Process state change
	enemy.target_ref = detected_close
	enemy.transition_to_state(enemy.AIState.ALERT, 0.35)
	assert_test(enemy.current_state == enemy.AIState.ALERT,
		"Enemy Transitions to ALERT State on Detection", "State: %d" % enemy.current_state)
	
	enemy.queue_free()
	dummy_player.queue_free()

# 3. Test Leash Boundary, Target Loss, SEARCH and RETURN to Territory
func _test_leash_boundary_and_territory_return() -> void:
	print("\n--- 3. Leash Boundary, Target Loss & Return to Territory Tests ---")
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var dummy_player = Node3D.new()
	dummy_player.name = "Player"
	dummy_player.add_to_group("player")
	add_child(dummy_player)
	
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.set_archetype(0) # Goblin
	var home = Vector3(10, 0, 20)
	enemy.home_position = home
	enemy.global_position = home + Vector3(0, 0, 2)
	enemy.target_ref = dummy_player
	enemy.current_state = enemy.AIState.CHASE
	enemy.chase_timer = 10.0
	
	# Case A: Player flees beyond lose_target_distance (22m)
	dummy_player.global_position = enemy.global_position + Vector3(0, 0, 28.0)
	enemy._physics_process(0.1)
	assert_test(enemy.current_state == enemy.AIState.SEARCH,
		"Target Loss Exceeding Distance Transitions to SEARCH State",
		"Target dist: 28m > 22m")
	
	# Case B: Search timer expires -> Transitions to RETURN
	enemy.state_timer = 0.0
	enemy._physics_process(0.1)
	assert_test(enemy.current_state == enemy.AIState.RETURN,
		"Search Timeout Transitions to RETURN State")
	
	# Case C: Arriving at home position -> Transitions to RECOVER
	enemy.global_position = home + Vector3(0.5, 0, 0.5)
	enemy._physics_process(0.1)
	assert_test(enemy.current_state == enemy.AIState.RECOVER,
		"Arriving at Home Territory Transitions to RECOVER State")
	
	# Case D: Leash limit check (enemy pulled beyond max_leash_distance 24m)
	enemy.global_position = home + Vector3(0, 0, 28.0) # > 24m
	enemy.target_ref = dummy_player
	enemy.current_state = enemy.AIState.CHASE
	dummy_player.global_position = enemy.global_position + Vector3(0, 0, 2.0)
	enemy._physics_process(0.1)
	assert_test(enemy.current_state == enemy.AIState.RETURN,
		"Exceeding Max Leash Boundary Immediately Forces RETURN to Territory",
		"Dist from home: 28m > 24m")
	
	enemy.queue_free()
	dummy_player.queue_free()

# 4. Test Attack Windup & Heavy Damage Interruption
func _test_attack_windup_and_interruption() -> void:
	print("\n--- 4. Attack Windup & Telegraph Interruption Tests ---")
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.set_archetype(1) # Skeleton Spear
	
	# Verify telegraph windup is configured
	assert_test(enemy.attack_windup >= 0.3,
		"Enemy Attack Features Readable Telegraph Windup (>= 0.3s)",
		"Windup: %.2fs" % enemy.attack_windup)
	
	# Simulate entering attack windup
	enemy.is_winding_up_attack = true
	
	# Player hits enemy with heavy attack (empowered spell / high damage)
	var initial_hp = enemy.current_health
	enemy.take_damage(25.0, Vector3(0, 0, -4.0))
	
	assert_test(enemy.current_health < initial_hp, "Enemy Took Combat Damage")
	assert_test(not enemy.is_winding_up_attack,
		"Heavy Damage Interrupts Enemy Attack Windup",
		"is_winding_up_attack: %s" % enemy.is_winding_up_attack)
	assert_test(enemy.current_state == enemy.AIState.RECOVER,
		"Interrupted Attack Forces RECOVER Stun Window")
	
	enemy.queue_free()

# 5. Test Personal Space Separation Between Enemies
func _test_separation_and_anti_overlap() -> void:
	print("\n--- 5. Enemy Separation & Anti-Overlap Repulsion Tests ---")
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var e1 = enemy_scene.instantiate()
	var e2 = enemy_scene.instantiate()
	add_child(e1)
	add_child(e2)
	e1.add_to_group("enemy")
	e2.add_to_group("enemy")
	
	e1.global_position = Vector3(0, 0, 0)
	e2.global_position = Vector3(0.5, 0, 0) # Crowded within 0.5m
	
	var sep1 = e1.get_separation_force()
	var sep2 = e2.get_separation_force()
	
	assert_test(sep1.length() > 0.0, "Enemy 1 Applies Repulsion Force Away from Neighbor")
	assert_test(sep2.length() > 0.0, "Enemy 2 Applies Repulsion Force Away from Neighbor")
	assert_test(sep1.dot(sep2) < 0.0,
		"Repulsion Forces Point in Opposite Directions (Separating)")
	
	e1.queue_free()
	e2.queue_free()

# 6. Test Empowered Magic Bolt (Centella Sobrecargada) Visual & Mechanics
func _test_empowered_magic_bolt_depth() -> void:
	print("\n--- 6. Centella Sobrecargada Visual & Area Mechanics Tests ---")
	var bolt_scene = load("res://scenes/MagicBolt.tscn")
	var enemy_scene = load("res://scenes/Enemy.tscn")
	
	# Create primary and secondary enemies
	var primary_target = enemy_scene.instantiate()
	var secondary_target = enemy_scene.instantiate()
	add_child(primary_target)
	add_child(secondary_target)
	primary_target.add_to_group("enemy")
	secondary_target.add_to_group("enemy")
	primary_target.set_archetype(0)
	secondary_target.set_archetype(0)
	
	primary_target.global_position = Vector3(0, 0, 10)
	secondary_target.global_position = Vector3(1.6, 0, 10) # 1.6m away (within 2.8m splash)
	
	var standard_bolt = bolt_scene.instantiate()
	add_child(standard_bolt)
	assert_test(not standard_bolt.is_empowered, "Standard Bolt is Not Empowered")
	assert_test(standard_bolt.damage == 25.0, "Standard Bolt Damage is 25.0")
	assert_test(standard_bolt.area_damage_radius == 0.0, "Standard Bolt Has No Area Splash")
	standard_bolt.queue_free()
	
	var empowered_bolt = bolt_scene.instantiate()
	add_child(empowered_bolt)
	empowered_bolt.set_empowered(true)
	empowered_bolt.global_position = primary_target.global_position
	
	assert_test(empowered_bolt.is_empowered, "Centella Sobrecargada Confirms is_empowered Flag")
	assert_test(empowered_bolt.damage == 42.0,
		"Centella Sobrecargada Deals 42.0 Direct Damage (+68%)",
		"Damage: %.1f" % empowered_bolt.damage)
	assert_test(empowered_bolt.area_damage_radius == 2.8,
		"Centella Sobrecargada Has 2.8m Area Blast Radius",
		"Radius: %.1fm" % empowered_bolt.area_damage_radius)
	assert_test(empowered_bolt.knockback_force == 12.0,
		"Centella Sobrecargada Knocks Back with 12.0 Impulse",
		"Knockback: %.1f" % empowered_bolt.knockback_force)
	
	# Impact collision with primary target
	var p_initial_hp = primary_target.current_health
	var s_initial_hp = secondary_target.current_health
	
	empowered_bolt._on_area_3d_body_entered(primary_target)
	
	assert_test(primary_target.current_health == p_initial_hp - 42.0,
		"Primary Target Took 42.0 Direct Damage",
		"HP: %.1f -> %.1f" % [p_initial_hp, primary_target.current_health])
	assert_test(secondary_target.current_health < s_initial_hp,
		"Secondary Target within 2.8m Suffered Area Splash Damage",
		"HP: %.1f -> %.1f" % [s_initial_hp, secondary_target.current_health])
	
	primary_target.queue_free()
	secondary_target.queue_free()

# 7. Test Zone 1 Paved Road Safe Passage
func _test_zone1_peaceful_road_exploration() -> void:
	print("\n--- 7. Zone 1 Peaceful Road Exploration Tests ---")
	var enc_mgr = EncounterManager.new()
	add_child(enc_mgr)
	
	# Check Zone 1 scout positions
	var z1_encounters = []
	for enc in enc_mgr.encounters:
		if enc["zone"] == 1:
			z1_encounters.append(enc)
	
	assert_test(z1_encounters.size() >= 2, "Zone 1 Has Planned Peripheral Encounters", "Count: %d" % z1_encounters.size())
	
	# Check off-road placement: scouts must be located >= 20m away from central road (X=0)
	for enc in z1_encounters:
		var x_dist = abs(enc["pos"].x)
		assert_test(x_dist >= 20.0,
			"Zone 1 Encounter Placed Off-Road (%s)" % enc["id"],
			"X Offset: %.1fm (Safe Road Perimeter >= 20m)" % x_dist)
	
	enc_mgr.queue_free()

# 8. Test Encounter Density Ceiling & Respawn Cooldown
func _test_encounter_density_and_respawn_cooldowns() -> void:
	print("\n--- 8. Density Control & Respawn Pacing Tests ---")
	var enc_mgr = EncounterManager.new()
	add_child(enc_mgr)
	
	assert_test(enc_mgr.MAX_ACTIVE_ENEMIES == 10, "Global Active Enemies Capped at 10")
	assert_test(enc_mgr.MAX_LOCAL_ENEMIES_NEARBY == 3,
		"Local Density Capped at 3 Nearby Enemies (Prevents Dogpiling)")
	assert_test(enc_mgr.ENCOUNTER_RESPAWN_COOLDOWN >= 120.0,
		"Encounter Respawn Cooldown Set to >= 120s (Paced Exploration)",
		"Cooldown: %.1fs" % enc_mgr.ENCOUNTER_RESPAWN_COOLDOWN)
	
	enc_mgr.queue_free()

# 9. Test Portal Victory Integration in Exploration Mode
func _test_portal_exploration_victory_integration() -> void:
	print("\n--- 9. Portal Victory Integration in Exploration Mode ---")
	var portal_scene = load("res://scenes/Portal.tscn")
	var portal = portal_scene.instantiate()
	add_child(portal)
	
	assert_test(not portal.is_active, "Portal Starts Sealed in World")
	portal.update_state(true)
	assert_test(portal.is_active, "Portal Successfully Activates When Boss Defeated")
	
	var dummy_player = Node3D.new()
	dummy_player.name = "Player"
	dummy_player.add_to_group("player")
	add_child(dummy_player)
	
	var signal_data = {"emitted": false}
	portal.level_completed.connect(func(): signal_data["emitted"] = true)
	
	portal._on_body_entered(dummy_player)
	assert_test(signal_data["emitted"], "Player Entering Portal Emits level_completed Signal")
	assert_test(GameManager.level_cleared, "GameManager Records Level Victory")
	
	dummy_player.queue_free()
	portal.queue_free()

# 10. Test Ice Projectile Chill & Crowd Control
func _test_ice_projectile_chill_mechanic() -> void:
	print("\n--- 10. Ice Spell CC & Chill Slowdown Tests ---")
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.set_archetype(0) # Goblin
	
	var base_speed = enemy.move_speed
	assert_test(enemy.chill_timer == 0.0, "Enemy Starts Unchilled")
	assert_test(enemy.get_effective_move_speed() == base_speed, "Normal Speed Active")
	
	# Apply chill slow (0.45 slow => factor 0.55)
	enemy.apply_chill(0.45, 4.0)
	assert_test(enemy.chill_timer > 3.0, "Chill Timer Active (Duration: 4.0s)")
	var chilled_speed = enemy.get_effective_move_speed()
	assert_test(chilled_speed < base_speed * 0.60,
		"Effective Move Speed Reduced by ~45%",
		"Base: %.1f -> Chilled: %.1f m/s" % [base_speed, chilled_speed])
	
	# Simulate expiration
	enemy.chill_timer = 0.0
	assert_test(enemy.get_effective_move_speed() == base_speed, "Movement Speed Recovers Upon Chill Expiration")
	
	enemy.queue_free()

# 11. Test Boss Telegraph & Vulnerability Response Window
func _test_boss_earthquake_and_vulnerability_window() -> void:
	print("\n--- 11. Boss Telegraph & Vulnerability Window Tests ---")
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var boss = enemy_scene.instantiate()
	add_child(boss)
	boss.is_boss = true
	boss.set_archetype(1) # Boss based on spear/guardian
	
	# Boss starts without vulnerability
	assert_test(boss.slam_recover_timer == 0.0, "Boss Starts Outside Vulnerability Window")
	
	# Standard hit
	var hp_before = boss.current_health
	boss.take_damage(20.0)
	var standard_damage_taken = hp_before - boss.current_health
	assert_test(standard_damage_taken == 20.0, "Boss Takes Standard Damage (20.0)")
	
	# Trigger earthquake slam -> sets recovery/vulnerability window
	boss._execute_boss_earthquake()
	assert_test(boss.slam_recover_timer == 2.0, "Earthquake Opens 2.0s Vulnerability Window")
	
	# Hit during vulnerability window (+50% damage)
	var hp_vulnerable = boss.current_health
	boss.take_damage(20.0)
	var bonus_damage_taken = hp_vulnerable - boss.current_health
	assert_test(bonus_damage_taken == 30.0,
		"Damage Amplified by +50% During Vulnerability Window",
		"Dealt: %.1f (Expected: 30.0)" % bonus_damage_taken)
	
	boss.queue_free()

# 12. Test 3D Terrain Elevation Profile Across All Zones
func _test_3d_terrain_elevation_profile() -> void:
	print("\n--- 12. Continuous 3D Topography Elevation Tests ---")
	# Zone 1 (Pradera): gentle rolling heights (0.0 to 1.5m)
	var z1_h = MapConfig.get_height_at(0.0, 96.0)
	assert_test(z1_h >= 0.0 and z1_h <= 1.5,
		"Zone 1 Meadow Has Gentle Rolling Ground",
		"Elevation: %.2fm at Z=96m" % z1_h)
	
	# Zone 2 (Bosque Exterior): gradual rising ground
	var z2_h = MapConfig.get_height_at(0.0, 32.0)
	assert_test(z2_h > z1_h,
		"Zone 2 Gradually Ascends Relative to Zone 1 Meadow",
		"Elevation: %.2fm at Z=32m" % z2_h)
	
	# Zone 2 Secret Glade elevated
	var glade_h = MapConfig.get_height_at(38.0, 32.0)
	assert_test(glade_h >= 3.0,
		"Zone 2 Secret Glade Features Distinct Elevated Clearing",
		"Elevation: %.2fm at (38, 32)" % glade_h)
	
	# Zone 3 (Corazón del Bosque): gorge depression with road bridge
	var bridge_h = MapConfig.get_height_at(0.0, -28.0)
	var gorge_floor_h = MapConfig.get_height_at(16.0, -28.0)
	assert_test(gorge_floor_h < bridge_h - 1.5,
		"Zone 3 Features Natural Ravine Gorge Flanking the Road Bridge",
		"Bridge: %.2fm vs Gorge Floor: %.2fm (Delta: -%.2fm)" % [bridge_h, gorge_floor_h, bridge_h - gorge_floor_h])
	
	# Zone 4 (Ruinas Arcanas): elevated plateau
	var z4_h = MapConfig.get_height_at(0.0, -96.0)
	assert_test(z4_h >= 5.5,
		"Zone 4 Arcane Plateau Rises to Dominant Elevation (>= 5.5m)",
		"Elevation: %.2fm at Z=-96m" % z4_h)
	
	# Perimeter natural mountain walls
	var wall_east_h = MapConfig.get_height_at(118.0, 0.0)
	var wall_north_h = MapConfig.get_height_at(0.0, -124.0)
	assert_test(wall_east_h >= 10.0 and wall_north_h >= 10.0,
		"World Perimeter Natural Mountain Walls Enclose the Arena (>= 10.0m)",
		"East: %.1fm, North: %.1fm" % [wall_east_h, wall_north_h])

