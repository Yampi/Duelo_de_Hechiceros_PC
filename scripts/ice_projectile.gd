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
			body.take_damage(damage, direction * 6.0)
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
	
	if light:
		var tween = create_tween()
		tween.tween_property(light, "light_energy", 0.0, 0.35)
	
	get_tree().create_timer(0.4).timeout.connect(queue_free)
