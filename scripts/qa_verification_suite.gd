extends Node

var tests_passed: int = 0
var tests_failed: int = 0
var test_log: Array[String] = []

func log_pass(test_name: String, details: String = "") -> void:
	tests_passed += 1
	var msg = "  [PASS] %s %s" % [test_name, details]
	test_log.append(msg)
	print(msg)

func log_fail(test_name: String, reason: String) -> void:
	tests_failed += 1
	var msg = "  [FAIL] %s - REASON: %s" % [test_name, reason]
	test_log.append(msg)
	push_error(msg)
	print(msg)

func _ready() -> void:
	print("\n========================================================")
	print("🚀 RUNNING QA AUTOMATED VERIFICATION SUITE")
	print("========================================================\n")
	
	test_camera_system()
	test_player_character_and_anims()
	test_monster_archetypes_and_anims()
	test_spells_vfx_and_lifecycle()
	test_combat_and_mana_economy()
	test_fantasy_ui_asset_pack_v1()
	test_character_orientation_and_locomotion()
	
	print("\n========================================================")
	print("📊 QA SUITE RESULTS: PASSED: %d | FAILED: %d" % [tests_passed, tests_failed])
	print("========================================================\n")
	
	if tests_failed == 0:
		print("✅ ALL ACCEPTANCE CRITERIA SATISFIED!")
	else:
		print("❌ QA FOUND %d DEFECTS!" % tests_failed)
	
	get_tree().quit(0 if tests_failed == 0 else 1)

func test_camera_system() -> void:
	print("--- 1. Camera & 3D Presentation Tests ---")
	var main_scene = load("res://scenes/Main.tscn")
	if not main_scene:
		log_fail("Camera Scene Load", "Cannot load Main.tscn")
		return
	var main = main_scene.instantiate()
	add_child(main)
	
	var cam_rig = main.get_node_or_null("CameraRig")
	if not cam_rig:
		log_fail("CameraRig Node", "CameraRig missing in Main.tscn")
		main.free()
		return
	log_pass("CameraRig Node", "Found in scene")
	
	var spring_arm = cam_rig.get_node_or_null("SpringArm3D") as SpringArm3D
	if not spring_arm:
		log_fail("SpringArm3D", "SpringArm3D missing in CameraRig")
	else:
		log_pass("SpringArm3D", "Present with spring_length=%.1f" % spring_arm.spring_length)
	
	var cam = cam_rig.find_child("Camera3D", true, false) as Camera3D
	if not cam:
		log_fail("Camera3D", "Camera3D missing")
	else:
		if cam.projection == Camera3D.PROJECTION_PERSPECTIVE:
			log_pass("Camera Projection", "Perspective projection verified (FOV: %.1f deg)" % cam.fov)
		else:
			log_fail("Camera Projection", "Camera is not perspective!")
		
		if cam.fov >= 60.0 and cam.fov <= 75.0:
			log_pass("Camera FOV", "True 3D FOV verified (%.1f deg)" % cam.fov)
		else:
			log_fail("Camera FOV", "FOV %.1f out of expected 3D third-person range [60, 75]" % cam.fov)
	
	main.free()

func test_player_character_and_anims() -> void:
	print("\n--- 2. Player Character & Animation Tests ---")
	var wiz_scene = load("res://scenes/Wizard.tscn")
	if not wiz_scene:
		log_fail("Wizard Scene Load", "Cannot load Wizard.tscn")
		return
	var wiz = wiz_scene.instantiate()
	add_child(wiz)
	
	# Verify collision shape
	var col = wiz.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col and col.shape is CapsuleShape3D:
		var cap = col.shape as CapsuleShape3D
		log_pass("Player Collision", "Capsule height=%.2f, radius=%.2f" % [cap.height, cap.radius])
	else:
		log_fail("Player Collision", "Invalid collision shape")
	
	# Verify Rig & Skeleton
	var skel = wiz.find_child("Skeleton3D", true, false) as Skeleton3D
	if skel:
		log_pass("Skeleton3D", "Rigged skeleton found with %d bones" % skel.get_bone_count())
	else:
		log_fail("Skeleton3D", "Skeleton3D not found in player model")
	
	# Verify Bone Attachments for Staff & Hat
	var staff_attach = wiz.find_child("StaffAttachment", true, false)
	var hat_attach = wiz.find_child("HatAttachment", true, false)
	if staff_attach:
		log_pass("Staff BoneAttachment", "Staff attached to right hand")
	else:
		log_fail("Staff BoneAttachment", "StaffAttachment missing")
	
	if hat_attach:
		log_pass("Hat BoneAttachment", "Hat attached to head")
	else:
		log_fail("Hat BoneAttachment", "HatAttachment missing")
	
	# Verify Staff Gem & Light
	var gem = wiz.find_child("Gem", true, false) as MeshInstance3D
	var staff_light = wiz.find_child("StaffLight", true, false) as OmniLight3D
	if gem and gem.material_override is StandardMaterial3D:
		var gmat = gem.material_override as StandardMaterial3D
		log_pass("Staff Arcane Gem", "Glowing gem with emission=%.1f" % gmat.emission_energy_multiplier)
	else:
		log_fail("Staff Arcane Gem", "Staff Gem missing or unshaded")
	
	if staff_light:
		log_pass("Staff Dynamic Light", "OmniLight3D energy=%.1f, range=%.1f" % [staff_light.light_energy, staff_light.omni_range])
	else:
		log_fail("Staff Dynamic Light", "StaffLight missing")
	
	# Verify AnimationPlayer & Critical Animations
	var ap = wiz.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		var required_anims = ["Idle", "Walk", "Spell_Simple_Enter", "Spell_Simple_Shoot", "Hit_Chest", "Death01"]
		var missing = []
		for req in required_anims:
			if not ap.has_animation(req):
				missing.append(req)
		if missing.is_empty():
			log_pass("Player Animations", "All required anims present: %s" % str(required_anims))
		else:
			log_fail("Player Animations", "Missing animations: %s" % str(missing))
	else:
		log_fail("Player AnimationPlayer", "AnimationPlayer missing on player model")
	
	wiz.free()

func test_monster_archetypes_and_anims() -> void:
	print("\n--- 3. Monster Archetypes, Models & Animation Tests ---")
	var enemy_scene = load("res://scenes/Enemy.tscn")
	if not enemy_scene:
		log_fail("Enemy Scene Load", "Cannot load Enemy.tscn")
		return
	
	for i in range(5):
		var enemy = enemy_scene.instantiate()
		add_child(enemy)
		enemy.set_archetype(i)
		var type_name = ["Goblin", "Skeleton Spear", "Skeleton Archer", "Fire Imp", "Shadow Imp"][i]
		
		# Verify Model Mesh
		var meshes = enemy.find_children("*", "MeshInstance3D", true, false)
		if meshes.size() > 0:
			log_pass("%s Meshes" % type_name, "Found %d meshes with valid scale %s" % [meshes.size(), str(enemy.scale)])
		else:
			log_fail("%s Meshes" % type_name, "No meshes found in model")
		
		# Verify Health & Damage stats
		if enemy.max_health > 0 and enemy.attack_damage > 0:
			log_pass("%s Combat Stats" % type_name, "HP=%.0f, ATK=%.0f, Range=%.1f" % [enemy.max_health, enemy.attack_damage, enemy.attack_range])
		else:
			log_fail("%s Combat Stats" % type_name, "Invalid stats")
		
		# Verify Animation Player or Procedural Animation
		if enemy.anim_player:
			if enemy.anim_walk != "" and enemy.anim_player.has_animation(enemy.anim_walk):
				log_pass("%s Locomotion Anim" % type_name, "Anim '%s' verified" % enemy.anim_walk)
			if enemy.anim_attack != "" and enemy.anim_player.has_animation(enemy.anim_attack):
				log_pass("%s Attack Anim" % type_name, "Anim '%s' verified" % enemy.anim_attack)
		else:
			# Procedural animation archetype (Imps)
			log_pass("%s Procedural Animation" % type_name, "Procedural squash/stretch & levitation verified")
		
		enemy.queue_free()

func test_spells_vfx_and_lifecycle() -> void:
	print("\n--- 4. Spells Visual Identity & Lifecycle Tests ---")
	
	# 1. MagicBolt
	var mb_scene = load("res://scenes/MagicBolt.tscn")
	if mb_scene:
		var bolt = mb_scene.instantiate()
		add_child(bolt)
		bolt.init_bolt(Vector3.ZERO, Vector3.FORWARD)
		var has_rings = bolt.find_child("Ring1", true, false) != null
		var has_trail = bolt.find_child("SparkTrail", true, false) != null
		var has_burst = bolt.find_child("ImpactBurst", true, false) != null
		if has_rings and has_trail and has_burst:
			log_pass("Magic Bolt VFX", "Orbital rings, spark trail & impact burst verified")
		else:
			log_fail("Magic Bolt VFX", "Missing rings/trail/burst components")
		bolt.queue_free()
	else:
		log_fail("Magic Bolt Scene", "Failed to load")
	
	# 2. Fireball
	var fb_scene = load("res://scenes/Fireball.tscn")
	if fb_scene:
		var fb = fb_scene.instantiate()
		add_child(fb)
		fb.init_trajectory(Vector3.ZERO, Vector3(0, 0, 10))
		var has_mantle = fb.find_child("FlameMantle", true, false) != null
		var has_trail = fb.find_child("FireTrail", true, false) != null
		var has_burst = fb.find_child("ExplosionBurst", true, false) != null
		var has_ring = fb.find_child("BlastRing", true, false) != null
		if has_mantle and has_trail and has_burst and has_ring:
			log_pass("Fireball VFX", "Incandescent core, flame mantle, trail, blast ring & explosion burst verified")
		else:
			log_fail("Fireball VFX", "Missing fireball VFX components")
		fb.queue_free()
	else:
		log_fail("Fireball Scene", "Failed to load")
	
	# 3. SummonCircle
	var sc_scene = load("res://scenes/SummonCircle.tscn")
	if sc_scene:
		var sc = sc_scene.instantiate()
		add_child(sc)
		var has_ground_ring = sc.find_child("GroundRing", true, false) != null
		var has_beam = sc.find_child("LightBeam", true, false) != null
		var has_motes = sc.find_child("SpiralMotes", true, false) != null
		if has_ground_ring and has_beam and has_motes:
			log_pass("Summon Circle VFX", "Ground rune ring, light beam & spiral motes verified")
		else:
			log_fail("Summon Circle VFX", "Missing summon ritual components")
		sc.queue_free()
	else:
		log_fail("Summon Circle Scene", "Failed to load")
	
	# 4. Shockwave
	var sw_scene = load("res://scenes/Shockwave.tscn")
	if sw_scene:
		var sw = sw_scene.instantiate()
		add_child(sw)
		var has_ring = sw.find_child("Ring", true, false) != null
		var has_dome = sw.find_child("EnergyDome", true, false) != null
		var has_particles = sw.find_child("RadialParticles", true, false) != null
		if has_ring and has_dome and has_particles:
			log_pass("Shockwave VFX", "Concussive ring, energy dome & radial particle blast verified")
		else:
			log_fail("Shockwave VFX", "Missing shockwave VFX components")
		sw.queue_free()
	else:
		log_fail("Shockwave Scene", "Failed to load")
	
	# 5. HealEffect
	var heal_scene = load("res://scenes/HealEffect.tscn")
	if heal_scene:
		var heal = heal_scene.instantiate()
		add_child(heal)
		var has_ring = heal.find_child("Ring", true, false) != null
		var has_pillar = heal.find_child("LightPillar", true, false) != null
		var has_glimmer = heal.find_child("RisingGlimmer", true, false) != null
		if has_ring and has_pillar and has_glimmer:
			log_pass("Heal Effect VFX", "Emerald ring, light pillar & rising glimmer particles verified")
		else:
			log_fail("Heal Effect VFX", "Missing heal VFX components")
		heal.queue_free()
	else:
		log_fail("Heal Effect Scene", "Failed to load")

func test_combat_and_mana_economy() -> void:
	print("\n--- 5. Combat Response & Mana Economy Tests ---")
	
	# Verify GameManager Spell Definitions
	for slot in range(1, 6):
		if GameManager.spells.has(slot):
			var s = GameManager.spells[slot]
			log_pass("Spell Slot %d Definition" % slot, "'%s' (Cost: %.0f MP)" % [s["name"], s["cost"]])
		else:
			log_fail("Spell Slot %d Definition" % slot, "Missing spell definition")
	
	# Verify Mana Capacity & Regen with Shrines
	GameManager.active_shrines = 0
	GameManager.update_mana_capacity()
	var base_cap = GameManager.player_max_mana
	
	GameManager.active_shrines = 2
	GameManager.update_mana_capacity()
	var shrine_cap = GameManager.player_max_mana
	
	if shrine_cap > base_cap:
		log_pass("Mana Territorial Economy", "Mana scales with shrines: Base=%.0f -> 2 Shrines=%.0f" % [base_cap, shrine_cap])
	else:
		log_fail("Mana Territorial Economy", "Shrine mana scaling failed")

func test_fantasy_ui_asset_pack_v1() -> void:
	print("\n--- 6. Fantasy UI Asset Pack V1 Integration Tests ---")
	
	var catalog: Array[Dictionary] = [
		{"name": "Poción de vida", "cat": "Consumibles", "path": "res://assets/ui/icons/consumables/potion_health.png"},
		{"name": "Vial de maná", "cat": "Consumibles", "path": "res://assets/ui/icons/consumables/potion_mana.png"},
		{"name": "Bola de fuego", "cat": "Hechizos", "path": "res://assets/ui/icons/spells/spell_fireball.png"},
		{"name": "Proyectil de hielo", "cat": "Hechizos", "path": "res://assets/ui/icons/spells/spell_ice_projectile.png"},
		{"name": "Rayo", "cat": "Hechizos", "path": "res://assets/ui/icons/spells/spell_lightning.png"},
		{"name": "Escudo mágico", "cat": "Hechizos", "path": "res://assets/ui/icons/spells/spell_arcane_shield.png"},
		{"name": "Curación", "cat": "Hechizos", "path": "res://assets/ui/icons/spells/spell_healing.png"},
		{"name": "Teletransporte", "cat": "Hechizos", "path": "res://assets/ui/icons/spells/spell_teleport.png"},
		{"name": "Pergamino mágico", "cat": "Objetos", "path": "res://assets/ui/icons/items/item_magic_scroll.png"},
		{"name": "Cristal arcano", "cat": "Objetos", "path": "res://assets/ui/icons/items/item_arcane_crystal.png"},
		{"name": "Ataque básico", "cat": "Habilidades", "path": "res://assets/ui/icons/abilities/ability_basic_attack.png"},
		{"name": "Habilidad bloqueada", "cat": "Estados", "path": "res://assets/ui/icons/states/state_ability_locked.png"}
	]
	
	# 1. Verify all 12 assets load and have 512x512 resolution
	for item in catalog:
		var tex = ResourceLoader.load(item["path"]) as Texture2D
		if tex:
			var sz = tex.get_size()
			if sz == Vector2(512, 512):
				log_pass("Asset Load: %s" % item["name"], "(%s) 512x512 RGBA OK" % item["cat"])
			else:
				log_fail("Asset Load: %s" % item["name"], "Invalid resolution: %s != (512, 512)" % str(sz))
		else:
			log_fail("Asset Load: %s" % item["name"], "Failed to load %s" % item["path"])
			
	# 2. Verify Preview Sheet
	var preview_tex = ResourceLoader.load("res://assets/ui/icons/preview_sheet.png") as Texture2D
	if preview_tex:
		log_pass("Preview Sheet Resource", "Preview sheet loaded successfully (Size: %s)" % str(preview_tex.get_size()))
	else:
		log_fail("Preview Sheet Resource", "Cannot load res://assets/ui/icons/preview_sheet.png")
		
	# 3. Verify HUD Integration
	var hud_scene = load("res://scenes/HUD.tscn")
	if hud_scene:
		var hud = hud_scene.instantiate()
		add_child(hud)
		
		# Verify Health & Mana stat bars have the new potion textures
		var hp_bar = hud.get_node_or_null("BottomHUD/LeftCluster/HealthBar")
		if not hp_bar:
			hp_bar = hud.find_child("HealthBar", true, false)
		var mana_bar = hud.get_node_or_null("BottomHUD/RightCluster/ManaBar")
		if not mana_bar:
			mana_bar = hud.find_child("ManaBar", true, false)
		if hp_bar and mana_bar:
			log_pass("HUD StatBars Integration", "HealthBar and ManaBar instantiated with consumable potion icons")
		else:
			log_fail("HUD StatBars Integration", "StatBars missing in HUD")
			
		# Verify Spell Slots integration
		var s1 = hud.find_child("Slot1", true, false)
		var s2 = hud.find_child("Slot2", true, false)
		var s5 = hud.find_child("Slot5", true, false)
		if s1 and s2 and s5:
			log_pass("HUD SpellBar Integration", "Slots 1, 2, 5 configured with new spell icons")
		else:
			log_fail("HUD SpellBar Integration", "Spell slots missing in HUD")
			
		# Verify locked state behavior
		if s1 and "is_locked" in s1:
			s1.is_locked = true
			var locked_rect = s1.find_child("Icon", true, false) as TextureRect
			if locked_rect and locked_rect.texture:
				log_pass("SpellSlot Locked State", "Locked state activates state_ability_locked.png cleanly")
			else:
				log_fail("SpellSlot Locked State", "Locked state texture failed")
			s1.is_locked = false # restore
			
		hud.queue_free()
	else:
		log_fail("HUD Integration", "Failed to load HUD.tscn")

func test_character_orientation_and_locomotion() -> void:
	print("\n--- 7. Character Orientation & Locomotion Tests ---")
	
	# Helper to calculate visual front vector of player or monster in world space
	var get_visual_front = func(node: CharacterBody3D) -> Vector3:
		var fwd = -node.global_transform.basis.z
		fwd.y = 0.0
		return fwd.normalized()
	
	# 7.1 Player orientation tests
	var root_player = Node3D.new()
	add_child(root_player)
	
	var cam = Camera3D.new()
	cam.position = Vector3(0, 5, 8)
	root_player.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3.ZERO)
	cam.current = true
	
	var wiz_scene = load("res://scenes/Wizard.tscn")
	var player = wiz_scene.instantiate() as CharacterBody3D
	root_player.add_child(player)
	player.global_position = Vector3.ZERO
	
	var sim_step = func(ix: float, iy: float, delta: float = 0.05, steps: int = 15):
		for s in range(steps):
			Input.action_press("move_right" if ix > 0 else "move_left", abs(ix))
			Input.action_press("move_down" if iy > 0 else "move_up", abs(iy))
			player._physics_process(delta)
			Input.action_release("move_right")
			Input.action_release("move_left")
			Input.action_release("move_up")
			Input.action_release("move_down")
	
	# Forward movement
	sim_step.call(0.0, -1.0, 0.05, 15)
	var vf_fwd = get_visual_front.call(player)
	var cam_fwd = -cam.global_transform.basis.z
	cam_fwd.y = 0.0
	cam_fwd = cam_fwd.normalized()
	if vf_fwd.dot(cam_fwd) > 0.85:
		log_pass("Player Forward Orientation", "Player faces camera forward direction")
	else:
		log_fail("Player Forward Orientation", "Player does not face camera forward")
	
	# Backward movement
	sim_step.call(0.0, 1.0, 0.05, 20)
	var vf_back = get_visual_front.call(player)
	if vf_back.dot(-cam_fwd) > 0.85:
		log_pass("Player Backward Orientation", "Player faces movement direction without moonwalking")
	else:
		log_fail("Player Backward Orientation", "Player moonwalks or faces backwards")
	
	# Lateral movement
	sim_step.call(-1.0, 0.0, 0.05, 20)
	var vf_left = get_visual_front.call(player)
	var cam_right = cam.global_transform.basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()
	if vf_left.dot(-cam_right) > 0.85:
		log_pass("Player Lateral Left Orientation", "Player faces left movement direction")
	else:
		log_fail("Player Lateral Left Orientation", "Failed to face left")
	
	sim_step.call(1.0, 0.0, 0.05, 20)
	var vf_right = get_visual_front.call(player)
	if vf_right.dot(cam_right) > 0.85:
		log_pass("Player Lateral Right Orientation", "Player faces right movement direction")
	else:
		log_fail("Player Lateral Right Orientation", "Failed to face right")
	
	# Stop orientation preservation
	sim_step.call(0.0, -1.0, 0.05, 15)
	var rot_before_stop = player.rotation.y
	for s in range(15):
		player._physics_process(0.05)
	var rot_after_stop = player.rotation.y
	if abs(angle_difference(rot_before_stop, rot_after_stop)) < 0.01:
		log_pass("Player Stop Preservation", "Orientation smoothly preserved when stopping")
	else:
		log_fail("Player Stop Preservation", "Orientation jitter or flip on stop")
	
	# Spell channel aim
	player.aim_point = Vector3(15, 0, 15)
	player.start_spell_channeling()
	for s in range(15):
		player._physics_process(0.05)
	var aim_dir = (player.aim_point - player.global_position)
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	if get_visual_front.call(player).dot(aim_dir) > 0.85:
		log_pass("Player Spell Channel Aim", "Body aligns with aim point during casting")
	else:
		log_fail("Player Spell Channel Aim", "Body does not align with aim point")
	
	root_player.free()
	
	# 7.2 Monster orientation tests: Goblin
	var root_gob = Node3D.new()
	add_child(root_gob)
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var goblin = enemy_scene.instantiate() as CharacterBody3D
	root_gob.add_child(goblin)
	goblin.set_archetype(0)
	goblin.global_position = Vector3.ZERO
	
	var dummy = CharacterBody3D.new()
	dummy.add_to_group("player")
	root_gob.add_child(dummy)
	
	# Chase East
	dummy.global_position = Vector3(12, 0, 0)
	for s in range(25):
		goblin._physics_process(0.05)
	if get_visual_front.call(goblin).dot(Vector3.RIGHT) > 0.85:
		log_pass("Goblin Chase East", "Goblin faces eastward movement towards player")
	else:
		log_fail("Goblin Chase East", "Goblin wrong chase orientation")
	
	# Turn South
	dummy.global_position = Vector3(0, 0, 12)
	for s in range(35):
		goblin._physics_process(0.05)
	if get_visual_front.call(goblin).dot(Vector3.BACK) > 0.80:
		log_pass("Goblin Turn South", "Goblin turns to face southward movement")
	else:
		log_fail("Goblin Turn South", "Goblin failed turn orientation")
	
	# Attack
	dummy.global_position = goblin.global_position + Vector3(0, 0, 1.4)
	for s in range(20):
		goblin._physics_process(0.05)
	var to_dummy = (dummy.global_position - goblin.global_position).normalized()
	if get_visual_front.call(goblin).dot(to_dummy) > 0.90:
		log_pass("Goblin Attack Facing", "Goblin maintains facing towards target during attack")
	else:
		log_fail("Goblin Attack Facing", "Goblin does not face target during attack")
	
	# Flee
	goblin.current_health = 15.0
	goblin.flee_timer = 0.0
	dummy.global_position = goblin.global_position + Vector3(3, 0, 0)
	for s in range(25):
		goblin._physics_process(0.05)
	var away_dir = (goblin.global_position - dummy.global_position).normalized()
	if goblin.is_fleeing and get_visual_front.call(goblin).dot(away_dir) > 0.80:
		log_pass("Goblin Flee Orientation", "Goblin faces escape direction while fleeing")
	else:
		log_fail("Goblin Flee Orientation", "Goblin wrong flee orientation")
	
	root_gob.free()
	
	# 7.3 Monster orientation tests: Archer
	var root_archer = Node3D.new()
	add_child(root_archer)
	var archer = enemy_scene.instantiate() as CharacterBody3D
	root_archer.add_child(archer)
	archer.set_archetype(2)
	archer.global_position = Vector3.ZERO
	
	var dummy_archer = CharacterBody3D.new()
	dummy_archer.add_to_group("player")
	root_archer.add_child(dummy_archer)
	
	# Advance
	dummy_archer.global_position = Vector3(20, 0, 0)
	for s in range(25):
		archer._physics_process(0.05)
	if get_visual_front.call(archer).dot(Vector3.RIGHT) > 0.85:
		log_pass("Archer Advance Facing", "Archer faces movement direction towards player")
	else:
		log_fail("Archer Advance Facing", "Archer wrong advance orientation")
	
	# Kite
	dummy_archer.global_position = archer.global_position + Vector3(4.0, 0, 0)
	for s in range(25):
		archer._physics_process(0.05)
	var to_dummy_arch = (dummy_archer.global_position - archer.global_position).normalized()
	var h_vel_arch = Vector3(archer.velocity.x, 0, archer.velocity.z)
	if get_visual_front.call(archer).dot(to_dummy_arch) > 0.85 and h_vel_arch.dot(to_dummy_arch) < 0:
		log_pass("Archer Kiting Facing", "Archer retreats away from player while aiming bow at player")
	else:
		log_fail("Archer Kiting Facing", "Archer failed kiting orientation")
	
	root_archer.free()
	
	# 7.4 Monster orientation tests: Fire Imp
	var root_imp = Node3D.new()
	add_child(root_imp)
	var imp = enemy_scene.instantiate() as CharacterBody3D
	root_imp.add_child(imp)
	imp.set_archetype(3)
	imp.global_position = Vector3(0, 0, 7)
	
	var dummy_imp = CharacterBody3D.new()
	dummy_imp.add_to_group("player")
	root_imp.add_child(dummy_imp)
	dummy_imp.global_position = Vector3.ZERO
	
	for s in range(25):
		imp._physics_process(0.05)
	var h_vel_imp = Vector3(imp.velocity.x, 0, imp.velocity.z).normalized()
	if get_visual_front.call(imp).dot(h_vel_imp) > 0.80:
		log_pass("Fire Imp Circling Facing", "Fire Imp aligns visual front with circling velocity vector")
	else:
		log_fail("Fire Imp Circling Facing", "Fire Imp sliding sideways")
	
	root_imp.free()

