class_name EarthFissure
extends Node3D

@export var radius: float = 4.0
@export var duration: float = 5.0
@export var damage: float = 12.0

var elapsed: float = 0.0
var tick_timer: float = 0.0
var affected_enemies: Dictionary = {}

@onready var mud_disk: MeshInstance3D = $MudDisk
@onready var dust_particles: CPUParticles3D = $DustParticles
@onready var light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	# Subtle ground alignment
	position.y = MapConfig.get_height_at(global_position.x, global_position.z) + 0.04
	
	GameManager.shake_camera(0.25)
	_pulse_fissure()
	_apply_fissure_effects()

func _process(delta: float) -> void:
	elapsed += delta
	tick_timer += delta
	
	if mud_disk:
		# Subtle rumble scale wobble
		var wobble = 1.0 + sin(elapsed * 18.0) * 0.02
		mud_disk.scale = Vector3(wobble, 1.0, wobble)
	
	if tick_timer >= 0.5:
		tick_timer = 0.0
		_apply_fissure_effects()
	
	if elapsed >= duration:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.4)
		await tween.finished
		queue_free()

func _pulse_fissure() -> void:
	GameManager.spawn_damage_number(global_position + Vector3(0, 1.2, 0), "🪨 ¡PANTANO ARCANO!", Color(0.75, 0.6, 0.4), 1.2)

func _apply_fissure_effects() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and enemy.is_inside_tree() and not enemy.get("is_dead"):
			var d_2d = Vector2(global_position.x, global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
			var dy = abs(global_position.y - enemy.global_position.y)
			if d_2d <= radius and dy <= 3.5:
				if enemy.has_method("apply_earth_sink"):
					enemy.apply_earth_sink(4.0, 0.70)
				if not affected_enemies.has(enemy):
					affected_enemies[enemy] = true
					if enemy.has_method("take_damage"):
						enemy.take_damage(damage, Vector3.ZERO, "earth")
