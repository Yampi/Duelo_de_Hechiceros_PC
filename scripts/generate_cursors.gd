extends SceneTree

func _init() -> void:
	_generate_default_cursor()
	_generate_target_cursor()
	_generate_enemy_cursor()
	_generate_interact_cursor()
	print("[CURSORS] All 4 game cursors generated successfully in assets/ui/cursors/")
	quit(0)

func _generate_default_cursor() -> void:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var col_gold = Color(0.95, 0.82, 0.38, 1.0)
	var col_gold_bright = Color(1.0, 0.95, 0.7, 1.0)
	var col_dark = Color(0.1, 0.12, 0.18, 1.0)
	var col_outline = Color(0.0, 0.0, 0.0, 0.95)
	
	# Draw fantasy gauntlet arrow pointer (starts at 0,0)
	for y in range(22):
		for x in range(min(y + 1, 16)):
			if x == 0 or y == x or (y >= 14 and (x == y - 6 or y == 15)):
				img.set_pixel(x, y, col_outline)
			elif x == 1 or y == x + 1:
				img.set_pixel(x, y, col_gold_bright)
			else:
				img.set_pixel(x, y, col_gold)
	
	# Add shadow outline
	_apply_outline(img)
	img.save_png("res://assets/ui/cursors/cursor_default.png")

func _generate_target_cursor() -> void:
	# Load reticule and scale cleanly to 32x32
	var src = Image.load_from_file("res://assets/ui/icons/target/target_reticule.png")
	if src:
		src.resize(32, 32, Image.INTERPOLATE_LANCZOS)
		# Tint cyan
		for y in range(32):
			for x in range(32):
				var p = src.get_pixel(x, y)
				if p.a > 0.1:
					src.set_pixel(x, y, Color(0.3, 0.9, 1.0, p.a))
		src.save_png("res://assets/ui/cursors/cursor_target.png")

func _generate_enemy_cursor() -> void:
	var src = Image.load_from_file("res://assets/ui/icons/target/target_enemy.png")
	if src:
		src.resize(32, 32, Image.INTERPOLATE_LANCZOS)
		for y in range(32):
			for x in range(32):
				var p = src.get_pixel(x, y)
				if p.a > 0.1:
					src.set_pixel(x, y, Color(1.0, 0.25, 0.25, p.a))
		src.save_png("res://assets/ui/cursors/cursor_enemy.png")

func _generate_interact_cursor() -> void:
	var src = Image.load_from_file("res://assets/ui/icons/target/target_reticule.png")
	if src:
		src.resize(32, 32, Image.INTERPOLATE_LANCZOS)
		for y in range(32):
			for x in range(32):
				var p = src.get_pixel(x, y)
				if p.a > 0.1:
					src.set_pixel(x, y, Color(1.0, 0.85, 0.3, p.a))
		src.save_png("res://assets/ui/cursors/cursor_interact.png")

func _apply_outline(img: Image) -> void:
	var copy = img.duplicate()
	for y in range(1, 31):
		for x in range(1, 31):
			if copy.get_pixel(x, y).a < 0.1:
				var has_solid_neighbor = false
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						if copy.get_pixel(x + dx, y + dy).a > 0.5:
							has_solid_neighbor = true
							break
				if has_solid_neighbor:
					img.set_pixel(x, y, Color(0, 0, 0, 0.85))
