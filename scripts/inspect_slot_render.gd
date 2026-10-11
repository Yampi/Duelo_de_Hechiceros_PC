extends SceneTree

func _init() -> void:
	var g = load("res://scenes/ui/UIGallery.tscn").instantiate()
	root.add_child(g)
	for i in range(10):
		await process_frame
	var s = g.get_node("Scroll/Content/SlotsSection/HBoxSlots/Slot1")
	var gpos = s.global_position
	var img = root.get_texture().get_image()
	print("Slot1 global_pos: ", gpos, " size: ", s.size)
	var center_pixel = img.get_pixel(int(gpos.x + 28), int(gpos.y + 28))
	print("Center pixel at slot1: ", center_pixel)
	quit(0)
