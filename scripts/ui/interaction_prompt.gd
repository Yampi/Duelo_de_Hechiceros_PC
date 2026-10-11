class_name InteractionPrompt
extends Control

const UIConstants = preload("res://scripts/ui/ui_constants.gd")

@export var prompt_key: String = "F":
	set(val):
		prompt_key = val
		if key_label:
			key_label.text = "[%s]" % prompt_key

@export var prompt_text: String = "Interactuar":
	set(val):
		prompt_text = val
		if action_label:
			action_label.text = prompt_text

@export var progress: float = 0.0:
	set(val):
		progress = clamp(val, 0.0, 1.0)
		if progress_arc:
			progress_arc.queue_redraw()

@onready var container: PanelContainer = $Container
@onready var key_label: Label = $Container/HBox/KeyBadge/KeyLabel
@onready var action_label: Label = $Container/HBox/ActionLabel
@onready var progress_arc: Control = $ProgressArc

var target_node: Node3D = null
var offset_3d: Vector3 = Vector3(0, 1.2, 0)
var camera_ref: Camera3D = null

func setup_target(node: Node3D, text_str: String, key_str: String = "F", height_offset: float = 1.2) -> void:
	target_node = node
	offset_3d = Vector3(0, height_offset, 0)
	prompt_text = text_str
	prompt_key = key_str

func _ready() -> void:
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	pivot_offset = size * 0.5
	
	if key_label:
		key_label.text = "[%s]" % prompt_key
	if action_label:
		action_label.text = prompt_text
	if progress_arc:
		progress_arc.draw.connect(_on_progress_arc_draw)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_progress_arc_draw() -> void:
	if progress <= 0.001:
		return
	var center = Vector2(18.0, size.y * 0.5)
	var radius = 13.0
	var start_angle = -PI * 0.5
	var end_angle = start_angle + (PI * 2.0 * progress)
	progress_arc.draw_arc(center, radius, start_angle, end_angle, 32, UIConstants.GOLD_BASE, 2.5, true)

func _process(_delta: float) -> void:
	if not target_node or not is_instance_valid(target_node):
		queue_free()
		return
	
	if not camera_ref:
		camera_ref = get_viewport().get_camera_3d()
		if not camera_ref:
			return
	
	var world_pos = target_node.global_position + offset_3d
	if camera_ref.is_position_behind(world_pos):
		visible = false
		return
	
	visible = true
	var screen_pos = camera_ref.unproject_position(world_pos)
	position = screen_pos - (size * 0.5)

func dismiss() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.parallel().tween_property(self, "scale", Vector2(0.8, 0.8), 0.15)
	tween.tween_callback(queue_free)
