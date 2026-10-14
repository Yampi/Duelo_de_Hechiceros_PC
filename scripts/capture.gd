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
		# Apply elegant Arcane theme to player
		var char_app = preload("res://scripts/character_appearance.gd")
		char_app.apply_to_model(main.player, {
			"staff_gem_idx": 0,
			"robe_color_idx": 0,
			"trim_color_idx": 0
		})
		
		var p = main.player.global_position
		
		# Skeleton Spearman advancing along the dirt path (target)
		var e1 = enemy_scene.instantiate()
		e1.set_archetype(1)
		main.add_child(e1)
		var p_e1 = p + Vector3(-1.2, 0.0, -5.6)
		p_e1.y = MapConfig.get_height_at(p_e1.x, p_e1.z)
		e1.global_position = p_e1
		e1.look_at(p + Vector3(0, 1.0, 0), Vector3.UP)
		
		# Skeleton Archer drawing bow from the elevated roadside shoulder
		var e2 = enemy_scene.instantiate()
		e2.set_archetype(2)
		main.add_child(e2)
		var p_e2 = p + Vector3(3.4, 0.0, -8.2)
		p_e2.y = MapConfig.get_height_at(p_e2.x, p_e2.z)
		e2.global_position = p_e2
		e2.look_at(p + Vector3(0, 1.0, 0), Vector3.UP)
		
		# Goblin Scout flanking from the left berm
		var e3 = enemy_scene.instantiate()
		e3.set_archetype(0)
		main.add_child(e3)
		var p_e3 = p + Vector3(-3.2, 0.0, -7.8)
		p_e3.y = MapConfig.get_height_at(p_e3.x, p_e3.z)
		e3.global_position = p_e3
		e3.look_at(p + Vector3(0, 1.0, 0), Vector3.UP)
		
		# Fire Imp hovering menacingly on right flank
		var e4 = enemy_scene.instantiate()
		e4.set_archetype(3)
		main.add_child(e4)
		var p_e4 = p + Vector3(2.2, 0.9, -4.6)
		p_e4.y = MapConfig.get_height_at(p_e4.x, p_e4.z) + 0.8
		e4.global_position = p_e4
		e4.look_at(p + Vector3(0, 1.0, 0), Vector3.UP)
		
		# Active Magic Bolt in flight with trail and orbital rings aimed at Spearman
		var bolt = bolt_scene.instantiate()
		main.add_child(bolt)
		var start_bolt = p + Vector3(0.3, 1.4, -0.4)
		var target_bolt = e1.global_position + Vector3(0.0, 1.2, 0.0)
		bolt.init_bolt(start_bolt, (target_bolt - start_bolt).normalized())
		
		# Active Summoning ritual circle with violet motes
		var summon = summon_scene.instantiate()
		main.add_child(summon)
		var p_sum = p + Vector3(-2.4, 0.0, -3.2)
		p_sum.y = MapConfig.get_height_at(p_sum.x, p_sum.z) + 0.05
		summon.global_position = p_sum
		
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
