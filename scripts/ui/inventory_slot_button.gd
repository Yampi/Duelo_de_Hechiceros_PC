class_name InventorySlotButton
extends Button

const ItemDefinition = preload("res://scripts/inventory/item_definition.gd")
const UIConstants = preload("res://scripts/ui/ui_constants.gd")

signal slot_clicked(index: int)
signal slot_right_clicked(index: int)
signal slot_swapped(from_index: int, to_index: int)

var slot_index: int = 0
var item_id: String = ""
var item_count: int = 0
var item_def: ItemDefinition = null
var is_slot_selected: bool = false

var icon_rect: TextureRect = null
var count_label: Label = null
var border_style: StyleBoxFlat = null

func _init(idx: int = 0) -> void:
	slot_index = idx
	custom_minimum_size = Vector2(60, 60)
	pivot_offset = Vector2(30, 30)
	focus_mode = Control.FOCUS_ALL
	name = "Slot_%d" % slot_index

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	_setup_nodes()
	_update_style()

func _setup_nodes() -> void:
	icon_rect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = 6
	icon_rect.offset_top = 6
	icon_rect.offset_right = -6
	icon_rect.offset_bottom = -6
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_rect)
	
	count_label = Label.new()
	count_label.name = "CountLabel"
	count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.offset_left = -30
	count_label.offset_top = -20
	count_label.offset_right = -4
	count_label.offset_bottom = -2
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_font_size_override("font_size", 11)
	count_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	count_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	count_label.add_theme_constant_override("shadow_offset_x", 1)
	count_label.add_theme_constant_override("shadow_offset_y", 1)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(count_label)

func set_item(def: ItemDefinition, count: int) -> void:
	item_def = def
	item_count = count
	item_id = def.id if def else ""
	
	if not icon_rect:
		return
	
	if def:
		icon_rect.texture = def.icon
		icon_rect.visible = true
		count_label.text = "x%d" % count if count > 1 else ""
		count_label.visible = count > 1
		
		var category_name = "Consumible"
		match def.category:
			"material": category_name = "Material"
			"quest": category_name = "Objeto Clave"
		
		var use_hint = "\n\n[Clic Izq]: Seleccionar\n[Clic Der]: Usar\n[Arrastrar]: Reorganizar" if def.is_usable else "\n\n[Clic Izq]: Seleccionar\n[Arrastrar]: Reorganizar"
		tooltip_text = "%s\n[%s]\n%s%s" % [def.name, category_name, def.description, use_hint]
	else:
		icon_rect.texture = null
		icon_rect.visible = false
		count_label.text = ""
		count_label.visible = false
		tooltip_text = "Casilla Vacía"
	
	_update_style()

func set_slot_selected(sel: bool) -> void:
	is_slot_selected = sel
	_update_style()

func _update_style() -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.94)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	
	var border_col: Color
	var border_w: int = 1
	
	if is_slot_selected:
		border_col = UIConstants.GOLD_BASE
		border_w = 2
	elif item_def:
		match item_def.category:
			"consumable":
				border_col = Color(0.2, 0.88, 0.5, 0.85)
			"material":
				border_col = Color(0.95, 0.65, 0.25, 0.85)
			"quest":
				border_col = Color(0.85, 0.45, 1.0, 0.95)
			_:
				border_col = Color(0.4, 0.5, 0.6, 0.7)
	else:
		border_col = Color(0.22, 0.26, 0.33, 0.45)
	
	sb.border_color = border_col
	sb.border_width_left = border_w
	sb.border_width_right = border_w
	sb.border_width_top = border_w
	sb.border_width_bottom = border_w
	
	# Apply style to all states
	add_theme_stylebox_override("normal", sb)
	
	var sb_hover = sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.10, 0.14, 0.20, 0.96)
	sb_hover.border_color = border_col.lightened(0.2)
	add_theme_stylebox_override("hover", sb_hover)
	
	var sb_focus = sb.duplicate() as StyleBoxFlat
	sb_focus.border_color = UIConstants.GOLD_BASE
	sb_focus.border_width_left = 2
	sb_focus.border_width_right = 2
	sb_focus.border_width_top = 2
	sb_focus.border_width_bottom = 2
	add_theme_stylebox_override("focus", sb_focus)
	
	var sb_pressed = sb.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = Color(0.04, 0.05, 0.08, 0.98)
	add_theme_stylebox_override("pressed", sb_pressed)

func _on_mouse_entered() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("hover")
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_focus_entered() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_focus_exited() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("click")
	slot_clicked.emit(slot_index)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_ui"):
				am.play_ui("click")
			slot_right_clicked.emit(slot_index)
			accept_event()

# Drag and drop implementation
func _get_drag_data(_at_position: Vector2) -> Variant:
	if not item_def or item_id.is_empty():
		return null
	
	var preview = Control.new()
	preview.custom_minimum_size = Vector2(48, 48)
	
	var tex_rect = TextureRect.new()
	tex_rect.texture = item_def.icon
	tex_rect.custom_minimum_size = Vector2(44, 44)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.position = Vector2(-22, -22)
	preview.add_child(tex_rect)
	
	set_drag_preview(preview)
	
	return {
		"type": "inventory_slot",
		"from_index": slot_index,
		"item_id": item_id
	}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type", "") == "inventory_slot"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.has("from_index"):
		var from_idx = data["from_index"] as int
		if from_idx != slot_index:
			slot_swapped.emit(from_idx, slot_index)
