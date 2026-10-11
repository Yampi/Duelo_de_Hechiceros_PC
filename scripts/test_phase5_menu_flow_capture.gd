extends Node

func _ready() -> void:
	DirAccess.make_dir_absolute("res://docs/ui_captures")
	print("[PHASE 5] Starting Menu, Pause, Settings & Flow verification...")
	
	var resolutions = [
		{"name": "1280x720", "size": Vector2i(1280, 720)},
		{"name": "1920x1080", "size": Vector2i(1920, 1080)}
	]
	
	# --- Part 1: Main Menu & Modes & Settings ---
	var menu_scene = load("res://scenes/MainMenu.tscn")
	var menu = menu_scene.instantiate()
	add_child(menu)
	
	for i in range(20):
		await get_tree().process_frame
	
	for res in resolutions:
		DisplayServer.window_set_size(res["size"])
		get_tree().root.size = res["size"]
		for i in range(12):
			await get_tree().process_frame
		
		# 1. Main Menu State
		_save_image("res://docs/ui_captures/phase5_main_menu_%s.png" % res["name"])
		
		# 2. Mode Selection Cards State
		menu._show_mode_selection()
		for i in range(12):
			await get_tree().process_frame
		_save_image("res://docs/ui_captures/phase5_mode_selection_%s.png" % res["name"])
		
		# 3. Settings Modal State
		menu.settings_modal.open_modal()
		for i in range(12):
			await get_tree().process_frame
		_save_image("res://docs/ui_captures/phase5_settings_modal_%s.png" % res["name"])
		menu.settings_modal.close_modal()
		menu._hide_mode_selection()
		for i in range(8):
			await get_tree().process_frame
	
	menu.queue_free()
	for i in range(10):
		await get_tree().process_frame
	
	# --- Part 2: Combat In-Game Pause, Game Over & Victory ---
	var main_scene = load("res://scenes/Main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	var hud = main.get_node("HUD")
	
	for i in range(25):
		await get_tree().process_frame
	
	for res in resolutions:
		DisplayServer.window_set_size(res["size"])
		get_tree().root.size = res["size"]
		for i in range(10):
			await get_tree().process_frame
		
		# 4. Pause Menu State
		hud.pause_menu.pause_game()
		for i in range(12):
			await get_tree().process_frame
		_save_image("res://docs/ui_captures/phase5_pause_menu_%s.png" % res["name"])
		hud.pause_menu.resume_game()
		for i in range(8):
			await get_tree().process_frame
		
		# 5. Game Over / Defeat State
		GameManager.enemies_defeated = 14
		GameManager.score = 750
		hud.show_game_over()
		for i in range(15):
			await get_tree().process_frame
		_save_image("res://docs/ui_captures/phase5_game_over_%s.png" % res["name"])
		hud.game_over_panel.visible = false
		
		# 6. Victory State
		GameManager.active_shrines = 3
		GameManager.enemies_defeated = 22
		GameManager.score = 1450
		hud.show_victory()
		for i in range(15):
			await get_tree().process_frame
		_save_image("res://docs/ui_captures/phase5_victory_%s.png" % res["name"])
		hud.victory_panel.visible = false
	
	print("[PHASE 5] Menu flow, Pause, Settings, Defeat and Victory completed successfully!")
	get_tree().quit(0)

func _save_image(path: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		var err = img.save_png(ProjectSettings.globalize_path(path))
		if err == OK:
			print("Saved screenshot: ", path)
		else:
			push_error("Failed to save screenshot: " + path)
