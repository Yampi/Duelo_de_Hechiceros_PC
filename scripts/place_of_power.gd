extends Area3D

signal control_changed(new_owner: String)

enum OwnerState { NEUTRAL, PLAYER, ENEMY }

@export var capture_speed: float = 0.35 # captures in ~3 seconds
@export var mana_bonus_rate: float = 8.0 # mana per second granted to owner

var current_owner: OwnerState = OwnerState.NEUTRAL
var capture_progress: float = 0.0 # 0.0 to 1.0
var player_inside: bool = false

@onready var rune_mesh: MeshInstance3D = $RuneCircle
@onready var beacon_light: OmniLight3D = $BeaconLight
@onready var beacon_pillar: MeshInstance3D = $BeaconPillar
@onready var label_status: Label3D = $StatusLabel

var neutral_color: Color = Color(0.6, 0.6, 0.6, 0.4)
var player_color: Color = Color(0.1, 0.8, 1.0, 0.9)
var enemy_color: Color = Color(0.95, 0.18, 0.22, 0.9)
var contested_color: Color = Color(1.0, 0.75, 0.1, 0.9)

var enemies_inside_count: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	update_visuals()

func _process(delta: float) -> void:
	# Rotate rune circle slowly
	if rune_mesh:
		rune_mesh.rotate_y(delta * 0.4)

	var has_enemies = enemies_inside_count > 0

	# Contested state
	if player_inside and has_enemies:
		if label_status:
			label_status.text = "LUGAR DE PODER\n⚔️ ¡ZONA DISPUTADA! ⚔️"
			label_status.modulate = contested_color
		return

	# Player capturing / liberating logic
	if player_inside and not has_enemies:
		if current_owner == OwnerState.ENEMY:
			# Neutralize enemy hold first
			capture_progress -= capture_speed * delta
			if capture_progress <= 0.0:
				capture_progress = 0.0
				current_owner = OwnerState.NEUTRAL
				control_changed.emit("neutral")
		elif current_owner != OwnerState.PLAYER:
			capture_progress += capture_speed * delta
			if capture_progress >= 1.0:
				capture_progress = 1.0
				current_owner = OwnerState.PLAYER
				GameManager.active_shrines += 1
				GameManager.update_mana_capacity()
				control_changed.emit("player")
				play_captured_effect(true)
		update_visuals()

	# Enemy capturing / corrupting logic
	elif has_enemies and not player_inside:
		if current_owner == OwnerState.PLAYER:
			# Neutralize player hold first
			capture_progress -= capture_speed * delta
			if capture_progress <= 0.0:
				capture_progress = 0.0
				current_owner = OwnerState.NEUTRAL
				GameManager.active_shrines = max(0, GameManager.active_shrines - 1)
				GameManager.update_mana_capacity()
				control_changed.emit("neutral")
		elif current_owner != OwnerState.ENEMY:
			capture_progress += capture_speed * delta
			if capture_progress >= 1.0:
				capture_progress = 1.0
				current_owner = OwnerState.ENEMY
				control_changed.emit("enemy")
				play_captured_effect(false)
		update_visuals()

	# Idle decay toward neutral if left unattended mid-capture
	elif not player_inside and not has_enemies and current_owner == OwnerState.NEUTRAL and capture_progress > 0.0:
		capture_progress = max(0.0, capture_progress - capture_speed * 0.5 * delta)
		update_visuals()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true
	elif body.is_in_group("rival_wizard") or (body.is_in_group("enemy") and body.get("is_boss") == true):
		enemies_inside_count += 1

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false
	elif body.is_in_group("rival_wizard") or (body.is_in_group("enemy") and body.get("is_boss") == true):
		enemies_inside_count = max(0, enemies_inside_count - 1)

func play_captured_effect(by_player: bool) -> void:
	GameManager.shake_camera(0.35)
	if by_player:
		GameManager.spawn_damage_number(global_position + Vector3(0, 1.5, 0), "🏛️ ¡LUGAR DE PODER RECLAMADO!", Color(0.2, 0.95, 1.0), 1.25)
	else:
		GameManager.spawn_damage_number(global_position + Vector3(0, 1.5, 0), "💀 ¡SANTUARIO CAPTURADO POR EL RIVAL!", Color(1.0, 0.2, 0.2), 1.3)
	
	var tween = create_tween()
	if beacon_light:
		tween.tween_property(beacon_light, "light_energy", 8.0, 0.25)
		tween.tween_property(beacon_light, "light_energy", 3.0, 0.5)

func update_visuals() -> void:
	var active_color: Color = neutral_color
	if current_owner == OwnerState.PLAYER:
		active_color = player_color
	elif current_owner == OwnerState.ENEMY:
		active_color = enemy_color
	elif player_inside:
		active_color = neutral_color.lerp(player_color, capture_progress)
	elif enemies_inside_count > 0:
		active_color = neutral_color.lerp(enemy_color, capture_progress)
	
	if rune_mesh and rune_mesh.material_override:
		rune_mesh.material_override.set("albedo_color", active_color)
		rune_mesh.material_override.set("emission", active_color)
		rune_mesh.material_override.set("emission_energy_multiplier", 1.0 + (capture_progress * 2.5))
	
	if beacon_pillar and beacon_pillar.material_override:
		beacon_pillar.material_override.set("albedo_color", Color(active_color.r, active_color.g, active_color.b, 0.3 * (capture_progress if current_owner == OwnerState.NEUTRAL else 1.0)))
	
	if beacon_light:
		beacon_light.light_color = active_color
		beacon_light.light_energy = 0.5 + (capture_progress * 2.0)

	if label_status:
		if current_owner == OwnerState.PLAYER:
			label_status.text = "LUGAR DE PODER\n[ BAJO TU CONTROL ]\n+8 Maná/seg"
			label_status.modulate = player_color
		elif current_owner == OwnerState.ENEMY:
			label_status.text = "LUGAR DE PODER\n[ CONTROL RIVAL ]\n¡Reconquístalo!"
			label_status.modulate = enemy_color
		elif player_inside:
			var pct = int(capture_progress * 100.0)
			label_status.text = "PURIFICANDO...\n" + str(pct) + "%"
			label_status.modulate = Color.YELLOW
		elif enemies_inside_count > 0:
			var pct = int(capture_progress * 100.0)
			label_status.text = "CORROMPIENDO...\n" + str(pct) + "%"
			label_status.modulate = Color(1.0, 0.4, 0.1)
		else:
			label_status.text = "LUGAR DE PODER\n[ NEUTRAL ]\nAcércate para reclamar"
			label_status.modulate = Color(0.8, 0.8, 0.8)
