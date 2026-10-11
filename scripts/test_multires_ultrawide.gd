extends Node

func _ready() -> void:
	print("[PHASE 7] Running Multi-Resolution & Ultrawide Safe-Area Verification...")
	
	var resolutions = [
		{"name": "1600x900", "size": Vector2i(1600, 900)},
		{"name": "2560x1080_ultrawide", "size": Vector2i(2560, 1080)}
	]
	
	var main_scene = load("res://scenes/Main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	for i in range(25):
		await get_tree().process_frame
	
	var hud = main.get_node("HUD")
	hud.update_hp(85.0, 100.0)
	hud.update_mana(65.0, 100.0, 4.0)
	hud.update_active_spell(1)
	
	for res in resolutions:
		DisplayServer.window_set_size(res["size"])
		get_tree().root.size = res["size"]
		
		for i in range(15):
			await get_tree().process_frame
		
		# 1. Combat HUD in this resolution
		_save_image("res://docs/ui_captures/phase7_hud_%s.png" % res["name"])
		
		# 2. Inventory UI in this resolution
		hud.inventory_ui.open_inventory()
		for i in range(15):
			await get_tree().process_frame
		_save_image("res://docs/ui_captures/phase7_inventory_%s.png" % res["name"])
		hud.inventory_ui.close_inventory()
		
		for i in range(10):
			await get_tree().process_frame
	
	print("[PHASE 7] Multi-Resolution & Ultrawide captures completed successfully!")
	get_tree().quit(0)

func _save_image(path: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		var err = img.save_png(ProjectSettings.globalize_path(path))
		if err == OK:
			print("Saved screenshot: ", path)
		else:
			push_error("Failed to save screenshot: " + path)
