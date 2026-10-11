extends Node

func _ready() -> void:
	# Ensure screenshots directory exists
	DirAccess.make_dir_absolute("res://screenshots")
	
	# Populate sample game state for realistic HUD verification
	GameManager.player_health = 85.0
	GameManager.player_max_health = 100.0
	GameManager.player_mana = 45.0
	GameManager.player_max_mana = 75.0
	GameManager.active_shrines = 2
	GameManager.reagents = {
		"apple": 4,
		"scroll": 2,
		"sulfur": 5,
		"clover": 3
	}
	if GameManager.inventory:
		GameManager.inventory.clear()
		GameManager.inventory.add_item("potion_health", 3)
		GameManager.inventory.add_item("potion_mana", 2)
		GameManager.inventory.add_item("arcane_crystal", 1)
		GameManager.inventory.add_item("magic_scroll", 2)
		GameManager.inventory.add_item("apple", 4)
		GameManager.inventory.add_item("sulfur", 5)
		GameManager.inventory.add_item("clover", 3)
	
	var hud_scene = load("res://scenes/HUD.tscn")
	var hud = hud_scene.instantiate()
	add_child(hud)
	
	hud.update_hp(GameManager.player_health, GameManager.player_max_health)
	hud.update_mana(GameManager.player_mana, GameManager.player_max_mana, 12.0)
	hud.update_shrines_display()
	hud.update_reagents_display()
	hud.update_mode_hud("MODO DUELO ARCANO", "Territorio: Bosque Primigenio", "Objetivo: Derrota a los hostiles arcanos")
	
	# Capture resolutions
	var resolutions = [
		{"name": "1280x720", "size": Vector2i(1280, 720)},
		{"name": "1920x1080", "size": Vector2i(1920, 1080)}
	]
	
	for res in resolutions:
		DisplayServer.window_set_size(res["size"])
		get_tree().root.size = res["size"]
		
		# 1. Capture HUD
		if hud.inventory_ui and hud.inventory_ui.visible:
			hud.inventory_ui.visible = false
		if hud.world_map_modal and hud.world_map_modal.visible:
			hud.world_map_modal.visible = false
		
		await _wait_frames(10)
		_save_viewport_image("res://screenshots/hud_%s.png" % res["name"])
		
		# 2. Capture Inventory
		if hud.inventory_ui:
			hud.inventory_ui.open_inventory()
		await _wait_frames(10)
		_save_viewport_image("res://screenshots/inventory_%s.png" % res["name"])
		if hud.inventory_ui:
			hud.inventory_ui.close_inventory()
		
		# 3. Capture World Map
		if hud.world_map_modal:
			hud.world_map_modal.open_map()
		await _wait_frames(10)
		_save_viewport_image("res://screenshots/map_%s.png" % res["name"])
		if hud.world_map_modal:
			hud.world_map_modal.close_map()
		
		await _wait_frames(5)
	
	print("\n[CAPTURE_SUITE] All screenshots captured successfully in res://screenshots/")
	get_tree().quit(0)

func _wait_frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame

func _save_viewport_image(path: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png(path)
		print("Saved screenshot: %s (%dx%d)" % [path, img.get_width(), img.get_height()])
	else:
		printerr("Failed to capture image for: %s" % path)
