class_name ArcaneVines
extends Node3D

@export var radius: float = 3.0
@export var duration: float = 3.6
@export var damage: float = 10.0

var elapsed: float = 0.0

@onready var vine_model: Node3D = $VineRoot
@onready var leaf_particles: CPUParticles3D = $LeafParticles
@onready var light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	# Subtle ground alignment
	position.y = MapConfig.get_height_at(global_position.x, global_position.z) + 0.05
	
	GameManager.shake_camera(0.2)
	_trap_enemies()
	_animate_growth()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.35)
		await tween.finished
		queue_free()

func _animate_growth() -> void:
	scale = Vector3(0.1, 0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _trap_enemies() -> void:
	GameManager.spawn_damage_number(global_position + Vector3(0, 1.4, 0), "🌿 ¡ENREDADERAS ARCANAS!", Color(0.3, 0.95, 0.4), 1.25)
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and enemy.is_inside_tree() and not enemy.get("is_dead"):
			var d = global_position.distance_to(enemy.global_position)
			if d <= radius:
				if enemy.has_method("apply_root"):
					enemy.apply_root(3.0)
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage, Vector3.ZERO, "earth")
