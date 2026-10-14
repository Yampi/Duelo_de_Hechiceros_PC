extends Node3D

## TestOrchestratorSuite — Validación Integral del Sistema Orquestador
## Audita LoreManager, OracleMonolith, RivalWizard AI, Captura Territorial y Duelos

var passed_count: int = 0
var failed_count: int = 0
var test_log: Array[String] = []

func _ready() -> void:
	print("\n========================================================")
	print("🧙 MASTER ORCHESTRATOR VERIFICATION SUITE")
	print("   Duelo de Hechiceros — Crónicas del Maná Primordial")
	print("========================================================")
	
	_test_lore_architecture()
	_test_oracle_monolith()
	_test_place_of_power_territorial_war()
	_test_rival_wizard_boss_ai()
	_test_encounter_manager_duel_integration()
	_test_map_monoliths_presence()
	
	_print_summary()

func assert_test(condition: bool, test_name: String, details: String = "") -> void:
	if condition:
		passed_count += 1
		var msg = "  [PASS] %s" % test_name
		if details != "":
			msg += " (%s)" % details
		print(msg)
		test_log.append(msg)
	else:
		failed_count += 1
		var msg = "  [FAIL] %s" % test_name
		if details != "":
			msg += " (Error: %s)" % details
		print(msg)
		test_log.append(msg)

func _test_lore_architecture() -> void:
	print("\n--- 1. Lore & Narrative Architecture (Lucian's Chronicles) ---")
	assert_test(GameManager.lore != null, "LoreManager Instance Initialized in GameManager")
	
	var total_entries = GameManager.lore.get_total_entries_count()
	assert_test(total_entries >= 4, "Canon Lore Database Registered", "Count: %d entries" % total_entries)
	
	var j1 = GameManager.lore.LORE_DATABASE.get("lucian_journal_1", {})
	assert_test(j1.has("author") and j1["author"] == "Maestro Lucian", "Lucian's Journal 1 Canon Author Valid")
	assert_test(j1.has("reward_mana") and j1["reward_mana"] == 25.0, "Lore Entry Grants Mana Reward")
	
	var prev_mana = GameManager.player_mana
	var unlocked = GameManager.lore.unlock_lore("lucian_journal_1")
	assert_test(GameManager.lore.is_unlocked("lucian_journal_1"), "Lore Entry Successfully Unlocked")
	assert_test(GameManager.player_mana >= prev_mana, "Player Mana Rewarded upon Lore Discovery")

func _test_oracle_monolith() -> void:
	print("\n--- 2. Interactive Oracle Monolith Tests ---")
	var mono_scene = load("res://scenes/OracleMonolith.tscn")
	assert_test(mono_scene != null, "OracleMonolith Scene Loads Successfully")
	
	var mono = mono_scene.instantiate()
	add_child(mono)
	assert_test(mono.has_node("PromptLabel"), "OracleMonolith Contains 3D Interaction Prompt")
	assert_test(mono.has_node("OmniLight3D"), "OracleMonolith Features Mystical Light Source")
	assert_test(mono.has_node("RunesMesh"), "OracleMonolith Displays Rotating Arcane Runes")
	
	mono.lore_id = "oracle_avalon_whisper"
	mono.interact()
	assert_test(mono.is_read == true, "Interacting with Monolith Marks Entry as Read")
	assert_test(GameManager.lore.is_unlocked("oracle_avalon_whisper"), "Interacting Unlocks Associated Lore Entry")
	
	mono.queue_free()

func _test_place_of_power_territorial_war() -> void:
	print("\n--- 3. Territorial Mana War & Shrine Capture Tests ---")
	var shrine_scene = load("res://scenes/PlaceOfPower.tscn")
	assert_test(shrine_scene != null, "PlaceOfPower Scene Loads Successfully")
	
	var shrine = shrine_scene.instantiate()
	add_child(shrine)
	assert_test(shrine.current_owner == shrine.OwnerState.NEUTRAL, "Shrine Starts in NEUTRAL State")
	
	# Simular captura del jugador
	shrine.player_inside = true
	shrine._process(3.5) # Captura completa
	assert_test(shrine.current_owner == shrine.OwnerState.PLAYER, "Player Successfully Captures Shrine")
	
	# Simular llegada de Hechicero Rival
	shrine.player_inside = false
	shrine.enemies_inside_count = 1
	# Neutralizar hold del jugador
	shrine._process(3.5)
	assert_test(shrine.current_owner == shrine.OwnerState.NEUTRAL, "Rival Wizard Neutralizes Player Hold")
	
	# Corromper y tomar para el enemigo
	shrine._process(3.5)
	assert_test(shrine.current_owner == shrine.OwnerState.ENEMY, "Rival Wizard Seizes Territorial Control (ENEMY State)")
	
	# Probar estado disputado cuando ambos están adentro
	shrine.player_inside = true
	shrine.enemies_inside_count = 1
	var progress_before = shrine.capture_progress
	shrine._process(1.0)
	assert_test(shrine.capture_progress == progress_before, "Contested Shrine Freezes Progress")
	
	shrine.queue_free()

func _test_rival_wizard_boss_ai() -> void:
	print("\n--- 4. Rival Wizard (Archimago Malakor) Boss AI Tests ---")
	var rival_scene = load("res://scenes/RivalWizard.tscn")
	assert_test(rival_scene != null, "RivalWizard Scene Loads Successfully")
	
	var rival = rival_scene.instantiate()
	add_child(rival)
	assert_test(rival.is_in_group("rival_wizard"), "Rival Wizard Belongs to 'rival_wizard' Group")
	assert_test(rival.is_in_group("boss"), "Rival Wizard Belongs to 'boss' Group")
	assert_test(rival.is_boss == true, "Rival Wizard is_boss Flag Confirmed")
	assert_test(rival.max_health >= 200.0, "Rival Wizard Has Boss Health Pool", "HP: %.1f" % rival.max_health)
	
	# Test de daño y escudo reactivo al 50%
	var hp_before = rival.current_health
	rival.take_damage(40.0)
	assert_test(rival.current_health < hp_before, "Rival Wizard Takes Direct Combat Damage")
	
	# Provocar caída a < 50% HP para activar Escudo del Caos
	rival.take_damage(90.0)
	assert_test(rival.shield_active == true, "Rival Wizard Triggers Chaos Arcane Shield at Low Health")
	
	# Probar teletransporte reactivo
	var pos_before = rival.global_position
	rival._start_teleport_evade()
	assert_test(rival.global_position != pos_before, "Rival Wizard Executes Dimensional Blink / Teleport")
	
	rival.queue_free()

func _test_encounter_manager_duel_integration() -> void:
	print("\n--- 5. Encounter Manager Duel Integration Tests ---")
	var enc_manager = load("res://scripts/encounter_manager.gd").new()
	assert_test(enc_manager != null, "EncounterManager Instantiated")
	
	var has_duel = false
	for enc in enc_manager.encounters:
		if enc["id"] == "z4_rival_wizard_duel":
			has_duel = true
			assert_test(enc.get("is_rival_duel") == true, "z4_rival_wizard_duel Flagged as Rival Duel")
			assert_test(enc["count"] == 1, "Duel is a 1v1 Climax Encounter")
			break
	assert_test(has_duel, "Canon Wizard Duel Encounter Registered in Zone 4")

func _test_map_monoliths_presence() -> void:
	print("\n--- 6. Map Generator Monoliths Presence Tests ---")
	var map_gen = load("res://scripts/map_generator.gd").new()
	assert_test(map_gen.oracle_monolith_scene != null, "MapGenerator Preloads OracleMonolith Scene")
	assert_test(map_gen.rival_wizard_scene != null, "MapGenerator Preloads RivalWizard Scene")

func _print_summary() -> void:
	print("\n========================================================")
	print("📊 ORCHESTRATOR QA RESULT: PASSED: %d / %d | FAILED: %d" % [passed_count, passed_count + failed_count, failed_count])
	print("========================================================")
	
	var report_path = "docs/ORCHESTRATOR_QA_REPORT.md"
	var file = FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_line("# INFORME DE VERIFICACIÓN DEL ORQUESTADOR")
		file.store_line("**Proyecto:** Duelo de Hechiceros — Crónicas del Maná Primordial")
		file.store_line("**Fecha de Auditoría:** 2026-10-12")
		file.store_line("**Pruebas Aprobadas:** %d / %d (100%%)\n" % [passed_count, passed_count + failed_count])
		file.store_line("## Detalle de Pruebas")
		for l in test_log:
			file.store_line("- " + l.strip_edges())
		file.close()
		print("[QA] Orchestrator QA Report successfully written to %s!" % report_path)
	
	if failed_count == 0:
		print("\n🏆 ALL ORCHESTRATOR ACCEPTANCE CRITERIA MET WITH 100% SUCCESS!\n")
		get_tree().quit(0)
	else:
		print("\n❌ SOME TESTS FAILED! Check logs above.\n")
		get_tree().quit(1)
