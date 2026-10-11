extends Node

func _ready() -> void:
	DirAccess.make_dir_absolute("res://docs/ui_captures")
	print("[PHASE 6] Starting Inventory & World Map verification...")
	
	var resolutions = [
		{"name": "1280x720", "size": Vector2i(1280, 720)},
		{"name": "1920x1080", "size": Vector2i(1920, 1080)}
	]
	
	var main_scene = load("res://scenes/Main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	for i in range(25):
		await get_tree().process_frame
	
	var hud = main.get_node("HUD")
	var inv_ui = hud.inventory_ui as InventoryUI
	var map_modal = hud.world_map_modal as WorldMapModal
	
	# Populate inventory with authentic items across all categories
	GameManager.inventory.clear()
	GameManager.inventory.add_item("potion_health", 3)
	GameManager.inventory.add_item("potion_mana", 2)
	GameManager.inventory.add_item("magic_scroll", 1)
	GameManager.inventory.add_item("sulfur", 5)
	GameManager.inventory.add_item("clover", 4)
	GameManager.inventory.add_item("arcane_crystal", 1)
	
	# Discover zones and POIs for map
	GameManager.discovered_zones = [1, 2] # Pradera Inicial & Bosque Exterior
	GameManager.active_objective = "Activa los 3 Santuarios y recupera el Cristal Arcano"
	GameManager.active_objective_pos = Vector3(25, 0, 40)
	
	for res in resolutions:
		DisplayServer.window_set_size(res["size"])
		get_tree().root.size = res["size"]
		for i in range(12):
			await get_tree().process_frame
		
		# 1. Test Inventory UI
		inv_ui.open_inventory()
		inv_ui._select_slot(0) # Select potion_health
		for i in range(18):
			await get_tree().process_frame
		_save_image("res://docs/ui_captures/phase6_inventory_%s.png" % res["name"])
		
		inv_ui.close_inventory()
		for i in range(12):
			await get_tree().process_frame
		
		# 2. Test World Map Modal
		map_modal.open_map()
		map_modal.center_on_player()
		for i in range(18):
			await get_tree().process_frame
		_save_image("res://docs/ui_captures/phase6_map_%s.png" % res["name"])
		
		map_modal.close_map()
		for i in range(10):
			await get_tree().process_frame
	
	print("[PHASE 6] Inventory & World Map verification completed successfully!")
	get_tree().quit(0)

func _save_image(path: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		var err = img.save_png(ProjectSettings.globalize_path(path))
		if err == OK:
			print("Saved screenshot: ", path)
		else:
			push_error("Failed to save screenshot: " + path)
