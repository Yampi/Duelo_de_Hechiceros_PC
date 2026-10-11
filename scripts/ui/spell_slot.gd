class_name SpellSlot
extends Control

const IconRegistry = preload("res://scripts/ui/icon_registry.gd")
const UIConstants = preload("res://scripts/ui/ui_constants.gd")

signal slot_pressed(slot_index: int)

@export var slot_index: int = 1
@export var spell_id: String = "magic_bolt"
@export var spell_name: String = "Centella Arcana"
@export var mana_cost: float = 5.0
@export var hotkey_text: String = "[1]"
@export var spell_desc: String = ""

@export var icon_texture: Texture2D:
	set(val):
		icon_texture = val
		_update_ui()

@export var icon_color: Color = Color.WHITE:
	set(val):
		icon_color = val
		_update_ui()

@export var is_selected: bool = false:
	set(val):
		is_selected = val
		_update_selection()

@export var is_locked: bool = false:
	set(val):
		is_locked = val
		_update_ui()

@onready var btn: Button = $Button
@onready var icon_rect: TextureRect = $Icon
@onready var frame_rect: NinePatchRect = $FrameBorder
@onready var select_glow: NinePatchRect = $SelectGlow
@onready var hotkey_label: Label = $HotkeyBadge/HotkeyLabel
@onready var cost_label: Label = $CostBadge/CostLabel
@onready var cooldown_overlay: ColorRect = $CooldownOverlay
@onready var flash_overlay: ColorRect = $FlashOverlay

var _can_afford_mana: bool = true
var _breathing_tween: Tween = null
var _is_on_cooldown: bool = false
var _base_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	pivot_offset = size * 0.5
	resized.connect(func(): pivot_offset = size * 0.5)
	_base_position = position
	
	if btn:
		btn.pressed.connect(_on_btn_pressed)
		btn.mouse_entered.connect(_on_mouse_entered)
		btn.mouse_exited.connect(_on_mouse_exited)
	
	_update_ui()
	_update_selection()
	set_cooldown(0.0)
	_start_breathing_glow()

func _update_ui() -> void:
	if not is_inside_tree():
		return
	
	pivot_offset = size * 0.5
	
	if is_locked:
		if icon_rect:
			icon_rect.texture = IconRegistry.get_icon("ui", "ability_locked")
			icon_rect.modulate = Color(0.85, 0.85, 0.85, 0.9)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.texture_filter = Control.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if cost_label:
			cost_label.text = "BLOQ."
			cost_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6, 0.8))
		if hotkey_label:
			hotkey_label.text = hotkey_text
		var locked_tip = "Habilidad Bloqueada (%s)" % hotkey_text
		if btn:
			btn.tooltip_text = locked_tip
		tooltip_text = locked_tip
		return
	
	# Sincronizar datos desde GameManager.spells
	var gm = get_node_or_null("/root/GameManager")
	if gm and "spells" in gm and gm.spells.has(slot_index):
		var sp = gm.spells[slot_index]
		spell_id = sp.get("id", spell_id)
		spell_name = sp.get("name", spell_name)
		mana_cost = sp.get("cost", mana_cost)
		spell_desc = sp.get("desc", spell_desc)
	
	var tex = icon_texture
	if not tex and not spell_id.is_empty():
		tex = IconRegistry.get_icon("spells", spell_id)
	
	if icon_rect:
		if tex:
			icon_rect.texture = tex
		icon_rect.modulate = icon_color
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = Control.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	if hotkey_label:
		hotkey_label.text = hotkey_text
	if cost_label:
		cost_label.text = "%d MP" % int(mana_cost)
	
	var full_tip = "%s (%d MP) %s — %s" % [spell_name, int(mana_cost), hotkey_text, spell_desc]
	if btn:
		btn.tooltip_text = full_tip
	tooltip_text = full_tip

func _update_selection() -> void:
	if not is_inside_tree():
		return
	if select_glow:
		select_glow.visible = is_selected
		if is_selected:
			_pulse_selection_ring()
	
	if frame_rect:
		if is_selected:
			frame_rect.modulate = Color(1.3, 1.15, 0.45, 1.0)
		elif not _can_afford_mana:
			frame_rect.modulate = Color(0.85, 0.3, 0.3, 0.85)
		else:
			frame_rect.modulate = Color(0.75, 0.7, 0.58, 0.95)

func _start_breathing_glow() -> void:
	if _breathing_tween and _breathing_tween.is_valid():
		_breathing_tween.kill()
	
	if is_locked:
		return
	
	_breathing_tween = create_tween().set_loops()
	_breathing_tween.tween_property(frame_rect, "modulate:a", 0.75, 1.2).set_trans(Tween.TRANS_SINE)
	_breathing_tween.tween_property(frame_rect, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)

func _pulse_selection_ring() -> void:
	if not select_glow:
		return
	var tween = create_tween().set_loops()
	tween.tween_property(select_glow, "modulate", Color(1.7, 1.45, 0.55, 1.0), 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(select_glow, "modulate", Color(1.2, 1.0, 0.35, 0.8), 0.6).set_trans(Tween.TRANS_SINE)

func update_mana_status(current_mana: float) -> void:
	if is_locked:
		return
	_can_afford_mana = (current_mana >= mana_cost)
	if cost_label:
		if _can_afford_mana:
			cost_label.add_theme_color_override("font_color", UIConstants.ARCANE_CYAN)
		else:
			cost_label.add_theme_color_override("font_color", UIConstants.DANGER_RED)
	if icon_rect:
		if _can_afford_mana:
			icon_rect.modulate = icon_color
		else:
			icon_rect.modulate = Color(icon_color.r * 0.45, icon_color.g * 0.45, icon_color.b * 0.45, 0.85)
	if frame_rect and not is_selected:
		if not _can_afford_mana:
			frame_rect.modulate = Color(0.85, 0.3, 0.3, 0.85)
		else:
			frame_rect.modulate = Color(0.75, 0.7, 0.58, 0.95)

func set_cooldown(progress: float) -> void:
	# progress: 0.0 (listo) a 1.0 (en enfriamiento maximo)
	_is_on_cooldown = (progress > 0.001)
	if cooldown_overlay and cooldown_overlay.material:
		var mat = cooldown_overlay.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("progress", clamp(progress, 0.0, 1.0))
	cooldown_overlay.visible = _is_on_cooldown

func flash_cast() -> void:
	if flash_overlay:
		flash_overlay.modulate = Color(1.5, 1.5, 1.5, 0.9)
		var tween = create_tween()
		tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	pivot_offset = size * 0.5
	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func shake_no_mana() -> void:
	# Feedback sensorial por falta de mana: shake rapido y sonido de fallo
	var orig_x = position.x
	var tween = create_tween()
	tween.tween_property(self, "position:x", orig_x - 3.0, 0.03)
	tween.tween_property(self, "position:x", orig_x + 3.0, 0.04)
	tween.tween_property(self, "position:x", orig_x - 2.0, 0.03)
	tween.tween_property(self, "position:x", orig_x, 0.03)
	
	# Sonido de error UI
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("error")

func _on_btn_pressed() -> void:
	if is_locked:
		return
	if not _can_afford_mana:
		shake_no_mana()
		return
	slot_pressed.emit(slot_index)
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("click")
	pivot_offset = size * 0.5
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)

func _on_mouse_entered() -> void:
	pivot_offset = size * 0.5
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.08)
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("hover")

func _on_mouse_exited() -> void:
	pivot_offset = size * 0.5
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)
