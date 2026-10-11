extends Node

func _ready() -> void:
	DirAccess.make_dir_absolute("res://docs/ui_captures")
	
	GameManager.current_mode = GameManager.GameMode.EXPLORATION
	var main_scene = load("res://scenes/Main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	var hud = main.get_node("HUD")
	var player = main.get_node("Wizard")
	
	# Wait for 3D world to initialize
	for i in range(25):
		await get_tree().process_frame
	
	var resolutions = [
		{"name": "1280x720", "size": Vector2i(1280, 720)},
		{"name": "1920x1080", "size": Vector2i(1920, 1080)}
	]
	
	for res in resolutions:
		DisplayServer.window_set_size(res["size"])
		get_tree().root.size = res["size"]
		for i in range(15):
			await get_tree().process_frame
		
		# 1. Zone Banner event
		hud.show_zone_banner("EL VALLE DE LAS BRUMAS", "Zona Arcana Antigua • Nivel II", Color(1.0, 0.85, 0.35))
		for i in range(12):
			await get_tree().process_frame
		_save_image("res://docs/ui_captures/phase3_zone_banner_%s.png" % res["name"])
		
		# 2. Spell Cast Flash event (Fireball element flash)
		hud.trigger_element_flash(Color(1.0, 0.45, 0.1), 0.5)
		if hud.spell_slots.size() >= 2:
			hud.spell_slots[1].flash_cast()
		for i in range(6):
			await get_tree().process_frame
		_save_image("res://docs/ui_captures/phase3_spell_cast_%s.png" % res["name"])
		
		# 3. Loot Toast event
		hud.show_loot_toast_for_item("potion_mana", 2)
		hud.show_loot_toast_for_item("arcane_crystal", 1)
		for i in range(10):
			await get_tree().process_frame
		_save_image("res://docs/ui_captures/phase3_loot_toast_%s.png" % res["name"])
		
		# 4. 3D Unprojected Interaction Prompt event
		var prompt = hud.create_interaction_prompt(player, "Activar Altar de Transmutación", "F", 1.8)
		prompt.progress = 0.65
		for i in range(8):
			await get_tree().process_frame
		_save_image("res://docs/ui_captures/phase3_interact_prompt_%s.png" % res["name"])
		if prompt:
			prompt.dismiss()
		
		# 5. Death slow-motion desaturation event
		if hud.screen_effects and hud.screen_effects.material:
			var mat = hud.screen_effects.material as ShaderMaterial
			mat.set_shader_parameter("desaturation", 0.85)
		if hud.screen_vignette and hud.screen_vignette.material:
			(hud.screen_vignette.material as ShaderMaterial).set_shader_parameter("vignette_intensity", 0.7)
		for i in range(6):
			await get_tree().process_frame
		_save_image("res://docs/ui_captures/phase3_death_desaturate_%s.png" % res["name"])
		
		# Reset screen effects for next resolution
		if hud.screen_effects and hud.screen_effects.material:
			(hud.screen_effects.material as ShaderMaterial).set_shader_parameter("desaturation", 0.0)
			(hud.screen_effects.material as ShaderMaterial).set_shader_parameter("flash_power", 0.0)
		if hud.screen_vignette and hud.screen_vignette.material:
			(hud.screen_vignette.material as ShaderMaterial).set_shader_parameter("vignette_intensity", 0.0)
	
	print("[PHASE 3] Feedback & Game Feel verification captures completed successfully!")
	get_tree().quit(0)

func _save_image(path: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		var err = img.save_png(ProjectSettings.globalize_path(path))
		if err == OK:
			print("Saved screenshot: ", path)
		else:
			push_error("Failed to save screenshot: " + path)
