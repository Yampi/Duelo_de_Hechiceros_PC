class_name AncientAltar
extends Area3D

const InteractionPrompt = preload("res://scripts/ui/interaction_prompt.gd")

var is_activated: bool = false
var prompt_range: float = 4.5
var time: float = 0.0

@onready var prompt_label: Label3D = $PromptLabel
@onready var light: OmniLight3D = $OmniLight3D
@onready var pillar: MeshInstance3D = $PillarMesh
@onready var runes: CPUParticles3D = $RuneParticles

func _ready() -> void:
	add_to_group("altar")
	if prompt_label:
		prompt_label.visible = false
	if pillar:
		pillar.visible = false
	
	# Register POI if not registered yet
	GameManager.discover_poi("altar_arcano", "Altar de Transmutación Arcana", global_position, "altar_transmutacion")

var prompt_inst: InteractionPrompt = null

func _process(delta: float) -> void:
	time += delta
	var player = _get_player()
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist <= 16.0:
			GameManager.discover_poi("altar_arcano", "Altar de Transmutación Arcana", global_position, "altar_transmutacion")
		
		if dist <= prompt_range:
			if prompt_label:
				prompt_label.visible = false # Replaced by 2D screen projected prompt
			if not prompt_inst:
				var hud = get_tree().root.find_child("HUD", true, false)
				if hud and hud.has_method("create_interaction_prompt"):
					var prompt_str = "Altar Activo" if is_activated else ("Activar Altar" if (GameManager.inventory and GameManager.inventory.has_item("arcane_crystal")) else "Requiere Cristal")
					prompt_inst = hud.create_interaction_prompt(self, prompt_str, "F", 1.8)
		else:
			if prompt_inst:
				prompt_inst.dismiss()
				prompt_inst = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_F):
		var player = _get_player()
		if player and global_position.distance_to(player.global_position) <= prompt_range:
			interact(player)
			get_viewport().set_input_as_handled()

func interact(player: Node) -> void:
	if is_activated:
		GameManager.spawn_damage_number(global_position + Vector3(0, 1.8, 0), "✨ El Altar resuena con energía plena", Color(0.3, 0.9, 1.0), 1.2)
		return
	
	if not GameManager.inventory or not GameManager.inventory.has_item("arcane_crystal"):
		GameManager.spawn_damage_number(global_position + Vector3(0, 1.8, 0), "🔒 Requiere un Cristal Arcano", Color(1.0, 0.4, 0.3), 1.3)
		return
	
	# Consume crystal and activate
	is_activated = true
	GameManager.inventory.remove_item("arcane_crystal", 1)
	GameManager.empower_arcana()
	
	# Visual spectacle
	if light:
		light.light_color = Color(0.2, 0.95, 1.0)
		light.light_energy = 8.0
	
	if pillar:
		pillar.visible = true
		pillar.scale = Vector3(0.1, 0.1, 0.1)
		var p_tween = create_tween()
		p_tween.tween_property(pillar, "scale", Vector3(1.2, 4.0, 1.2), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if runes:
		runes.emitting = true
	
	GameManager.shake_camera(0.6)
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("shrine")
	GameManager.spawn_damage_number(global_position + Vector3(0, 2.2, 0), "🔮 ¡ALQUIMIA ARCANA DESPERTADA!", Color(0.85, 0.45, 1.0), 1.5)
	GameManager.set_objective("¡Poder arcano al máximo! Avanza hacia las Ruinas Arcanas.", Vector3(0, 0, -98))
	
	# Pulse player staff
	if player and player.has_method("_pulse_staff"):
		player._pulse_staff(Color(0.2, 0.95, 1.0), 1.2)

func _get_player() -> Node3D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		return players[0]
	return null
