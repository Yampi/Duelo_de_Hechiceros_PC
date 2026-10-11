class_name QuickSlot
extends Control

const IconRegistry = preload("res://scripts/ui/icon_registry.gd")
const UIConstants = preload("res://scripts/ui/ui_constants.gd")

signal quick_slot_used(action: String)

@export var action_key: String = "Q":
	set(val):
		action_key = val
		if hotkey_label:
			hotkey_label.text = "[%s]" % action_key

@export var item_id: String = "potion_health":
	set(val):
		item_id = val
		_update_icon()

@onready var icon_rect: TextureRect = $Icon
@onready var count_label: Label = $CountBadge/CountLabel
@onready var hotkey_label: Label = $HotkeyBadge/HotkeyLabel
@onready var cooldown_overlay: ColorRect = $CooldownOverlay
@onready var btn: Button = $Button

var count: int = 0:
	set(val):
		count = val
		_update_count()

var _is_on_cooldown: bool = false

func _ready() -> void:
	pivot_offset = size * 0.5
	if hotkey_label:
		hotkey_label.text = "[%s]" % action_key
	if btn:
		btn.pressed.connect(_on_pressed)
		btn.mouse_entered.connect(_on_mouse_entered)
		btn.mouse_exited.connect(_on_mouse_exited)
	_update_icon()
	_update_count()
	set_cooldown(0.0)

func _update_icon() -> void:
	if icon_rect:
		var tex = IconRegistry.get_icon("items", item_id)
		if tex:
			icon_rect.texture = tex

func _update_count() -> void:
	if count_label:
		count_label.text = "x%d" % count
	if icon_rect:
		icon_rect.modulate = Color.WHITE if count > 0 else Color(0.4, 0.4, 0.4, 0.6)

func set_cooldown(progress: float) -> void:
	_is_on_cooldown = (progress > 0.001)
	if cooldown_overlay and cooldown_overlay.material:
		var mat = cooldown_overlay.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("progress", clamp(progress, 0.0, 1.0))
	cooldown_overlay.visible = _is_on_cooldown

func trigger_use() -> void:
	pivot_offset = size * 0.5
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.92, 0.92), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _on_pressed() -> void:
	trigger_use()
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("click")
	quick_slot_used.emit(action_key)

func _on_mouse_entered() -> void:
	pivot_offset = size * 0.5
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.08)
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("hover")

func _on_mouse_exited() -> void:
	pivot_offset = size * 0.5
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)
