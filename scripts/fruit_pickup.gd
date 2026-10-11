extends Area3D

@export var heal_amount: float = 25.0

var base_y: float = 0.4
var time: float = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time += delta
	rotate_y(delta * 2.0)
	position.y = base_y + sin(time * 3.5) * 0.1

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		GameManager.player_health = min(GameManager.player_max_health, GameManager.player_health + heal_amount)
		GameManager.add_reagent("apple", 1)
		
		# Collect chime/scale animation
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.15)
		if light:
			tween.tween_property(light, "light_energy", 5.0, 0.15)
		await tween.finished
		queue_free()
