extends Node3D

const SettingsManager = preload("res://scripts/settings_manager.gd")

@export var follow_target: Node3D:
	set(val):
		follow_target = val
		_update_target_exclusions()
@export var follow_smoothness: float = 12.0
@export var target_offset: Vector3 = Vector3(0, 1.4, 0)

# 3D Third-person orbit configuration
@export var mouse_sensitivity: float = 0.004
@export var min_pitch: float = deg_to_rad(-14.0) # Looking slightly up
@export var max_pitch: float = deg_to_rad(55.0)  # Looking down
@export var default_pitch: float = deg_to_rad(20.0)

# Zoom configuration
@export var default_distance: float = 6.5
@export var min_distance: float = 3.2
@export var max_distance: float = 12.0
@export var zoom_step: float = 0.9

@onready var spring_arm: SpringArm3D = $SpringArm3D if has_node("SpringArm3D") else null
@onready var camera: Camera3D = $SpringArm3D/Camera3D if has_node("SpringArm3D/Camera3D") else ($Camera3D if has_node("Camera3D") else null)

var current_pitch: float = deg_to_rad(20.0)
var current_yaw: float = 0.0
var target_distance: float = 6.5
var current_distance: float = 6.5

var is_orbiting: bool = false
var trauma: float = 0.0
var max_offset_shake: float = 0.45
var noise_time: float = 0.0

func _ready() -> void:
	add_to_group("camera")
	current_pitch = default_pitch
	current_distance = default_distance
	target_distance = default_distance
	
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
	
	# 2. Smooth zoom interpolation
	current_distance = lerp(current_distance, target_distance, delta * 10.0)
	
	if spring_arm:
		# Clamp effective spring length so camera NEVER clips into first-person even with obstacles
		spring_arm.spring_length = max(2.4, current_distance)
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
	# Right-click drag orbits camera around wizard
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_orbiting = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_distance = clamp(target_distance - zoom_step, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_distance = clamp(target_distance + zoom_step, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			# Reset camera view behind character
			if follow_target:
				current_yaw = follow_target.rotation.y
				current_pitch = default_pitch
				target_distance = default_distance
	
	# Mouse motion while holding right button orbits camera
	if event is InputEventMouseMotion and is_orbiting:
		current_yaw -= event.relative.x * mouse_sensitivity
		current_pitch = clamp(current_pitch + (event.relative.y * mouse_sensitivity), min_pitch, max_pitch)
