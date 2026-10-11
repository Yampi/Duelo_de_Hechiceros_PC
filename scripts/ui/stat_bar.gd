class_name StatBar
extends Control

const IconRegistry = preload("res://scripts/ui/icon_registry.gd")
const UIConstants = preload("res://scripts/ui/ui_constants.gd")

enum BarType { HEALTH, MANA, STAMINA, CAST }

@export var bar_type: BarType = BarType.HEALTH:
	set(val):
		bar_type = val
		_apply_bar_type()

@export var bar_title: String = "SALUD":
	set(val):
		bar_title = val
		if title_label:
			title_label.text = bar_title

@export var current_value: float = 100.0:
	set(val):
		current_value = val
		_update_values()

@export var max_value: float = 100.0:
	set(val):
		max_value = max(1.0, val)
		_update_values()

@export var sub_text: String = "":
	set(val):
		sub_text = val
		if sub_label:
			sub_label.text = sub_text

@onready var trail_bar: TextureProgressBar = $HBox/BarVBox/BarContainer/TrailBar
@onready var progress_bar: TextureProgressBar = $HBox/BarVBox/BarContainer/ProgressBar
@onready var icon_frame: Control = $HBox/IconFrame
@onready var icon_rect: TextureRect = $HBox/IconFrame/Icon
@onready var title_label: Label = $HBox/BarVBox/TopRow/TitleLabel
@onready var value_label: Label = $HBox/BarVBox/TopRow/ValueLabel
@onready var sub_label: Label = $HBox/BarVBox/TopRow/SubLabel

var _trail_tween: Tween = null
var _low_hp_tween: Tween = null
var _is_low_pulse_active: bool = false

func _ready() -> void:
	_apply_bar_type()
	_update_values()

func _apply_bar_type() -> void:
	if not is_inside_tree():
		return
	match bar_type:
		BarType.HEALTH:
			bar_title = "SALUD"
			if icon_rect:
				icon_rect.texture = IconRegistry.get_icon("items", "potion_health")
				icon_rect.modulate = Color(1.0, 1.0, 1.0)
				icon_rect.tooltip_text = "Salud del Hechicero"
			if progress_bar:
				progress_bar.texture_progress = preload("res://assets/ui/bars/bar_hp_fill.png")
				progress_bar.tint_progress = Color(1.0, 1.0, 1.0)
			if trail_bar:
				trail_bar.texture_progress = preload("res://assets/ui/bars/bar_hp_fill.png")
				trail_bar.tint_progress = UIConstants.HP_TRAIL
		BarType.MANA:
			bar_title = "MANÁ"
			if icon_rect:
				icon_rect.texture = IconRegistry.get_icon("items", "potion_mana")
				icon_rect.modulate = Color(1.0, 1.0, 1.0)
				icon_rect.tooltip_text = "Maná Arcano Territorial"
			if progress_bar:
				progress_bar.texture_progress = preload("res://assets/ui/bars/bar_mana_fill.png")
				progress_bar.tint_progress = Color(1.0, 1.0, 1.0)
			if trail_bar:
				trail_bar.texture_progress = preload("res://assets/ui/bars/bar_mana_fill.png")
				trail_bar.tint_progress = UIConstants.MANA_TRAIL
		BarType.STAMINA:
			bar_title = "VIGOR"
			if icon_rect:
				icon_rect.texture = IconRegistry.get_icon("status", "shield_physical")
				icon_rect.modulate = Color(0.35, 1.0, 0.45)
				icon_rect.tooltip_text = "Vigor Físico"
			if progress_bar:
				progress_bar.texture_progress = preload("res://assets/ui/bars/bar_stamina_fill.png")
				progress_bar.tint_progress = Color(1.0, 1.0, 1.0)
			if trail_bar:
				trail_bar.texture_progress = preload("res://assets/ui/bars/bar_stamina_fill.png")
				trail_bar.tint_progress = Color(0.7, 1.0, 0.5, 0.8)
		BarType.CAST:
			bar_title = "LANZAMIENTO"
			if icon_rect:
				icon_rect.texture = IconRegistry.get_icon("spells", "magic_bolt")
				icon_rect.modulate = Color(1.0, 0.85, 0.3)
				icon_rect.tooltip_text = "Canalización de Hechizo"
			if progress_bar:
				progress_bar.texture_progress = preload("res://assets/ui/bars/bar_cast_fill.png")
				progress_bar.tint_progress = Color(1.0, 1.0, 1.0)
			if trail_bar:
				trail_bar.texture_progress = preload("res://assets/ui/bars/bar_cast_fill.png")
				trail_bar.tint_progress = Color(1.0, 0.9, 0.5, 0.8)
	
	if title_label:
		title_label.text = bar_title

func set_values(cur: float, max_val: float, extra_info: String = "") -> void:
	var old_val = current_value
	max_value = max(1.0, max_val)
	current_value = clamp(cur, 0.0, max_value)
	if extra_info != "":
		sub_text = extra_info
	
	if progress_bar and trail_bar:
		progress_bar.max_value = max_value
		trail_bar.max_value = max_value
		
		if current_value < old_val:
			# DAÑO / GASTO: la barra principal cae rápido; el trail espera y luego cae suavemente
			progress_bar.value = current_value
			
			if _trail_tween and _trail_tween.is_valid():
				_trail_tween.kill()
			_trail_tween = create_tween()
			_trail_tween.tween_interval(UIConstants.DURATION_TRAIL_DELAY)
			_trail_tween.tween_property(trail_bar, "value", current_value, UIConstants.DURATION_TRAIL_DROP).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			# CURACIÓN / RECUPERACIÓN: sube de inmediato con destello
			progress_bar.value = current_value
			trail_bar.value = current_value
			_flash_heal()
	
	if value_label:
		value_label.text = "%d / %d" % [int(current_value), int(max_value)]
	if sub_label:
		sub_label.text = sub_text
	
	_check_low_hp_pulse()

func _flash_heal() -> void:
	if not icon_frame:
		return
	var orig_mod = Color.WHITE
	var flash_col = Color(1.3, 1.3, 1.3, 1.0)
	if bar_type == BarType.HEALTH:
		flash_col = Color(0.4, 1.8, 0.6, 1.0)
	elif bar_type == BarType.MANA:
		flash_col = Color(0.4, 1.4, 2.0, 1.0)
	
	var tween = create_tween()
	tween.tween_property(icon_frame, "modulate", flash_col, 0.1)
	tween.tween_property(icon_frame, "modulate", orig_mod, 0.25)

func _check_low_hp_pulse() -> void:
	if bar_type != BarType.HEALTH:
		return
	
	var is_low = (current_value / max_value) <= 0.25
	if is_low and not _is_low_pulse_active:
		_is_low_pulse_active = true
		if _low_hp_tween and _low_hp_tween.is_valid():
			_low_hp_tween.kill()
		_low_hp_tween = create_tween().set_loops()
		_low_hp_tween.tween_property(icon_frame, "modulate", Color(1.6, 0.4, 0.4, 1.0), 0.35).set_trans(Tween.TRANS_SINE)
		_low_hp_tween.tween_property(icon_frame, "modulate", Color.WHITE, 0.35).set_trans(Tween.TRANS_SINE)
	elif not is_low and _is_low_pulse_active:
		_is_low_pulse_active = false
		if _low_hp_tween and _low_hp_tween.is_valid():
			_low_hp_tween.kill()
		icon_frame.modulate = Color.WHITE

func _update_values() -> void:
	if not is_inside_tree():
		return
	if progress_bar:
		progress_bar.max_value = max_value
		progress_bar.value = current_value
	if trail_bar:
		trail_bar.max_value = max_value
		trail_bar.value = current_value
	if value_label:
		value_label.text = "%d / %d" % [int(current_value), int(max_value)]
	if title_label:
		title_label.text = bar_title
	if sub_label:
		sub_label.text = sub_text
	_check_low_hp_pulse()
