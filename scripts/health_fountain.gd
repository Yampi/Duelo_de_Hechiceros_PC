extends Area3D

@export var heal_rate: float = 25.0

var player_inside: bool = false

@onready var water_mesh: MeshInstance3D = $Water
@onready var light: OmniLight3D = $OmniLight3D
@onready var chalice: Node3D = $Chalice if has_node("Chalice") else null

var time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	time += delta
	if player_inside:
		GameManager.player_health = min(GameManager.player_max_health, GameManager.player_health + (heal_rate * delta))
	
	if water_mesh:
		water_mesh.rotate_y(delta * 0.8)
	
	if chalice:
		chalice.rotate_y(delta * 1.2)
		chalice.position.y = 1.05 + sin(time * 2.5) * 0.12

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		if light:
			light.light_energy = 4.5

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		if light:
			light.light_energy = 2.0
