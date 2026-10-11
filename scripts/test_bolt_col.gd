extends Node

func _ready() -> void:
	print("Testing Fireball collision directly...")
	var fb_scene = preload("res://scenes/Fireball.tscn")
	var enemy_scene = preload("res://scenes/Enemy.tscn")
	
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = Vector3(0, 0, 5)
	
	var fb = fb_scene.instantiate()
	add_child(fb)
	fb.init_trajectory(Vector3(0, 1.4, 0), Vector3(0, 0, 5))
	
	print("Enemy pos: %s, Fireball target: (0, 0, 5)" % [enemy.global_position])
	
	for f in range(40):
		await get_tree().physics_frame
		if enemy.current_health < 60.0:
			print("Frame %d: Fireball hit enemy! HP: %.1f" % [f, enemy.current_health])
			break
		print("Frame %d: Enemy HP: %.1f, FB pos: %s" % [f, enemy.current_health, fb.global_position if is_instance_valid(fb) else "dead"])
	
	get_tree().quit(0)
