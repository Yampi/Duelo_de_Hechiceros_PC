extends Area3D

signal level_completed

var is_active: bool = false

@onready var vortex: MeshInstance3D = $Vortex
@onready var light: OmniLight3D = $OmniLight3D
@onready var label: Label3D = $Label3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	update_state(false)

func _process(delta: float) -> void:
	if vortex:
		vortex.rotate_z(delta * (3.0 if is_active else 0.5))

func update_state(active: bool) -> void:
	is_active = active
	var color = Color(0.1, 1.0, 0.8) if is_active else Color(0.4, 0.4, 0.4)
	if vortex and vortex.material_override:
		vortex.material_override.set("emission", color)
		vortex.material_override.set("emission_energy_multiplier", 4.0 if is_active else 0.5)
	if light:
		light.light_color = color
		light.light_energy = 4.0 if is_active else 0.8
	if label:
		if is_active:
			label.text = "★ PORTAL DE EVASIÓN ABIERTO ★\n¡Entra para superar el nivel!"
			label.modulate = Color.YELLOW
		else:
			label.text = "PORTAL ARCANO SELLADO\nActiva 3 Lugares de Poder y vence al Guardián"
			label.modulate = Color(0.7, 0.7, 0.7)

func _on_body_entered(body: Node3D) -> void:
	if is_active and body.is_in_group("player"):
		GameManager.level_cleared = true
		level_completed.emit()
