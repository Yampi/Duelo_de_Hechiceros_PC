class_name CursorManager
extends RefCounted

enum CursorType {
	DEFAULT,
	TARGET,
	ENEMY,
	INTERACT
}

static var _current_type: CursorType = CursorType.DEFAULT
static var _initialized: bool = false

static var _tex_default: Resource = null
static var _tex_target: Resource = null
static var _tex_enemy: Resource = null
static var _tex_interact: Resource = null

static func _load_cursor_texture(path: String) -> Resource:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res:
			return res
	var global_p = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global_p):
		var img = Image.load_from_file(global_p)
		if img:
			return ImageTexture.create_from_image(img)
	return null

static func init_cursors() -> void:
	if _initialized:
		return
	
	_tex_default = _load_cursor_texture("res://assets/ui/cursors/cursor_default.png")
	_tex_target = _load_cursor_texture("res://assets/ui/cursors/cursor_target.png")
	_tex_enemy = _load_cursor_texture("res://assets/ui/cursors/cursor_enemy.png")
	_tex_interact = _load_cursor_texture("res://assets/ui/cursors/cursor_interact.png")
	
	_initialized = true
	set_cursor(CursorType.DEFAULT)

static func set_cursor(type: CursorType) -> void:
	_current_type = type
	match type:
		CursorType.DEFAULT:
			if _tex_default:
				Input.set_custom_mouse_cursor(_tex_default, Input.CURSOR_ARROW, Vector2(2, 2))
		CursorType.TARGET:
			if _tex_target:
				Input.set_custom_mouse_cursor(_tex_target, Input.CURSOR_ARROW, Vector2(16, 16))
		CursorType.ENEMY:
			if _tex_enemy:
				Input.set_custom_mouse_cursor(_tex_enemy, Input.CURSOR_ARROW, Vector2(16, 16))
		CursorType.INTERACT:
			if _tex_interact:
				Input.set_custom_mouse_cursor(_tex_interact, Input.CURSOR_ARROW, Vector2(16, 16))

static func get_current_cursor() -> CursorType:
	return _current_type
