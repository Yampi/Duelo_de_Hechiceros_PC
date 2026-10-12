class_name ItemDefinition
extends Resource

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D = null
@export var category: String = "consumable" # "consumable", "material", "equipment", "quest"
@export var max_stack: int = 10
@export var is_usable: bool = false
@export var effect_type: String = "" # "heal_hp", "restore_mana", "haste_buff", "regen_hp", "regen_mp", "invulnerability", "banquet_buff", "teleport_escape", "equip_relic"
@export var effect_value: float = 0.0
@export var effect_duration: float = 0.0
@export var rarity: String = "common" # "common", "uncommon", "rare", "epic", "legendary"
@export var buff_name: String = ""

func _init(
	p_id: String = "",
	p_name: String = "",
	p_desc: String = "",
	p_icon: Texture2D = null,
	p_category: String = "consumable",
	p_max_stack: int = 10,
	p_is_usable: bool = false,
	p_effect_type: String = "",
	p_effect_value: float = 0.0,
	p_effect_duration: float = 0.0,
	p_rarity: String = "common",
	p_buff_name: String = ""
) -> void:
	id = p_id
	name = p_name
	description = p_desc
	icon = p_icon
	category = p_category
	max_stack = p_max_stack
	is_usable = p_is_usable
	effect_type = p_effect_type
	effect_value = p_effect_value
	effect_duration = p_effect_duration
	rarity = p_rarity
	buff_name = p_buff_name
