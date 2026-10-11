extends SceneTree

const IconRegistry = preload("res://scripts/ui/icon_registry.gd")

func _init() -> void:
	print("\n========================================================")
	print("🔍 VALIDATING ICON REGISTRY & TEXTURE RESOURCE INTEGRITY")
	print("========================================================")
	
	var paths = IconRegistry.get_all_registered_paths()
	var failed_count = 0
	var passed_count = 0
	
	print("Total unique registered icon paths: %d\n" % paths.size())
	
	for path in paths:
		if not ResourceLoader.exists(path):
			printerr("  [FAIL] File does not exist on disk: %s" % path)
			failed_count += 1
			continue
		
		var res = ResourceLoader.load(path)
		if not res:
			printerr("  [FAIL] ResourceLoader failed to load: %s" % path)
			failed_count += 1
		elif not (res is Texture2D):
			printerr("  [FAIL] Resource is not a Texture2D (%s): %s" % [res.get_class(), path])
			failed_count += 1
		else:
			var tex: Texture2D = res as Texture2D
			var size = tex.get_size()
			if size.x <= 0 or size.y <= 0:
				printerr("  [FAIL] Texture2D has invalid dimensions %s: %s" % [size, path])
				failed_count += 1
			else:
				print("  [PASS] %s (%dx%d)" % [path, int(size.x), int(size.y)])
				passed_count += 1
	
	# Also test get_icon across all categories and entries
	print("\n--- Testing IconRegistry.get_icon() with Category Dictionaries ---")
	var categories = {
		"spells": IconRegistry.SPELLS,
		"items": IconRegistry.ITEMS,
		"status": IconRegistry.STATUS,
		"ui": IconRegistry.UI,
		"poi": IconRegistry.POI
	}
	
	for cat in categories:
		var d = categories[cat]
		for key in d:
			var tex = IconRegistry.get_icon(cat, key)
			if tex == null:
				printerr("  [FAIL] get_icon('%s', '%s') returned null!" % [cat, key])
				failed_count += 1
			else:
				passed_count += 1
	
	# Test fallback mechanism with non-existent icon
	var fallback_tex = IconRegistry.get_icon("non_existent", "missing_key")
	if fallback_tex == null:
		printerr("  [FAIL] Fallback icon for invalid key returned null!")
		failed_count += 1
	else:
		print("  [PASS] Fallback mechanism active for unknown keys (%dx%d)" % [int(fallback_tex.get_size().x), int(fallback_tex.get_size().y)])
		passed_count += 1
	
	print("\n========================================================")
	print("📊 RESULTS: PASSED: %d | FAILED: %d" % [passed_count, failed_count])
	print("========================================================")
	
	if failed_count > 0:
		print("❌ TEST SUITE FAILED!")
		quit(1)
	else:
		print("✅ ALL ICONS LOADED SUCCESSFULLY!")
		quit(0)
