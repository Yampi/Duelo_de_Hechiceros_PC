class_name GatheringNode
extends Node3D

const ItemDB = preload("res://scripts/inventory/item_db.gd")

@export var resource_item_id: String = "berry"
@export var resource_name: String = "Arbusto de Bayas Silvestres"
@export var min_yield: int = 1
@export var max_yield: int = 2
@export var respawn_time: float = 40.0
@export var prompt_range: float = 4.0

var can_gather: bool = true
var respawn_timer: float = 0.0

@onready var visual_mesh: MeshInstance3D = find_child("VisualMesh", true, false)
@onready var aura_light: OmniLight3D = find_child("AuraLight", true, false)

func _ready() -> void:
	add_to_group("gathering_node")

func _process(delta: float) -> void:
	if not can_gather:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			respawn()

func gather(player: Node = null) -> bool:
	if not can_gather:
		return false
	
	var yield_count = randi_range(min_yield, max_yield)
	var inv = GameManager.inventory
	if inv:
		if not inv.can_add_item(resource_item_id, yield_count):
			GameManager.spawn_damage_number(global_position + Vector3(0, 1.2, 0), "🎒 ¡Inventario lleno!", Color(1.0, 0.4, 0.4), 1.2)
			return false
		inv.add_item(resource_item_id, yield_count)
	
	can_gather = false
	respawn_timer = respawn_time
	
	var def = ItemDB.get_item(resource_item_id)
	var disp_name = def.name if def else resource_name
	GameManager.spawn_damage_number(global_position + Vector3(0, 1.4, 0), "🌿 +%d %s" % [yield_count, disp_name], Color(0.4, 1.0, 0.6), 1.4)
	
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("loot")
	
	if visual_mesh:
		visual_mesh.visible = false
	if aura_light:
		aura_light.visible = false
	
	return true

func respawn() -> void:
	can_gather = true
	respawn_timer = 0.0
	if visual_mesh:
		visual_mesh.visible = true
	if aura_light:
		aura_light.visible = true
