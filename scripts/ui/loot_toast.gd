class_name LootToast
extends PanelContainer

const UIConstants = preload("res://scripts/ui/ui_constants.gd")
const ItemDB = preload("res://scripts/inventory/item_db.gd")

@onready var icon_rect: TextureRect = $HBox/Icon
@onready var label: Label = $HBox/Label

func setup(item_name: String, count: int, icon_tex: Texture2D = null, border_col: Color = UIConstants.GOLD_BASE) -> void:
	if not label:
		label = $HBox/Label
	if not icon_rect:
		icon_rect = $HBox/Icon
	
	label.text = "+%d %s" % [count, item_name]
	label.add_theme_color_override("font_color", UIConstants.TEXT_BODY)
	
	if icon_tex:
		icon_rect.texture = icon_tex
	
	# Borde coloreado por rareza o categoria
	var sb = get_theme_stylebox("panel")
	if sb:
		var dup = sb.duplicate() as StyleBoxFlat
		if dup:
			dup.border_color = border_col
			add_theme_stylebox_override("panel", dup)

func setup_from_item(item_id: String, count: int = 1) -> void:
	var def = ItemDB.get_item(item_id)
	var item_name = def.name if def else item_id
	var icon = def.icon if def else null
	var border = UIConstants.GOLD_BASE
	if def:
		match def.category:
			"consumable":
				border = UIConstants.ARCANE_CYAN if "mana" in item_id else Color(0.3, 0.95, 0.45)
			"quest":
				border = Color(0.85, 0.35, 1.0)
			"material":
				border = Color(1.0, 0.65, 0.2)
	setup(item_name, count, icon, border)

func setup_message(msg: String, icon_tex: Texture2D = null, border_col: Color = UIConstants.GOLD_BASE) -> void:
	if not label:
		label = $HBox/Label
	if not icon_rect:
		icon_rect = $HBox/Icon
	
	label.text = msg
	label.add_theme_color_override("font_color", UIConstants.TEXT_BODY)
	
	if icon_tex:
		icon_rect.texture = icon_tex
		icon_rect.visible = true
	else:
		icon_rect.visible = false
	
	var sb = get_theme_stylebox("panel")
	if sb:
		var dup = sb.duplicate() as StyleBoxFlat
		if dup:
			dup.border_color = border_col
			add_theme_stylebox_override("panel", dup)

func _ready() -> void:
	modulate.a = 0.0
	position.x += 40.0
	
	var tween = create_tween()
	# Slide in from right and pop
	tween.tween_property(self, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position:x", position.x - 40.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Wait visible
	tween.tween_interval(2.2)
	# Float up and fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "position:y", position.y - 18.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
