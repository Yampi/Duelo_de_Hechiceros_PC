class_name FantasyButton
extends Button

enum ButtonVariant { PRIMARY, SECONDARY, DANGER }

@export var variant: ButtonVariant = ButtonVariant.PRIMARY:
	set(val):
		variant = val
		_apply_style_variant()

@export var icon_texture: Texture2D:
	set(val):
		icon_texture = val
		_update_icon()

@export var button_text: String = "BOTÓN":
	set(val):
		button_text = val
		text = button_text

# StyleBox caches
static var _styles_initialized: bool = false
static var _primary_styles: Dictionary = {}
static var _secondary_styles: Dictionary = {}
static var _danger_styles: Dictionary = {}

func _ready() -> void:
	_ensure_styles()
	_apply_style_variant()
	_update_icon()
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	pressed.connect(_on_pressed)

func _update_icon() -> void:
	if icon_texture:
		icon = icon_texture
		expand_icon = true

func _ensure_styles() -> void:
	if _styles_initialized:
		return
	_styles_initialized = true
	
	var tex_normal = load("res://assets/ui/buttons/btn_rect_normal.png")
	var tex_hover = load("res://assets/ui/buttons/btn_rect_hover.png")
	var tex_pressed = load("res://assets/ui/buttons/btn_rect_pressed.png")
	var tex_disabled = load("res://assets/ui/buttons/btn_rect_disabled.png")
	var tex_focus = load("res://assets/ui/frames/panel-border-000.png")
	
	# Secondary Styles (Hierro forjado)
	_secondary_styles["normal"] = _create_stylebox(tex_normal, Color(0.12, 0.14, 0.18, 0.94))
	_secondary_styles["hover"] = _create_stylebox(tex_hover, Color(0.20, 0.25, 0.32, 1.0))
	_secondary_styles["pressed"] = _create_stylebox(tex_pressed, Color(0.08, 0.09, 0.12, 1.0))
	_secondary_styles["disabled"] = _create_stylebox(tex_disabled, Color(0.10, 0.11, 0.13, 0.5))
	_secondary_styles["focus"] = _create_stylebox(tex_focus, Color(0.65, 0.70, 0.80, 0.85))
	
	# Danger Styles (Carmesí nigromante)
	_danger_styles["normal"] = _create_stylebox(tex_normal, Color(0.30, 0.09, 0.10, 0.96))
	_danger_styles["hover"] = _create_stylebox(tex_hover, Color(0.48, 0.12, 0.14, 1.0))
	_danger_styles["pressed"] = _create_stylebox(tex_pressed, Color(0.18, 0.05, 0.06, 1.0))
	_danger_styles["disabled"] = _create_stylebox(tex_disabled, Color(0.14, 0.08, 0.09, 0.5))
	_danger_styles["focus"] = _create_stylebox(tex_focus, Color(1.0, 0.35, 0.35, 0.90))

func _create_stylebox(tex: Texture2D, mod: Color) -> StyleBoxTexture:
	var sb = StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 18.0
	sb.texture_margin_top = 18.0
	sb.texture_margin_right = 18.0
	sb.texture_margin_bottom = 18.0
	sb.modulate_color = mod
	return sb

func _apply_style_variant() -> void:
	if not is_inside_tree():
		return
	_ensure_styles()
	
	match variant:
		ButtonVariant.PRIMARY:
			# Uses the primary styling configured in FantasyTheme.tres
			remove_theme_stylebox_override("normal")
			remove_theme_stylebox_override("hover")
			remove_theme_stylebox_override("pressed")
			remove_theme_stylebox_override("disabled")
			remove_theme_stylebox_override("focus")
			add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1.0))
			add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
			add_theme_color_override("font_focus_color", Color(1.0, 0.95, 0.75, 1.0))
		ButtonVariant.SECONDARY:
			add_theme_stylebox_override("normal", _secondary_styles["normal"])
			add_theme_stylebox_override("hover", _secondary_styles["hover"])
			add_theme_stylebox_override("pressed", _secondary_styles["pressed"])
			add_theme_stylebox_override("disabled", _secondary_styles["disabled"])
			add_theme_stylebox_override("focus", _secondary_styles["focus"])
			add_theme_color_override("font_color", Color(0.85, 0.88, 0.92, 1.0))
			add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
			add_theme_color_override("font_focus_color", Color(0.9, 0.95, 1.0, 1.0))
		ButtonVariant.DANGER:
			add_theme_stylebox_override("normal", _danger_styles["normal"])
			add_theme_stylebox_override("hover", _danger_styles["hover"])
			add_theme_stylebox_override("pressed", _danger_styles["pressed"])
			add_theme_stylebox_override("disabled", _danger_styles["disabled"])
			add_theme_stylebox_override("focus", _danger_styles["focus"])
			add_theme_color_override("font_color", Color(1.0, 0.75, 0.75, 1.0))
			add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.92, 1.0))
			add_theme_color_override("font_focus_color", Color(1.0, 0.85, 0.85, 1.0))

func _on_mouse_entered() -> void:
	if not disabled:
		pivot_offset = size * 0.5
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_play_sfx("hover")

func _on_mouse_exited() -> void:
	if not has_focus():
		pivot_offset = size * 0.5
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_focus_entered() -> void:
	if not disabled:
		pivot_offset = size * 0.5
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_focus_exited() -> void:
	pivot_offset = size * 0.5
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_pressed() -> void:
	pivot_offset = size * 0.5
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.96, 0.96), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.03 if has_focus() else 1.0, 1.03 if has_focus() else 1.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_play_sfx("click")

func _play_sfx(type: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui(type)
