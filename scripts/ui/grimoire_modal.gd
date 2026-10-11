class_name GrimoireModal
extends Control

const IconRegistry = preload("res://scripts/ui/icon_registry.gd")
const UIConstants = preload("res://scripts/ui/ui_constants.gd")

signal grimoire_closed

@onready var panel_container: PanelContainer = find_child("Panel", true, false)
@onready var catalog_container: VBoxContainer = find_child("CatalogList", true, false)
@onready var slots_container: VBoxContainer = find_child("SlotsList", true, false)
@onready var btn_close: Button = find_child("BtnClose", true, false)
@onready var lbl_selected_info: Label = find_child("LblSelectedInfo", true, false)

var selected_spell_id: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if btn_close:
		btn_close.pressed.connect(close_grimoire)
	
	GameManager.grimorio_updated.connect(_refresh_ui)
	_refresh_ui()

func toggle_grimoire() -> void:
	if visible:
		close_grimoire()
	else:
		open_grimoire()

func open_grimoire() -> void:
	visible = true
	_refresh_ui()
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("open")

func close_grimoire() -> void:
	visible = false
	grimoire_closed.emit()
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("close")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_G or event.keycode == KEY_ESCAPE:
			close_grimoire()
			get_viewport().set_input_as_handled()

func _refresh_ui() -> void:
	_build_catalog()
	_build_slots()
	_update_selected_label()

func _update_selected_label() -> void:
	if not lbl_selected_info:
		return
	if selected_spell_id.is_empty() or not GameManager.spell_catalog.has(selected_spell_id):
		lbl_selected_info.text = "Selecciona un hechizo del catálogo para equiparlo en una ranura."
		lbl_selected_info.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	else:
		var sp = GameManager.spell_catalog[selected_spell_id]
		lbl_selected_info.text = "Hechizo seleccionado: %s (%d MP, %.1fs CD). Haz clic en 'Equipar' en la ranura deseada." % [sp["name"], int(sp["cost"]), sp["cooldown"]]
		lbl_selected_info.add_theme_color_override("font_color", UIConstants.ARCANE_CYAN)

func _build_catalog() -> void:
	if not catalog_container:
		return
	for c in catalog_container.get_children():
		c.queue_free()
	
	for s_id in GameManager.spell_catalog:
		var sp = GameManager.spell_catalog[s_id]
		var item_btn = Button.new()
		item_btn.custom_minimum_size = Vector2(0, 48)
		item_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Comprobar si está equipado
		var equipped_in_slot = -1
		for i in range(GameManager.equipped_spell_ids.size()):
			if GameManager.equipped_spell_ids[i] == s_id:
				equipped_in_slot = i + 1
				break
		
		var icon_tex = IconRegistry.get_icon("spells", s_id)
		if icon_tex:
			item_btn.icon = icon_tex
			item_btn.expand_icon = true
		
		var tag = " [Ranura %d]" % equipped_in_slot if equipped_in_slot != -1 else ""
		item_btn.text = " %s — %d MP (CD: %.1fs)%s\n   %s" % [sp["name"], int(sp["cost"]), sp["cooldown"], tag, sp.get("desc", "")]
		
		if s_id == selected_spell_id:
			item_btn.modulate = Color(1.2, 1.15, 0.7, 1.0)
		else:
			item_btn.modulate = Color.WHITE
		
		var captured_id = s_id
		item_btn.pressed.connect(func():
			selected_spell_id = captured_id
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_ui"):
				am.play_ui("hover")
			_refresh_ui()
		)
		catalog_container.add_child(item_btn)

func equip_selected_to_slot(slot_idx: int) -> void:
	if not selected_spell_id.is_empty():
		GameManager.equip_spell(slot_idx, selected_spell_id)
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_ui"):
			am.play_ui("click")
		_refresh_ui()

func _build_slots() -> void:
	if not slots_container:
		return
	for c in slots_container.get_children():
		c.queue_free()
	
	for slot_idx in range(1, 10):
		var s_id = GameManager.equipped_spell_ids[slot_idx - 1] if (slot_idx - 1) < GameManager.equipped_spell_ids.size() else "magic_bolt"
		var sp = GameManager.spell_catalog.get(s_id, {})
		
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 42)
		row.add_theme_constant_override("separation", 8)
		
		var hotkey_lbl = Label.new()
		hotkey_lbl.custom_minimum_size = Vector2(40, 0)
		hotkey_lbl.text = "[%d]" % slot_idx
		hotkey_lbl.add_theme_color_override("font_color", UIConstants.GOLD_BASE)
		hotkey_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(hotkey_lbl)
		
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(36, 36)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_tex = IconRegistry.get_icon("spells", s_id)
		if icon_tex:
			icon_rect.texture = icon_tex
		row.add_child(icon_rect)
		
		var name_lbl = Label.new()
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.text = "%s (%d MP)" % [sp.get("name", "Vacio"), int(sp.get("cost", 0))]
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(name_lbl)
		
		var btn_equip = Button.new()
		btn_equip.custom_minimum_size = Vector2(90, 32)
		btn_equip.text = "Equipar"
		btn_equip.disabled = (selected_spell_id.is_empty() or selected_spell_id == s_id)
		
		var cap_slot = slot_idx
		btn_equip.pressed.connect(func(): equip_selected_to_slot(cap_slot))
		row.add_child(btn_equip)
		
		slots_container.add_child(row)
