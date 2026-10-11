extends CharacterBody3D

signal spell_cast_requested(spell_id: String, target_point: Vector3)

@export var move_speed: float = 6.0
@export var acceleration: float = 14.0
@export var rotation_speed: float = 12.0

var target_position: Vector3 = Vector3.ZERO
var is_moving: bool = false
var stop_distance: float = 0.3

@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer if has_node("Model/AnimationPlayer") else null
@onready var selection_ring: Node3D = $SelectionRing
@onready var staff_gem: MeshInstance3D = $Model/Staff/Gem if has_node("Model/Staff/Gem") else null

func _ready() -> void:
	target_position = global_position
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")
	
	# Stylized Wizard Cornelius color scheme
	_apply_wizard_materials()

func _apply_wizard_materials() -> void:
	var robe_mat = StandardMaterial3D.new()
	robe_mat.albedo_color = Color(0.12, 0.38, 0.82) # Cornelius Royal Blue
	robe_mat.roughness = 0.7
	
	var leather_mat = StandardMaterial3D.new()
	leather_mat.albedo_color = Color(0.35, 0.22, 0.15) # Leather boots/belts
	leather_mat.roughness = 0.8
	
	var skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.95, 0.78, 0.65) # Hands/face
	skin_mat.roughness = 0.5
	
	for child in find_children("*", "MeshInstance3D", true):
		if child.name.begins_with("torso"):
			child.material_override = robe_mat
		elif child.name.begins_with("arm"):
			child.material_override = robe_mat
		elif child.name.begins_with("leg"):
			child.material_override = leather_mat

func set_target_destination(dest: Vector3) -> void:
	target_position = Vector3(dest.x, global_position.y, dest.z)
	is_moving = true
	if anim_player and anim_player.has_animation("walk"):
		anim_player.play("walk")

func _physics_process(delta: float) -> void:
	if is_moving:
		var diff = target_position - global_position
		diff.y = 0.0
		var dist = diff.length()
		
		if dist <= stop_distance:
			is_moving = false
			velocity = Vector3.ZERO
			if anim_player and anim_player.has_animation("idle"):
				anim_player.play("idle")
		else:
			var dir = diff.normalized()
			velocity = velocity.lerp(dir * move_speed, delta * acceleration)
			
			# Smooth rotation towards movement direction
			var target_rot = atan2(-dir.x, -dir.z)
			rotation.y = lerp_angle(rotation.y, target_rot, delta * rotation_speed)
	else:
		velocity = velocity.lerp(Vector3.ZERO, delta * acceleration)
	
	move_and_slide()

func cast_spell_gesture(spell_name: String) -> void:
	# Subtle staff pulse effect on cast
	if staff_gem:
		var tween = create_tween()
		tween.tween_property(staff_gem.material_override, "emission_energy_multiplier", 5.0, 0.1)
		tween.tween_property(staff_gem.material_override, "emission_energy_multiplier", 1.5, 0.3)
