class_name CraftingManager
extends RefCounted

const CraftingRecipe = preload("res://scripts/crafting/crafting_recipe.gd")
const ItemDB = preload("res://scripts/inventory/item_db.gd")

signal recipe_crafted(recipe_id: String, result_item_id: String, result_count: int)

var _recipes: Dictionary = {} # id -> CraftingRecipe
var _station_index: Dictionary = {
	"alchemy": [],
	"cooking": [],
	"forge": [],
	"herbalism": []
}

func _init() -> void:
	_init_recipes()

func _init_recipes() -> void:
	_recipes.clear()
	for k in _station_index:
		_station_index[k].clear()
	
	# ==========================================
	# 1. ALQUIMIA (ALCHEMIST WORKBENCH)
	# ==========================================
	_add_recipe(CraftingRecipe.new(
		"recipe_pot_health_greater", "Poción Mayor de Salud",
		"Destila pociones ordinarias con raíz de sangre para crear una curación superior (120 HP).",
		"alchemy",
		{ "potion_health": 2, "blood_root": 1 },
		"potion_health_greater", 1
	))

	_add_recipe(CraftingRecipe.new(
		"recipe_pot_mana_greater", "Poción Mayor de Maná",
		"Concentra la esencia luminiscente para restaurar 100 de maná arcano.",
		"alchemy",
		{ "potion_mana": 2, "bioluminescent_mushroom": 1 },
		"potion_mana_greater", 1
	))

	_add_recipe(CraftingRecipe.new(
		"recipe_elixir", "Elixir del Archimago",
		"Poderosa infusión dual que restaura 75 de salud y 75 de maná.",
		"alchemy",
		{ "potion_health": 1, "potion_mana": 1, "star_lotus": 1 },
		"potion_elixir", 1
	))

	_add_recipe(CraftingRecipe.new(
		"recipe_haste", "Pergamino de Celeridad",
		"Inscribe runas de viento y azufre para acelerar tus reflejos (+35% vel por 12s).",
		"alchemy",
		{ "clover": 1, "star_lotus": 1, "sulfur": 1 },
		"magic_scroll", 1
	))

	_add_recipe(CraftingRecipe.new(
		"recipe_invulnerability", "Filtro de Éter Protector",
		"Filtro supremo de éter y obsidiana que concede 5 segundos de invulnerabilidad absoluta.",
		"alchemy",
		{ "crystallized_ether": 2, "obsidian_shard": 1 },
		"potion_invulnerability", 1
	))

	# ==========================================
	# 2. COCINA (CAMP COOKING)
	# ==========================================
	_add_recipe(CraftingRecipe.new(
		"recipe_baked_apple", "Manzana Asada con Especias",
		"Hornea manzanas al fuego elemental para otorgar regeneración de 4 HP/s por 20s.",
		"cooking",
		{ "apple": 2, "sulfur": 1 },
		"baked_apple", 1
	))

	_add_recipe(CraftingRecipe.new(
		"recipe_mushroom_stew", "Guiso de Hongos Arcanos",
		"Prepara una cazuela silvestre que regenera 6 MP/s por 20 segundos.",
		"cooking",
		{ "bioluminescent_mushroom": 2, "berry": 2 },
		"mushroom_stew", 1
	))

	_add_recipe(CraftingRecipe.new(
		"recipe_roasted_meat", "Carne Asada de Bestia",
		"Platillo cárnico a las brasas que regenera 8 HP/s por 25 segundos.",
		"cooking",
		{ "goblin_tooth": 2, "sulfur": 1 },
		"roasted_meat", 1
	))

	_add_recipe(CraftingRecipe.new(
		"recipe_banquet", "Banquete del Archimago",
		"Platillo supremo de frutas y loto estelar (+25% velocidad, +6 HP/s, +6 MP/s por 30s).",
		"cooking",
		{ "apple": 2, "berry": 2, "bioluminescent_mushroom": 1, "star_lotus": 1 },
		"sorcerer_banquet", 1
	))

	# ==========================================
	# 3. FORJA RÚNICA (RUNIC FORGE)
	# ==========================================
	_add_recipe(CraftingRecipe.new(
		"recipe_amulet_vitality", "Amuleto de Vitalidad",
		"Forja un medallón de hierro y raíz que otorga +50 de Salud Máxima permanente.",
		"forge",
		{ "arcane_iron": 3, "blood_root": 2, "skeleton_bone": 1 },
		"amulet_vitality", 1
	))

	_add_recipe(CraftingRecipe.new(
		"recipe_ring_mana_flow", "Anillo de Flujo Arcano",
		"Engarza oro y éter para reducir en 20% el coste de maná de todos los hechizos.",
		"forge",
		{ "gold_nugget": 2, "crystallized_ether": 2, "goblin_tooth": 1 },
		"ring_mana_flow", 1
	))

	_add_recipe(CraftingRecipe.new(
		"recipe_talisman_swiftness", "Talismán del Viento",
		"Moldea escamas de dragón y loto para ganar +20% de velocidad de movimiento permanente.",
		"forge",
		{ "gold_nugget": 2, "star_lotus": 2, "wyvern_scale": 1 },
		"talisman_swiftness", 1
	))

	_add_recipe(CraftingRecipe.new(
		"recipe_brooch_pyromancer", "Broche del Piromante",
		"Funde obsidiana y núcleo ígneo para potenciar en +25% los hechizos de fuego.",
		"forge",
		{ "obsidian_shard": 3, "fire_core": 2, "sulfur": 2 },
		"brooch_pyromancer", 1
	))

	# ==========================================
	# 4. HERBOLARIA & TRANSMUTACIÓN (HERBALISM)
	# ==========================================
	_add_recipe(CraftingRecipe.new(
		"recipe_health_from_herbs", "Infusión Curativa Básica",
		"Combina tréboles y raíz de sangre para destilar una Poción de Salud clásica.",
		"herbalism",
		{ "clover": 3, "blood_root": 1 },
		"potion_health", 1
	))

	_add_recipe(CraftingRecipe.new(
		"recipe_mana_from_herbs", "Infusión Etérea Básica",
		"Macera tréboles y hongos luminiscentes para destilar una Poción de Maná.",
		"herbalism",
		{ "clover": 2, "bioluminescent_mushroom": 2 },
		"potion_mana", 1
	))

	_add_recipe(CraftingRecipe.new(
		"recipe_ether_transmute", "Transmutación de Éter",
		"Comprime cristales arcanos con obsidiana para sintetizar Éter Cristalizado puro.",
		"herbalism",
		{ "arcane_crystal": 2, "obsidian_shard": 1 },
		"crystallized_ether", 1
	))

	_add_recipe(CraftingRecipe.new(
		"recipe_clover_extract", "Destilado de Loto Estelar",
		"Transmuta una gran masa de tréboles mágicos para condensar una Flor de Loto Estelar.",
		"herbalism",
		{ "clover": 4 },
		"star_lotus", 1
	))

func _add_recipe(recipe: CraftingRecipe) -> void:
	_recipes[recipe.id] = recipe
	if _station_index.has(recipe.station):
		_station_index[recipe.station].append(recipe)

func get_recipe(recipe_id: String) -> CraftingRecipe:
	return _recipes.get(recipe_id, null)

func get_recipes_by_station(station: String) -> Array:
	return _station_index.get(station, [])

func get_all_recipes() -> Array:
	var list = []
	for r in _recipes.values():
		list.append(r)
	return list

func can_craft(recipe_id: String, inv = null) -> bool:
	var recipe = get_recipe(recipe_id)
	if not recipe:
		return false
	
	var inventory = inv
	if not inventory:
		inventory = GameManager.inventory
	if not inventory:
		return false
	
	# Verificar si tiene espacio para el objeto resultante
	if not inventory.can_add_item(recipe.result_item_id, recipe.result_count):
		return false
	
	# Verificar ingredientes
	for item_id in recipe.ingredients:
		var needed = recipe.ingredients[item_id]
		if inventory.get_item_count(item_id) < needed:
			return false
	
	return true

func craft(recipe_id: String, inv = null) -> bool:
	var recipe = get_recipe(recipe_id)
	if not recipe:
		return false
	
	var inventory = inv
	if not inventory:
		inventory = GameManager.inventory
	if not inventory:
		return false
	
	if not can_craft(recipe_id, inventory):
		return false
	
	# Deducir ingredientes
	for item_id in recipe.ingredients:
		var needed = recipe.ingredients[item_id]
		inventory.remove_item(item_id, needed)
	
	# Añadir producto
	inventory.add_item(recipe.result_item_id, recipe.result_count)
	
	recipe_crafted.emit(recipe.id, recipe.result_item_id, recipe.result_count)
	return true
