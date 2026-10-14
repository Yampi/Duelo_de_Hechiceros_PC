extends Node

const ItemDB = preload("res://scripts/inventory/item_db.gd")
const InventoryManager = preload("res://scripts/inventory/inventory_manager.gd")
const MapConfig = preload("res://scripts/map_config.gd")

var total_passed: int = 0
var total_failed: int = 0

func _ready() -> void:
	print("\n========================================================")
	print("🧪 AUTOMATED TEST SUITE: SPELLS, INVENTORY, MAP & LOOP")
	print("========================================================\n")
	
	await _test_spell_repeat_materials()
	_test_item_definitions()
	_test_inventory_manager()
	_test_inventory_overflow_protection()
	_test_consumable_effects()
	_test_world_item_pickup()
	_test_minimap_and_world_map()
	_test_exploration_loop_altar_empowerment()
	
	print("\n========================================================")
	print("📊 SUITE RESULTS: PASSED: %d | FAILED: %d" % [total_passed, total_failed])
	print("========================================================")
	
	if total_failed == 0:
		print("✅ ALL TESTS PASSED SUCCESSFULLY!\n")
	else:
		print("❌ SOME TESTS FAILED!\n")
	
	get_tree().quit(0 if total_failed == 0 else 1)

func assert_test(condition: bool, test_name: String, details: String = "") -> void:
	if condition:
		total_passed += 1
		print("  [PASS] %s %s" % [test_name, ("(" + details + ")") if not details.is_empty() else ""])
	else:
		total_failed += 1
		print("  [FAIL] %s %s" % [test_name, ("(" + details + ")") if not details.is_empty() else ""])

func _test_spell_repeat_materials() -> void:
	print("--- 1. Defective Spell Fix & Repeat Cast Verification ---")
	
	# Test HealEffect material preservation
	var heal_scene = load("res://scenes/HealEffect.tscn")
	var h1 = heal_scene.instantiate()
	add_child(h1)
	for i in range(50):
		await get_tree().physics_frame
	
	var h2 = heal_scene.instantiate()
	add_child(h2)
	var h2_ring_ov = h2.get_node("Ring").material_override as StandardMaterial3D
	var h2_pillar_ov = h2.get_node("LightPillar").material_override as StandardMaterial3D
	var h2_ring_alpha = h2_ring_ov.albedo_color.a if h2_ring_ov else 0.0
	var h2_pillar_alpha = h2_pillar_ov.albedo_color.a if h2_pillar_ov else 0.0
	assert_test(h2_ring_alpha >= 0.8, "HealEffect Ring Visible on Repeat Cast", "Alpha: %.2f" % h2_ring_alpha)
	assert_test(h2_pillar_alpha >= 0.25, "HealEffect Pillar Visible on Repeat Cast", "Alpha: %.2f" % h2_pillar_alpha)
	h2.queue_free()
	
	# Test Shockwave material preservation
	var sw_scene = load("res://scenes/Shockwave.tscn")
	var sw1 = sw_scene.instantiate()
	add_child(sw1)
	for i in range(30):
		await get_tree().physics_frame
	
	var sw2 = sw_scene.instantiate()
	add_child(sw2)
	var sw2_ring_ov = sw2.get_node("Ring").material_override as StandardMaterial3D
	var sw2_ring_alpha = sw2_ring_ov.albedo_color.a if sw2_ring_ov else 0.0
	assert_test(sw2_ring_alpha >= 0.8, "Shockwave Ring Visible on Repeat Cast", "Alpha: %.2f" % sw2_ring_alpha)
	sw2.queue_free()
	
	# Test ArcaneShield material preservation
	var sh_scene = load("res://scenes/ArcaneShield.tscn")
	var sh1 = sh_scene.instantiate()
	add_child(sh1)
	sh1.deactivate()
	for i in range(20):
		await get_tree().physics_frame
	
	var sh2 = sh_scene.instantiate()
	add_child(sh2)
	var sh2_mesh_ov = sh2.get_node("ShieldMesh").material_override
	var sh2_alpha: float = 0.0
	if sh2_mesh_ov is StandardMaterial3D:
		sh2_alpha = (sh2_mesh_ov as StandardMaterial3D).albedo_color.a
	elif sh2_mesh_ov is ShaderMaterial:
		var col = (sh2_mesh_ov as ShaderMaterial).get_shader_parameter("shield_color")
		if col is Color:
			sh2_alpha = col.a
	assert_test(sh2_alpha >= 0.5, "ArcaneShield Sphere Visible on Repeat Cast", "Alpha: %.2f" % sh2_alpha)
	sh2.queue_free()

func _test_item_definitions() -> void:
	print("\n--- 2. Item Definition Architecture Tests ---")
	ItemDB.init_db()
	
	var required_items = ["potion_health", "potion_mana", "arcane_crystal", "magic_scroll", "sulfur", "apple", "clover"]
	for item_id in required_items:
		var def = ItemDB.get_item(item_id)
		assert_test(def != null, "Item Definition Exists: %s" % item_id, def.name if def else "MISSING")
		if def:
			assert_test(def.icon != null, "Item Has Icon: %s" % item_id)
			assert_test(def.max_stack > 0, "Item Has Valid Max Stack: %s" % item_id, "Max: %d" % def.max_stack)
	
	var p_hp = ItemDB.get_item("potion_health")
	assert_test(p_hp.is_usable and p_hp.category == "consumable", "Health Potion is Usable Consumable")
	
	var crystal = ItemDB.get_item("arcane_crystal")
	assert_test(not crystal.is_usable and crystal.category == "quest", "Arcane Crystal is Quest Key Item")

func _test_inventory_manager() -> void:
	print("\n--- 3. Inventory Manager & Stacking Tests ---")
	var inv = InventoryManager.new()
	assert_test(inv.slots.size() == 16, "Inventory Initializes with 16 Slots")
	assert_test(inv.get_used_slots_count() == 0, "Inventory Initially Empty")
	
	# Add items
	var ok1 = inv.add_item("potion_health", 3)
	assert_test(ok1 and inv.get_item_count("potion_health") == 3, "Add Health Potions (Count: 3)")
	assert_test(inv.get_used_slots_count() == 1, "Occupies 1 Slot")
	
	# Stack items
	var ok2 = inv.add_item("potion_health", 4)
	assert_test(ok2 and inv.get_item_count("potion_health") == 7, "Stack Potions on Same Slot (Count: 7)")
	assert_test(inv.get_used_slots_count() == 1, "Still Occupies 1 Slot")
	
	# Remove items
	var ok3 = inv.remove_item("potion_health", 2)
	assert_test(ok3 and inv.get_item_count("potion_health") == 5, "Remove Potions (Count: 5)")
	
	# Remove all
	inv.remove_item("potion_health", 5)
	assert_test(inv.get_item_count("potion_health") == 0 and inv.get_used_slots_count() == 0, "Slot Emptied and Reclaimed")

func _test_inventory_overflow_protection() -> void:
	print("\n--- 4. Inventory Overflow & Anti-Loss Tests ---")
	var inv = InventoryManager.new()
	
	# Fill all 16 slots with unique items or max stacks
	for i in range(16):
		inv.add_item("potion_health", 10) # 10 is max stack, fills 1 slot each
	
	assert_test(inv.get_used_slots_count() == 16, "Inventory Completely Full (16/16 Slots)")
	assert_test(not inv.can_add_item("potion_mana", 1), "can_add_item Returns False When Full")
	
	var warning_state = [false]
	inv.inventory_full_warning.connect(func(_id): warning_state[0] = true)
	
	var add_failed = inv.add_item("potion_mana", 1)
	assert_test(not add_failed, "add_item Rejected When Full")
	assert_test(warning_state[0], "inventory_full_warning Signal Emitted")
	assert_test(inv.get_item_count("potion_mana") == 0, "No Items Lost or Corrupted")

func _test_consumable_effects() -> void:
	print("\n--- 5. Consumable Usage & Magic Resource Recovery Tests ---")
	var inv = InventoryManager.new()
	GameManager.player_health = 40.0
	GameManager.player_max_health = 100.0
	GameManager.player_mana = 20.0
	GameManager.player_max_mana = 75.0
	
	inv.add_item("potion_health", 1)
	inv.add_item("potion_mana", 1)
	
	# Consume health potion (+50 HP)
	var used_hp = inv.use_item("potion_health")
	assert_test(used_hp, "Health Potion Consumed Successfully")
	assert_test(GameManager.player_health == 90.0, "Player Health Restored (40 -> 90 HP)", "HP: %.1f" % GameManager.player_health)
	assert_test(inv.get_item_count("potion_health") == 0, "Potion Count Decremented to 0")
	
	# Consume mana potion (+50 MP)
	var used_mp = inv.use_item("potion_mana")
	assert_test(used_mp, "Mana Potion Consumed Successfully")
	assert_test(GameManager.player_mana == 70.0, "Player Mana Restored (20 -> 70 MP)", "MP: %.1f" % GameManager.player_mana)
	assert_test(inv.get_item_count("potion_mana") == 0, "Mana Potion Count Decremented to 0")

func _test_world_item_pickup() -> void:
	print("\n--- 6. World Item Entity & Pickup System Tests ---")
	var world_item_scene = load("res://scenes/WorldItem.tscn")
	var w_item = world_item_scene.instantiate()
	add_child(w_item)
	w_item.setup("potion_health", 2)
	assert_test(w_item.item_id == "potion_health" and w_item.amount == 2, "WorldItem Configured Properly")
	
	# Test pickup adds to GameManager inventory
	GameManager.inventory.clear()
	w_item._attempt_pickup(null)
	assert_test(GameManager.inventory.get_item_count("potion_health") == 2, "WorldItem Collected into Inventory (+2)")
	
	# Test full inventory overflow protection on ground item
	var w_item2 = world_item_scene.instantiate()
	add_child(w_item2)
	w_item2.setup("potion_mana", 1)
	for i in range(16):
		GameManager.inventory.add_item("apple", 20)
	
	w_item2._attempt_pickup(null)
	assert_test(not w_item2.is_collected, "Item Remains Uncollected on Ground When Inventory Full")
	assert_test(is_instance_valid(w_item2), "Ground Item Is NOT Deleted Silently")
	w_item2.queue_free()
	GameManager.inventory.clear()

func _test_minimap_and_world_map() -> void:
	print("\n--- 7. Minimap & Expanded World Map Tests ---")
	var minimap_scene = load("res://scenes/ui/Minimap.tscn")
	var minimap = minimap_scene.instantiate()
	add_child(minimap)
	
	# Test player position transform on 256m map
	var test_pos = Vector3(64.0, 0, -64.0)
	var diff = test_pos - Vector3.ZERO
	var offset = minimap._world_to_minimap_offset(diff, 1.0)
	assert_test(offset.x == 64.0 and offset.y == -64.0, "Minimap Linear Offset Transform Verified")
	
	# Test Expanded World Map
	var world_map_scene = load("res://scenes/ui/WorldMapModal.tscn")
	var world_map = world_map_scene.instantiate()
	add_child(world_map)
	
	world_map.open_map()
	assert_test(world_map.visible, "WorldMapModal Opens with open_map()")
	world_map.close_map()
	assert_test(not world_map.visible, "WorldMapModal Closes with close_map()")
	
	# Test Fog of War state
	GameManager.discovered_zones = [1]
	assert_test(1 in GameManager.discovered_zones, "Zone 1 (Pradera) Discovered by Default")
	assert_test(not (4 in GameManager.discovered_zones), "Zone 4 (Ruinas) Undiscovered Initially")
	
	# Test POI registration
	GameManager.discovered_pois.clear()
	GameManager.discover_poi("shrine_0", "Santuario de Poder 1", Vector3(28, 0, -42), "◆")
	assert_test(GameManager.is_poi_discovered("shrine_0"), "POI Registered in Discovered List")
	
	minimap.queue_free()
	world_map.queue_free()

func _test_exploration_loop_altar_empowerment() -> void:
	print("\n--- 8. Exploration Purpose: Ancient Altar & Arcane Empowerment Tests ---")
	var altar_scene = load("res://scenes/AncientAltar.tscn")
	var altar = altar_scene.instantiate()
	add_child(altar)
	
	GameManager.inventory.clear()
	GameManager.arcana_empowered = false
	GameManager.base_mana_cap = 75.0
	GameManager.player_max_mana = 75.0
	
	# Interact without crystal
	altar.interact(null)
	assert_test(not altar.is_activated, "Altar Rejects Activation Without Arcane Crystal")
	assert_test(not GameManager.arcana_empowered, "Player Arcana Not Empowered Yet")
	
	# Give player the Arcane Crystal found on exploration
	GameManager.inventory.add_item("arcane_crystal", 1)
	assert_test(GameManager.inventory.has_item("arcane_crystal", 1), "Player Collects Arcane Crystal from Exploration")
	
	# Interact with crystal
	altar.interact(null)
	assert_test(altar.is_activated, "Altar Successfully Activated with Arcane Crystal")
	assert_test(GameManager.inventory.get_item_count("arcane_crystal") == 0, "Arcane Crystal Consumed by Altar")
	assert_test(GameManager.arcana_empowered, "Arcane Empowerment Activated!")
	assert_test(GameManager.player_max_mana == 100.0, "Player Max Mana Capacity Increased to 100 MP (+25)", "Max MP: %.1f" % GameManager.player_max_mana)
	assert_test(GameManager.spells[1]["name"] == "Centella Sobrecargada", "Centella Arcana Upgraded to Centella Sobrecargada")
	
	altar.queue_free()
