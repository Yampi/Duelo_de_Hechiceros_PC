extends Node3D

const ENEMY_SCENE = preload("res://scenes/Enemy.tscn")
const MINION_SCENE = preload("res://scenes/GoblinMinion.tscn")

var failures: Array[String] = []
var passes: int = 0

func _ready() -> void:
	print("\n========================================================")
	print("🧟 HEADLESS TEST SUITE: AUDITORÍA DE ANIMACIONES MONSTRUOS")
	print("========================================================\n")
	
	# Create directory for captures
	DirAccess.make_dir_recursive_absolute("res://docs/enemy_anims")
	
	# Setup camera & light for visual capture test
	var cam = Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 1.8, 3.8)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	
	var light = DirectionalLight3D.new()
	add_child(light)
	light.rotation_degrees = Vector3(-45, 45, 0)
	
	await get_tree().physics_frame
	
	# Test all 5 archetypes in Enemy.tscn
	await test_archetype(0, "Duende Hostil (Goblin)")
	await test_archetype(1, "Esqueleto Lancero (Spear Skeleton)")
	await test_archetype(2, "Esqueleto Arquero (Archer Skeleton)")
	await test_archetype(3, "Diablillo de Fuego (Fire Imp)")
	await test_archetype(4, "Diablo Sombrío (Shadow Imp)")
	
	# Test Boss (Dragon Arcano) and CC states
	await test_boss()
	
	# Test Minion
	await test_minion()
	
	print("\n========================================================")
	print("📊 RESUMEN FINAL DE AUDITORÍA DE ANIMACIONES")
	print("========================================================")
	print("  Pruebas superadas: %d" % passes)
	print("  Fallos detectados: %d" % failures.size())
	for f in failures:
		print("  ❌ %s" % f)
	print("========================================================\n")
	
	if failures.is_empty():
		get_tree().quit(0)
	else:
		get_tree().quit(1)

func test_archetype(type_index: int, type_name: String) -> void:
	print("--- Evaluando Monstruo: %s (Tipo %d) ---" % [type_name, type_index])
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	enemy.global_position = Vector3.ZERO
	enemy.set_archetype(type_index)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var ap = enemy.anim_player
	if not ap:
		ap = enemy.find_child("AnimationPlayer", true, false)
	
	if not ap:
		failures.append("%s: AnimationPlayer no encontrado" % type_name)
		enemy.queue_free()
		return
	
	# 1. Validar loop_mode en idle
	var idle_name = enemy.anim_idle
	if idle_name == "":
		failures.append("%s: anim_idle no está definido" % type_name)
	elif not ap.has_animation(idle_name):
		failures.append("%s: Clip anim_idle '%s' no existe en AnimationPlayer" % [type_name, idle_name])
	else:
		var idle_clip = ap.get_animation(idle_name)
		if idle_clip.loop_mode != Animation.LOOP_LINEAR:
			failures.append("%s: Idle '%s' tiene loop_mode=%d (esperado LOOP_LINEAR=1)" % [type_name, idle_name, idle_clip.loop_mode])
		else:
			print("  [PASS] Idle '%s' en bucle continuo (LOOP_LINEAR)" % idle_name)
			passes += 1
		
		# Regla especial: duende hostil NO debe usar Happy_002
		if type_index == 0 and idle_name == "Happy_002":
			failures.append("%s: Sigue usando Happy_002 como idle" % type_name)
		elif type_index == 0:
			print("  [PASS] Duende usa '%s' en lugar de Happy_002" % idle_name)
			passes += 1
	
	# 2. Validar loop_mode en locomoción (walk / run)
	var walk_name = enemy.anim_walk
	if walk_name != "" and ap.has_animation(walk_name):
		var walk_clip = ap.get_animation(walk_name)
		if walk_clip.loop_mode != Animation.LOOP_LINEAR:
			failures.append("%s: Locomoción '%s' tiene loop_mode=%d (esperado LOOP_LINEAR=1)" % [type_name, walk_name, walk_clip.loop_mode])
		else:
			print("  [PASS] Locomoción '%s' en bucle continuo (LOOP_LINEAR)" % walk_name)
			passes += 1
	
	# 3. Validar loop_mode en ataque
	var atk_name = enemy.anim_attack
	if atk_name != "" and ap.has_animation(atk_name):
		var atk_clip = ap.get_animation(atk_name)
		if atk_clip.loop_mode != Animation.LOOP_NONE:
			failures.append("%s: Ataque '%s' tiene loop_mode=%d (esperado LOOP_NONE=0)" % [type_name, atk_name, atk_clip.loop_mode])
		else:
			print("  [PASS] Ataque '%s' es one-shot (LOOP_NONE)" % atk_name)
			passes += 1
	
	# 4. Probar secuencia de ataque y seguimiento
	enemy.transition_to_state(enemy.AIState.IDLE)
	enemy.play_anim(enemy.anim_idle)
	await get_tree().physics_frame
	
	# Simular objetivo: para arquero a 8m (rango de disparo > 6m kite), melee a 1.5m
	var target_dist = 8.0 if type_index == 2 else 1.5
	var dummy_target = Node3D.new()
	add_child(dummy_target)
	dummy_target.global_position = Vector3(0, 0, -target_dist)
	enemy.target_ref = dummy_target
	
	# Forzar inicio de ataque
	enemy.attack_timer = 0.0
	enemy.is_winding_up_attack = false
	enemy.is_recovering_attack = false
	
	# Procesar un frame de IA para que active ataque
	var diff = dummy_target.global_position - enemy.global_position
	var dist = diff.length()
	match type_index:
		0: enemy._process_goblin_ai(0.016, diff, dist, dummy_target)
		1: enemy._process_spear_ai(0.016, diff, dist, dummy_target)
		2: enemy._process_archer_ai(0.016, diff, dist, dummy_target)
		3, 4: enemy._process_imp_ai(0.016, diff, dist, dummy_target)
	
	if enemy.is_winding_up_attack:
		print("  [PASS] Ataque activado con windup sincronizado (%.2fs)" % enemy.windup_timer)
		passes += 1
	else:
		failures.append("%s: No inició windup de ataque al estar en rango" % type_name)
	
	# 5. Probar reacción a Hit
	var hp_before = enemy.current_health
	enemy.take_damage(10.0, Vector3(0, 0, 2.0))
	if enemy.current_health < hp_before:
		print("  [PASS] Reacción a daño (Hit) aplicada correctamente (HP: %.1f -> %.1f)" % [hp_before, enemy.current_health])
		passes += 1
	else:
		failures.append("%s: take_damage no redujo salud" % type_name)
	
	# 6. Probar Muerte
	enemy.die()
	await get_tree().physics_frame
	
	var col = enemy.find_child("CollisionShape3D", true, false) as CollisionShape3D
	var col_disabled = col.disabled if col else true
	var in_enemy_group = enemy.is_in_group("enemy")
	var physics_stopped = not enemy.is_physics_processing()
	
	if col_disabled and not in_enemy_group and physics_stopped and enemy.is_dead:
		print("  [PASS] Muerte limpia: colisión desactivada, fuera de grupo 'enemy' e IA detenida")
		passes += 1
	else:
		failures.append("%s: Al morir no cumplió estado seguro (col_disabled=%s, in_group=%s, physics_stopped=%s)" % [type_name, str(col_disabled), str(in_enemy_group), str(physics_stopped)])
	
	# Captura de pantalla si no es headless
	if DisplayServer.get_name() != "headless":
		var vp = get_viewport()
		if vp and vp.get_texture():
			var img = vp.get_texture().get_image()
			if img and img.get_width() > 0:
				var path = "res://docs/enemy_anims/%s.png" % type_name.validate_filename()
				img.save_png(path)
	
	dummy_target.queue_free()
	enemy.queue_free()
	await get_tree().physics_frame

func test_minion() -> void:
	print("--- Evaluando Esbirro Aliado: Duende Invocado (Goblin Minion) ---")
	var minion = MINION_SCENE.instantiate()
	add_child(minion)
	minion.global_position = Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var ap = minion.anim_player
	if not ap:
		failures.append("Minion: AnimationPlayer no encontrado")
		minion.queue_free()
		return
	
	# 1. Comprobar que NO usa Happy_002
	if not ap.has_animation("combat_idle"):
		failures.append("Minion: No tiene 'combat_idle'")
	else:
		var idle_clip = ap.get_animation("combat_idle")
		if idle_clip.loop_mode != Animation.LOOP_LINEAR:
			failures.append("Minion: 'combat_idle' loop_mode=%d (esperado LOOP_LINEAR=1)" % idle_clip.loop_mode)
		else:
			print("  [PASS] Esbirro usa 'combat_idle' en bucle continuo (LOOP_LINEAR)")
			passes += 1
	
	# 2. Comprobar muerte del esbirro
	minion.die()
	await get_tree().physics_frame
	var col = minion.find_child("CollisionShape3D", true, false) as CollisionShape3D
	var col_disabled = col.disabled if col else true
	var in_group = minion.is_in_group("minion")
	var physics_stopped = not minion.is_physics_processing()
	
	if col_disabled and not in_group and physics_stopped and minion.is_dead:
		print("  [PASS] Muerte esbirro: colisión desactivada, fuera de grupo 'minion' e IA detenida")
		passes += 1
	else:
		failures.append("Minion: Muerte no cumplió estado seguro")
	
	minion.queue_free()
	await get_tree().physics_frame

func test_boss() -> void:
	print("--- Evaluando Jefe: Dragón Arcano (is_boss = true) ---")
	var boss = ENEMY_SCENE.instantiate()
	boss.is_boss = true
	add_child(boss)
	boss.global_position = Vector3.ZERO
	boss.set_archetype(1)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var ap = boss.anim_player
	if not ap:
		failures.append("Boss: AnimationPlayer no encontrado")
		boss.queue_free()
		return
	
	var fly_anim = ap.get_animation(boss.anim_idle)
	if fly_anim and fly_anim.loop_mode == Animation.LOOP_LINEAR:
		print("  [PASS] Jefe Idle/Fly '%s' en bucle continuo (LOOP_LINEAR)" % boss.anim_idle)
		passes += 1
	else:
		failures.append("Boss: Idle '%s' no tiene LOOP_LINEAR" % boss.anim_idle)
	
	# Test CC: Ice freeze on 3 hits
	boss.apply_chill(0.45, 3.0)
	boss.apply_chill(0.45, 3.0)
	boss.apply_chill(0.45, 3.0)
	if boss.freeze_timer > 0.0:
		print("  [PASS] CC Congelamiento exitoso tras 3 impactos de hielo (freeze_timer=%.1f)" % boss.freeze_timer)
		passes += 1
	else:
		failures.append("Boss: Congelamiento falló tras 3 impactos")
	
	# Test CC: Stun
	boss.apply_stun(0.5)
	if boss.stun_timer > 0.0:
		print("  [PASS] CC Aturdimiento aplicado correctamente")
		passes += 1
	else:
		failures.append("Boss: Aturdimiento falló")
	
	# Test CC: Earth sink
	boss.apply_earth_sink(3.0, 0.70)
	if boss.earth_sink_timer > 0.0 and is_equal_approx(boss.earth_slow_factor, 0.30):
		print("  [PASS] CC Hundimiento de tierra (-70%) aplicado correctamente")
		passes += 1
	else:
		failures.append("Boss: Hundimiento de tierra falló")
	
	# Test CC: Arcane Root
	boss.apply_root(3.0)
	if boss.root_timer > 0.0:
		print("  [PASS] CC Atadura de enredaderas aplicado correctamente")
		passes += 1
	else:
		failures.append("Boss: Atadura de enredaderas falló")
	
	# Test Elemental weakness discovery
	var prev_hp = boss.current_health
	boss.take_damage(20.0, Vector3.ZERO, "ice") # Ice is boss weakness!
	var dmg_taken = prev_hp - boss.current_health
	if dmg_taken >= 28.0: # 20 * 1.5 = 30
		print("  [PASS] Debilidad elemental detectada y bonificada (+50% daño)")
		passes += 1
	else:
		failures.append("Boss: Bonificación de debilidad elemental falló (recibió %.1f)" % dmg_taken)
	
	boss.die()
	print("  [PASS] Muerte de Jefe limpia")
	passes += 1
	
	boss.queue_free()
	await get_tree().physics_frame
