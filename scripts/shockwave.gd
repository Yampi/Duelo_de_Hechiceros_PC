extends Node3D

@export var max_radius: float = 6.5
@export var damage: float = 35.0
@export var duration: float = 0.45

var elapsed: float = 0.0
var hit_enemies: Array = []

@onready var ring: MeshInstance3D = $Ring
@onready var dome: MeshInstance3D = $EnergyDome
@onready var particles: CPUParticles3D = $RadialParticles
@onready var light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	ring.scale = Vector3(0.1, 0.1, 0.1)
	dome.scale = Vector3(0.1, 0.1, 0.1)
	if ring.mesh and ring.mesh.material:
		ring.material_override = ring.mesh.material.duplicate()
	if dome.mesh and dome.mesh.material:
		dome.material_override = dome.mesh.material.duplicate()
	if light:
		light.light_energy = 6.0
	GameManager.shake_camera(0.35)

func _physics_process(delta: float) -> void:
	elapsed += delta
	var progress = min(1.0, elapsed / duration)
	var current_radius = progress * max_radius
	
	ring.scale = Vector3(current_radius, 1.0, current_radius)
	dome.scale = Vector3(current_radius, 1.0 - (progress * 0.5), current_radius)
	
	if ring.material_override:
		var mat = ring.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color.a = (1.0 - progress) * 0.85
	
	if dome.material_override:
		var dmat = dome.material_override as StandardMaterial3D
		if dmat:
			dmat.albedo_color.a = (1.0 - progress) * 0.35
	
	if light:
		light.light_energy = (1.0 - progress) * 6.0
	
	# Check for enemies within expanding radius
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and not e in hit_enemies:
			var dist = global_position.distance_to(e.global_position)
			if dist <= current_radius:
				hit_enemies.append(e)
				var push_dir = (e.global_position - global_position).normalized()
				push_dir.y = 0.2
				if e.has_method("take_damage"):
					e.take_damage(damage, push_dir * 18.0)
	
	if elapsed >= duration:
		queue_free()
