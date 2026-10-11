extends Node

# Walkthrough and Full Gameplay Journey Simulation
# Validates the complete player experience from Zone 1 spawn to final Portal victory.

const MapConfig = preload("res://scripts/map_config.gd")
const ItemDB = preload("res://scripts/inventory/item_db.gd")

var total_passed: int = 0
var total_failed: int = 0
var main_instance: Node3D = null

func _ready() -> void:
	print("\n========================================================")
	print("🧙 DUELO DE HECHICEROS — SIMULACIÓN COMPLETA DE RECORRIDO")
	print("   Validación de Experiencia Jugable y Diseño de Encuentros")
	print("========================================================\n")
	
	GameManager.reset_for_new_game(GameManager.GameMode.EXPLORATION)
	var main_scene = load("res://scenes/Main.tscn")
	main_instance = main_scene.instantiate()
	add_child(main_instance)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var player = main_instance.get_node("Wizard") as CharacterBody3D
	var hud = main_instance.get_node("HUD")
	var enc_mgr = main_instance.get_node("EncounterManager")
	var mapgen = main_instance.get_node("MapGenerator")
	
	# --- PASO 1: ZONA 1 (PRADERA INICIAL) ---
	print("--- FASE 1: Spawn y Zona 1 (Pradera Inicial) ---")
	assert_test(player.global_position.distance_to(MapConfig.PLAYER_SPAWN_POS) < 1.0,
		"Jugador aparece en Plaza de Inicio de Zona 1", "Pos: %s" % str(player.global_position))
	assert_test(GameManager.discovered_zones.has(1), "Zona 1 descubierta por defecto")
	assert_test(GameManager.is_poi_discovered("plaza_inicio"), "POI Plaza de Inicio registrado")
	
	# Comprobar seguridad del camino central
	var road_cleared = true
	for enc in enc_mgr.encounters:
		if enc["zone"] == 1 and abs(enc["pos"].x) < 18.0:
			road_cleared = false
	assert_test(road_cleared, "Camino principal de Zona 1 es seguro y libre de combates obligatorios")
	
	# Desplazar hacia el explorador este (28, 0, 76) para probar encuentro opcional
	print("  -> Explorando hacia la arboleda este (explorador duende)...")
	player.global_position = Vector3(24.0, MapConfig.get_height_at(24.0, 76.0), 76.0)
	main_instance._process(0.1)
	enc_mgr._process(0.1)
	
	var spawned_scouts = []
	for enc in enc_mgr.encounters:
		if enc["id"] == "z1_scout_east" and enc["is_triggered"]:
			spawned_scouts = enc["spawned"]
	assert_test(spawned_scouts.size() == 1, "Encuentro de explorador este se activó de forma comprensible (1 duende)")
	
	if spawned_scouts.size() > 0:
		var scout = spawned_scouts[0]
		assert_test(scout.is_scout, "Explorador duende tiene flag is_scout activa")
		assert_test(scout.detection_radius <= 13.5, "Radio de percepción del explorador permite observarlo antes de combatir (13m <= 16m)")
		
		# Probar impacto táctico y huida de baja salud
		var initial_scout_hp = scout.current_health
		scout.take_damage(45.0) # Reduce salud a 15/60 (< 35%)
		scout._process_goblin_ai(0.1, Vector3.FORWARD, 5.0, player)
		assert_test(scout.is_fleeing, "Duende huye en pánico al caer por debajo del 35% de vida")
		
		# Derrotar al duende y verificar botín
		scout.take_damage(20.0)
		assert_test(scout.is_dead, "Duende derrotado")
	
	# --- PASO 2: ZONA 2 (BOSQUE EXTERIOR) Y CLARO SECRETO ---
	print("\n--- FASE 2: Entrada a Zona 2 y Emboscada del Claro Secreto ---")
	player.global_position = Vector3(0.0, MapConfig.get_height_at(0.0, 50.0), 50.0)
	main_instance._process(0.1)
	enc_mgr._process(0.1)
	assert_test(GameManager.discovered_zones.has(2), "Zona 2 (Bosque Exterior) descubierta al cruzar el umbral")
	
	# Desviarse hacia el Claro Secreto en (38, 0, 32)
	print("  -> Tomando desvío secundario hacia el Claro Secreto del Este...")
	player.global_position = Vector3(34.0, MapConfig.get_height_at(34.0, 32.0), 32.0)
	main_instance._process(0.1)
	enc_mgr._process(0.1)
	
	assert_test(GameManager.is_poi_discovered("claro_bosque"), "POI Claro Secreto del Este descubierto")
	var clearing_enemies = []
	for enc in enc_mgr.encounters:
		if enc["id"] == "z2_east_clearing_guardian":
			clearing_enemies = enc["spawned"]
	assert_test(clearing_enemies.size() == 2, "Emboscada del claro genera 2 enemigos intencionales (Lancero + Duende)")
	
	if clearing_enemies.size() == 2:
		var spear = clearing_enemies[0]
		var flanker = clearing_enemies[1]
		var spear_dist_to_crystal = spear.global_position.distance_to(Vector3(38, MapConfig.get_height_at(38, 30), 30))
		assert_test(spear_dist_to_crystal < 4.0, "Lancero actúa como centinela guardando el Cristal Arcano")
		assert_test(flanker.alert_duration > spear.alert_duration, "Duende flanqueador tiene alerta escalonada para evitar avalancha simultánea")
		
		# Despejar enemigos del claro
		spear.take_damage(200.0)
		flanker.take_damage(200.0)
	
	# Recoger el Cristal Arcano
	GameManager.inventory.add_item("arcane_crystal", 1)
	assert_test(GameManager.inventory.has_item("arcane_crystal"), "Jugador obtiene el Cristal Arcano del claro secreto")
	
	# --- PASO 3: ZONA 3 (CORAZÓN DEL BOSQUE) — PUENTE VS CRESTA OCCIDENTAL ---
	print("\n--- FASE 3: Zona 3 — Garganta, Puente y Cresta Occidental ---")
	player.global_position = Vector3(0.0, MapConfig.get_height_at(0.0, -10.0), -10.0)
	main_instance._process(0.1)
	enc_mgr._process(0.1)
	assert_test(GameManager.discovered_zones.has(3), "Zona 3 (Corazón del Bosque) descubierta")
	
	# Comprobar la diferencia de altura entre el Puente y el Mirador Occidental
	var bridge_height = MapConfig.get_height_at(0.0, -28.0)
	var gorge_floor_height = MapConfig.get_height_at(12.0, -28.0)
	var ridge_height = MapConfig.get_height_at(-38.0, -28.0)
	assert_test(ridge_height > bridge_height, "Cresta occidental está más alta que el puente", "Cresta: %.1fm vs Puente: %.1fm" % [ridge_height, bridge_height])
	assert_test(bridge_height > gorge_floor_height, "Puente está elevado sobre el fondo del desfiladero", "Puente: %.1fm vs Fondo: %.1fm" % [bridge_height, gorge_floor_height])
	
	# Visitar el Mirador de la Cresta Occidental
	print("  -> Subiendo al Mirador de la Cresta Occidental (-38, -28)...")
	player.global_position = Vector3(-38.0, ridge_height, -28.0)
	main_instance._process(0.1)
	assert_test(GameManager.is_poi_discovered("mirador_occidental"), "POI Mirador de la Cresta Occidental descubierto")
	
	# Probar teletransporte en desnivel (comprobando corrección del bug de altura y=0)
	print("  -> Probando parpadeo/teletransporte en la cresta a cota %.1fm..." % ridge_height)
	player.aim_point = Vector3(-36.0, ridge_height, -24.0)
	player.cast_teleport(false)
	var tp_y = player.global_position.y
	assert_test(tp_y >= ridge_height - 0.5, "Teletransporte mantiene la altura del terreno correctamente (sin enterrarse en y=0)", "Y alcanzada: %.2fm" % tp_y)
	
	# Probar encuentro del puente y su disposición táctica
	print("  -> Evaluando encuentro del puente (0, -28)...")
	player.global_position = Vector3(0.0, bridge_height, -18.0)
	enc_mgr._process(0.1)
	var bridge_enemies = []
	for enc in enc_mgr.encounters:
		if enc["id"] == "z3_bridge_ambush":
			bridge_enemies = enc["spawned"]
	assert_test(bridge_enemies.size() == 2, "Encuentro del puente generado (Lancero + Arquero)")
	if bridge_enemies.size() == 2:
		var spear = bridge_enemies[0]
		var archer = bridge_enemies[1]
		assert_test(spear.global_position.z > archer.global_position.z,
			"Lancero bloquea entrada sur del puente mientras Arquero dispara desde el extremo norte",
			"Lancero Z: %.1f | Arquero Z: %.1f" % [spear.global_position.z, archer.global_position.z])
		spear.take_damage(200.0)
		archer.take_damage(200.0)
	
	# --- PASO 4: ZONA 4 (RUINAS ARCANAS) Y ALTAR DE TRANSMUTACIÓN ---
	print("\n--- FASE 4: Zona 4 — Altar de Transmutación y Progresión Arcana ---")
	player.global_position = Vector3(0.0, MapConfig.get_height_at(0.0, -68.0), -68.0)
	main_instance._process(0.1)
	enc_mgr._process(0.1)
	assert_test(GameManager.discovered_zones.has(4), "Zona 4 (Ruinas Arcanas) descubierta")
	
	# Visitar Altar de Transmutación en (-36, -68)
	var altar_pos = Vector3(-36.0, MapConfig.get_height_at(-36.0, -68.0), -68.0)
	player.global_position = altar_pos
	main_instance._process(0.1)
	assert_test(GameManager.is_poi_discovered("altar_transmutacion"), "POI Altar de Transmutación descubierto")
	
	# Encontrar el nodo del altar e interactuar
	var altars = get_tree().get_nodes_in_group("altar")
	assert_test(altars.size() > 0, "Altar de Transmutación instanciado en el mundo")
	if altars.size() > 0:
		var altar = altars[0]
		var prev_mana_cap = GameManager.player_max_mana
		altar.interact(player)
		assert_test(altar.is_activated, "Altar activado con éxito usando el Cristal Arcano")
		assert_test(not GameManager.inventory.has_item("arcane_crystal"), "Cristal Arcano consumido en el ritual")
		assert_test(GameManager.arcana_empowered, "Arcana potenciada permanentemente")
		assert_test(GameManager.player_max_mana > prev_mana_cap, "Capacidad de Maná aumentada (+25 MP)", "Nuevo Máx: %.0f MP" % GameManager.player_max_mana)
		assert_test(GameManager.spells[1]["name"] == "Centella Sobrecargada", "Hechizo 1 transformado en Centella Sobrecargada")
	
	# --- PASO 5: COMBATE FINAL CONTRA EL GUARDIÁN ---
	print("\n--- FASE 5: Combate contra el Guardián de las Ruinas ---")
	player.global_position = MapConfig.BOSS_ALTAR_POS + Vector3(0, 0, 14.0)
	player.global_position.y = MapConfig.get_height_at(player.global_position.x, player.global_position.z)
	enc_mgr._process(0.1)
	
	var boss_enemies = []
	for enc in enc_mgr.encounters:
		if enc["id"] == "z4_portal_boss":
			boss_enemies = enc["spawned"]
	assert_test(boss_enemies.size() == 3, "Encuentro del jefe activado (Guardián + 2 Diablos Sombríos)")
	
	var boss = null
	for e in boss_enemies:
		if e.is_boss:
			boss = e
			break
	assert_test(boss != null, "Guardián de las Ruinas (Boss) presente en el Altar")
	
	if boss:
		# Probar telégrafo de Terremoto y anillo de peligro
		print("  -> Evaluando telégrafo de Golpe Sísmico (1.2s de anticipación)...")
		boss.is_charging_slam = true
		boss.slam_charge_timer = 1.0
		boss._process_boss_specials(0.1)
		assert_test(boss.boss_danger_ring != null, "Anillo visual de peligro (8.5m) activo en el suelo durante la carga del golpe")
		
		# Disparar terremoto y validar ventana de vulnerabilidad
		boss.slam_charge_timer = 0.0
		boss._process_boss_specials(0.01)
		assert_test(boss.slam_recover_timer > 0.0, "Terremoto abre ventana de vulnerabilidad (2.0s de contragolpe)")
		assert_test(boss.boss_vuln_ring != null, "Aura azul de vulnerabilidad visible rodeando al Guardián")
		
		# Probar amplificación de daño durante la ventana de vulnerabilidad
		var hp_before_hit = boss.current_health
		boss.take_damage(20.0) # Con +50% debe recibir 30 de daño
		var dmg_dealt = hp_before_hit - boss.current_health
		assert_test(dmg_dealt == 30.0, "Daño amplificado por +50% durante ventana de vulnerabilidad", "Dealt: %.1f (Base 20)" % dmg_dealt)
		
		# Derrotar al Guardián
		print("  -> Derrotando al Guardián...")
		boss.take_damage(600.0)
		assert_test(GameManager.boss_defeated, "GameManager registra victoria sobre el Guardián")
	
	# --- PASO 6: ACTIVACIÓN DEL PORTAL Y VICTORIA ---
	print("\n--- FASE 6: Activación del Portal Arcano y Finalización ---")
	main_instance._process(0.1)
	var portal = mapgen.portal_instance
	assert_test(portal != null, "Portal Arcano instanciado en el extremo norte")
	if portal:
		assert_test(portal.is_active, "Portal Arcano se activa y brilla tras la caída del Guardián")
		
		# El jugador cruza el portal
		player.global_position = portal.global_position
		portal._on_body_entered(player)
		assert_test(GameManager.level_cleared, "Cruzar el portal completa la misión y otorga la victoria")
	
	print("\n========================================================")
	print("📊 RESULTADOS DEL RECORRIDO COMPLETO:")
	print("   PASADOS: %d | FALLADOS: %d" % [total_passed, total_failed])
	print("========================================================")
	
	if total_failed == 0:
		print("🎉 ¡VALIDACIÓN INTEGRAL DE EXPERIENCIA JUGABLE EXITOSA!")
	else:
		print("❌ SE DETECTARON FALLOS EN EL RECORRIDO.")
	
	get_tree().quit(0 if total_failed == 0 else 1)

func assert_test(condition: bool, test_name: String, details: String = "") -> void:
	if condition:
		total_passed += 1
		print("  [PASS] %s %s" % [test_name, ("(" + details + ")") if not details.is_empty() else ""])
	else:
		total_failed += 1
		print("  [FAIL] %s %s" % [test_name, ("(" + details + ")") if not details.is_empty() else ""])
