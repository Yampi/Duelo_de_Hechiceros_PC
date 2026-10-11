class_name ItemDB
extends RefCounted

const ItemDefinition = preload("res://scripts/inventory/item_definition.gd")
const IconRegistry = preload("res://scripts/ui/icon_registry.gd")

static var _items: Dictionary = {}
static var _initialized: bool = false

static func init_db() -> void:
	if _initialized:
		return
	_initialized = true
	
	_register_item(ItemDefinition.new(
		"potion_health",
		"Poción de Salud",
		"Elixir alquímico revitalizante de hierbas mágicas. Restaura 50 puntos de salud vital inmediatamente.",
		IconRegistry.get_icon("items", "potion_health"),
		"consumable",
		10,
		true,
		"heal_hp",
		50.0
	))
	
	_register_item(ItemDefinition.new(
		"potion_mana",
		"Poción de Maná",
		"Destilado puro de éter concentrado. Restaura 50 puntos de maná arcano al instante.",
		IconRegistry.get_icon("items", "potion_mana"),
		"consumable",
		10,
		true,
		"restore_mana",
		50.0
	))
	
	_register_item(ItemDefinition.new(
		"magic_scroll",
		"Pergamino de Celeridad",
		"Encantamiento antiguo de aceleración motriz y reflejos arcanos (+30% de velocidad y casteo veloz por 10s).",
		IconRegistry.get_icon("items", "magic_scroll"),
		"consumable",
		5,
		true,
		"haste_buff",
		10.0
	))
	
	_register_item(ItemDefinition.new(
		"apple",
		"Manzana Silvestre",
		"Fruta recolectada de los manzanos del Bosque Arcano. Deliciosa y reconstituyente, restaura 25 puntos de salud.",
		IconRegistry.get_icon("items", "apple"),
		"consumable",
		20,
		true,
		"heal_hp",
		50.0
	))
	
	_register_item(ItemDefinition.new(
		"sulfur",
		"Azufre Alquímico",
		"Reactivo elemental altamente inflamable extraído de bestias ígneas. Material clave para alquimia arcana.",
		IconRegistry.get_icon("items", "sulfur"),
		"material",
		20,
		false,
		"",
		0.0
	))
	
	_register_item(ItemDefinition.new(
		"clover",
		"Trébol Mágico",
		"Hierba mágica de cuatro hojas que absorbe la radiación mística de los santuarios territoriales.",
		IconRegistry.get_icon("items", "clover"),
		"material",
		20,
		false,
		"",
		0.0
	))
	
	_register_item(ItemDefinition.new(
		"arcane_crystal",
		"Cristal Arcano",
		"Gema primordial impregnada de resonancia arcana pura. Es la reliquia necesaria para reactivar el Altar de Transmutación en las Ruinas.",
		IconRegistry.get_icon("items", "arcane_crystal"),
		"quest",
		5,
		false,
		"quest_catalyst",
		1.0
	))

static func _register_item(def: ItemDefinition) -> void:
	_items[def.id] = def

static func get_item(id: String) -> ItemDefinition:
	if not _initialized:
		init_db()
	return _items.get(id, null)

static func has_item(id: String) -> bool:
	if not _initialized:
		init_db()
	return _items.has(id)

static func get_all_items() -> Dictionary:
	if not _initialized:
		init_db()
	return _items
