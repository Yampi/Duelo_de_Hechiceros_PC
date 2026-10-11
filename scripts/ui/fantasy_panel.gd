class_name FantasyPanel
extends Control

@export var title: String = "":
	set(val):
		title = val
		_update_ui()

@export var border_color: Color = Color(0.85, 0.72, 0.35, 1.0): # Oro arcano
	set(val):
		border_color = val
		_update_ui()

@export var background_color: Color = Color(0.06, 0.08, 0.12, 0.92): # Obsidiana mística
	set(val):
		background_color = val
		_update_ui()

@export var show_header: bool = true:
	set(val):
		show_header = val
		_update_ui()

@onready var bg_rect: ColorRect = $Background
@onready var frame_rect: NinePatchRect = $FrameBorder
@onready var title_label: Label = $VBox/Header/TitleLabel
@onready var header_container: VBoxContainer = $VBox/Header
@onready var content_container: MarginContainer = $VBox/Content

func _ready() -> void:
	_update_ui()

func _update_ui() -> void:
	if not is_inside_tree():
		return
	if bg_rect:
		bg_rect.color = background_color
	if frame_rect:
		frame_rect.modulate = border_color
	if title_label:
		title_label.text = title
	if header_container:
		header_container.visible = show_header and (title != "")

func set_panel_title(new_title: String) -> void:
	self.title = new_title
