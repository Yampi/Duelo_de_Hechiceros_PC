class_name CraftingRecipe
extends RefCounted

var id: String = ""
var name: String = ""
var description: String = ""
var station: String = "alchemy" # "alchemy", "cooking", "forge", "herbalism"
var ingredients: Dictionary = {} # {"item_id": count}
var result_item_id: String = ""
var result_count: int = 1

func _init(
	p_id: String = "",
	p_name: String = "",
	p_desc: String = "",
	p_station: String = "alchemy",
	p_ingredients: Dictionary = {},
	p_result_id: String = "",
	p_result_count: int = 1
) -> void:
	id = p_id
	name = p_name
	description = p_desc
	station = p_station
	ingredients = p_ingredients
	result_item_id = p_result_id
	result_count = p_result_count
