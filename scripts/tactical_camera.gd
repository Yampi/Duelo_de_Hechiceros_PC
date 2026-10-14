extends Node3D

const SettingsManager = preload("res://scripts/settings_manager.gd")

enum CameraMode {
	FREE_3D = 0,
	ISOMETRIC_25D = 1
}

@export var follow_target: Node3D:
	set(val):
		follow_target = val
		_update_target_exclusions()
@export var follow_smoothness: float = 12.0
@export var target_offset: Vector3 = Vector3(0, 1.4, 0)

# Mode configuration
@export var camera_mode: CameraMode = CameraMode.FREE_3D

# 2.5D Isometric parameters (Classic ARPG perspective)
@export var isometric_pitch: float = deg_to_rad(52.0)
@export var isometric_yaw: float = deg_to_rad(45.0)
@export var isometric_distance: float = 10.5
@export var isometric_min_distance: float = 5.0
@export var isometric_max_distance: float = 18.0
@export var isometric_fov: float = 54.0

# 3D Third-person orbit configuration
@export var mouse_sensitivity: float = 0.004
@export var min_pitch: float = deg_to_rad(-14.0) # Looking slightly up
@export var max_pitch: float = deg_to_rad(55.0)  # Looking down
@export var default_pitch: float = deg_to_rad(20.0)

# Zoom configuration
@export var default_distance: float = 6.5
@export var min_distance: float = 3.2
@export var max_distance: float = 12.0
@export var default_fov: float = 68.0
@export var zoom_step: float = 0.9

@onready var spring_arm: SpringArm3D = $SpringArm3D if has_node("SpringArm3D") else null
@onready var camera: Camera3D = $SpringArm3D/Camera3D if has_node("SpringArm3D/Camera3D") else ($Camera3D if has_node("Camera3D") else null)

var current_pitch: float = deg_to_rad(20.0)
var current_yaw: float = 0.0
var target_pitch: float = deg_to_rad(20.0)
var target_yaw: float = 0.0
var target_distance: float = 6.5
var current_distance: float = 6.5
var target_fov: float = 68.0

var is_orbiting: bool = false
var trauma: float = 0.0
var max_offset_shake: float = 0.45
var noise_time: float = 0.0

func _ready() -> void:
	add_to_group("camera")
	SettingsManager.init_settings()
	apply_settings(true)
	
	if spring_arm:
		var sphere = SphereShape3D.new()
		sphere.radius = 0.22
		spring_arm.shape = sphere
		spring_arm.margin = 0.15
		spring_arm.spring_length = current_distance
		spring_arm.rotation.x = -current_pitch
		_update_target_exclusions()
	elif camera:
		# Fallback if no spring arm in scene: set initial camera position
		_update_manual_camera_transform()
	
	if follow_target:
		global_position = follow_target.global_position + target_offset
		_update_target_exclusions()

func apply_settings(instant: bool = false) -> void:
	set_camera_mode(SettingsManager.camera_mode, instant)

func set_camera_mode(mode: int, instant: bool = false) -> void:
	camera_mode = mode as CameraMode
	if camera_mode == CameraMode.ISOMETRIC_25D:
		target_pitch = isometric_pitch
		target_yaw = isometric_yaw
		target_distance = isometric_distance
		target_fov = isometric_fov
		is_orbiting = false
	else:
		target_pitch = default_pitch
		target_fov = default_fov
		target_distance = default_distance
		if follow_target and is_instance_valid(follow_target):
			target_yaw = follow_target.rotation.y
	
	if instant:
		current_pitch = target_pitch
		current_yaw = target_yaw
		current_distance = target_distance
		if camera:
			camera.fov = target_fov
		if spring_arm:
			spring_arm.spring_length = current_distance
			spring_arm.rotation.x = -current_pitch
		rotation.y = current_yaw

func toggle_mode() -> void:
	var next = 1 if camera_mode == CameraMode.FREE_3D else 0
	SettingsManager.camera_mode = next
	SettingsManager.save_to_disk()

func _update_target_exclusions() -> void:
	if not spring_arm or not follow_target or not is_instance_valid(follow_target):
		return
	spring_arm.clear_excluded_objects()
	if follow_target is CollisionObject3D:
		spring_arm.add_excluded_object(follow_target.get_rid())
	for child in follow_target.find_children("*", "CollisionObject3D", true, false):
		if child is CollisionObject3D:
			spring_arm.add_excluded_object(child.get_rid())

func add_trauma(amount: float) -> void:
	if SettingsManager.reduce_shake:
		amount *= 0.35
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	# 1. Smoothly follow target position with height offset
	if follow_target and is_instance_valid(follow_target):
		var target_pos = follow_target.global_position + target_offset
		global_position = global_position.lerp(target_pos, delta * follow_smoothness)
	
	# 2. Smooth zoom, pitch, yaw and fov interpolation
	current_distance = lerp(current_distance, target_distance, delta * 8.0)
	current_pitch = lerp(current_pitch, target_pitch, delta * 8.0)
	current_yaw = lerp_angle(current_yaw, target_yaw, delta * 8.0)
	
	if camera:
		camera.fov = lerp(camera.fov, target_fov, delta * 6.0)
	
	if spring_arm:
		# Clamp effective spring length so camera NEVER clips into first-person even with obstacles
		var min_clamp = 3.5 if camera_mode == CameraMode.ISOMETRIC_25D else 2.4
		spring_arm.spring_length = max(min_clamp, current_distance)
		spring_arm.rotation.x = -current_pitch
		rotation.y = current_yaw
	elif camera:
		_update_manual_camera_transform()
	
	# 3. Screen shake trauma decay and subtle procedural punch
	if camera:
		if trauma > 0.0:
			trauma = max(0.0, trauma - (delta * 2.2))
			var shake_intensity = trauma * trauma
			noise_time += delta * 45.0
			camera.h_offset = sin(noise_time * 1.4) * max_offset_shake * shake_intensity
			camera.v_offset = cos(noise_time * 1.9) * max_offset_shake * shake_intensity
		else:
			camera.h_offset = 0.0
			camera.v_offset = 0.0

func _update_manual_camera_transform() -> void:
	if not camera:
		return
	rotation.y = current_yaw
	var pitch_rot = Basis(Vector3.RIGHT, -current_pitch)
	var cam_offset = pitch_rot * Vector3(0, 0, current_distance)
	camera.position = cam_offset
	camera.look_at(global_position + Vector3(0, 0.2, 0))

func _unhandled_input(event: InputEvent) -> void:
	var cur_min = isometric_min_distance if camera_mode == CameraMode.ISOMETRIC_25D else min_distance
	var cur_max = isometric_max_distance if camera_mode == CameraMode.ISOMETRIC_25D else max_distance

	# Right-click drag orbits camera around wizard (ONLY in free 3D mode)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if camera_mode == CameraMode.FREE_3D:
				is_orbiting = event.pressed
			else:
				is_orbiting = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_distance = clamp(target_distance - zoom_step, cur_min, cur_max)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_distance = clamp(target_distance + zoom_step, cur_min, cur_max)
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			# Reset camera view
			if camera_mode == CameraMode.ISOMETRIC_25D:
				target_distance = isometric_distance
				target_yaw = isometric_yaw
				target_pitch = isometric_pitch
			else:
				if follow_target and is_instance_valid(follow_target):
					target_yaw = follow_target.rotation.y
				target_pitch = default_pitch
				target_distance = default_distance
	
	# Mouse motion while holding right button orbits camera (ONLY in free 3D mode)
	if event is InputEventMouseMotion and is_orbiting and camera_mode == CameraMode.FREE_3D:
		target_yaw -= event.relative.x * mouse_sensitivity
		target_pitch = clamp(target_pitch + (event.relative.y * mouse_sensitivity), min_pitch, max_pitch)
