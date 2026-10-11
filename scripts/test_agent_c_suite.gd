extends Node

const WIZARD_SCENE = preload("res://scenes/Wizard.tscn")
const ENEMY_SCENE = preload("res://scenes/Enemy.tscn")
const MINIMAP_SCENE = preload("res://scenes/ui/Minimap.tscn")

var passes: int = 0
var fails: int = 0

func _ready() -> void:
	print("\n========================================================")
	print("🌫️ TEST SUITE: AGENT C — NIEBLA DE GUERRA Y FOG 3D")
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
	# 1. Instanciación y cuadrícula FogOfWar
	var fog = GameManager.fog_of_war
	assert_test(fog != null, "GameManager.fog_of_war inicializado correctamente")
	assert_test(fog.GRID_SIZE == 128, "Cuadrícula FogOfWar es exactamente 128x128")
	assert_test(fog.CELL_SIZE == 2.0, "Tamaño de celda es exactamente 2.0m")
	assert_test(fog.REVEAL_RADIUS == 20.0, "Radio de visión y revelación es exactamente 20.0m")
	
	# 2. Estado inicial tras reset
	fog.reset_fog()
	var test_center = Vector3(0, 0, 96.0) # Spawn en Zona 1
	var distant_pos = Vector3(0, 0, 0.0)  # A 96m de distancia
	
	assert_test(not fog.is_point_explored(test_center), "Punto inicial no explorado antes de primera actualización")
	assert_test(not fog.is_point_visible(test_center), "Punto inicial no visible antes de primera actualización")
	
	# 3. Revelación en radio de 20m
	fog.update_player_position(test_center)
	var near_point = test_center + Vector3(10.0, 0, 0) # 10m < 20m
	var outside_point = test_center + Vector3(25.0, 0, 0) # 25m > 20m
	
	assert_test(fog.is_point_visible(test_center), "Posición del jugador es visible")
	assert_test(fog.is_point_explored(test_center), "Posición del jugador está explorada")
	assert_test(fog.is_point_visible(near_point), "Punto a 10m está dentro del radio visible")
	assert_test(fog.is_point_explored(near_point), "Punto a 10m está explorado")
	assert_test(not fog.is_point_visible(outside_point), "Punto a 25m no es visible")
	assert_test(not fog.is_point_explored(outside_point), "Punto a 25m no está explorado")
	
	# 4. Movimiento del jugador: persistencia de exploración y sombra
	var new_center = Vector3(40.0, 0, 96.0)
	fog.update_player_position(new_center)
	
	assert_test(fog.is_point_visible(new_center), "Nueva posición del jugador es visible")
	assert_test(not fog.is_point_visible(test_center), "Posición anterior ya no es visible (queda en sombra)")
	assert_test(fog.is_point_explored(test_center), "Posición anterior permanece explorada en memoria")
	
	# 5. Generación de textura de niebla para shaders y canvas
	var tex = fog.get_fog_texture()
	assert_test(tex != null, "get_fog_texture() genera textura válida")
	assert_test(tex.get_width() == 128 and tex.get_height() == 128, "Textura de niebla mide 128x128 píxeles")
	
	# 6. Filtrado de enemigos en minimapa
	var p_pos = Vector3(0, 0, 0)
	fog.reset_fog()
	fog.update_player_position(p_pos)
	
	var near_enemy_pos = Vector3(0, 0, 12.0) # 12m: visible
	var far_enemy_pos = Vector3(0, 0, 35.0)  # 35m: oculto en niebla
	
	assert_test(fog.is_point_visible(near_enemy_pos), "Enemigo a 12m es visible en Fog of War (visible en minimapa)")
	assert_test(not fog.is_point_visible(far_enemy_pos), "Enemigo a 35m está oculto en la niebla (filtrado en minimapa)")
	
	# 7. Niebla atmosférica 3D por zonas
	var main_scene = load("res://scenes/Main.tscn").instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	
	assert_test(main_scene.has_node("WorldEnvironment"), "Main.tscn contiene WorldEnvironment")
	var w_env = main_scene.get_node("WorldEnvironment") as WorldEnvironment
	assert_test(w_env.environment.fog_enabled == true, "Niebla volumétrica 3D habilitada en WorldEnvironment")
	
	# Probar transición a Zona 3
	main_scene._update_target_atmospheric_fog(MapConfig.ZoneId.CORAZON_BOSQUE)
	assert_test(main_scene.target_fog_color == Color(0.24, 0.18, 0.36), "Niebla 3D para Corazón del Bosque configurada a violeta crepuscular")
	assert_test(main_scene.target_fog_density == 0.022, "Densidad de niebla 3D para Corazón del Bosque ajustada a 0.022")
	
	main_scene.queue_free()
	
	print("\n========================================================")
	print("📊 RESULTADOS FINALES AGENT C: %d PASADOS, %d FALLADOS" % [passes, fails])
	print("========================================================\n")
	get_tree().quit(0 if fails == 0 else 1)
