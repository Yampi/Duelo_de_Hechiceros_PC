extends Node3D

@export var speed: float = 32.0
@export var damage: float = 25.0
@export var lifetime: float = 2.0
@export var area_damage_radius: float = 0.0
@export var knockback_force: float = 6.0

var direction: Vector3 = Vector3.FORWARD
var time_alive: float = 0.0
var has_exploded: bool = false
var is_empowered: bool = false

@onready var visuals: Node3D = $Visuals
@onready var ring1: MeshInstance3D = $Visuals/Ring1
@onready var ring2: MeshInstance3D = $Visuals/Ring2
@onready var spark_trail: CPUParticles3D = $SparkTrail
@onready var impact_burst: CPUParticles3D = $ImpactBurst
@onready var light: OmniLight3D = $OmniLight3D

func init_bolt(start: Vector3, dir: Vector3) -> void:
	global_position = start
	direction = dir.normalized()
	if direction != Vector3.ZERO:
		look_at(global_position + direction, Vector3.UP)

func set_empowered(empowered: bool) -> void:
	is_empowered = empowered
	if is_empowered:
		damage = 42.0
		speed = 38.0
		area_damage_radius = 2.8
		knockback_force = 12.0
		if visuals:
			visuals.scale = Vector3(1.6, 1.6, 1.6)
		if ring1:
			ring1.scale = Vector3(1.5, 1.5, 1.5)
		if ring2:
			ring2.scale = Vector3(1.5, 1.5, 1.5)
		if spark_trail:
			spark_trail.amount = 30
			spark_trail.speed_scale = 1.3
		if light:
			light.light_color = Color(0.15, 0.95, 1.0)
			light.light_energy = 4.8
			light.omni_range = 6.5

func _physics_process(delta: float) -> void:
	if has_exploded:
		return
	
	global_position += direction * speed * delta
	time_alive += delta
	
	# Animate counter-rotating energy orbital rings
	var rot_speed = (delta * 22.0) if is_empowered else (delta * 14.0)
	if ring1:
		ring1.rotation.z += rot_speed
	if ring2:
		ring2.rotation.x += rot_speed * 0.85
		ring2.rotation.y += rot_speed * 0.7
	
	if light:
		var base_eng = 4.8 if is_empowered else 2.5
		light.light_energy = base_eng + sin(time_alive * 32.0) * 0.35
	
	if time_alive >= lifetime:
		explode()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if has_exploded:
		return
	
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			var knock_force = 12.0 if is_empowered else 6.0
			body.take_damage(damage, direction * knock_force)
		explode()
	elif body.name == "Ground" or body.is_in_group("obstacle"):
		explode()

func explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	
	if is_empowered:
		GameManager.shake_camera(0.24)
		# Arcane shock blast damaging nearby secondary targets within 2.8m
		for e in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(e) and not e.get("is_dead"):
				var d = global_position.distance_to(e.global_position)
				if d <= 2.8 and d > 0.05:
					if e.has_method("take_damage"):
						var falloff = 1.0 - (d / 2.8)
						var push = (e.global_position - global_position).normalized()
						e.take_damage(18.0 * falloff, push * 8.0)
	else:
		GameManager.shake_camera(0.12)
	
	# Hide projectile visuals & stop continuous trail
	if visuals:
		visuals.visible = false
	if spark_trail:
		spark_trail.emitting = false
	
	# Trigger one-shot impact particle burst
	if impact_burst:
		if is_empowered:
			impact_burst.amount = 32
			impact_burst.initial_velocity_max = 12.0
		impact_burst.emitting = true
	
	# Arcane impact ring flash
	if get_parent():
		var ring = MeshInstance3D.new()
		var quad = QuadMesh.new()
		quad.size = Vector2(2.4, 2.4)
		var rmat = StandardMaterial3D.new()
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		rmat.albedo_texture = preload("res://assets/vfx/textures/ring_sharp.png")
		rmat.albedo_color = Color(0.3, 0.85, 1.0, 0.9)
		quad.material = rmat
		ring.mesh = quad
		get_parent().add_child(ring)
		ring.global_position = global_position
		ring.scale = Vector3(0.2, 0.2, 0.2)
		var rtween = ring.create_tween().set_parallel(true)
		rtween.tween_property(ring, "scale", Vector3(1.8, 1.8, 1.8), 0.28)
		rtween.tween_property(rmat, "albedo_color:a", 0.0, 0.28)
		rtween.chain().tween_callback(ring.queue_free)
	
	if light:
		light.light_energy = 8.0 if is_empowered else 5.5
		var tween = create_tween()
		tween.tween_property(light, "light_energy", 0.0, 0.35)
	
	# Wait for burst to complete then free
	get_tree().create_timer(0.45).timeout.connect(queue_free)
