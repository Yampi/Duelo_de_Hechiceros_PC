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
	
	# ==========================================
	# 1. CONSUMIBLES & POCIONES
	# ==========================================
	_register_item(ItemDefinition.new(
		"potion_health", "Poción de Salud",
		"Elixir revitalizante de hierbas mágicas. Restaura 50 puntos de salud inmediatamente.",
		IconRegistry.get_icon("items", "potion_health"), "consumable", 10, true, "heal_hp", 50.0, 0.0, "common"
	))
	
	_register_item(ItemDefinition.new(
		"potion_mana", "Poción de Maná",
		"Destilado puro de éter concentrado. Restaura 50 puntos de maná arcano al instante.",
		IconRegistry.get_icon("items", "potion_mana"), "consumable", 10, true, "restore_mana", 50.0, 0.0, "common"
	))

	_register_item(ItemDefinition.new(
		"potion_health_greater", "Poción Mayor de Salud",
		"Filtro alquímico concentrado con raíz de sangre. Restaura 120 puntos de salud.",
		IconRegistry.get_icon("items", "potion_health_greater"), "consumable", 10, true, "heal_hp", 120.0, 0.0, "uncommon"
	))

	_register_item(ItemDefinition.new(
		"potion_mana_greater", "Poción Mayor de Maná",
		"Esencia mística pura de hongos bioluminiscentes. Restaura 100 puntos de maná.",
		IconRegistry.get_icon("items", "potion_mana_greater"), "consumable", 10, true, "restore_mana", 100.0, 0.0, "uncommon"
	))

	_register_item(ItemDefinition.new(
		"potion_elixir", "Elixir del Archimago",
		"Poderosa infusión alquímica que restaura 75 puntos de salud y 75 de maná simultáneamente.",
		IconRegistry.get_icon("items", "potion_elixir"), "consumable", 5, true, "heal_both", 75.0, 0.0, "epic"
	))

	_register_item(ItemDefinition.new(
		"potion_invulnerability", "Filtro de Éter Protector",
		"Otorga una barrera impenetrable de éter que hace al mago inmune al daño durante 5 segundos.",
		IconRegistry.get_icon("items", "potion_invulnerability"), "consumable", 3, true, "invulnerability", 1.0, 5.0, "epic", "Inmunidad Arcana"
	))

	_register_item(ItemDefinition.new(
		"magic_scroll", "Pergamino de Celeridad",
		"Encantamiento antiguo de aceleración motriz y reflejos (+35% de velocidad de movimiento por 12s).",
		IconRegistry.get_icon("items", "magic_scroll"), "consumable", 5, true, "haste_buff", 12.0, 12.0, "uncommon", "Celeridad"
	))

	_register_item(ItemDefinition.new(
		"scroll_teleport", "Pergamino de Salto Etéreo",
		"Reliquia de evasión que transporta instantáneamente al hechicero 15 metros al frente.",
		IconRegistry.get_icon("items", "scroll_teleport"), "consumable", 5, true, "teleport_escape", 15.0, 0.0, "rare"
	))

	# ==========================================
	# 2. COMESTIBLES & COCINA (BUFFS PROLONGADOS)
	# ==========================================
	_register_item(ItemDefinition.new(
		"apple", "Manzana Silvestre",
		"Fruta dulce recolectada de los manzanos del Bosque. Restaura 25 puntos de salud.",
		IconRegistry.get_icon("items", "apple"), "consumable", 20, true, "heal_hp", 25.0, 0.0, "common"
	))

	_register_item(ItemDefinition.new(
		"baked_apple", "Manzana Asada con Especias",
		"Manzana cocinada al fuego. Regenera 4 puntos de salud por segundo durante 20 segundos.",
		IconRegistry.get_icon("items", "baked_apple"), "consumable", 15, true, "regen_hp", 4.0, 20.0, "common", "Vigor Frutal"
	))

	_register_item(ItemDefinition.new(
		"berry", "Bayas del Bosque",
		"Pequeños frutos silvestres energéticos. Restauran 15 puntos de vida y 10 de maná.",
		IconRegistry.get_icon("items", "berry"), "consumable", 25, true, "heal_both", 15.0, 0.0, "common"
	))

	_register_item(ItemDefinition.new(
		"mushroom_stew", "Guiso de Hongos Arcanos",
		"Sopa reconfortante de esporas luminiscentes. Regenera 6 de maná por segundo durante 20 segundos.",
		IconRegistry.get_icon("items", "mushroom_stew"), "consumable", 10, true, "regen_mp", 6.0, 20.0, "uncommon", "Marea Mental"
	))

	_register_item(ItemDefinition.new(
		"roasted_meat", "Carne Asada de Bestia",
		"Carne sustanciosa cocinada a las brasas. Otorga regeneración de 8 HP/s durante 25 segundos.",
		IconRegistry.get_icon("items", "roasted_meat"), "consumable", 10, true, "regen_hp", 8.0, 25.0, "uncommon", "Fortaleza Carnívora"
	))

	_register_item(ItemDefinition.new(
		"sorcerer_banquet", "Banquete del Archimago",
		"Platillo legendario de ingredientes combinados. Concede regeneración de 6 HP/s, 6 MP/s y +25% de velocidad por 30s.",
		IconRegistry.get_icon("items", "sorcerer_banquet"), "consumable", 5, true, "banquet_buff", 6.0, 30.0, "rare", "Banquete Arcano"
	))

	# ==========================================
	# 3. MATERIALES: FLORA & HIERBAS
	# ==========================================
	_register_item(ItemDefinition.new(
		"clover", "Trébol Mágico",
		"Hierba de cuatro hojas que absorbe la energía del bosque. Base de pociones y crafteo herbal.",
		IconRegistry.get_icon("items", "clover"), "material", 30, false, "", 0.0, 0.0, "common"
	))

	_register_item(ItemDefinition.new(
		"blood_root", "Raíz de Sangre",
		"Raíz carmesí densa en vitalidad terrenal. Ingrediente clave para curación avanzada y forja de vida.",
		IconRegistry.get_icon("items", "blood_root"), "material", 25, false, "", 0.0, 0.0, "uncommon"
	))

	_register_item(ItemDefinition.new(
		"bioluminescent_mushroom", "Hongo Bioluminiscente",
		"Hongo radiante de las cavernas sombrías. Reactivo supremo para destilados de maná y cocina mística.",
		IconRegistry.get_icon("items", "bioluminescent_mushroom"), "material", 25, false, "", 0.0, 0.0, "uncommon"
	))

	_register_item(ItemDefinition.new(
		"star_lotus", "Flor de Loto Estelar",
		"Exótica flor azulada que florece bajo la luz estelar. Utilizada en elixires y artefactos de celeridad.",
		IconRegistry.get_icon("items", "star_lotus"), "material", 15, false, "", 0.0, 0.0, "rare"
	))

	# ==========================================
	# 4. MATERIALES: MINERALES & METALES
	# ==========================================
	_register_item(ItemDefinition.new(
		"sulfur", "Azufre Alquímico",
		"Reactivo elemental inflamable extraído de bestias ígneas. Material clave para alquimia y cocina de fuego.",
		IconRegistry.get_icon("items", "sulfur"), "material", 30, false, "", 0.0, 0.0, "common"
	))

	_register_item(ItemDefinition.new(
		"arcane_iron", "Mineral de Hierro Arcano",
		"Metal imbuido de resonancia mágica. Base para la forja de talismanes y armaduras rúnicas.",
		IconRegistry.get_icon("items", "arcane_iron"), "material", 20, false, "", 0.0, 0.0, "uncommon"
	))

	_register_item(ItemDefinition.new(
		"obsidian_shard", "Fragmento de Obsidiana",
		"Piedra volcánica impenetrable. Confiere resistencia a magia oscura y sirve para forjar protecciones.",
		IconRegistry.get_icon("items", "obsidian_shard"), "material", 20, false, "", 0.0, 0.0, "uncommon"
	))

	_register_item(ItemDefinition.new(
		"gold_nugget", "Pepita de Oro Rúnico",
		"Metal precioso de altísima conductividad etérea. Necesario para anillos de poder y amuletos.",
		IconRegistry.get_icon("items", "gold_nugget"), "material", 15, false, "", 0.0, 0.0, "rare"
	))

	_register_item(ItemDefinition.new(
		"crystallized_ether", "Éter Cristalizado",
		"Magia congelada en un prisma sólido. Reactivo para transmutaciones de élite.",
		IconRegistry.get_icon("items", "crystallized_ether"), "material", 15, false, "", 0.0, 0.0, "rare"
	))

	# ==========================================
	# 5. MATERIALES: RESTOS DE MONSTRUOS
	# ==========================================
	_register_item(ItemDefinition.new(
		"skeleton_bone", "Hueso Ancestral",
		"Resto óseo endurecido por siglos de nigromancia. Se usa en forja de talismanes de aguante.",
		IconRegistry.get_icon("items", "skeleton_bone"), "material", 25, false, "", 0.0, 0.0, "common"
	))

	_register_item(ItemDefinition.new(
		"goblin_tooth", "Colmillo de Goblin",
		"Diente afilado obtenido de esbirros de los bosques. Material de refuerzo para joyería y forja.",
		IconRegistry.get_icon("items", "goblin_tooth"), "material", 25, false, "", 0.0, 0.0, "common"
	))

	_register_item(ItemDefinition.new(
		"wyvern_scale", "Escama de Dragón",
		"Placa protectora desprendida del Jefe Dragón de Fuego. Posee una resistencia titánica.",
		IconRegistry.get_icon("items", "wyvern_scale"), "material", 10, false, "", 0.0, 0.0, "epic"
	))

	_register_item(ItemDefinition.new(
		"fire_core", "Núcleo Ígneo",
		"Centro condensado de llama viva extraído de bestias elementales. Canalizador piromántico supremo.",
		IconRegistry.get_icon("items", "fire_core"), "material", 10, false, "", 0.0, 0.0, "rare"
	))

	# ==========================================
	# 6. EQUIPO & RELIQUIAS (EQUIPABLES / JOYERÍA)
	# ==========================================
	_register_item(ItemDefinition.new(
		"amulet_vitality", "Amuleto de Vitalidad",
		"Colgante forjado con hierro arcano y raíz de sangre. Otorga +50 de Salud Máxima permanente al portador.",
		IconRegistry.get_icon("items", "amulet_vitality"), "equipment", 1, true, "equip_relic", 50.0, 0.0, "rare", "Vigor Ancestral"
	))

	_register_item(ItemDefinition.new(
		"ring_mana_flow", "Anillo de Flujo Arcano",
		"Sortija de oro rúnico engarzada con éter. Reduce el costo de maná de todos los hechizos en un 20%.",
		IconRegistry.get_icon("items", "ring_mana_flow"), "equipment", 1, true, "equip_relic", 0.20, 0.0, "rare", "Flujo Etéreo"
	))

	_register_item(ItemDefinition.new(
		"talisman_swiftness", "Talismán del Viento",
		"Insignia ligera adornada con escamas y loto estelar. Aumenta la velocidad de movimiento permanente en +20%.",
		IconRegistry.get_icon("items", "talisman_swiftness"), "equipment", 1, true, "equip_relic", 0.20, 0.0, "epic", "Gracia del Viento"
	))

	_register_item(ItemDefinition.new(
		"brooch_pyromancer", "Broche del Piromante",
		"Joya de obsidiana con núcleo de fuego pulsante. Aumenta la potencia de todos los hechizos ígneos en un 25%.",
		IconRegistry.get_icon("items", "brooch_pyromancer"), "equipment", 1, true, "equip_relic", 0.25, 0.0, "epic", "Furia de Fuego"
	))

	# ==========================================
	# 7. OBJETOS DE MISIÓN
	# ==========================================
	_register_item(ItemDefinition.new(
		"arcane_crystal", "Cristal Arcano",
		"Gema primordial impregnada de resonancia arcana pura. Reliquia para reactivar el Altar de Transmutación.",
		IconRegistry.get_icon("items", "arcane_crystal"), "quest", 5, false, "quest_catalyst", 1.0, 0.0, "legendary"
	))

	_register_item(ItemDefinition.new(
		"forest_heart", "Corazón del Bosque",
		"Núcleo místico viviente custodiado por los espíritus arcanos antiguos.",
		IconRegistry.get_icon("items", "forest_heart"), "quest", 1, false, "quest_catalyst", 1.0, 0.0, "legendary"
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

static func get_items_by_category(category: String) -> Array[ItemDefinition]:
	if not _initialized:
		init_db()
	var res: Array[ItemDefinition] = []
	for id in _items:
		if _items[id].category == category:
			res.append(_items[id])
	return res

static func get_items_by_rarity(rarity: String) -> Array[ItemDefinition]:
	if not _initialized:
		init_db()
	var res: Array[ItemDefinition] = []
	for id in _items:
		if _items[id].rarity == rarity:
			res.append(_items[id])
	return res
