class_name RivalWizard
extends CharacterBody3D

## RivalWizard — Hechicero Rival Autónomo (Archimago del Caos)
## Inspirado en los Duelos de Hechiceros de Magic & Mayhem (1998)
## Posee IA de combate mágico táctico, teletransporte evasivo,
## invocación de esbirros y guerra territorial por Lugares de Poder.

signal wizard_defeated(wizard_name: String)
signal spell_cast(spell_name: String)

enum DuelState {
	IDLE,
	SEEK_SHRINE,
	APPROACH_PLAYER,
	CAST_BOLT,
	CAST_FIREBALL,
	TELEPORT_EVADE,
	SUMMON_MINIONS,
	RETREAT
}

@export var wizard_name: String = "Archimago Malakor"
@export var max_health: float = 240.0
@export var move_speed: float = 4.2
@export var is_boss: bool = true

var current_health: float = 240.0
var is_dead: bool = false
var state: DuelState = DuelState.IDLE
var state_timer: float = 0.0

var target_player: CharacterBody3D = null
var nearest_shrine: Node3D = null
var summon_cooldown: float = 16.0
var summon_timer: float = 0.0
var cast_timer: float = 0.0
var teleport_cooldown: float = 6.0
var teleport_timer: float = 0.0
var shield_active: bool = false
var shield_duration: float = 0.0

var projectile_scene: PackedScene = preload("res://scenes/MagicBolt.tscn")
var fireball_scene: PackedScene = preload("res://scenes/Fireball.tscn")
var minion_scene: PackedScene = preload("res://scenes/GoblinMinion.tscn")

@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer if has_node("Model/AnimationPlayer") else null
@onready var status_label: Label3D = $StatusLabel
@onready var shield_mesh: MeshInstance3D = $ShieldMesh
@onready var aura_light: OmniLight3D = $AuraLight

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("rival_wizard")
	add_to_group("boss")
	current_health = max_health
	shield_mesh.visible = false
	_apply_rival_visuals()
	_update_label()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	_tick_cooldowns(delta)
	_find_targets()
	
	match state:
		DuelState.IDLE:
			_process_idle(delta)
		DuelState.SEEK_SHRINE:
			_process_seek_shrine(delta)
		DuelState.APPROACH_PLAYER:
			_process_approach_player(delta)
		DuelState.CAST_BOLT:
			_process_cast_bolt(delta)
		DuelState.CAST_FIREBALL:
			_process_cast_fireball(delta)
		DuelState.TELEPORT_EVADE:
			_process_teleport_evade(delta)
		DuelState.SUMMON_MINIONS:
			_process_summon_minions(delta)
		DuelState.RETREAT:
			_process_retreat(delta)
	
	# Gravity
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	move_and_slide()

func _tick_cooldowns(delta: float) -> void:
	summon_timer = max(0.0, summon_timer - delta)
	teleport_timer = max(0.0, teleport_timer - delta)
	cast_timer = max(0.0, cast_timer - delta)
	state_timer = max(0.0, state_timer - delta)
	
	if shield_active:
		shield_duration -= delta
		if shield_duration <= 0.0:
			shield_active = false
			shield_mesh.visible = false

func _find_targets() -> void:
	if not target_player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]
	
	# Buscar Lugar de Poder más cercano si no tiene uno
	if not nearest_shrine:
		var shrines = get_tree().get_nodes_in_group("poi")
		var best_dist = 999.0
		for s in shrines:
			if s.has_method("play_captured_effect"):
				var d = global_position.distance_to(s.global_position)
				if d < best_dist:
					best_dist = d
					nearest_shrine = s

func _process_idle(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	
	if target_player:
		var dist = global_position.distance_to(target_player.global_position)
		if dist < 22.0:
			if teleport_timer <= 0.0 and dist < 7.0:
				_start_teleport_evade()
			elif summon_timer <= 0.0:
				_start_summon()
			elif cast_timer <= 0.0:
				if randf() < 0.4:
					_start_cast_fireball()
				else:
					_start_cast_bolt()
			else:
				state = DuelState.APPROACH_PLAYER
				state_timer = 2.0
		elif nearest_shrine and nearest_shrine.get("current_owner") != 2: # No es ENEMY
			state = DuelState.SEEK_SHRINE
			state_timer = 5.0
	elif nearest_shrine:
		state = DuelState.SEEK_SHRINE
		state_timer = 5.0

func _process_seek_shrine(delta: float) -> void:
	if not nearest_shrine:
		state = DuelState.IDLE
		return
	
	var dir = (nearest_shrine.global_position - global_position)
	dir.y = 0.0
	if dir.length() > 3.0:
		dir = dir.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		# Quedarse en el santuario para capturarlo
		if target_player and global_position.distance_to(target_player.global_position) < 18.0:
			state = DuelState.IDLE

func _process_approach_player(delta: float) -> void:
	if not target_player:
		state = DuelState.IDLE
		return
	
	var dist = global_position.distance_to(target_player.global_position)
	if dist < 6.0 and teleport_timer <= 0.0:
		_start_teleport_evade()
		return
	
	if dist <= 14.0 and cast_timer <= 0.0:
		state = DuelState.IDLE
		return
	
	var dir = (target_player.global_position - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	look_at(global_position + dir, Vector3.UP)
	
	if state_timer <= 0.0:
		state = DuelState.IDLE

func _start_cast_bolt() -> void:
	state = DuelState.CAST_BOLT
	state_timer = 0.4
	velocity.x = 0.0
	velocity.z = 0.0
	if target_player:
		var dir = (target_player.global_position - global_position).normalized()
		look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)

func _process_cast_bolt(delta: float) -> void:
	if state_timer <= 0.0:
		_fire_bolt()
		cast_timer = 1.2
		state = DuelState.IDLE

func _fire_bolt() -> void:
	if not target_player:
		return
	var bolt = projectile_scene.instantiate()
	get_parent().add_child(bolt)
	bolt.global_position = global_position + Vector3(0, 1.4, 0)
	var dir = (target_player.global_position + Vector3(0, 0.8, 0) - bolt.global_position).normalized()
	bolt.launch(dir)
	spell_cast.emit("Centella Arcana Hostil")

func _start_cast_fireball() -> void:
	state = DuelState.CAST_FIREBALL
	state_timer = 0.75
	velocity.x = 0.0
	velocity.z = 0.0
	GameManager.spawn_damage_number(global_position + Vector3(0, 2.2, 0), "🔥 CONCENTRANDO FUEGO...", Color(1.0, 0.4, 0.1), 1.0)

func _process_cast_fireball(delta: float) -> void:
	if state_timer <= 0.0:
		_fire_fireball()
		cast_timer = 2.5
		state = DuelState.IDLE

func _fire_fireball() -> void:
	if not target_player:
		return
	var fb = fireball_scene.instantiate()
	get_parent().add_child(fb)
	fb.global_position = global_position + Vector3(0, 1.5, 0)
	var dir = (target_player.global_position - fb.global_position).normalized()
	fb.launch(dir)
	spell_cast.emit("Bola de Fuego del Caos")

func _start_teleport_evade() -> void:
	state = DuelState.TELEPORT_EVADE
	teleport_timer = teleport_cooldown
	
	# Salto dimensional hacia atrás o lateral
	var evade_dir = -transform.basis.z
	if randf() < 0.5:
		evade_dir += transform.basis.x * (1.0 if randf() < 0.5 else -1.0)
	evade_dir = evade_dir.normalized()
	
	GameManager.spawn_damage_number(global_position + Vector3(0, 1.8, 0), "✨ PARPADEO EVASIVO", Color(0.8, 0.2, 0.9), 1.1)
	global_position += evade_dir * 12.0
	global_position.y = max(0.2, global_position.y)
	
	state = DuelState.IDLE

func _process_teleport_evade(delta: float) -> void:
	state = DuelState.IDLE

func _start_summon() -> void:
	state = DuelState.SUMMON_MINIONS
	state_timer = 0.8
	summon_timer = summon_cooldown
	velocity.x = 0.0
	velocity.z = 0.0
	GameManager.spawn_damage_number(global_position + Vector3(0, 2.0, 0), "💀 ¡INVOCANDO ESBIRROS!", Color(0.9, 0.1, 0.3), 1.25)

func _process_summon_minions(delta: float) -> void:
	if state_timer <= 0.0:
		_spawn_minions()
		state = DuelState.IDLE

func _spawn_minions() -> void:
	for i in range(2):
		var offset = Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0))
		var minion = minion_scene.instantiate()
		get_parent().add_child(minion)
		minion.global_position = global_position + offset
		# Configurar esbirro hostil
		if minion.is_in_group("allies"):
			minion.remove_from_group("allies")
		minion.add_to_group("enemy")

func _process_retreat(delta: float) -> void:
	if not target_player:
		state = DuelState.IDLE
		return
	var away_dir = (global_position - target_player.global_position).normalized()
	velocity.x = away_dir.x * (move_speed * 1.1)
	velocity.z = away_dir.z * (move_speed * 1.1)
	if state_timer <= 0.0:
		state = DuelState.IDLE

func take_damage(amount: float, source_element: String = "") -> void:
	if is_dead:
		return
	
	var actual_damage = amount
	if shield_active:
		actual_damage *= 0.4 # Escudo absorbe 60%
		GameManager.spawn_damage_number(global_position + Vector3(0, 1.6, 0), "🛡️ ABSORBIDO", Color(0.4, 0.7, 1.0), 0.9)
	
	current_health -= actual_damage
	GameManager.spawn_damage_number(global_position + Vector3(0, 1.2, 0), str(int(actual_damage)), Color(1.0, 0.3, 0.3), 1.1)
	
	# Activar escudo de emergencia si vida cae a < 50%
	if current_health <= (max_health * 0.5) and not shield_active and shield_duration <= 0.0:
		shield_active = true
		shield_duration = 6.0
		shield_mesh.visible = true
		GameManager.spawn_damage_number(global_position + Vector3(0, 2.0, 0), "🛡️ ¡ESCUDO DEL CAOS!", Color(0.9, 0.2, 0.8), 1.2)
	
	# Posible teletransporte reactivo al recibir golpe fuerte
	if actual_damage >= 30.0 and teleport_timer <= 0.0:
		_start_teleport_evade()
	
	_update_label()
	
	if current_health <= 0.0:
		die()

func die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	remove_from_group("enemy")
	remove_from_group("rival_wizard")
	GameManager.spawn_damage_number(global_position + Vector3(0, 2.0, 0), "🏆 ¡ARCHIMAGO MALAKOR DERROTADO!", Color(1.0, 0.85, 0.1), 1.5)
	GameManager.shake_camera(0.6)
	wizard_defeated.emit(wizard_name)
	
	# Desvanecimiento
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 1.0)
	tween.tween_callback(queue_free)

func _update_label() -> void:
	if status_label:
		status_label.text = "👑 " + wizard_name + "\n[" + str(int(current_health)) + " / " + str(int(max_health)) + " HP]"

func _apply_rival_visuals() -> void:
	if aura_light:
		aura_light.light_color = Color(0.85, 0.15, 0.25)
		aura_light.light_energy = 3.5
	
	if anim_player and anim_player.has_animation("wizard_anim_lib/idle"):
		anim_player.play("wizard_anim_lib/idle")
	elif anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")
		
	var robe_mat = StandardMaterial3D.new()
	robe_mat.albedo_color = Color(0.65, 0.08, 0.12) # Crimson Chaos Robe
	robe_mat.roughness = 0.6
	
	var leather_mat = StandardMaterial3D.new()
	leather_mat.albedo_color = Color(0.12, 0.10, 0.14) # Dark Obsidian Leather
	leather_mat.roughness = 0.8
	
	for child in find_children("*", "MeshInstance3D", true):
		if child == shield_mesh:
			continue
		if child.name.to_lower().begins_with("torso") or child.name.to_lower().begins_with("arm"):
			child.material_override = robe_mat
		elif child.name.to_lower().begins_with("leg"):
			child.material_override = leather_mat
