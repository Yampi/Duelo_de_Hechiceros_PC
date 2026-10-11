extends StaticBody3D

@export var respawn_time: float = 40.0

var has_fruit: bool = true
var player_near: bool = false
var respawn_timer: float = 0.0

@onready var fruit_nodes: Node3D = $Fruits
@onready var label: Label3D = $PromptLabel

var fruit_scene: PackedScene = preload("res://scenes/FruitPickup.tscn")

func _ready() -> void:
	add_to_group("fruit_tree")
	$InteractZone.body_entered.connect(_on_zone_entered)
	$InteractZone.body_exited.connect(_on_zone_exited)
	update_state()

func _unhandled_input(event: InputEvent) -> void:
	if player_near and has_fruit:
		if event is InputEventKey and event.pressed and event.keycode == KEY_E:
			harvest()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not has_fruit:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			has_fruit = true
			update_state()

func _on_zone_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_near = true
		# Also harvest automatically or show prompt
		if has_fruit:
			harvest()

func _on_zone_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_near = false

func harvest() -> void:
	if not has_fruit:
		return
	
	has_fruit = false
	respawn_timer = respawn_time
	update_state()
	
	# Drop 2 to 3 fruits on the ground around the tree
	for i in range(3):
		var offset = Vector3(randf_range(-2.0, 2.0), 0.3, randf_range(-2.0, 2.0))
		var fruit = fruit_scene.instantiate()
		get_parent().add_child(fruit)
		fruit.global_position = global_position + offset

func update_state() -> void:
	if fruit_nodes:
		fruit_nodes.visible = has_fruit
	if label:
		label.visible = has_fruit
