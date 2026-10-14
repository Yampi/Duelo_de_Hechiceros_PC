extends Node3D

@export var speed: float = 28.0
@export var damage: float = 35.0
@export var max_range: float = 28.0

var direction: Vector3 = Vector3.FORWARD
var traveled_distance: float = 0.0
var has_hit: bool = false

@onready var visuals: Node3D = $Visuals
@onready var frost_trail: CPUParticles3D = $FrostTrail
@onready var shatter_burst: CPUParticles3D = $ShatterBurst
@onready var light: OmniLight3D = $OmniLight3D

func init_projectile(start_pos: Vector3, dir: Vector3) -> void:
	global_position = start_pos
	direction = dir.normalized()
	if direction.length_squared() > 0.001:
		look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	if has_hit:
		return
	
	var step = speed * delta
	global_position += direction * step
	traveled_distance += step
	
	# Crystalline axial spin
	if visuals:
		visuals.rotate_z(delta * 12.0)
	
	if traveled_distance >= max_range:
		impact()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if has_hit:
		return
	if body.is_in_group("enemy"):
		if body.has_method("apply_chill"):
			body.apply_chill(0.45, 4.0)
		if body.has_method("take_damage"):
			body.take_damage(damage, direction * 6.0, "ice")
		impact()
	elif not body.is_in_group("player") and body is StaticBody3D:
		impact()

func impact() -> void:
	if has_hit:
		return
	has_hit = true
	
	if visuals:
		visuals.visible = false
	if frost_trail:
		frost_trail.emitting = false
	if shatter_burst:
		shatter_burst.emitting = true
	
	# Frost shatter ring
	if get_parent():
		var ring = MeshInstance3D.new()
		var quad = QuadMesh.new()
		quad.size = Vector2(2.2, 2.2)
		var rmat = StandardMaterial3D.new()
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		rmat.albedo_texture = preload("res://assets/vfx/textures/ring_sharp.png")
		rmat.albedo_color = Color(0.5, 0.9, 1.0, 0.85)
		quad.material = rmat
		ring.mesh = quad
		get_parent().add_child(ring)
		ring.global_position = global_position
		ring.scale = Vector3(0.2, 0.2, 0.2)
		var rtween = ring.create_tween().set_parallel(true)
		rtween.tween_property(ring, "scale", Vector3(1.6, 1.6, 1.6), 0.3)
		rtween.tween_property(rmat, "albedo_color:a", 0.0, 0.3)
		rtween.chain().tween_callback(ring.queue_free)
	
	if light:
		var tween = create_tween()
		tween.tween_property(light, "light_energy", 0.0, 0.35)
	
	get_tree().create_timer(0.4).timeout.connect(queue_free)
