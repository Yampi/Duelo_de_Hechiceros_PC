extends Node

func _ready() -> void:
	DirAccess.make_dir_absolute("res://docs/ui_captures")
	
	var gallery_scene = load("res://scenes/ui/UIGallery.tscn")
	var gallery = gallery_scene.instantiate()
	add_child(gallery)
	
	var resolutions = [
		{"name": "1280x720", "size": Vector2i(1280, 720)},
		{"name": "1920x1080", "size": Vector2i(1920, 1080)}
	]
	
	for res in resolutions:
		DisplayServer.window_set_size(res["size"])
		get_tree().root.size = res["size"]
		for i in range(12):
			await get_tree().process_frame
		
		var img = get_viewport().get_texture().get_image()
		if img:
			var path = "res://docs/ui_captures/phase1_gallery_%s.png" % res["name"]
			img.save_png(path)
			print("Saved: %s (%dx%d)" % [path, img.get_width(), img.get_height()])
	
	print("[PHASE 1] UIGallery screenshots saved successfully!")
	get_tree().quit(0)
