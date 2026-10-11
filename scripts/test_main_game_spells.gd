extends Node

func _ready() -> void:
	print("\n========================================================")
	print("🎮 TESTING ALL SPELLS IN FULL RUNNING GAME (Main.tscn)")
	print("========================================================\n")
	
	var main_scene = load("res://scenes/Main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	# Wait 5 frames for map generation and ready
	for i in range(5):
		await get_tree().physics_frame
	
	var player = main.get_node("Wizard")
	var hud = main.get_node("HUD")
	
	# Spawn a test target enemy 6m in front of player
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var test_enemy = enemy_scene.instantiate()
	main.add_child(test_enemy)
	test_enemy.global_position = player.global_position + Vector3(0, 0, -6.0) # Player looks towards -Z
	
	print("Player at: %s, Test Enemy at: %s" % [player.global_position, test_enemy.global_position])
	
	# Test every spell
	for slot in range(1, 10):
		if not GameManager.spells.has(slot):
			continue
		var s_data = GameManager.spells[slot]
		print("\n>>> Testing Spell Slot %d: '%s' <<<" % [slot, s_data["name"]])
		
		# Reset player mana and health
		GameManager.player_mana = 75.0
		GameManager.player_health = 60.0
		var mana_before = GameManager.player_mana
		var enemy_hp_before = test_enemy.current_health
		var player_hp_before = GameManager.player_health
		
		# Set player aim point directly at enemy chest
		player.aim_point = test_enemy.global_position + Vector3(0, 0.9, 0)
		
		# 1. Activation test
		player.select_spell_slot(slot)
		await get_tree().physics_frame
		
		# Trigger channel
		player.start_spell_channeling()
		
		var channel_ticks = 0
		while player.is_channeling and channel_ticks < 120:
			await get_tree().physics_frame
			channel_ticks += 1
		
		# Allow projectile / spell execution
		for wait_f in range(40):
			await get_tree().physics_frame
		
		var mana_after = GameManager.player_mana
		var mana_cost = mana_before - mana_after
		var enemy_hp_after = test_enemy.current_health
		var enemy_dmg = enemy_hp_before - enemy_hp_after
		var player_hp_after = GameManager.player_health
		var player_heal = player_hp_after - player_hp_before
		
		print("  Channel frames: %d" % channel_ticks)
		print("  Mana before: %.1f, after: %.1f, consumed: %.1f (expected: %.1f)" % [mana_before, mana_after, mana_cost, s_data["cost"]])
		print("  Enemy HP before: %.1f, after: %.1f, dmg dealt: %.1f" % [enemy_hp_before, enemy_hp_after, enemy_dmg])
		print("  Player HP change: %+.1f" % player_heal)
		
		# Check active shield or minions
		var minions = get_tree().get_nodes_in_group("minion")
		if minions.size() > 0:
			print("  Active minions: %d" % minions.size())
		if player.active_shield and is_instance_valid(player.active_shield):
			print("  Player has active shield: YES")
		
		# Reset enemy health for next test if alive
		if test_enemy.current_health <= 0:
			test_enemy.queue_free()
			test_enemy = enemy_scene.instantiate()
			main.add_child(test_enemy)
			test_enemy.global_position = player.global_position + Vector3(0, 0, -6.0)
		else:
			test_enemy.current_health = 60.0
	
	print("\n========================================================")
	print("🏁 MAIN GAME SPELL TEST COMPLETED")
	print("========================================================\n")
	get_tree().quit(0)
