extends Node

var passed_count: int = 0
var failed_count: int = 0

func log_pass(name: String, details: String = ""):
	passed_count += 1
	print("  [PASS] %s %s" % [name, details])

func log_fail(name: String, reason: String):
	failed_count += 1
	print("  [FAIL] %s - REASON: %s" % [name, reason])
	push_error("[FAIL] %s: %s" % [name, reason])

func _ready():
	print("\n========================================================")
	print("🧙 ORIENTATION & LOCOMOTION ACCEPTANCE TEST SUITE")
	print("========================================================\n")
	
	test_player_locomotion()
	test_monster_goblin_locomotion()
	test_monster_archer_locomotion()
	test_monster_imp_circling()
	
	print("\n========================================================")
	print("📊 RESULTS: PASSED: %d | FAILED: %d" % [passed_count, failed_count])
	print("========================================================\n")
	
	if failed_count == 0:
		print("✅ ALL ORIENTATION AND LOCOMOTION ACCEPTANCE CRITERIA MET!")
	else:
		print("❌ VERIFICATION FAILED WITH %d ERRORS" % failed_count)
	
	get_tree().quit(0 if failed_count == 0 else 1)

# Helper to calculate visual front vector of player or monster in world space
func get_visual_front(node: CharacterBody3D) -> Vector3:
	var fwd = -node.global_transform.basis.z
	fwd.y = 0.0
	return fwd.normalized()

func test_player_locomotion():
	print("--- SECTION 1: PLAYER ORIENTATION & LOCOMOTION ---")
	
	var root = Node3D.new()
	add_child(root)
	
	var cam = Camera3D.new()
	cam.position = Vector3(0, 5, 8)
	root.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3.ZERO)
	cam.current = true
	
	var wiz_scene = load("res://scenes/Wizard.tscn")
	var player = wiz_scene.instantiate() as CharacterBody3D
	root.add_child(player)
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

	# 1. Forward movement (W)
	sim_step.call(0.0, -1.0, 0.05, 15)
	var vf_forward = get_visual_front(player)
	var cam_fwd = -cam.global_transform.basis.z
	cam_fwd.y = 0.0
	cam_fwd = cam_fwd.normalized()
	var dot_fwd = vf_forward.dot(cam_fwd)
	if dot_fwd > 0.85:
		log_pass("Player Forward (W)", "Faces forward with camera (dot=%.2f, vf=%s)" % [dot_fwd, vf_forward])
	else:
		log_fail("Player Forward (W)", "Does not face forward (dot=%.2f, vf=%s, cam_fwd=%s)" % [dot_fwd, vf_forward, cam_fwd])

	# 2. Backward movement (S) - MUST NOT WALK BACKWARDS / MOONWALK
	sim_step.call(0.0, 1.0, 0.05, 20)
	var vf_back = get_visual_front(player)
	var expected_back = -cam_fwd
	var dot_back = vf_back.dot(expected_back)
	if dot_back > 0.85:
		log_pass("Player Backward (S)", "Faces movement direction, no moonwalk (dot=%.2f, vf=%s)" % [dot_back, vf_back])
	else:
		log_fail("Player Backward (S)", "Does not face movement direction (dot=%.2f, vf=%s)" % [dot_back, vf_back])

	# 3. Lateral movement (A and D)
	sim_step.call(-1.0, 0.0, 0.05, 20)
	var vf_left = get_visual_front(player)
	var cam_right = cam.global_transform.basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()
	var dot_left = vf_left.dot(-cam_right)
	if dot_left > 0.85:
		log_pass("Player Lateral Left (A)", "Faces left movement direction (dot=%.2f)" % dot_left)
	else:
		log_fail("Player Lateral Left (A)", "Failed to face left (dot=%.2f, vf=%s)" % [dot_left, vf_left])

	sim_step.call(1.0, 0.0, 0.05, 20)
	var vf_right = get_visual_front(player)
	var dot_right = vf_right.dot(cam_right)
	if dot_right > 0.85:
		log_pass("Player Lateral Right (D)", "Faces right movement direction (dot=%.2f)" % dot_right)
	else:
		log_fail("Player Lateral Right (D)", "Failed to face right (dot=%.2f, vf=%s)" % [dot_right, vf_right])

	# 4. Turn in various directions and stop: preserve orientation
	sim_step.call(0.0, -1.0, 0.05, 15)
	var rot_before_stop = player.rotation.y
	for s in range(15):
		player._physics_process(0.05)
	var rot_after_stop = player.rotation.y
	var diff_rot = abs(angle_difference(rot_before_stop, rot_after_stop))
	if diff_rot < 0.01:
		log_pass("Player Stop (Preserve Orientation)", "Orientation preserved on stop (diff=%.4f rad)" % diff_rot)
	else:
		log_fail("Player Stop (Preserve Orientation)", "Jitter or snap on stop (diff=%.4f rad)" % diff_rot)

	# 5. Move while changing camera angle
	cam.position = Vector3(8, 5, 0)
	cam.look_at_from_position(cam.position, Vector3.ZERO)
	sim_step.call(0.0, -1.0, 0.05, 20)
	var new_cam_fwd = -cam.global_transform.basis.z
	new_cam_fwd.y = 0.0
	new_cam_fwd = new_cam_fwd.normalized()
	var vf_cam_turn = get_visual_front(player)
	var dot_cam_turn = vf_cam_turn.dot(new_cam_fwd)
	if dot_cam_turn > 0.85:
		log_pass("Player Camera Orbit Tracking", "Movement & body orientation adapt to camera orbit (dot=%.2f)" % dot_cam_turn)
	else:
		log_fail("Player Camera Orbit Tracking", "Did not adapt to camera orbit (dot=%.2f)" % dot_cam_turn)

	# 6. Spell aiming and casting
	player.aim_point = Vector3(15, 0, 15)
	player.start_spell_channeling()
	for s in range(15):
		player._physics_process(0.05)
	var aim_dir = (player.aim_point - player.global_position)
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	var vf_aim = get_visual_front(player)
	var dot_aim = vf_aim.dot(aim_dir)
	if dot_aim > 0.85:
		log_pass("Player Spell Channel Aiming", "Body faces aim target during spell channel (dot=%.2f)" % dot_aim)
	else:
		log_fail("Player Spell Channel Aiming", "Body did not face aim target (dot=%.2f)" % dot_aim)
	
	root.free()

func test_monster_goblin_locomotion():
	print("\n--- SECTION 2: MONSTER 1 (GOBLIN) ORIENTATION & BEHAVIORS ---")
	var root = Node3D.new()
	add_child(root)
	
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var goblin = enemy_scene.instantiate() as CharacterBody3D
	root.add_child(goblin)
	goblin.set_archetype(0) # GOBLIN
	goblin.global_position = Vector3.ZERO
	
	# Target dummy
	var dummy = CharacterBody3D.new()
	dummy.add_to_group("player")
	root.add_child(dummy)
	
	# 1. Chase target at (+12, 0, 0)
	dummy.global_position = Vector3(12, 0, 0)
	for s in range(25):
		goblin._physics_process(0.05)
	var vf_chase1 = get_visual_front(goblin)
	var dot_chase1 = vf_chase1.dot(Vector3.RIGHT)
	if dot_chase1 > 0.85:
		log_pass("Goblin Chase East (+X)", "Faces eastward movement direction towards target (dot=%.2f)" % dot_chase1)
	else:
		log_fail("Goblin Chase East (+X)", "Wrong orientation (dot=%.2f, vf=%s)" % [dot_chase1, vf_chase1])

	# 2. Change direction: target moves to (0, 0, 12)
	dummy.global_position = Vector3(0, 0, 12)
	for s in range(35):
		goblin._physics_process(0.05)
	var vf_chase2 = get_visual_front(goblin)
	var dot_chase2 = vf_chase2.dot(Vector3.BACK)
	if dot_chase2 > 0.80:
		log_pass("Goblin Turn & Chase South (+Z)", "Dynamically turned to face southward movement (dot=%.2f)" % dot_chase2)
	else:
		log_fail("Goblin Turn & Chase South (+Z)", "Failed to turn south (dot=%.2f, vf=%s)" % [dot_chase2, vf_chase2])

	# 3. Arrive at attack range and attack
	dummy.global_position = goblin.global_position + Vector3(0, 0, 1.4)
	for s in range(20):
		goblin._physics_process(0.05)
	var vf_atk = get_visual_front(goblin)
	var to_dummy = (dummy.global_position - goblin.global_position).normalized()
	var dot_atk = vf_atk.dot(to_dummy)
	if dot_atk > 0.90:
		log_pass("Goblin Attack Orientation", "Maintains orientation facing target during melee attack (dot=%.2f)" % dot_atk)
	else:
		log_fail("Goblin Attack Orientation", "Did not face target during attack (dot=%.2f)" % dot_atk)

	# 4. Flee behavior (Huida): HP reduced to < 35%
	goblin.current_health = 15.0 # Low HP triggers flee
	goblin.flee_timer = 0.0
	dummy.global_position = goblin.global_position + Vector3(3, 0, 0)
	for s in range(25):
		goblin._physics_process(0.05)
	var vf_flee = get_visual_front(goblin)
	var away_dir = (goblin.global_position - dummy.global_position).normalized()
	var dot_flee = vf_flee.dot(away_dir)
	if goblin.is_fleeing and dot_flee > 0.80:
		log_pass("Goblin Flee Orientation (Huida)", "Orients body facing the escape direction, runs forward (dot=%.2f)" % dot_flee)
	else:
		log_fail("Goblin Flee Orientation (Huida)", "Did not face escape direction (is_fleeing=%s, dot=%.2f)" % [goblin.is_fleeing, dot_flee])

	root.free()

func test_monster_archer_locomotion():
	print("\n--- SECTION 3: MONSTER 2 (SKELETON ARCHER) ORIENTATION & KITING ---")
	var root = Node3D.new()
	add_child(root)
	
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var archer = enemy_scene.instantiate() as CharacterBody3D
	root.add_child(archer)
	archer.set_archetype(2) # SKELETON_ARCHER
	archer.global_position = Vector3.ZERO
	
	var dummy = CharacterBody3D.new()
	dummy.add_to_group("player")
	root.add_child(dummy)
	
	# 1. Advance at long distance (> 14m)
	dummy.global_position = Vector3(20, 0, 0)
	for s in range(25):
		archer._physics_process(0.05)
	var vf_adv = get_visual_front(archer)
	var dot_adv = vf_adv.dot(Vector3.RIGHT)
	if dot_adv > 0.85:
		log_pass("Archer Advance (+X)", "Faces forward displacement towards target (dot=%.2f)" % dot_adv)
	else:
		log_fail("Archer Advance (+X)", "Wrong advance orientation (dot=%.2f, vf=%s)" % [dot_adv, vf_adv])

	# 2. Tactical retreat looking at target ("flee shoot" / kiting at dist < 6m)
	dummy.global_position = archer.global_position + Vector3(4.0, 0, 0)
	for s in range(25):
		archer._physics_process(0.05)
	var vf_kite = get_visual_front(archer)
	var to_dummy = (dummy.global_position - archer.global_position).normalized()
	var dot_kite = vf_kite.dot(to_dummy)
	var h_vel = Vector3(archer.velocity.x, 0, archer.velocity.z)
	var is_retreating = h_vel.dot(to_dummy) < 0
	if dot_kite > 0.85 and is_retreating:
		log_pass("Archer Tactical Retreat ('flee shoot')", "Retreats away from player while keeping body aimed at target (dot=%.2f, retreating=%s)" % [dot_kite, is_retreating])
	else:
		log_fail("Archer Tactical Retreat ('flee shoot')", "Failed kiting orientation (dot=%.2f, retreating=%s)" % [dot_kite, is_retreating])

	root.free()

func test_monster_imp_circling():
	print("\n--- SECTION 4: MONSTER 3 (FIRE IMP) CIRCLING ORIENTATION ---")
	var root = Node3D.new()
	add_child(root)
	
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var imp = enemy_scene.instantiate() as CharacterBody3D
	root.add_child(imp)
	imp.set_archetype(3) # FIRE_IMP
	imp.global_position = Vector3(0, 0, 7) # In circling zone (5m to 9m)
	imp.attack_timer = imp.attack_cooldown # Ensure imp is in active circling behavior
	
	var dummy = CharacterBody3D.new()
	dummy.add_to_group("player")
	root.add_child(dummy)
	dummy.global_position = Vector3.ZERO
	
	for s in range(25):
		imp._physics_process(0.05)
	
	var h_vel = Vector3(imp.velocity.x, 0, imp.velocity.z).normalized()
	var vf_imp = get_visual_front(imp)
	var dot_move = vf_imp.dot(h_vel)
	if dot_move > 0.80:
		log_pass("Fire Imp Circling Orientation", "Orients visual front along curved movement path, not locked sideways (dot=%.2f)" % dot_move)
	else:
		log_fail("Fire Imp Circling Orientation", "Imp crab-walking/sliding sideways (dot=%.2f, vf=%s, vel=%s)" % [dot_move, vf_imp, h_vel])
	
	root.free()
