class_name CraftingModal
extends Control

signal crafting_closed

const UIConstants = preload("res://scripts/ui/ui_constants.gd")
const ItemDB = preload("res://scripts/inventory/item_db.gd")
const CraftingRecipe = preload("res://scripts/crafting/crafting_recipe.gd")

@onready var btn_close: Button = find_child("BtnClose", true, false)
@onready var recipes_container: VBoxContainer = find_child("RecipesList", true, false)

# Tabs
@onready var tab_alchemy: Button = find_child("TabAlchemy", true, false)
@onready var tab_cooking: Button = find_child("TabCooking", true, false)
@onready var tab_forge: Button = find_child("TabForge", true, false)
@onready var tab_herbalism: Button = find_child("TabHerbalism", true, false)

# Detail pane
@onready var detail_icon: TextureRect = find_child("DetailIcon", true, false)
@onready var detail_name: Label = find_child("DetailName", true, false)
@onready var detail_station: Label = find_child("DetailStation", true, false)
@onready var detail_desc: Label = find_child("DetailDesc", true, false)
@onready var ingredients_box: VBoxContainer = find_child("IngredientsBox", true, false)
@onready var btn_craft: Button = find_child("BtnCraft", true, false)
@onready var lbl_feedback: Label = find_child("LblFeedback", true, false)

var current_station: String = "alchemy"
var selected_recipe_id: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	if btn_close:
		btn_close.pressed.connect(close_crafting)
	
	_setup_tabs()
	
	if btn_craft:
		btn_craft.pressed.connect(_on_craft_pressed)
	
	if GameManager.inventory:
		GameManager.inventory.inventory_updated.connect(_refresh_ui)
	
	_select_station("alchemy")

func _setup_tabs() -> void:
	if tab_alchemy:
		tab_alchemy.pressed.connect(func(): _select_station("alchemy"))
	if tab_cooking:
		tab_cooking.pressed.connect(func(): _select_station("cooking"))
	if tab_forge:
		tab_forge.pressed.connect(func(): _select_station("forge"))
	if tab_herbalism:
		tab_herbalism.pressed.connect(func(): _select_station("herbalism"))

func open_crafting() -> void:
	visible = true
	_refresh_ui()
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("open")

func close_crafting() -> void:
	visible = false
	crafting_closed.emit()
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("close")

func toggle_crafting() -> void:
	if visible:
		close_crafting()
	else:
		open_crafting()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_C or event.keycode == KEY_ESCAPE:
			close_crafting()
			get_viewport().set_input_as_handled()

func _select_station(station: String) -> void:
	current_station = station
	selected_recipe_id = ""
	_highlight_active_tab()
	_refresh_ui()

func _highlight_active_tab() -> void:
	var tabs = {
		"alchemy": tab_alchemy,
		"cooking": tab_cooking,
		"forge": tab_forge,
		"herbalism": tab_herbalism
	}
	for s in tabs:
		var btn = tabs[s] as Button
		if btn:
			if s == current_station:
				btn.add_theme_color_override("font_color", UIConstants.GOLD_BASE)
			else:
				btn.remove_theme_color_override("font_color")

func _refresh_ui() -> void:
	_build_recipes_list()
	_update_detail_view()

func _build_recipes_list() -> void:
	if not recipes_container:
		return
	
	for child in recipes_container.get_children():
		child.queue_free()
	
	if not GameManager.crafting:
		return
	
	var recipes = GameManager.crafting.get_recipes_by_station(current_station)
	if recipes.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No hay recetas disponibles en este taller."
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		recipes_container.add_child(empty_lbl)
		return
	
	if selected_recipe_id.is_empty() and not recipes.is_empty():
		selected_recipe_id = recipes[0].id
	
	for r in recipes:
		var btn = Button.new()
		var can_make = GameManager.crafting.can_craft(r.id)
		var prefix = "✓ " if can_make else "• "
		btn.text = prefix + r.name
		btn.custom_minimum_size = Vector2(0, 42)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var res_def = ItemDB.get_item(r.result_item_id)
		if res_def and res_def.icon:
			btn.icon = res_def.icon
			btn.expand_icon = true
		
		if can_make:
			btn.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
		else:
			btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
		
		if r.id == selected_recipe_id:
			btn.add_theme_color_override("font_color", UIConstants.GOLD_BASE)
		
		var rec_id = r.id
		btn.pressed.connect(func():
			selected_recipe_id = rec_id
			if lbl_feedback: lbl_feedback.text = ""
			_refresh_ui()
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_ui"):
				am.play_ui("click")
		)
		recipes_container.add_child(btn)

func _update_detail_view() -> void:
	if not GameManager.crafting or selected_recipe_id.is_empty():
		_clear_detail_view()
		return
	
	var r = GameManager.crafting.get_recipe(selected_recipe_id)
	if not r:
		_clear_detail_view()
		return
	
	var res_def = ItemDB.get_item(r.result_item_id)
	if detail_name:
		detail_name.text = r.name
	if detail_desc:
		detail_desc.text = r.description
	if detail_station:
		var st_names = {
			"alchemy": "Taller de Alquimia",
			"cooking": "Cocina de Campamento",
			"forge": "Forja Rúnica",
			"herbalism": "Mesa de Herbolaria"
		}
		detail_station.text = st_names.get(r.station, r.station)
	
	if detail_icon and res_def and res_def.icon:
		detail_icon.texture = res_def.icon
	
	# Construir lista de ingredientes requeridos
	if ingredients_box:
		for child in ingredients_box.get_children():
			child.queue_free()
		
		var inv = GameManager.inventory
		for ing_id in r.ingredients:
			var needed = r.ingredients[ing_id]
			var have = inv.get_item_count(ing_id) if inv else 0
			var ing_def = ItemDB.get_item(ing_id)
			var ing_name = ing_def.name if ing_def else ing_id
			
			var row = HBoxContainer.new()
			var icon_rect = TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(24, 24)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if ing_def and ing_def.icon:
				icon_rect.texture = ing_def.icon
			row.add_child(icon_rect)
			
			var lbl = Label.new()
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var has_enough = have >= needed
			var color = Color(0.4, 1.0, 0.5) if has_enough else Color(1.0, 0.4, 0.4)
			lbl.text = "%s: %d / %d" % [ing_name, have, needed]
			lbl.add_theme_color_override("font_color", color)
			row.add_child(lbl)
			
			ingredients_box.add_child(row)
	
	var can_make = GameManager.crafting.can_craft(r.id)
	if btn_craft:
		btn_craft.disabled = not can_make
		if can_make:
			btn_craft.text = "⚒ FABRICAR"
			btn_craft.add_theme_color_override("font_color", UIConstants.GOLD_BASE)
		else:
			btn_craft.text = "✕ FALTAN INGREDIENTES"
			btn_craft.remove_theme_color_override("font_color")

func _clear_detail_view() -> void:
	if detail_name: detail_name.text = "Selecciona una receta"
	if detail_desc: detail_desc.text = ""
	if detail_station: detail_station.text = ""
	if detail_icon: detail_icon.texture = null
	if btn_craft: btn_craft.disabled = true; btn_craft.text = "FABRICAR"
	if ingredients_box:
		for child in ingredients_box.get_children():
			child.queue_free()

func _on_craft_pressed() -> void:
	if not GameManager.crafting or selected_recipe_id.is_empty():
		return
	
	var ok = GameManager.crafting.craft(selected_recipe_id)
	if ok:
		var r = GameManager.crafting.get_recipe(selected_recipe_id)
		if lbl_feedback:
			lbl_feedback.text = "✓ ¡Has fabricado %s con éxito!" % r.name
			lbl_feedback.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_ui"):
			am.play_ui("loot")
		
		_refresh_ui()
	else:
		if lbl_feedback:
			lbl_feedback.text = "✕ No se pudo fabricar la receta (espacio insuficiente o faltan ingredientes)."
			lbl_feedback.add_theme_color_override("font_color", UIConstants.DANGER_RED)
