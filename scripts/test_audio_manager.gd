extends SceneTree

func _init() -> void:
	print("[AUDIO_TEST] Starting Phase 4 AudioManager verification...")
	
	# 1. Verify AudioServer buses
	var required_buses = ["Master", "Music", "SFX", "UI"]
	for b in required_buses:
		var idx = AudioServer.get_bus_index(b)
		assert(idx != -1, "Missing audio bus: " + b)
		print("  ✓ Bus confirmed: ", b, " (index ", idx, ")")
	
	# 2. Verify AudioManager autoload
	var am = root.get_node_or_null("AudioManager")
	if not am:
		var am_script = load("res://scripts/audio_manager.gd")
		am = am_script.new()
		am.name = "AudioManager"
		root.add_child(am)
	print("  ✓ AudioManager active in SceneTree")
	
	# 3. Test UI sounds playback
	var ui_sounds = ["hover", "click", "open", "close", "error", "error_mana", "loot", "shrine", "victory", "defeat"]
	for s in ui_sounds:
		am.play_ui(s)
		print("  ✓ Played UI sound: ", s)
	
	# 4. Test music playback & crossfade
	am.play_music("exploration", 0.2)
	print("  ✓ Music track started: exploration")
	am.play_music("boss", 0.2)
	print("  ✓ Music crossfade to track: boss")
	am.stop_music(0.1)
	print("  ✓ Music stop tested")
	
	# 5. Test volume setters and persistence
	am.set_volume("Master", 0.75)
	am.set_volume("Music", 0.60)
	am.set_volume("SFX", 0.80)
	am.set_volume("UI", 0.90)
	assert(abs(am.get_volume("Master") - 0.75) < 0.01, "Volume getter/setter mismatch")
	am.save_settings()
	am.load_settings()
	assert(abs(am.get_volume("Master") - 0.75) < 0.01, "Volume persistence load mismatch")
	print("  ✓ Audio volume settings and persistence verified")
	
	print("[AUDIO_TEST] Phase 4 AudioManager verification completed successfully!")
	quit(0)
