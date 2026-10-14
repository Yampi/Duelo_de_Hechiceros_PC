extends Node

var wiz_scene = preload("res://scenes/Wizard.tscn")
var enemy_scene = preload("res://scenes/Enemy.tscn")

func _ready() -> void:
	print("\n========================================================")
	print("🔍 ASYNC REAL-PHYSICS SPELL AUDIT")
	print("========================================================\n")
	
	run_audit()

func run_audit() -> void:
	for spell_id in range(1, 10):
		await test_single_spell(spell_id)
	
	print("\n========================================================")
	print("✅ SPELL AUDIT COMPLETE")
	print("========================================================\n")
	get_tree().quit(0)

func test_single_spell(spell_id: int) -> void:
	var info = GameManager.spells[spell_id]
	var s_name = info["name"]
	var cost = info["cost"]
	print("\n--- Testing Spell %d: %s (Cost: %s MP) ---" % [spell_id, s_name, str(cost)])
	
	var test_root = Node3D.new()
	add_child(test_root)
	
	var player = wiz_scene.instantiate()
	test_root.add_child(player)
	player.global_position = Vector3(0, 0, 0)
	
	# Spawn enemy at Vector3(0, 0, 5) for close spells or 8m for projectiles
	var dummy = enemy_scene.instantiate()
	test_root.add_child(dummy)
	dummy.global_position = Vector3(0, 0, 4.0 if spell_id == 4 else 7.0)
	dummy.move_speed = 0.0
	dummy.attack_damage = 0.0
	var enemy_initial_hp = dummy.current_health
	
	# Turn off mana regen temporarily for exact cost verification
	var old_regen = GameManager.mana_regen_rate
	GameManager.mana_regen_rate = 0.0
	GameManager.player_max_mana = 100.0
	GameManager.player_mana = 100.0
	GameManager.player_health = 50.0
	
	player.aim_point = dummy.global_position + Vector3(0, 0.8, 0) # Aim at enemy chest
	player.select_spell_slot(spell_id)
	
	var mana_before = GameManager.player_mana
	player.start_spell_channeling()
	
	# Wait for channeling and spell cast
	var frames = 0
	while player.is_channeling and frames < 120:
		await get_tree().physics_frame
		frames += 1
	
	# Let 1 extra frame pass for execute_spell to run
	await get_tree().physics_frame
	
	var mana_after_cast = GameManager.player_mana
	var mana_consumed = mana_before - mana_after_cast
	print("  Channel took %d physics frames. Mana consumed: %.1f (Expected: %.1f)" % [frames, mana_consumed, cost])
	
	# Wait 60 physics frames (1 second) for projectile travel / effect execution
	for f in range(60):
		await get_tree().physics_frame
	
	var damage_dealt = enemy_initial_hp - dummy.current_health
	var player_hp_diff = GameManager.player_health - 50.0
	
	print("  Enemy HP: %.1f -> %.1f (Damage: %.1f)" % [enemy_initial_hp, dummy.current_health, damage_dealt])
	print("  Player HP change: %+.1f" % [player_hp_diff])
	
	# Check children left in test_root
	var active_children = []
	for c in test_root.get_children():
		if c != player and c != dummy:
			active_children.append(c.name)
	print("  Children in test root: %s" % [str(active_children)])
	
	# Check for errors/behavior
	var pass_mana = abs(mana_consumed - cost) < 0.01
	print("  [EVALUATION]")
	print("    - Mana Consumption: %s" % ("PASS" if pass_mana else "FAIL"))
	
	match spell_id:
		1: # Magic Bolt
			print("    - Hits Enemy: %s (Damage: %.1f)" % [("PASS" if damage_dealt > 0 else "FAIL"), damage_dealt])
		2: # Fireball
			print("    - AOE Hit: %s (Damage: %.1f)" % [("PASS" if damage_dealt > 0 else "FAIL"), damage_dealt])
		3: # Summon Goblin
			var has_minion = false
			for c in test_root.get_children():
				if c.is_in_group("minion"):
					has_minion = true
					break
			print("    - Spawns Minion: %s" % [("PASS" if has_minion else "FAIL")])
		4: # Shockwave
			print("    - Radial Damage: %s (Damage: %.1f)" % [("PASS" if damage_dealt > 0 else "FAIL"), damage_dealt])
		5: # Heal
			print("    - Heals Player: %s (+%.1f HP)" % [("PASS" if player_hp_diff > 0 else "FAIL"), player_hp_diff])
		6: # Teleport
			print("    - Blink Relocation: %s (Dist: %.1f)" % [("PASS" if player.global_position.length() > 1.0 else "FAIL"), player.global_position.length()])
		7: # Ice Projectile
			print("    - Hits Enemy: %s (Damage: %.1f)" % [("PASS" if damage_dealt > 0 else "FAIL"), damage_dealt])
		8: # Lightning
			print("    - Instant Hit: %s (Damage: %.1f)" % [("PASS" if damage_dealt > 0 else "FAIL"), damage_dealt])
		9: # Shield
			print("    - Shield Active: %s" % [("PASS" if (player.active_shield and is_instance_valid(player.active_shield)) else "FAIL")])
	
	GameManager.mana_regen_rate = old_regen
	test_root.queue_free()
	await get_tree().physics_frame
