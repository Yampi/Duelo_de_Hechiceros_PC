extends Node

const ItemDB = preload("res://scripts/inventory/item_db.gd")
const ItemDefinition = preload("res://scripts/inventory/item_definition.gd")
const CraftingRecipe = preload("res://scripts/crafting/crafting_recipe.gd")
const CraftingManager = preload("res://scripts/crafting/crafting_manager.gd")
const GatheringNode = preload("res://scripts/gathering_node.gd")
const CraftingModal = preload("res://scripts/ui/crafting_modal.gd")

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

func _ready() -> void:
	print("\n========================================================")
	print("🧪 TEST SUITE: AGENT E — ÍTEMS, ALQUIMIA, FORJA Y COCINA")
	print("========================================================\n")
	
	_run_all_tests()
	
	print("\n========================================================")
	print("📊 RESULTADOS FINALES AGENT E: %d PASADOS, %d FALLADOS" % [passed_tests, failed_tests])
	print("========================================================\n")
	
	if failed_tests == 0:
		get_tree().quit(0)
	else:
		get_tree().quit(1)

func assert_test(condition: bool, message: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  ✅ [PASS] %s" % message)
	else:
		failed_tests += 1
		print("  ❌ [FAIL] %s" % message)

func _run_all_tests() -> void:
	# -------------------------------------------------------------
	# 1. CATALOGO DE ÍTEMS EN ItemDB
	# -------------------------------------------------------------
	var all_items = ItemDB.get_all_items()
	assert_test(all_items.size() >= 28, "Catálogo ItemDB contiene al menos 28 ítems registrados (Total actual: %d)" % all_items.size())
	
	var consumables = ItemDB.get_items_by_category("consumable")
	var materials = ItemDB.get_items_by_category("material")
	var equipment = ItemDB.get_items_by_category("equipment")
	var quest_items = ItemDB.get_items_by_category("quest")
	
	assert_test(consumables.size() >= 10, "Categoría consumibles cuenta con al menos 10 pociones y platos (Actual: %d)" % consumables.size())
	assert_test(materials.size() >= 12, "Categoría materiales cuenta con al menos 12 recursos flora, minerales y monstruos (Actual: %d)" % materials.size())
	assert_test(equipment.size() >= 4, "Categoría equipo cuenta con al menos 4 reliquias y joyas mágicas (Actual: %d)" % equipment.size())
	assert_test(quest_items.size() >= 2, "Categoría misiones cuenta con al menos 2 reliquias arcanas (Actual: %d)" % quest_items.size())
	
	# Verificación de ítems clave de Agent E
	var elix = ItemDB.get_item("potion_elixir")
	assert_test(elix != null and elix.effect_type == "heal_both" and elix.rarity == "epic", "Elixir de Doble Esencia configurado como épico y cura vida + maná")
	
	var invuln = ItemDB.get_item("potion_invulnerability")
	assert_test(invuln != null and invuln.effect_type == "invulnerability" and invuln.effect_duration >= 4.0, "Poción de Inmunidad otorga invulnerabilidad con duración >= 4s")
	
	var banquet = ItemDB.get_item("sorcerer_banquet")
	assert_test(banquet != null and banquet.effect_type == "banquet_buff" and banquet.effect_duration >= 30.0, "Banquete del Archimago otorga buff extendido de 30s")
	
	var amulet = ItemDB.get_item("amulet_vitality")
	assert_test(amulet != null and amulet.category == "equipment" and amulet.effect_value == 50.0, "Amuleto de Vitalidad otorga +50 HP de equipamiento")

	# -------------------------------------------------------------
	# 2. MOTOR DE RECETAS Y TALLERES (CraftingManager)
	# -------------------------------------------------------------
	assert_test(GameManager.crafting != null, "CraftingManager está inicializado y vinculado en GameManager")
	var cm = GameManager.crafting
	
	var all_recipes = cm.get_all_recipes()
	assert_test(all_recipes.size() >= 17, "Sistema de crafteo contiene al menos 17 recetas disponibles (Actual: %d)" % all_recipes.size())
	
	var alchemy_recipes = cm.get_recipes_by_station("alchemy")
	var cooking_recipes = cm.get_recipes_by_station("cooking")
	var forge_recipes = cm.get_recipes_by_station("forge")
	var herbalism_recipes = cm.get_recipes_by_station("herbalism")
	
	assert_test(alchemy_recipes.size() >= 5, "Taller de Alquimia cuenta con al menos 5 recetas (Actual: %d)" % alchemy_recipes.size())
	assert_test(cooking_recipes.size() >= 4, "Taller de Cocina cuenta con al menos 4 recetas (Actual: %d)" % cooking_recipes.size())
	assert_test(forge_recipes.size() >= 4, "Forja Rúnica cuenta con al menos 4 recetas de joyas y equipo (Actual: %d)" % forge_recipes.size())
	assert_test(herbalism_recipes.size() >= 4, "Mesa de Herbolaria cuenta con al menos 4 recetas de transmutación (Actual: %d)" % herbalism_recipes.size())

	# -------------------------------------------------------------
	# 3. EJECUCIÓN Y CONSUMO DE CRAFTEO
	# -------------------------------------------------------------
	var inv = GameManager.inventory
	assert_test(inv != null, "Inventario de GameManager disponible")
	inv.clear()
	
	# Comprobar que no se puede craftear Poción de Vida Mayor sin ingredientes
	assert_test(not cm.can_craft("recipe_pot_health_greater"), "can_craft rechaza crafteo si faltan ingredientes en inventario")
	assert_test(not cm.craft("recipe_pot_health_greater"), "craft() retorna false cuando no hay suficientes ingredientes")
	
	# Otorgar ingredientes requeridos para Poción de Vida Mayor: potion_health x2, blood_root x1
	inv.add_item("potion_health", 2)
	inv.add_item("blood_root", 1)
	assert_test(cm.can_craft("recipe_pot_health_greater"), "can_craft autoriza crafteo cuando el inventario posee todos los reactivos")
	
	var craft_ok = cm.craft("recipe_pot_health_greater")
	assert_test(craft_ok, "craft() ejecuta la receta con éxito")
	assert_test(inv.get_item_count("potion_health") == 0, "Ingredientes 'potion_health' consumidos adecuadamente (quedan 0)")
	assert_test(inv.get_item_count("blood_root") == 0, "Ingredientes 'blood_root' consumidos adecuadamente (quedan 0)")
	assert_test(inv.get_item_count("potion_health_greater") == 1, "Producto 'potion_health_greater' agregado correctamente al inventario")

	# -------------------------------------------------------------
	# 4. BUFFS CONSUMIBLES, REGENERACIÓN GRADUAL Y RELIQUIAS
	# -------------------------------------------------------------
	var player_scene = load("res://scenes/Wizard.tscn")
	assert_test(player_scene != null, "Escena Wizard.tscn cargada exitosamente")
	var player = player_scene.instantiate()
	add_child(player)
	
	# Probar Buff de Inmunidad Arcana
	GameManager.player_health = 80.0
	player.apply_invulnerability_buff(5.0)
	assert_test(player.invulnerability_timer >= 4.9, "Buff de inmunidad asigna temporizador >= 4.9s")
	
	# Intentar infligir daño mientras está inmune
	player.take_damage(50.0)
	assert_test(GameManager.player_health == 80.0, "take_damage() no reduce vida mientras el jugador esté bajo inmunidad arcana")
	
	# Probar Regeneración Gradual
	player.apply_regen_buff("hp", 15.0, 6.0)
	assert_test(player.regen_hp_timer >= 5.9 and player.regen_hp_rate == 15.0, "Buff de regeneración gradual HP activado con tasa 15 HP/s")
	
	player._physics_process(1.0)
	assert_test(GameManager.player_health == 95.0, "Un tick de física regenera exactamente 15 HP (80 -> 95)")
	
	# Probar Reliquia de Equipamiento: Amuleto de Vitalidad (+50 Salud Máxima)
	var base_max_hp = GameManager.player_max_health
	player.toggle_equip_relic("amulet_vitality")
	assert_test("amulet_vitality" in player.equipped_relics, "Amuleto de Vitalidad se registra como equipado")
	assert_test(GameManager.player_max_health == base_max_hp + 50.0, "Salud máxima del jugador aumenta en +50 al equipar reliquia")
	
	player.toggle_equip_relic("amulet_vitality")
	assert_test(not ("amulet_vitality" in player.equipped_relics), "Amuleto de Vitalidad se desequipa correctamente")
	assert_test(GameManager.player_max_health == base_max_hp, "Salud máxima del jugador retorna al valor base al desequipar")

	# -------------------------------------------------------------
	# 5. NODO DE RECOLECCIÓN EN EL MUNDO (GatheringNode)
	# -------------------------------------------------------------
	var gnode_scene = load("res://scenes/GatheringNode.tscn")
	assert_test(gnode_scene != null, "Escena GatheringNode.tscn cargada con éxito")
	var gnode = gnode_scene.instantiate() as GatheringNode
	add_child(gnode)
	gnode.resource_item_id = "berry"
	gnode.min_yield = 2
	gnode.max_yield = 2
	
	assert_test(gnode.can_gather, "Nodo de recolección se inicializa en estado recolectable (can_gather = true)")
	var berries_before = inv.get_item_count("berry")
	var gathered = gnode.gather(player)
	assert_test(gathered, "gather() recolecta recursos del nodo exitosamente")
	assert_test(inv.get_item_count("berry") == berries_before + 2, "Inventario recibe el rendimiento de 2 bayas silvestres")
	assert_test(not gnode.can_gather, "Nodo de recolección entra en cooldown tras ser cosechado")
	assert_test(not gnode.gather(player), "gather() deniega recolectas consecutivas mientras el nodo está agotado")
	
	gnode.respawn()
	assert_test(gnode.can_gather, "respawn() restaura el nodo a estado disponible")

	# -------------------------------------------------------------
	# 6. MODAL UI DE CRAFTEO (CraftingModal)
	# -------------------------------------------------------------
	var craft_ui_scene = load("res://scenes/ui/CraftingModal.tscn")
	assert_test(craft_ui_scene != null, "Escena CraftingModal.tscn cargada exitosamente")
	var craft_ui = craft_ui_scene.instantiate() as CraftingModal
	add_child(craft_ui)
	
	assert_test(craft_ui.tab_alchemy != null, "Pestaña TabAlchemy encontrada en CraftingModal")
	assert_test(craft_ui.tab_cooking != null, "Pestaña TabCooking encontrada en CraftingModal")
	assert_test(craft_ui.tab_forge != null, "Pestaña TabForge encontrada en CraftingModal")
	assert_test(craft_ui.tab_herbalism != null, "Pestaña TabHerbalism encontrada en CraftingModal")
	assert_test(craft_ui.btn_craft != null, "Botón BtnCraft encontrado en CraftingModal")
	
	# Abrir y conmutar modal
	craft_ui.open_crafting()
	assert_test(craft_ui.visible, "open_crafting() hace visible la ventana de creación")
	
	craft_ui.toggle_crafting()
	assert_test(not craft_ui.visible, "toggle_crafting() oculta la ventana cuando estaba abierta")
	
	# Cambio de estación a Cocina
	craft_ui.open_crafting()
	craft_ui._select_station("cooking")
	assert_test(craft_ui.current_station == "cooking", "Selección de pestaña cambia estación activa a 'cooking'")
	assert_test(craft_ui.recipes_container.get_child_count() >= 4, "Contenedor de recetas muestra las recetas de Cocina")

	# -------------------------------------------------------------
	# 7. INTEGRACIÓN CON HUD
	# -------------------------------------------------------------
	var hud_scene = load("res://scenes/HUD.tscn")
	assert_test(hud_scene != null, "Escena HUD.tscn cargada exitosamente")
	var hud = hud_scene.instantiate()
	add_child(hud)
	
	assert_test(hud.crafting_modal != null, "HUD contiene instancia vinculada de CraftingModal")
	assert_test(hud.btn_craft_toggle != null, "HUD contiene botón de acceso rápido BtnCraftToggle en NavRow")
	
	hud.toggle_crafting()
	assert_test(hud.crafting_modal.visible, "toggle_crafting() en HUD despliega correctamente el modal de crafteo")
	hud.toggle_crafting()
	assert_test(not hud.crafting_modal.visible, "toggle_crafting() en HUD cierra el modal de crafteo limpiamente")
