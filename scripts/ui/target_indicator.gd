class_name TargetIndicator
extends Control

const IconRegistry = preload("res://scripts/ui/icon_registry.gd")
const UIConstants = preload("res://scripts/ui/ui_constants.gd")

@export var target_name: String = "Enemigo":
	set(val):
		target_name = val
		if name_label:
			name_label.text = target_name

@onready var container: Control = $Panel
@onready var frame_border: NinePatchRect = $Panel/FrameBorder
@onready var name_label: Label = $Panel/HBox/InfoVBox/TopRow/NameLabel
@onready var trail_bar: TextureProgressBar = $Panel/HBox/InfoVBox/BarContainer/TrailBar
@onready var hp_bar: TextureProgressBar = $Panel/HBox/InfoVBox/BarContainer/HpBar
@onready var hp_label: Label = $Panel/HBox/InfoVBox/TopRow/HpLabel
@onready var icon_rect: TextureRect = $Panel/HBox/IconFrame/Icon
@onready var boss_badge: Label = $Panel/HBox/InfoVBox/TopRow/BossBadge

var current_target: Node = null
var hide_timer: float = 0.0
var _trail_tween: Tween = null
var _last_hp: float = -1.0

func _ready() -> void:
	modulate.a = 0.0
	visible = false
	if icon_rect:
		icon_rect.texture = IconRegistry.get_icon("ui", "target_reticule")
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = Control.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _process(delta: float) -> void:
	if current_target and is_instance_valid(current_target):
		hide_timer = 2.5
		if "current_health" in current_target and "max_health" in current_target:
			update_target(
				_get_enemy_display_name(current_target),
				current_target.current_health,
				current_target.max_health,
				current_target.get("is_boss") == true
			)
			if current_target.current_health <= 0.0:
				current_target = null
	else:
		if visible and modulate.a > 0.0:
			hide_timer -= delta
			if hide_timer <= 0.0:
				var tween = create_tween()
				tween.tween_property(self, "modulate:a", 0.0, 0.25)
				tween.tween_callback(func(): visible = false)

func set_target_node(target: Node) -> void:
	if target == current_target and visible:
		return
	current_target = target
	hide_timer = 3.0
	_last_hp = -1.0
	
	if current_target and is_instance_valid(current_target):
		visible = true
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.15)
		update_target(
			_get_enemy_display_name(current_target),
			current_target.get("current_health"),
			current_target.get("max_health"),
			current_target.get("is_boss") == true
		)

func update_target(t_name: String, cur_hp: float, max_hp: float, is_boss: bool = false) -> void:
	if not is_inside_tree():
		return
	
	if name_label:
		name_label.text = t_name
		if is_boss:
			name_label.add_theme_color_override("font_color", UIConstants.GOLD_BRIGHT)
			name_label.add_theme_font_size_override("font_size", 14)
		else:
			name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.8, 1.0))
			name_label.add_theme_font_size_override("font_size", 12)
	
	if boss_badge:
		boss_badge.visible = is_boss
	
	if frame_border:
		if is_boss:
			frame_border.modulate = UIConstants.GOLD_BASE
			custom_minimum_size = Vector2(460, 60)
			offset_left = -230.0
			offset_right = 230.0
		else:
			frame_border.modulate = Color(0.9, 0.35, 0.35, 0.95)
			custom_minimum_size = Vector2(340, 52)
			offset_left = -170.0
			offset_right = 170.0
	
	var safe_max = max(1.0, max_hp)
	var safe_cur = clamp(cur_hp, 0.0, safe_max)
	
	if hp_bar and trail_bar:
		hp_bar.max_value = safe_max
		trail_bar.max_value = safe_max
		
		if _last_hp >= 0.0 and safe_cur < _last_hp:
			# Daño recibido: barra principal cae rápido, trail retrasado
			hp_bar.value = safe_cur
			if _trail_tween and _trail_tween.is_valid():
				_trail_tween.kill()
			_trail_tween = create_tween()
			_trail_tween.tween_interval(UIConstants.DURATION_TRAIL_DELAY)
			_trail_tween.tween_property(trail_bar, "value", safe_cur, UIConstants.DURATION_TRAIL_DROP).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			hp_bar.value = safe_cur
			trail_bar.value = safe_cur
	
	_last_hp = safe_cur
	
	if hp_label:
		var pct = int((safe_cur / safe_max) * 100.0)
		hp_label.text = "%d / %d (%d%%)" % [max(0, int(safe_cur)), int(safe_max), pct]

func _get_enemy_display_name(enemy: Node) -> String:
	if enemy.get("is_boss") == true:
		return "👑 SEÑOR NIGROMANTE DE LAS RUINAS"
	if "enemy_type" in enemy:
		match enemy.enemy_type:
			0: return "Duende Asaltante"
			1: return "Lancero Esquelético"
			2: return "Arquero Esquelético"
			3: return "Diablillo Ígneo"
			4: return "Diablillo Sombrío"
	return "Hostil Arcano"
