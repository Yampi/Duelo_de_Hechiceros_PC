extends Node3D

@export var speed: float = 24.0
@export var arc_height: float = 3.5
@export var damage: float = 75.0
@export var explosion_radius: float = 4.5

var start_point: Vector3
var target_point: Vector3
var progress: float = 0.0
var total_distance: float = 1.0
var has_exploded: bool = false
var anim_time: float = 0.0

@onready var visuals: Node3D = $Visuals
@onready var flame_mantle: MeshInstance3D = $Visuals/FlameMantle
@onready var fire_trail: CPUParticles3D = $FireTrail
@onready var blast_ring: MeshInstance3D = $BlastRing
@onready var explosion_burst: CPUParticles3D = $ExplosionBurst
@onready var light: OmniLight3D = $OmniLight3D

func init_trajectory(start: Vector3, target: Vector3) -> void:
	start_point = start
	target_point = target
	global_position = start
	total_distance = max(0.5, start.distance_to(target))

func _physics_process(delta: float) -> void:
	if has_exploded:
		return
	
	anim_time += delta
	var step = (speed / total_distance) * delta
	progress += step
	
	# Turbulent pulsating flame mantle
	if flame_mantle:
		var pulse = 1.0 + sin(anim_time * 18.0) * 0.12
		flame_mantle.scale = Vector3(pulse, 1.0 / pulse, pulse)
		flame_mantle.rotation.y += delta * 8.0
	
	if progress >= 1.0:
		global_position = target_point
		explode()
		return
	
	# Parabolic arc calculation
	var current_ground = start_point.lerp(target_point, progress)
	var arc = sin(progress * PI) * arc_height
	global_position = current_ground + Vector3(0, arc, 0)

func explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	
	# Hide projectile visuals & stop continuous fire trail
	if visuals:
		visuals.visible = false
	if fire_trail:
		fire_trail.emitting = false
	
	# Deal AOE damage to enemies
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and e.is_inside_tree():
			var dist = global_position.distance_to(e.global_position)
			if dist <= explosion_radius:
				var falloff = 1.0 - (dist / explosion_radius) * 0.4
				var knockback = (e.global_position - global_position).normalized() * 14.0
				if e.has_method("take_damage"):
					e.take_damage(damage * falloff, knockback, "fire")
				if e.has_method("apply_burn"):
					e.apply_burn(4.0, 6.0)
	
	# Friendly fire to minions
	for m in get_tree().get_nodes_in_group("minion"):
		if is_instance_valid(m) and m.is_inside_tree():
			var dist = global_position.distance_to(m.global_position)
			if dist <= explosion_radius:
				var knockback = (m.global_position - global_position).normalized() * 10.0
				if m.has_method("take_damage"):
					m.take_damage(damage * 0.45, knockback, "fire")
	
	# Directive 5: Zero friendly fire to the wizard player
	
	GameManager.shake_camera(0.42)
	
	# Trigger one-shot explosive burst particles
	if explosion_burst:
		explosion_burst.emitting = true
	
	# Expand blast ring on the ground
	if blast_ring:
		blast_ring.visible = true
		blast_ring.scale = Vector3(0.2, 0.2, 0.2)
		if blast_ring.mesh and blast_ring.mesh.material:
			blast_ring.material_override = blast_ring.mesh.material.duplicate()
			var mat = blast_ring.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color.a = 0.85
				var ring_tween = create_tween().set_parallel(true)
				ring_tween.tween_property(blast_ring, "scale", Vector3(explosion_radius * 0.9, 1.0, explosion_radius * 0.9), 0.38)
				ring_tween.tween_property(mat, "albedo_color:a", 0.0, 0.38)
	
	# Ground scorch mark that fades out
	if get_parent():
		var scorch = MeshInstance3D.new()
		var quad = QuadMesh.new()
		quad.size = Vector2(explosion_radius * 1.5, explosion_radius * 1.5)
		quad.orientation = PlaneMesh.FACE_Y
		var smat = StandardMaterial3D.new()
		smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smat.albedo_texture = preload("res://assets/vfx/textures/smoke_noise.png")
		smat.albedo_color = Color(0.08, 0.05, 0.04, 0.72)
		quad.material = smat
		scorch.mesh = quad
		get_parent().add_child(scorch)
		scorch.global_position = Vector3(global_position.x, 0.03, global_position.z)
		var stween = scorch.create_tween()
		stween.tween_property(smat, "albedo_color:a", 0.0, 3.2).set_delay(0.8)
		stween.tween_callback(scorch.queue_free)
	
	if light:
		light.light_energy = 9.0
		light.omni_range = 9.0
		var light_tween = create_tween()
		light_tween.tween_property(light, "light_energy", 0.0, 0.45)
	
	get_tree().create_timer(0.55).timeout.connect(queue_free)
