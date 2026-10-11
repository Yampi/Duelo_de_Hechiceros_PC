extends Node3D

@export var speed: float = 18.0
@export var damage: float = 14.0
var direction: Vector3 = Vector3.FORWARD
var lifetime: float = 2.5
var has_hit: bool = false

@onready var visuals: Node3D = $Visuals
@onready var trail: CPUParticles3D = $NecroticTrail
@onready var impact_burst: CPUParticles3D = $ImpactBurst
@onready var light: OmniLight3D = $OmniLight3D

func init_arrow(start_pos: Vector3, dir: Vector3) -> void:
	direction = dir.normalized()
	if direction.length_squared() > 0.001:
		look_at_from_position(start_pos, start_pos + direction, Vector3.UP)
	else:
		global_position = start_pos

func _process(delta: float) -> void:
	if has_hit:
		return
	
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		_on_impact()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if has_hit:
		return
	
	if body.is_in_group("player") or body.is_in_group("minion"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_on_impact()
	elif body.is_in_group("obstacle") or body.name == "Ground":
		_on_impact()

func _on_impact() -> void:
	if has_hit:
		return
	has_hit = true
	
	if visuals:
		visuals.visible = false
	if trail:
		trail.emitting = false
	if impact_burst:
		impact_burst.emitting = true
	if light:
		var tween = create_tween()
		tween.tween_property(light, "light_energy", 0.0, 0.25)
	
	get_tree().create_timer(0.35).timeout.connect(queue_free)
