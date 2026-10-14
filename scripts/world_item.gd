class_name WorldItem
extends Area3D

const ItemDB = preload("res://scripts/inventory/item_db.gd")
const InteractionPrompt = preload("res://scripts/ui/interaction_prompt.gd")

@export var item_id: String = "potion_health"
@export var amount: int = 1
@export var auto_pickup_range: float = 2.2
@export var prompt_range: float = 4.0

var base_y: float = 0.5
var time: float = 0.0
var is_collected: bool = false
var warning_cooldown: float = 0.0

@onready var mesh_inst: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D
@onready var prompt_label: Label3D = $PromptLabel

func _ready() -> void:
	add_to_group("world_item")
	base_y = global_position.y
	_setup_visuals()
	body_entered.connect(_on_body_entered)

func setup(p_id: String, p_amount: int = 1) -> void:
	item_id = p_id
	amount = p_amount
	_setup_visuals()

func _setup_visuals() -> void:
	var def = ItemDB.get_item(item_id)
	var col = Color(0.2, 0.85, 1.0)
	var item_name = item_id
	
	if def:
		item_name = def.name
		match def.category:
			"consumable":
				if "health" in item_id or "apple" in item_id:
					col = Color(0.2, 1.0, 0.4)
				elif "mana" in item_id:
					col = Color(0.2, 0.7, 1.0)
				else:
					col = Color(1.0, 0.8, 0.2)
			"quest":
				col = Color(0.85, 0.35, 1.0)
			"material":
				col = Color(1.0, 0.5, 0.1) if item_id == "sulfur" else Color(0.3, 0.95, 0.5)
	
	if mesh_inst and mesh_inst.material_override:
		mesh_inst.material_override.set("albedo_color", col)
		mesh_inst.material_override.set("emission", col)
		mesh_inst.material_override.set("emission_energy_multiplier", 2.2)
	elif mesh_inst:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 2.2
		mesh_inst.material_override = mat
	
	if light:
		light.light_color = col
		light.light_energy = 2.0
	
	if prompt_label:
		prompt_label.text = "[E] %s x%d" % [item_name, amount]
		prompt_label.modulate = col
		prompt_label.visible = false

var prompt_inst: InteractionPrompt = null

func _process(delta: float) -> void:
	if is_collected:
		if prompt_inst:
			prompt_inst.dismiss()
			prompt_inst = null
		return
	
	time += delta
	warning_cooldown = max(0.0, warning_cooldown - delta)
	
	# Gentle hover bob & rotation
	rotate_y(delta * 2.2)
	position.y = base_y + sin(time * 3.2) * 0.14
	
	# Proximity check for player
	var player = _get_player()
	if player:
		var dist = global_position.distance_to(player.global_position)
		if prompt_label:
			prompt_label.visible = false # Handled by 2D screen projected prompt
		
		if dist <= prompt_range:
			if not prompt_inst:
				var hud = get_tree().root.find_child("HUD", true, false)
				if hud and hud.has_method("create_interaction_prompt"):
					var def = ItemDB.get_item(item_id)
					var item_name = def.name if def else item_id
					prompt_inst = hud.create_interaction_prompt(self, "Recoger %s" % item_name, "E", 0.75)
		else:
			if prompt_inst:
				prompt_inst.dismiss()
				prompt_inst = null
		
		# Proximity interaction or auto-pickup if close
		if dist <= auto_pickup_range:
			_attempt_pickup(player)

func _get_player() -> Node3D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		return players[0]
	return null

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_attempt_pickup(body)

func _unhandled_input(event: InputEvent) -> void:
	if is_collected:
		return
	if event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_F):
		var player = _get_player()
		if player and global_position.distance_to(player.global_position) <= prompt_range:
			_attempt_pickup(player)
			get_viewport().set_input_as_handled()

func _attempt_pickup(player: Node) -> void:
	if is_collected:
		return
	if prompt_inst:
		prompt_inst.dismiss()
		prompt_inst = null
	
	var def = ItemDB.get_item(item_id)
	var item_name = def.name if def else item_id
	
	if not GameManager.inventory.can_add_item(item_id, amount):
		if warning_cooldown <= 0.0:
			warning_cooldown = 1.6
			GameManager.spawn_damage_number(global_position + Vector3(0, 0.8, 0), "⚠️ ¡Inventario Lleno!", Color(1.0, 0.3, 0.3), 1.25)
		return
	
	is_collected = true
	GameManager.inventory.add_item(item_id, amount)
	
	var notif_text = "📦 +%d %s" % [amount, item_name]
	GameManager.spawn_damage_number(global_position + Vector3(0, 0.8, 0), notif_text, Color(1.0, 0.9, 0.3), 1.3)
	
	# Special discovery objective progress for Arcane Crystal
	if item_id == "arcane_crystal":
		GameManager.set_objective("Lleva el Cristal Arcano al Altar en las Ruinas (-36, 0, -68)", Vector3(-36.0, 0.0, -68.0))
		GameManager.discover_poi("altar_arcano", "Altar de Transmutación Arcana", Vector3(-36.0, 0.0, -68.0), "altar_transmutacion")
	
	# Pickup collection animation
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector3(1.8, 1.8, 1.8), 0.16)
	if light:
		tween.tween_property(light, "light_energy", 7.0, 0.16)
	tween.chain().tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.12)
	await tween.finished
	queue_free()
