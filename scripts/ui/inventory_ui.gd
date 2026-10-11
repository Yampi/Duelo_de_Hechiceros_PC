class_name InventoryUI
extends Control

const ItemDB = preload("res://scripts/inventory/item_db.gd")
const ItemDefinition = preload("res://scripts/inventory/item_definition.gd")
const IconRegistry = preload("res://scripts/ui/icon_registry.gd")
const InventorySlotButton = preload("res://scripts/ui/inventory_slot_button.gd")
const UIConstants = preload("res://scripts/ui/ui_constants.gd")

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var center_container: CenterContainer = $CenterContainer
@onready var panel: Control = $CenterContainer/Panel
@onready var slots_grid: GridContainer = $CenterContainer/Panel/VBox/BodyHBox/LeftSection/SlotsGrid
@onready var capacity_label: Label = $CenterContainer/Panel/VBox/TopRow/CapacityLabel
@onready var btn_close: Button = $CenterContainer/Panel/VBox/TopRow/BtnClose
@onready var title_label: Label = $CenterContainer/Panel/VBox/TopRow/Title

# Detail pane nodes
@onready var detail_icon: TextureRect = $CenterContainer/Panel/VBox/BodyHBox/RightSection/DetailIcon
@onready var detail_name: Label = $CenterContainer/Panel/VBox/BodyHBox/RightSection/DetailName
@onready var detail_category: Label = $CenterContainer/Panel/VBox/BodyHBox/RightSection/DetailCategory
@onready var detail_desc: Label = $CenterContainer/Panel/VBox/BodyHBox/RightSection/DetailDesc
@onready var btn_use: Button = $CenterContainer/Panel/VBox/BodyHBox/RightSection/BtnUse
@onready var feedback_label: Label = $CenterContainer/Panel/VBox/BodyHBox/RightSection/FeedbackLabel

# Category tabs
@onready var tab_all: Button = $CenterContainer/Panel/VBox/CategoryTabs/TabAll
@onready var tab_consumable: Button = $CenterContainer/Panel/VBox/CategoryTabs/TabConsumable
@onready var tab_material: Button = $CenterContainer/Panel/VBox/CategoryTabs/TabMaterial
@onready var tab_quest: Button = $CenterContainer/Panel/VBox/CategoryTabs/TabQuest

var current_category_filter: String = "all"
var selected_slot_index: int = -1
var selected_item_id: String = ""

var slot_buttons: Array[InventorySlotButton] = []
var _is_animating: bool = false

func _ready() -> void:
	visible = false
	panel.pivot_offset = panel.custom_minimum_size * 0.5
	
	var cinzel_font = load("res://assets/ui/fonts/Cinzel.ttf")
	if cinzel_font and title_label:
		title_label.add_theme_font_override("font", cinzel_font)
		title_label.add_theme_font_size_override("font_size", 20)
	
	if btn_close:
		btn_close.pressed.connect(close_inventory)
	if btn_use:
		btn_use.pressed.connect(_on_use_pressed)
	
	_setup_tabs()
	_create_slot_buttons()
	
	if GameManager.inventory:
		GameManager.inventory.inventory_updated.connect(refresh_inventory)
		GameManager.inventory.item_used.connect(_on_item_used)
		GameManager.inventory.inventory_full_warning.connect(_on_inventory_full_warning)
	
	refresh_inventory()

func _setup_tabs() -> void:
	var tabs = [
		{"btn": tab_all, "id": "all", "icon": null},
		{"btn": tab_consumable, "id": "consumable", "icon": IconRegistry.get_icon("items", "potion_health")},
		{"btn": tab_material, "id": "material", "icon": IconRegistry.get_icon("items", "apple")},
		{"btn": tab_quest, "id": "quest", "icon": IconRegistry.get_icon("items", "arcane_crystal")}
	]
	
	for tab_data in tabs:
		var btn = tab_data["btn"] as Button
		var cat_id = tab_data["id"] as String
		if btn:
			if tab_data["icon"]:
				btn.icon = tab_data["icon"]
				btn.expand_icon = true
			btn.pressed.connect(func():
				var am = get_node_or_null("/root/AudioManager")
				if am and am.has_method("play_ui"):
					am.play_ui("click")
				_set_filter(cat_id)
			)

func _create_slot_buttons() -> void:
	for c in slots_grid.get_children():
		c.queue_free()
	slot_buttons.clear()
	
	slots_grid.columns = 4
	
	for i in range(16):
		var btn = InventorySlotButton.new(i)
		btn.slot_clicked.connect(_on_slot_clicked)
		btn.slot_right_clicked.connect(_on_slot_right_clicked)
		btn.slot_swapped.connect(_on_slot_swapped)
		
		# Set keyboard navigation neighbor links (4x4)
		var row = i / 4
		var col = i % 4
		if col > 0:
			btn.focus_neighbor_left = NodePath("../Slot_%d" % (i - 1))
		if col < 3:
			btn.focus_neighbor_right = NodePath("../Slot_%d" % (i + 1))
		if row > 0:
			btn.focus_neighbor_top = NodePath("../Slot_%d" % (i - 4))
		if row < 3:
			btn.focus_neighbor_bottom = NodePath("../Slot_%d" % (i + 4))
		
		slots_grid.add_child(btn)
		slot_buttons.append(btn)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_I or event.keycode == KEY_TAB:
			toggle_inventory()
			get_viewport().set_input_as_handled()
		elif (event.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel")) and visible:
			close_inventory()
			get_viewport().set_input_as_handled()

func toggle_inventory() -> void:
	if visible:
		close_inventory()
	else:
		open_inventory()

func open_inventory() -> void:
	if _is_animating:
		return
	
	visible = true
	_is_animating = true
	refresh_inventory()
	
	if feedback_label:
		feedback_label.text = ""
	
	# Fluid intro animation: scale 0.92 to 1.0, fade in
	dim_overlay.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	panel.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(dim_overlay, "modulate:a", 0.65, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func():
		_is_animating = false
		# Give focus to first non-empty slot or slot 0
		var found_focus = false
		for btn in slot_buttons:
			if btn.item_def:
				btn.grab_focus()
				found_focus = true
				break
		if not found_focus and slot_buttons.size() > 0:
			slot_buttons[0].grab_focus()
	)
	
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("open")

func close_inventory() -> void:
	if _is_animating or not visible:
		return
	
	_is_animating = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(dim_overlay, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "scale", Vector2(0.94, 0.94), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		visible = false
		_is_animating = false
	)
	
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("close")

func _set_filter(cat: String) -> void:
	current_category_filter = cat
	_highlight_active_tab()
	refresh_inventory()

func _highlight_active_tab() -> void:
	var tabs = [
		{"btn": tab_all, "id": "all"},
		{"btn": tab_consumable, "id": "consumable"},
		{"btn": tab_material, "id": "material"},
		{"btn": tab_quest, "id": "quest"}
	]
	for t in tabs:
		var btn = t["btn"] as Button
		if btn:
			if t["id"] == current_category_filter:
				btn.modulate = Color(1.2, 1.2, 1.2, 1.0)
			else:
				btn.modulate = Color(0.75, 0.75, 0.8, 0.8)

func refresh_inventory() -> void:
	if not GameManager.inventory:
		return
	
	var slots = GameManager.inventory.slots
	var used_count = 0
	
	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]
		if i < slots.size() and not slots[i].is_empty():
			var i_id = slots[i].get("item_id", "")
			var count = slots[i].get("count", 0)
			var def = ItemDB.get_item(i_id)
			used_count += 1
			
			var matches_filter = (current_category_filter == "all" or (def and def.category == current_category_filter))
			btn.set_item(def, count)
			btn.modulate = Color.WHITE if matches_filter else Color(0.35, 0.35, 0.4, 0.35)
		else:
			btn.set_item(null, 0)
			btn.modulate = Color.WHITE
		
		btn.set_slot_selected(i == selected_slot_index)
	
	if capacity_label:
		capacity_label.text = "Espacio: %d / 16" % used_count
		if used_count >= 16:
			capacity_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		else:
			capacity_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.6))
	
	if selected_slot_index >= 0 and selected_slot_index < slots.size() and not slots[selected_slot_index].is_empty():
		_display_slot_details(selected_slot_index)
	else:
		_clear_detail_pane()

func _on_slot_clicked(index: int) -> void:
	_select_slot(index)

func _on_slot_right_clicked(index: int) -> void:
	_select_slot(index)
	if not selected_item_id.is_empty():
		var def = ItemDB.get_item(selected_item_id)
		if def and def.is_usable:
			_use_current_item()

func _on_slot_swapped(from_idx: int, to_idx: int) -> void:
	if GameManager.inventory and GameManager.inventory.has_method("swap_slots"):
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_ui"):
			am.play_ui("click")
		GameManager.inventory.swap_slots(from_idx, to_idx)
		if selected_slot_index == from_idx:
			_select_slot(to_idx)
		elif selected_slot_index == to_idx:
			_select_slot(from_idx)

func _select_slot(index: int) -> void:
	selected_slot_index = index
	for i in range(slot_buttons.size()):
		slot_buttons[i].set_slot_selected(i == selected_slot_index)
	
	if not GameManager.inventory or index < 0 or index >= GameManager.inventory.slots.size():
		_clear_detail_pane()
		return
	
	var slot = GameManager.inventory.slots[index]
	if slot.is_empty():
		_clear_detail_pane()
		return
	
	_display_slot_details(index)

func _display_slot_details(index: int) -> void:
	var slot = GameManager.inventory.slots[index]
	selected_item_id = slot.get("item_id", "")
	var count = slot.get("count", 0)
	var def = ItemDB.get_item(selected_item_id)
	if not def:
		_clear_detail_pane()
		return
	
	if detail_icon:
		detail_icon.texture = def.icon
		detail_icon.visible = true
	if detail_name:
		detail_name.text = def.name
	if detail_category:
		var cat_name = "Consumible Mágico"
		var cat_col = Color(0.2, 0.9, 0.4)
		match def.category:
			"material":
				cat_name = "Material Alquímico"
				cat_col = Color(1.0, 0.65, 0.25)
			"quest":
				cat_name = "Objeto Primordial / Reliquia"
				cat_col = Color(0.85, 0.45, 1.0)
		detail_category.text = "[ %s ]  •  x%d" % [cat_name, count]
		detail_category.add_theme_color_override("font_color", cat_col)
	if detail_desc:
		detail_desc.text = def.description
	
	if btn_use:
		btn_use.visible = def.is_usable
		btn_use.disabled = not def.is_usable

func _clear_detail_pane() -> void:
	selected_slot_index = -1
	selected_item_id = ""
	for btn in slot_buttons:
		btn.set_slot_selected(false)
	
	if detail_icon:
		detail_icon.texture = null
		detail_icon.visible = false
	if detail_name:
		detail_name.text = "Selecciona un objeto"
	if detail_category:
		detail_category.text = ""
	if detail_desc:
		detail_desc.text = "Haz clic en una casilla para ver sus propiedades arcanas, o clic derecho para usar consumibles."
	if btn_use:
		btn_use.visible = false

func _on_use_pressed() -> void:
	_use_current_item()

func _use_current_item() -> void:
	if selected_item_id.is_empty() or not GameManager.inventory:
		return
	
	var player = _get_player()
	var success = GameManager.inventory.use_item(selected_item_id, player)
	if success:
		if feedback_label:
			feedback_label.text = "✔ Objeto utilizado con éxito."
			feedback_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	else:
		if feedback_label:
			feedback_label.text = "❌ No se puede utilizar en este momento."
			feedback_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

func _on_item_used(_item_id: String, _success: bool) -> void:
	refresh_inventory()

func _on_inventory_full_warning(_item_id: String) -> void:
	if feedback_label:
		feedback_label.text = "⚠️ ¡El inventario está lleno! No cabe más."
		feedback_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))

func _get_player() -> Node:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null
