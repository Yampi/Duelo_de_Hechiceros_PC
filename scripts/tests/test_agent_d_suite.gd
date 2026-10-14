extends Node

const CharacterAppearance = preload("res://scripts/character_appearance.gd")
const CharacterCreator = preload("res://scripts/ui/character_creator.gd")

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

func _ready() -> void:
	print("\n========================================================")
	print("🧙 TEST SUITE: AGENT D — PERSONALIZADOR DE HECHICERO")
	print("========================================================\n")
	
	_run_all_tests()
	
	print("\n========================================================")
	print("📊 RESULTADOS FINALES AGENT D: %d PASADOS, %d FALLADOS" % [passed_tests, failed_tests])
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
	# 1. Test Config Defaults
	var def_cfg = CharacterAppearance.get_default_config()
	assert_test(def_cfg.has("character_name") and def_cfg["character_name"] == "Cornelius", "Config por defecto tiene nombre Cornelius")
	assert_test(def_cfg.has("robe_color_idx") and def_cfg["robe_color_idx"] == 0, "Túnica por defecto es índice 0")
	assert_test(CharacterAppearance.ROBE_COLORS.size() >= 8, "Catálogo de túnicas tiene al menos 8 variantes de color")
	assert_test(CharacterAppearance.SKIN_TONES.size() >= 5, "Catálogo de piel tiene al menos 5 tonos")
	assert_test(CharacterAppearance.EYE_COLORS.size() >= 5, "Catálogo de ojos tiene al menos 5 miradas")
	assert_test(CharacterAppearance.TRIM_COLORS.size() >= 5, "Catálogo de metales/hombreras tiene al menos 5 estilos")
	assert_test(CharacterAppearance.GEM_COLORS.size() >= 5, "Catálogo de gemas tiene al menos 5 variantes")
	assert_test(CharacterAppearance.EXPRESSION_STYLES.size() >= 4, "Catálogo de portes y expresión tiene al menos 4 estilos")
	assert_test(CharacterAppearance.EYE_SHAPES.size() >= 5, "Catálogo de formas de ojos tiene al menos 5 geometrías")
	assert_test(CharacterAppearance.HAIR_COLORS.size() >= 5, "Catálogo de tintes de cabello tiene al menos 5 colores")
	assert_test(CharacterAppearance.BEARD_STYLES.size() >= 3, "Catálogo de estilos de barba tiene al menos 3 cortes")

	# 2. Test Save & Load Persistence
	var test_custom_cfg = {
		"character_name": "Valerius el Rojo",
		"skin_tone_idx": 1,
		"eye_type_idx": 1,
		"eye_shape_idx": 2, # Estrella Cósmica
		"hair_color_idx": 1, # Negro Azabache
		"beard_style_idx": 1, # Barba Recortada
		"robe_color_idx": 1, # Pyromancer Crimson
		"trim_color_idx": 2, # Bronce Titán
		"staff_gem_idx": 1, # Inferno Rojo
		"expression_idx": 1  # Místico Iluminado
	}
	var save_ok = CharacterAppearance.save_config(test_custom_cfg)
	assert_test(save_ok, "CharacterAppearance.save_config guarda en user://character_appearance.cfg sin errores")
	
	var loaded_cfg = CharacterAppearance.load_config()
	assert_test(loaded_cfg["character_name"] == "Valerius el Rojo", "Persistencia recupera nombre personalizado correctamente")
	assert_test(loaded_cfg["robe_color_idx"] == 1, "Persistencia recupera color de túnica personalizado")
	assert_test(loaded_cfg["staff_gem_idx"] == 1, "Persistencia recupera gema de bastón personalizada")
	assert_test(loaded_cfg["eye_shape_idx"] == 2, "Persistencia recupera forma de ojo personalizada")
	assert_test(loaded_cfg["hair_color_idx"] == 1, "Persistencia recupera tinte de cabello personalizado")
	assert_test(loaded_cfg["beard_style_idx"] == 1, "Persistencia recupera estilo de barba personalizado")
	
	# 3. Test Material Application on WizardModel
	var model_scene = load("res://assets/characters/wizard/WizardModel.tscn")
	assert_test(model_scene != null, "Escena WizardModel.tscn cargada exitosamente")
	
	var model_instance = model_scene.instantiate() as Node3D
	add_child(model_instance)
	CharacterAppearance.apply_to_model(model_instance, test_custom_cfg)
	
	var face_mesh: MeshInstance3D = null
	for m in model_instance.find_children("*", "MeshInstance3D", true, false):
		if m.name == "Face":
			face_mesh = m
			break
	assert_test(face_mesh != null and face_mesh.material_override != null, "Malla de Rostro (Face) recibe material de rostro personalizado")
	if face_mesh and face_mesh.material_override is ShaderMaterial:
		var face_mat = face_mesh.material_override as ShaderMaterial
		var expected_skin = CharacterAppearance.SKIN_TONES[1]["color"]
		var skin_param = face_mat.get_shader_parameter("skin_color")
		var eye_param = face_mat.get_shader_parameter("eye_color")
		var shape_param = face_mat.get_shader_parameter("eye_shape")
		var hair_param = face_mat.get_shader_parameter("hair_color")
		assert_test(skin_param != null and skin_param.is_equal_approx(expected_skin), "Color de piel del rostro coincide con tono seleccionado")
		assert_test(eye_param != null and face_mat.get_shader_parameter("eye_emission_energy") > 0.0, "Emisión ocular en rostro activada según estilo místico")
		assert_test(shape_param == 2, "Forma de ojo en shader coincide con Estrella Cósmica")
		assert_test(hair_param != null and hair_param.is_equal_approx(CharacterAppearance.HAIR_COLORS[1]["color"]), "Tinte capilar en shader coincide con Negro Azabache")
	elif face_mesh and face_mesh.material_override is StandardMaterial3D:
		var face_mat = face_mesh.material_override as StandardMaterial3D
		var expected_skin = CharacterAppearance.SKIN_TONES[1]["color"]
		assert_test(face_mat.albedo_color.is_equal_approx(expected_skin), "Color de piel del rostro coincide con tono seleccionado")
		assert_test(face_mat.emission_enabled, "Emisión ocular en rostro activada según estilo místico")
	
	var robe_mesh = model_instance.find_child("Wizard_001", true, false) as MeshInstance3D
	assert_test(robe_mesh != null and robe_mesh.material_override != null, "Malla de Túnica (Wizard_001) recibe material override")
	if robe_mesh and robe_mesh.material_override is StandardMaterial3D:
		var robe_mat = robe_mesh.material_override as StandardMaterial3D
		var expected_robe = CharacterAppearance.ROBE_COLORS[1]["color"]
		assert_test(robe_mat.albedo_color.is_equal_approx(expected_robe), "Color de túnica coincide con Piromante Carmesí")
	
	var staff_gem = model_instance.find_child("Gem", true, false) as MeshInstance3D
	assert_test(staff_gem != null and staff_gem.material_override != null, "Gema del bastón recibe material emisivo personalizado")
	if staff_gem and staff_gem.material_override is StandardMaterial3D:
		var gem_mat = staff_gem.material_override as StandardMaterial3D
		var expected_gem = CharacterAppearance.GEM_COLORS[1]["color"]
		assert_test(gem_mat.albedo_color.is_equal_approx(expected_gem), "Color de la gema del bastón coincide con Inferno Rojo")
	
	var staff_light = model_instance.find_child("StaffLight", true, false) as OmniLight3D
	assert_test(staff_light != null, "Luz OmniLight3D del bastón detectada")
	if staff_light:
		var expected_gem = CharacterAppearance.GEM_COLORS[1]["color"]
		assert_test(staff_light.light_color.is_equal_approx(expected_gem), "Color de luz del bastón sincronizado con gema")

	# 4. Test CharacterCreator UI Modal
	var creator_scene = load("res://scenes/ui/CharacterCreator.tscn")
	assert_test(creator_scene != null, "Escena CharacterCreator.tscn existe y carga")
	
	var creator_instance = creator_scene.instantiate() as CharacterCreator
	add_child(creator_instance)
	assert_test(creator_instance != null, "CharacterCreator instanciado")
	
	creator_instance.open_creator()
	assert_test(creator_instance.visible, "CharacterCreator se hace visible al llamar open_creator()")
	
	creator_instance._on_randomize()
	assert_test(creator_instance.current_config["robe_color_idx"] >= 0, "Aleatorización genera configuración válida")
	
	creator_instance.close_creator()
	assert_test(not creator_instance.visible, "CharacterCreator se oculta al llamar close_creator()")

	# 5. Test MainMenu integration
	var menu_scene = load("res://scenes/MainMenu.tscn")
	assert_test(menu_scene != null, "MainMenu.tscn carga correctamente")
	var menu_instance = menu_scene.instantiate()
	add_child(menu_instance)
	
	var btn_char = menu_instance.find_child("BtnCharacter", true, false) as Button
	assert_test(btn_char != null, "MainMenu contiene botón BtnCharacter en navegación principal")
	
	var menu_creator = menu_instance.find_child("CharacterCreator", true, false)
	assert_test(menu_creator != null, "MainMenu contiene instancia de CharacterCreator")

	# 6. Test Wizard In-Game Player Spawn
	var wiz_scene = load("res://scenes/Wizard.tscn")
	assert_test(wiz_scene != null, "Wizard.tscn carga correctamente")
	var wiz_instance = wiz_scene.instantiate()
	add_child(wiz_instance)
	assert_test(wiz_instance.is_in_group("player"), "Wizard se registra en grupo player y aplica materiales")
	
	# Cleanup test nodes
	model_instance.queue_free()
	creator_instance.queue_free()
	menu_instance.queue_free()
	wiz_instance.queue_free()
