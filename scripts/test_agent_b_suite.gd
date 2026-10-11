extends Node

const WIZARD_SCENE = preload("res://scenes/Wizard.tscn")
const ENEMY_SCENE = preload("res://scenes/Enemy.tscn")
const GRIMOIRE_SCENE = preload("res://scenes/ui/GrimoireModal.tscn")

var passes: int = 0
var fails: int = 0

func _ready() -> void:
	print("\n========================================================")
	print("📜 TEST SUITE: AGENT B — GRIMORIO, COOLDOWNS Y NUEVOS HECHIZOS")
	print("========================================================\n")
	run_tests()

func assert_test(condition: bool, test_name: String) -> void:
	if condition:
		print("  ✅ [PASS] %s" % test_name)
		passes += 1
	else:
		print("  ❌ [FAIL] %s" % test_name)
		fails += 1

func run_tests() -> void:
	# 1. Verificar catálogo de 11 hechizos
	assert_test(GameManager.spell_catalog.size() == 11, "Catálogo de hechizos contiene exactamente 11 hechizos")
	assert_test(GameManager.spell_catalog.has("earth_fissure"), "Catálogo contiene 'earth_fissure'")
	assert_test(GameManager.spell_catalog.has("arcane_vines"), "Catálogo contiene 'arcane_vines'")
	assert_test(GameManager.spell_catalog["magic_bolt"]["cost"] == 8.0, "Centella Arcana tiene costo de 8.0 MP")
	
	# 2. Verificar 9 ranuras equipadas por defecto
	assert_test(GameManager.equipped_spell_ids.size() == 9, "Ranuras activas de hotbar son exactamente 9")
	assert_test(GameManager.spells.size() == 9, "Diccionario GameManager.spells sincronizado con 9 ranuras")
	
	# 3. Equipar nuevos hechizos en ranuras
	GameManager.equip_spell(1, "earth_fissure")
	assert_test(GameManager.equipped_spell_ids[0] == "earth_fissure", "Ranura 1 equipó 'earth_fissure'")
	assert_test(GameManager.spells[1]["id"] == "earth_fissure", "GameManager.spells[1] refleja 'earth_fissure'")
	
	GameManager.equip_spell(2, "arcane_vines")
	assert_test(GameManager.equipped_spell_ids[1] == "arcane_vines", "Ranura 2 equipó 'arcane_vines'")
	
	# 4. Guardado y carga de persistencia
	GameManager.save_grimorio()
	GameManager.equipped_spell_ids[0] = "magic_bolt"
	GameManager.load_grimorio()
	assert_test(GameManager.equipped_spell_ids[0] == "earth_fissure", "Persistencia user://grimorio.cfg cargada con éxito")
	
	# 5. Instanciar mundo de prueba para ejecución de hechizos y combate
	var ground = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(100, 2, 100)
	col.shape = box
	col.position.y = -1.0
	ground.add_child(col)
	add_child(ground)
	
	var wizard = WIZARD_SCENE.instantiate()
	wizard.position = Vector3(0, 0.1, 0)
	add_child(wizard)
	
	var dummy = ENEMY_SCENE.instantiate()
	dummy.position = Vector3(0, 0.1, -4.0)
	dummy.move_speed = 0.0
	add_child(dummy)
	
	await get_tree().process_frame
	await get_tree().physics_frame
	
	# 6. Lanzar Earth Fissure y verificar efecto de lentitud / sink
	wizard.selected_spell = 1 # Ranura 1 = earth_fissure
	GameManager.player_mana = 100.0
	wizard.start_spell_channeling()
	
	var frames = 0
	while wizard.is_channeling and frames < 120:
		wizard.aim_point = dummy.global_position
		await get_tree().physics_frame
		frames += 1
	await get_tree().physics_frame
	
	assert_test(wizard.slot_cooldowns.has(1), "Ranura 1 entró en enfriamiento tras lanzar Fisura de Tierra")
	assert_test(wizard.global_cooldown_timer > 0.0, "Global Cooldown activado (0.3s) tras lanzar")
	assert_test(wizard.mana_regen_pause_timer > 0.0, "Pausa de regeneración de maná de 1.5s activada tras lanzamiento")
	
	# Dummy impactado por Earth Fissure
	await get_tree().create_timer(0.25).timeout
	assert_test(dummy.earth_sink_timer > 0.0 or dummy.current_health < 60.0, "Dummy afectado por Fisura de Tierra (daño o ralentización)")
	
	# 7. Lanzar Arcane Vines
	await get_tree().create_timer(0.4).timeout
	wizard.global_cooldown_timer = 0.0
	wizard.slot_cooldowns.clear()
	wizard.selected_spell = 2 # Ranura 2 = arcane_vines
	GameManager.player_mana = 100.0
	wizard.start_spell_channeling()
	
	frames = 0
	while wizard.is_channeling and frames < 120:
		wizard.aim_point = dummy.global_position
		await get_tree().physics_frame
		frames += 1
	await get_tree().physics_frame
	
	await get_tree().create_timer(0.25).timeout
	assert_test(dummy.root_timer > 0.0 or dummy.current_health < 50.0, "Dummy enraizado / impactado por Enredaderas Arcanas")
	
	# 8. Grimoire Modal instanciación e interfaz
	var grimoire_modal = GRIMOIRE_SCENE.instantiate()
	add_child(grimoire_modal)
	assert_test(is_instance_valid(grimoire_modal), "GrimoireModal instanciado correctamente")
	
	grimoire_modal.open_grimoire()
	assert_test(grimoire_modal.visible == true, "GrimoireModal se abre correctamente con open_grimoire()")
	
	grimoire_modal.selected_spell_id = "magic_bolt"
	grimoire_modal.equip_selected_to_slot(1)
	assert_test(GameManager.equipped_spell_ids[0] == "magic_bolt", "GrimoireModal equipó 'magic_bolt' de vuelta en ranura 1")
	
	grimoire_modal.close_grimoire()
	assert_test(grimoire_modal.visible == false, "GrimoireModal se cierra correctamente")
	
	# Restaurar ranuras por defecto
	GameManager.equipped_spell_ids = [
		"magic_bolt", "fireball", "summon_goblin", "shockwave",
		"heal", "teleport", "ice_projectile", "lightning", "arcane_shield"
	]
	GameManager.save_grimorio()
	GameManager._rebuild_spells_dictionary()
	
	print("\n========================================================")
	print("📊 RESULTADOS FINALES AGENT B: %d PASADOS, %d FALLADOS" % [passes, fails])
	print("========================================================\n")
	get_tree().quit(0 if fails == 0 else 1)
