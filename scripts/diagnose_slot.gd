extends SceneTree

func _init() -> void:
	var g = load("res://scenes/ui/UIGallery.tscn").instantiate()
	root.add_child(g)
	for i in range(3):
		await process_frame
	var s = g.get_node("Scroll/Content/SlotsSection/HBoxSlots/Slot1")
	var icon = s.get_node("Icon")
	print("Slot size: ", s.size)
	print("Icon size: ", icon.size)
	print("Icon pos: ", icon.position)
	print("Icon texture: ", icon.texture)
	print("Icon modulate: ", icon.modulate)
	print("Icon visible: ", icon.visible)
	quit(0)
