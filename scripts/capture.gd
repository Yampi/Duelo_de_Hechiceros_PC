extends Node

func _ready() -> void:
	await get_tree().create_timer(0.15).timeout
	var main = get_parent().get_node("Main")
	if main:
		var enemy_scene = preload("res://scenes/Enemy.tscn")
		var tree_scene = preload("res://scenes/FruitTree.tscn")
		var rock_scene = preload("res://assets/environment/Rock_Medium_1.gltf")
		var fountain_scene = preload("res://scenes/HealthFountain.tscn")
		var bolt_scene = preload("res://scenes/MagicBolt.tscn")
		var summon_scene = preload("res://scenes/SummonCircle.tscn")
		var heal_scene = preload("res://scenes/HealEffect.tscn")
		
		# Sample reagents and captured shrine for HUD showcase
		GameManager.reagents["apple"] = 3
		GameManager.reagents["sulfur"] = 2
		GameManager.reagents["clover"] = 1
		GameManager.reagents["scroll"] = 1
		GameManager.active_shrines = 1
		GameManager.update_mana_capacity()
		GameManager.player_health = 92.0
		GameManager.player_mana = 68.0
		
		# Fruit tree on the left
		var ftree = tree_scene.instantiate()
		ftree.position = Vector3(-4.8, 0.0, -4.5)
		main.add_child(ftree)
		
		# Health fountain on the right
		var fountain = fountain_scene.instantiate()
		fountain.position = Vector3(4.6, 0.0, -4.0)
		main.add_child(fountain)
		
		# Rock boulder
		var rock = rock_scene.instantiate()
		rock.scale = Vector3(1.2, 1.2, 1.2)
		rock.position = Vector3(3.5, 0.0, -2.2)
		main.add_child(rock)
		
		# Skeleton Spearman advancing in mid-range
		var e1 = enemy_scene.instantiate()
		e1.set_archetype(1)
		e1.position = Vector3(-1.8, 0.0, -3.8)
		main.add_child(e1)
		
		# Skeleton Archer drawing bow on right flank
		var e2 = enemy_scene.instantiate()
		e2.set_archetype(2)
		e2.position = Vector3(2.2, 0.0, -5.2)
		main.add_child(e2)
		
		# Goblin Warrior advancing
		var e3 = enemy_scene.instantiate()
		e3.set_archetype(0)
		e3.position = Vector3(0.5, 0.0, -4.2)
		main.add_child(e3)
		
		# Fire Imp levitating on right
		var e4 = enemy_scene.instantiate()
		e4.set_archetype(3)
		e4.position = Vector3(1.8, 0.8, -3.2)
		main.add_child(e4)
		
		# Shadow Imp levitating on left
		var e5 = enemy_scene.instantiate()
		e5.set_archetype(4)
		e5.position = Vector3(-2.6, 0.8, -4.8)
		main.add_child(e5)
		
		# Active Magic Bolt in flight with trail and orbital rings aimed at Spearman
		var bolt = bolt_scene.instantiate()
		main.add_child(bolt)
		var start_bolt = Vector3(0.3, 1.4, -0.4)
		var target_bolt = Vector3(-1.8, 1.2, -3.8)
		bolt.init_bolt(start_bolt, (target_bolt - start_bolt).normalized())
		
		# Active Summoning ritual circle with violet motes
		var summon = summon_scene.instantiate()
		main.add_child(summon)
		summon.global_position = Vector3(-1.4, 0.05, -2.0)
		
		# Showcase target indicator on Skeleton Spearman
		if main.hud:
			main.hud.set_target_enemy(e1)
			main.hud.update_hp(92.0, 100.0)
			main.hud.update_mana(68.0, 75.0, 2.0)
			main.hud.update_cast_progress(1, 0.0)
		
	print("CAPTURE: Rendering 0.8 seconds...")
	await get_tree().create_timer(0.6).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshot_preview.png")
		print("SCREENSHOT_SAVED_SUCCESS")
	get_tree().quit()
