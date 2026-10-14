extends SceneTree

const SettingsManager = preload("res://scripts/settings_manager.gd")
const TacticalCamera = preload("res://scripts/tactical_camera.gd")

func _init() -> void:
	print("\n==========================================")
	print("🎥 VERIFICACIÓN DE MODOS DE CÁMARA (3D / 2.5D)")
	print("==========================================")
	
	# 1. Test Settings persistence
	SettingsManager.init_settings()
	var prev_mode = SettingsManager.camera_mode
	
	SettingsManager.camera_mode = 1
	SettingsManager.save_to_disk()
	SettingsManager.load_from_disk()
	assert(SettingsManager.camera_mode == 1, "Error: camera_mode debería persistir como 1")
	print("  [PASS] Persistencia de camera_mode (2.5D Isométrica) en user://settings.cfg")
	
	SettingsManager.camera_mode = 0
	SettingsManager.save_to_disk()
	SettingsManager.load_from_disk()
	assert(SettingsManager.camera_mode == 0, "Error: camera_mode debería persistir como 0")
	print("  [PASS] Persistencia de camera_mode (3D Libre) en user://settings.cfg")
	
	# 2. Test TacticalCamera instantiation and configuration
	var cam_rig = TacticalCamera.new()
	var spring_arm = SpringArm3D.new()
	spring_arm.name = "SpringArm3D"
	var cam3d = Camera3D.new()
	cam3d.name = "Camera3D"
	spring_arm.add_child(cam3d)
	cam_rig.add_child(spring_arm)
	
	root.add_child(cam_rig)
	
	# Test Free mode
	cam_rig.set_camera_mode(0, true)
	assert(cam_rig.camera_mode == cam_rig.CameraMode.FREE_3D, "Error: modo debe ser FREE_3D")
	assert(is_equal_approx(cam_rig.target_pitch, cam_rig.default_pitch), "Error: pitch libre incorrecto")
	assert(is_equal_approx(cam_rig.target_distance, cam_rig.default_distance), "Error: distancia libre incorrecta")
	print("  [PASS] Configuración de Cámara 3D Libre correcta (Pitch: 20°, Dist: 6.5m)")
	
	# Test Isometric mode
	cam_rig.set_camera_mode(1, true)
	assert(cam_rig.camera_mode == cam_rig.CameraMode.ISOMETRIC_25D, "Error: modo debe ser ISOMETRIC_25D")
	assert(is_equal_approx(cam_rig.target_pitch, cam_rig.isometric_pitch), "Error: pitch isométrico incorrecto")
	assert(is_equal_approx(cam_rig.target_yaw, cam_rig.isometric_yaw), "Error: yaw isométrico incorrecto")
	assert(is_equal_approx(cam_rig.target_distance, cam_rig.isometric_distance), "Error: distancia isométrica incorrecta")
	assert(is_equal_approx(cam_rig.target_fov, cam_rig.isometric_fov), "Error: fov isométrico incorrecto")
	print("  [PASS] Configuración de Cámara 2.5D Isométrica correcta (Pitch: 52°, Yaw: 45°, Dist: 10.5m, FOV: 54°)")
	
	# Test Toggle
	cam_rig.toggle_mode()
	assert(SettingsManager.camera_mode == 0, "Error: toggle_mode debe alternar a 0")
	print("  [PASS] Toggle interactivo de modo de cámara funcional")
	
	# Cleanup
	SettingsManager.camera_mode = prev_mode
	SettingsManager.save_to_disk()
	cam_rig.queue_free()
	
	print("\n✨ TODAS LAS PRUEBAS DE CÁMARA 2.5D ISOMÉTRICA PASARON EXITOSAMENTE!\n")
	quit(0)
