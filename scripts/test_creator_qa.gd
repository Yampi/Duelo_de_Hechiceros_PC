extends Node3D

func _ready() -> void:
	print("\n========================================================")
	print("🧙 QA AUDITORÍA: TALLER DE PERSONALIZACIÓN Y CÁMARA")
	print("========================================================\n")
	
	var passes: int = 0
	var failures: Array[String] = []
	
	var creator_scene = load("res://scenes/ui/CharacterCreator.tscn").instantiate() as CharacterCreator
	add_child(creator_scene)
	creator_scene.open_creator()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 1. Comprobar que inicia en modo CUERPO COMPLETO
	if creator_scene.current_camera_mode == CharacterCreator.CameraMode.FULL_BODY:
		print("  [PASS] Al abrir, la cámara inicia en modo CUERPO COMPLETO")
		passes += 1
	else:
		failures.append("Al abrir, no inició en modo FULL_BODY")
	
	if is_equal_approx(creator_scene.cam_target_pos.y, 1.05) and is_equal_approx(creator_scene.cam_target_pos.z, 3.65):
		print("  [PASS] Coordenadas de cuerpo completo correctas (y=1.05, z=3.65)")
		passes += 1
	else:
		failures.append("Coordenadas de cuerpo completo erróneas: %s" % creator_scene.cam_target_pos)
	
	# 2. Probar botón "Ver Rostro"
	var btn_face = creator_scene.find_child("BtnViewFace", true, false) as Button
	if btn_face:
		btn_face.emit_signal("pressed")
		if creator_scene.current_camera_mode == CharacterCreator.CameraMode.FACE:
			print("  [PASS] Botón 'Ver Rostro' activó modo FACE")
			passes += 1
		else:
			failures.append("Botón 'Ver Rostro' no activó modo FACE")
		
		if is_equal_approx(creator_scene.cam_target_pos.y, 1.74) and is_equal_approx(creator_scene.cam_target_pos.z, 1.45):
			print("  [PASS] Coordenadas de encuadre facial correctas (y=1.74, z=1.45)")
			passes += 1
		else:
			failures.append("Coordenadas de rostro erróneas: %s" % creator_scene.cam_target_pos)
	else:
		failures.append("No se encontró BtnViewFace")
	
	# 3. Probar clic en opción de Tez (GridSkin)
	var grid_skin = creator_scene.find_child("GridSkin", true, false) as GridContainer
	if grid_skin and grid_skin.get_child_count() > 0:
		# Volver a cuerpo completo primero
		creator_scene.set_camera_view_full_body()
		var skin_btn = grid_skin.get_child(0) as Button
		skin_btn.emit_signal("pressed")
		if creator_scene.current_camera_mode == CharacterCreator.CameraMode.FACE:
			print("  [PASS] Clic en color de Tez acerca automáticamente la cámara al ROSTRO")
			passes += 1
		else:
			failures.append("Clic en color de Tez no acercó la cámara al rostro")
	else:
		failures.append("GridSkin no tiene botones")
	
	# 4. Probar clic en opción de Ojos (GridEyes)
	var grid_eyes = creator_scene.find_child("GridEyes", true, false) as GridContainer
	if grid_eyes and grid_eyes.get_child_count() > 0:
		creator_scene.set_camera_view_full_body()
		var eye_btn = grid_eyes.get_child(1) as Button
		eye_btn.emit_signal("pressed")
		if creator_scene.current_camera_mode == CharacterCreator.CameraMode.FACE:
			print("  [PASS] Clic en color de Ojos acerca automáticamente la cámara al ROSTRO")
			passes += 1
		else:
			failures.append("Clic en color de Ojos no acercó la cámara al rostro")
	else:
		failures.append("GridEyes no tiene botones")
	
	# 5. Probar clic en opción de Túnica (GridRobe)
	var grid_robe = creator_scene.find_child("GridRobe", true, false) as GridContainer
	if grid_robe and grid_robe.get_child_count() > 0:
		var robe_btn = grid_robe.get_child(0) as Button
		robe_btn.emit_signal("pressed")
		if creator_scene.current_camera_mode == CharacterCreator.CameraMode.FULL_BODY:
			print("  [PASS] Clic en Túnica aleja la cámara para mostrar CUERPO COMPLETO")
			passes += 1
		else:
			failures.append("Clic en Túnica no mostró cuerpo completo")
	else:
		failures.append("GridRobe no tiene botones")
	
	# 6. Probar clic en opción de Bastón (GridGem)
	var grid_gem = creator_scene.find_child("GridGem", true, false) as GridContainer
	if grid_gem and grid_gem.get_child_count() > 0:
		var gem_btn = grid_gem.get_child(0) as Button
		gem_btn.emit_signal("pressed")
		if creator_scene.current_camera_mode == CharacterCreator.CameraMode.STAFF:
			print("  [PASS] Clic en Gema de Bastón acerca la cámara al BASTÓN")
			passes += 1
		else:
			failures.append("Clic en Gema no acercó al bastón")
	else:
		failures.append("GridGem no tiene botones")
	
	# 7. Probar botón "Ver Cuerpo"
	var btn_body = creator_scene.find_child("BtnViewBody", true, false) as Button
	if btn_body:
		btn_body.emit_signal("pressed")
		if creator_scene.current_camera_mode == CharacterCreator.CameraMode.FULL_BODY:
			print("  [PASS] Botón 'Ver Cuerpo' restauró modo CUERPO COMPLETO")
			passes += 1
		else:
			failures.append("Botón 'Ver Cuerpo' falló")
	else:
		failures.append("No se encontró BtnViewBody")
	
	print("\n========================================================")
	print("📊 RESUMEN FINAL QA PERSONALIZACIÓN")
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
