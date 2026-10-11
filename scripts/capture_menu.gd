extends Node

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshot_menu.png")
		print("MENU_SCREENSHOT_SAVED_SUCCESS")
	get_tree().quit()
