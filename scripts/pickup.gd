extends Area3D

enum PickupType { HEALTH, MANA }
@export var type: PickupType = PickupType.MANA

var base_y: float = 0.5
var time: float = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	# Randomize type if not set
	if randf() > 0.5:
		type = PickupType.HEALTH
	
	base_y = position.y
	_update_visuals()
	body_entered.connect(_on_body_entered)

func _update_visuals() -> void:
	var color = Color(0.2, 1.0, 0.4) if type == PickupType.HEALTH else Color(0.2, 0.7, 1.0)
	if mesh and mesh.material_override:
		mesh.material_override.set("albedo_color", color)
		mesh.material_override.set("emission", color)
	if light:
		light.light_color = color

func _process(delta: float) -> void:
	time += delta
	rotate_y(delta * 2.5)
	position.y = base_y + sin(time * 3.0) * 0.15

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if type == PickupType.HEALTH:
			GameManager.player_health = min(GameManager.player_max_health, GameManager.player_health + 30.0)
		else:
			GameManager.player_mana = min(GameManager.player_max_mana, GameManager.player_mana + 35.0)
		
		# Collect pulse effect
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "scale", Vector3(1.6, 1.6, 1.6), 0.15)
		if light:
			tween.tween_property(light, "light_energy", 6.0, 0.15)
		await tween.finished
		queue_free()
