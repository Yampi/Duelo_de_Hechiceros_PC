extends Node

const WIZARD_SCENE = preload("res://scenes/Wizard.tscn")
const ENEMY_SCENE = preload("res://scenes/Enemy.tscn")

var results: Dictionary = {}
var failed_spells: Array[String] = []

func _ready() -> void:
	print("\n========================================================")
	print("🧙 HEADLESS TEST SUITE: AUDITORÍA DE TODOS LOS HECHIZOS")
	print("========================================================\n")
	
	run_all_tests()

func run_all_tests() -> void:
	for spell_id in range(1, 10):
		await test_spell(spell_id)
	
	# Test Full Health edge case for Heal
	await test_heal_at_full_health()
	
	print("\n========================================================")
	print("📊 RESUMEN FINAL DE AUDITORÍA DE HECHIZOS")
	print("========================================================")
	for spell_id in range(1, 10):
		var sp_name = GameManager.spells[spell_id]["name"]
		var res = results.get(spell_id, {"status": "FAIL", "reason": "No ejecutado"})
		if res["status"] == "PASS":
			print("  [PASS] Hechizo %d (%s): %s" % [spell_id, sp_name, res.get("details", "OK")])
		else:
			print("  [FAIL] Hechizo %d (%s): %s" % [spell_id, sp_name, res.get("reason", "Error desconocido")])
			failed_spells.append("%d: %s -> %s" % [spell_id, sp_name, res.get("reason", "Error")])
	
	var full_hp_res = results.get("heal_full_hp", {"status": "FAIL", "reason": "No verificado"})
	if full_hp_res["status"] == "PASS":
		print("  [PASS] Regla Fuente de Vida (Vida Completa): No gasta maná ni lanza")
	else:
		print("  [FAIL] Regla Fuente de Vida (Vida Completa): %s" % [full_hp_res.get("reason", "Falló")])
		failed_spells.append("5: Fuente de Vida (Vida Completa) -> %s" % [full_hp_res.get("reason", "Falló")])
	
	print("\nHECHIZOS CON FALLOS DETECTADOS: %d" % [failed_spells.size()])
	for f in failed_spells:
		print("  ❌ %s" % f)
	
	print("========================================================\n")
	get_tree().quit(0 if failed_spells.is_empty() else 1)

func test_spell(spell_id: int) -> void:
	var info = GameManager.spells[spell_id]
	var s_name = info["name"]
	var cost = info["cost"]
	print("--- Evaluando Hechizo %d: %s (Costo: %.1f MP) ---" % [spell_id, s_name, cost])
	
	var test_root = Node3D.new()
	test_root.name = "TestRoot_%d" % spell_id
	add_child(test_root)
	
	# Suelo estático para evitar caída libre de CharacterBody3D
	var floor_body = StaticBody3D.new()
	floor_body.name = "Ground"
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(120, 2, 120)
	col.shape = box
	col.position.y = -1.0
	floor_body.add_child(col)
	test_root.add_child(floor_body)
	
	var player = WIZARD_SCENE.instantiate()
	player.position = Vector3(0, 0.1, 0)
	player.platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	test_root.add_child(player)
	
	# Instanciar enemigo dummy al frente del jugador (-Z)
	var dummy = ENEMY_SCENE.instantiate()
	var target_dist = 3.5 if spell_id == 4 else 6.0
	dummy.position = Vector3(0, 0.1, -target_dist)
	dummy.platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	test_root.add_child(dummy)
	dummy.move_speed = 0.0
	dummy.attack_damage = 0.0
	dummy.look_at(Vector3.ZERO, Vector3.UP)
	var initial_enemy_hp = dummy.current_health
	
	# Desactivar regeneración natural de maná durante el test para medición exacta
	var orig_regen = GameManager.mana_regen_rate
	GameManager.mana_regen_rate = 0.0
	GameManager.player_max_mana = 100.0
	GameManager.player_mana = 100.0
	GameManager.player_health = 50.0 # Salud inicial reducida para medir curación
	
	player.aim_point = dummy.global_position + Vector3(0, 0.8, 0)
	player.select_spell_slot(spell_id)
	var cam = get_viewport().get_camera_3d()
	print("  [DEBUG] Inicio: Player pos: %s, vel: %s, Camera: %s, InX: %f, InY: %f" % [player.global_position, player.velocity, str(cam), Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down")])
	
	var mana_before = GameManager.player_mana
	player.start_spell_channeling()
	
	# Esperar canalización y lanzamiento
	var frames = 0
	while player.is_channeling and frames < 120:
		await get_tree().physics_frame
		frames += 1
	
	print("  [DEBUG] Post-canalizar (f=%d): Player pos: %s, vel: %s" % [frames, player.global_position, player.velocity])
	
	# Un frame adicional para que execute_spell procese
	await get_tree().physics_frame
	
	var mana_after_cast = GameManager.player_mana
	var mana_consumed = mana_before - mana_after_cast
	var mana_ok = abs(mana_consumed - cost) < 0.05
	print("  [DEBUG] Post-cast: Player pos: %s, vel: %s, Maná consumido: %.1f" % [player.global_position, player.velocity, mana_consumed])
	
	# Detectar efecto instanciado en test_root o player (ignorando suelo)
	var instantiated_effect: Node = null
	for child in test_root.get_children():
		if child != player and child != dummy and child != floor_body:
			instantiated_effect = child
			break
	if not instantiated_effect and player.has_node("HealEffect"):
		instantiated_effect = player.get_node("HealEffect")
	elif not instantiated_effect and player.active_shield:
		instantiated_effect = player.active_shield
	
	var effect_instantiated = (instantiated_effect != null)
	if instantiated_effect:
		print("  [DEBUG] Efecto instanciado: %s (%s) en pos %s" % [instantiated_effect.name, instantiated_effect.get_class(), instantiated_effect.global_position if "global_position" in instantiated_effect else "N/A"])
	
	# Esperar 65 frames de física (aprox 1.1s) para que el proyectil viaje o impacte
	for f in range(65):
		await get_tree().physics_frame
	
	var damage_dealt = initial_enemy_hp - dummy.current_health
	var hp_recovered = GameManager.player_health - 50.0
	print("  [DEBUG] Daño: %.1f, HP final dummy: %.1f, Dummy pos final: %s" % [damage_dealt, dummy.current_health, dummy.global_position])
	
	var effect_valid = false
	var reason = ""
	var details = ""
	
	if not mana_ok:
		reason = "Maná incorrecto: consumió %.1f MP (esperado %.1f MP)" % [mana_consumed, cost]
	else:
		match spell_id:
			1: # Centella
				if damage_dealt > 0:
					effect_valid = true
					details = "Impactó enemigo infligiendo %.1f de daño" % damage_dealt
				else:
					reason = "No causó daño al enemigo (HP intacto: %.1f)" % dummy.current_health
			2: # Bola de Fuego
				if damage_dealt > 0:
					effect_valid = true
					details = "Explosión en área infligió %.1f de daño" % damage_dealt
				else:
					reason = "No causó daño de explosión (HP intacto: %.1f)" % dummy.current_health
			3: # Invocar Duende
				var found_minion = false
				for c in test_root.get_children():
					if c.is_in_group("minion") and is_instance_valid(c):
						found_minion = true
						break
				if found_minion:
					effect_valid = true
					details = "Duende aliado instanciado y añadido al grupo 'minion'"
				else:
					reason = "No se encontró ningún duende aliado en el grupo 'minion'"
			4: # Onda Expansiva
				if damage_dealt > 0:
					effect_valid = true
					details = "Onda expansiva golpeó al enemigo infligiendo %.1f de daño" % damage_dealt
				else:
					reason = "No causó daño radial al enemigo a %.1fm" % target_dist
			5: # Fuente de Vida
				if hp_recovered >= 39.0:
					effect_valid = true
					details = "Restauró +%.1f HP al jugador" % hp_recovered
				else:
					reason = "No restauró salud al jugador (+%.1f HP)" % hp_recovered
			6: # Teletransporte
				var dist_moved = player.global_position.length()
				if dist_moved >= 4.0:
					effect_valid = true
					details = "Jugador trasladado a %.1fm de distancia" % dist_moved
				else:
					reason = "El jugador no cambió de posición (distancia: %.1fm)" % dist_moved
			7: # Hielo
				var is_chilled = dummy.chill_timer > 0.0
				if damage_dealt > 0 and is_chilled:
					effect_valid = true
					details = "Daño %.1f y aplicó efecto Slow (chill_timer: %.2fs)" % [damage_dealt, dummy.chill_timer]
				elif damage_dealt <= 0:
					reason = "No causó daño al enemigo"
				else:
					reason = "Causó daño pero NO aplicó slow/chill al enemigo"
			8: # Rayo
				if damage_dealt > 0:
					effect_valid = true
					details = "Descarga de rayo infligió %.1f de daño" % damage_dealt
				else:
					reason = "No causó daño observable al enemigo (HP intacto: %.1f)" % dummy.current_health
			9: # Escudo Mágico
				if player.active_shield and is_instance_valid(player.active_shield):
					# Probar reducción del 65%: daño recibido debe ser 35%
					var hp_before_hit = GameManager.player_health
					player.take_damage(40.0)
					var actual_dmg_taken = hp_before_hit - GameManager.player_health
					# Con 65% reducción, 40 * 0.35 = 14.0
					if abs(actual_dmg_taken - 14.0) < 1.0:
						effect_valid = true
						details = "Escudo activo absorbió 65%% de daño (recibió %.1f de 40.0)" % actual_dmg_taken
					else:
						reason = "Escudo instanciado pero no redujo daño al 65%% (recibió %.1f de 40.0)" % actual_dmg_taken
				else:
					reason = "No se instanció escudo activo en player.active_shield"
	
	# Verificar liberación del efecto
	# Esperar 60 frames más para que los efectos temporales se liberen
	for f in range(60):
		await get_tree().physics_frame
	
	var effect_freed = true
	if is_instance_valid(instantiated_effect) and instantiated_effect != player.active_shield:
		# Si sigue vivo después de su tiempo de vida esperado
		if instantiated_effect.is_inside_tree() and not instantiated_effect.is_queued_for_deletion():
			# Minion debe seguir vivo, el resto de efectos de hechizo deben liberarse
			if spell_id != 3:
				effect_freed = false
				reason += " | Efecto no fue liberado (%s)" % instantiated_effect.name
	
	if effect_valid and effect_freed and mana_ok:
		results[spell_id] = {"status": "PASS", "details": details}
	else:
		results[spell_id] = {"status": "FAIL", "reason": reason}
	
	GameManager.mana_regen_rate = orig_regen
	test_root.queue_free()
	await get_tree().physics_frame

func test_heal_at_full_health() -> void:
	print("--- Evaluando Regla Especial: Fuente de Vida a Vida Completa ---")
	var test_root = Node3D.new()
	test_root.name = "TestRoot_HealFullHP"
	add_child(test_root)
	
	var player = WIZARD_SCENE.instantiate()
	test_root.add_child(player)
	player.global_position = Vector3.ZERO
	
	var orig_regen = GameManager.mana_regen_rate
	GameManager.mana_regen_rate = 0.0
	GameManager.player_max_mana = 100.0
	GameManager.player_mana = 100.0
	GameManager.player_health = GameManager.player_max_health # Vida Completa (100)
	
	player.select_spell_slot(5) # Fuente de Vida
	var mana_before = GameManager.player_mana
	player.start_spell_channeling()
	
	for f in range(60):
		await get_tree().physics_frame
	
	var mana_after = GameManager.player_mana
	var mana_spent = mana_before - mana_after
	
	if mana_spent > 0.0 or player.is_channeling:
		results["heal_full_hp"] = {
			"status": "FAIL",
			"reason": "Gastó %.1f MP o inició casteo a pesar de tener vida completa" % mana_spent
		}
	else:
		results["heal_full_hp"] = {
			"status": "PASS",
			"details": "Lanzamiento bloqueado correctamente y 0 maná gastado"
		}
	
	GameManager.mana_regen_rate = orig_regen
	test_root.queue_free()
	await get_tree().physics_frame
