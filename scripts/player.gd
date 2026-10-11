extends CharacterBody3D

const MapConfig = preload("res://scripts/map_config.gd")
const CursorManager = preload("res://scripts/ui/cursor_manager.gd")
const CharacterAppearance = preload("res://scripts/character_appearance.gd")

signal spell_changed(slot: int)
signal health_updated(current: float, max_val: float)
signal mana_updated(current: float, max_val: float)
signal player_died
signal cast_progress_updated(slot: int, progress: float)
signal target_changed(target: Node)
signal element_flash_requested(color: Color)
signal cast_failed_no_mana(slot: int)
signal stamina_updated(current: float, max_val: float)

@export var move_speed: float = 7.5
@export var walk_speed: float = 4.8
@export var acceleration: float = 18.0
@export var rotation_speed: float = 16.0
@export var max_stamina: float = 100.0

var current_stamina: float = 100.0
var stamina_drain_rate: float = 14.5
var stamina_regen_rate: float = 22.0
var is_exhausted: bool = false

var selected_spell: int = 1 # 1 to 5
var aim_point: Vector3 = Vector3.ZERO
var is_dead: bool = false
var hurt_cooldown: float = 0.0

var is_channeling: bool = false
var channel_timer: float = 0.0
var total_channel_time: float = 0.0
var pending_spell: int = 1
var haste_timer: float = 0.0

var spell_windups: Dictionary = {
	1: 0.15, # Centella Arcana: rápido
	2: 0.55, # Bola de Fuego: carga ígnea
	3: 0.75, # Invocar Duende: ritual de invocación
	4: 0.50, # Onda Expansiva: concentración de fuerza
	5: 0.85, # Fuente de Vida: canalización curativa
	6: 0.20, # Teletransporte: parpadeo veloz
	7: 0.25, # Proyectil de Hielo: concentración gélida
	8: 0.30, # Rayo: acumulación eléctrica
	9: 0.35  # Escudo Mágico: conjuro de barrera
}

@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer if has_node("Model/AnimationPlayer") else null
@onready var staff_gem: MeshInstance3D = find_child("Gem", true, false) as MeshInstance3D
@onready var staff_light: OmniLight3D = find_child("StaffLight", true, false) as OmniLight3D
@onready var aim_marker: Node3D = $AimMarker

var magic_bolt_scene: PackedScene = preload("res://scenes/MagicBolt.tscn")
var fireball_scene: PackedScene = preload("res://scenes/Fireball.tscn")
var goblin_scene: PackedScene = preload("res://scenes/GoblinMinion.tscn")
var summon_circle_scene: PackedScene = preload("res://scenes/SummonCircle.tscn")
var shockwave_scene: PackedScene = preload("res://scenes/Shockwave.tscn")
var heal_scene: PackedScene = preload("res://scenes/HealEffect.tscn")
var ice_projectile_scene: PackedScene = preload("res://scenes/IceProjectile.tscn")
var lightning_bolt_scene: PackedScene = preload("res://scenes/LightningBolt.tscn")
var arcane_shield_scene: PackedScene = preload("res://scenes/ArcaneShield.tscn")
var teleport_effect_scene: PackedScene = preload("res://scenes/TeleportEffect.tscn")
var earth_fissure_scene: PackedScene = preload("res://scenes/EarthFissure.tscn")
var arcane_vines_scene: PackedScene = preload("res://scenes/ArcaneVines.tscn")

var global_cooldown_timer: float = 0.0
var slot_cooldowns: Dictionary = {}
var slot_max_cooldowns: Dictionary = {}
var mana_regen_pause_timer: float = 0.0

var active_shield: Node3D = null

func _ready() -> void:
	add_to_group("player")
	floor_snap_length = 0.35
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(45.0)
	_apply_wizard_materials()
	if anim_player:
		anim_player.playback_default_blend_time = 0.15
		play_anim("Idle")
	emit_signal("spell_changed", selected_spell)
	emit_signal("stamina_updated", current_stamina, max_stamina)

func _apply_wizard_materials() -> void:
	# Configure Quaternius Wizard materials and apply saved character customization
	CharacterAppearance.apply_to_model(self)
	
	# Alias animations on anim_player if from Quaternius Wizard armature
	if anim_player:
		var lib = anim_player.get_animation_library("")
		if lib:
			var mapping = {
				"Idle": "CharacterArmature|Idle",
				"Walk": "CharacterArmature|Walk",
				"Sprint": "CharacterArmature|Run",
				"Spell_Simple_Enter": "CharacterArmature|Spell1",
				"Spell_Simple_Idle": "CharacterArmature|Idle_Attacking",
				"Spell_Simple_Shoot": "CharacterArmature|Spell2",
				"Hit_Chest": "CharacterArmature|RecieveHit",
				"Death01": "CharacterArmature|Death"
			}
			for alias in mapping:
				var src = mapping[alias]
				if lib.has_animation(src) and not lib.has_animation(alias):
					lib.add_animation(alias, lib.get_animation(src))

func play_anim(anim_name: String, blend_time: float = 0.15) -> void:
	if not anim_player or not anim_player.has_animation(anim_name):
		return
	if anim_player.current_animation == anim_name and anim_player.is_playing():
		return
	anim_player.play(anim_name, blend_time)

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	
	# Select spells via keyboard or direct cast
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			select_spell_slot(1)
		elif event.keycode == KEY_2:
			select_spell_slot(2)
		elif event.keycode == KEY_3:
			select_spell_slot(3)
		elif event.keycode == KEY_4:
			select_spell_slot(4)
		elif event.keycode == KEY_5:
			select_spell_slot(5)
		elif event.keycode == KEY_6:
			select_spell_slot(6)
		elif event.keycode == KEY_7:
			select_spell_slot(7)
		elif event.keycode == KEY_8:
			select_spell_slot(8)
		elif event.keycode == KEY_9:
			select_spell_slot(9)
		elif event.keycode == KEY_SPACE:
			cast_teleport()
		elif event.keycode == KEY_C or event.keycode == KEY_F:
			cast_arcane_shield()
		elif event.keycode == KEY_R:
			cast_lightning_bolt()
		elif event.keycode == KEY_T:
			cast_ice_projectile()
		elif event.keycode == KEY_Q:
			use_consumable_apple()
		elif event.keycode == KEY_Z:
			use_consumable_scroll()
		elif event.keycode == KEY_E:
			interact_nearest()
	
	# Cast spell with Left Click (begins tactical windup delay)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		start_spell_channeling()

func use_consumable_apple() -> void:
	if GameManager.inventory and GameManager.inventory.has_item("potion_health"):
		GameManager.inventory.use_item("potion_health", self)
		health_updated.emit(GameManager.player_health, GameManager.player_max_health)
	elif GameManager.inventory and GameManager.inventory.has_item("apple"):
		GameManager.inventory.use_item("apple", self)
		health_updated.emit(GameManager.player_health, GameManager.player_max_health)
	elif GameManager.reagents.get("apple", 0) > 0 and GameManager.player_health < GameManager.player_max_health:
		GameManager.reagents["apple"] -= 1
		GameManager.player_health = min(GameManager.player_max_health, GameManager.player_health + 25.0)
		GameManager.reagents_updated.emit()
		health_updated.emit(GameManager.player_health, GameManager.player_max_health)
		_pulse_staff(Color(0.2, 1.0, 0.4), 0.4)
		if heal_scene:
			var heal = heal_scene.instantiate()
			add_child(heal)

func use_consumable_scroll() -> void:
	if GameManager.inventory and GameManager.inventory.has_item("potion_mana") and GameManager.player_mana < GameManager.player_max_mana:
		GameManager.inventory.use_item("potion_mana", self)
		mana_updated.emit(GameManager.player_mana, GameManager.player_max_mana)
	elif GameManager.inventory and GameManager.inventory.has_item("magic_scroll"):
		GameManager.inventory.use_item("magic_scroll", self)
		mana_updated.emit(GameManager.player_mana, GameManager.player_max_mana)
	elif GameManager.reagents.get("scroll", 0) > 0:
		GameManager.reagents["scroll"] -= 1
		GameManager.player_mana = GameManager.player_max_mana
		apply_haste_buff(8.0)
		GameManager.reagents_updated.emit()
		mana_updated.emit(GameManager.player_mana, GameManager.player_max_mana)
		_pulse_staff(Color(0.3, 0.8, 1.0), 0.6)
	elif GameManager.reagents.get("core", 0) > 0:
		GameManager.reagents["core"] -= 1
		apply_haste_buff(12.0)
		GameManager.reagents_updated.emit()
		_pulse_staff(Color(0.9, 0.2, 1.0), 0.8)

func interact_nearest() -> void:
	var closest_interactable: Node = null
	var min_dist: float = 99999.0
	
	# 1. Comprobar objetos interactuables en el mundo (WorldItem)
	for item in get_tree().get_nodes_in_group("world_item"):
		if is_instance_valid(item) and item.has_method("_attempt_pickup") and not item.get("is_collected"):
			var d = global_position.distance_to(item.global_position)
			var p_range = item.prompt_range if "prompt_range" in item else 4.0
			if d <= p_range and d < min_dist:
				min_dist = d
				closest_interactable = item
	
	# 2. Comprobar altares arcanos
	for altar in get_tree().get_nodes_in_group("altar"):
		if is_instance_valid(altar) and altar.has_method("interact"):
			var d = global_position.distance_to(altar.global_position)
			var p_range = altar.prompt_range if "prompt_range" in altar else 4.5
			if d <= p_range and d < min_dist:
				min_dist = d
				closest_interactable = altar
	
	# 3. Comprobar árboles frutales
	for tree in get_tree().get_nodes_in_group("fruit_tree"):
		if is_instance_valid(tree) and tree.has_method("harvest") and tree.get("has_fruit"):
			var d = global_position.distance_to(tree.global_position)
			if d <= 5.0 and d < min_dist:
				min_dist = d
				closest_interactable = tree
	
	if closest_interactable:
		if closest_interactable.has_method("_attempt_pickup"):
			closest_interactable._attempt_pickup(self)
		elif closest_interactable.has_method("interact"):
			closest_interactable.interact(self)
		elif closest_interactable.has_method("harvest"):
			closest_interactable.harvest()
		get_viewport().set_input_as_handled()

func select_spell_slot(slot: int) -> void:
	if slot >= 1 and slot <= 9:
		selected_spell = slot
		spell_changed.emit(selected_spell)

func _get_spell_element_color(spell_key: String) -> Color:
	match spell_key:
		"magic_bolt": return Color(0.2, 0.85, 1.0)
		"fireball": return Color(1.0, 0.45, 0.1)
		"summon_goblin": return Color(0.85, 0.3, 1.0)
		"shockwave": return Color(1.0, 0.85, 0.2)
		"heal": return Color(0.25, 1.0, 0.45)
		"teleport": return Color(0.85, 0.35, 1.0)
		"ice_projectile": return Color(0.4, 0.85, 1.0)
		"lightning": return Color(0.9, 0.95, 1.0)
		"arcane_shield": return Color(0.3, 0.75, 1.0)
		"earth_fissure": return Color(0.72, 0.45, 0.2)
		"arcane_vines": return Color(0.2, 0.85, 0.3)
		_: return Color(0.4, 0.8, 1.0)

func _find_slot_for_spell(spell_id_key: String) -> int:
	for slot in GameManager.spells:
		if GameManager.spells[slot].get("id", "") == spell_id_key:
			return slot
	return -1

func start_spell_channeling() -> void:
	if is_channeling:
		return
	
	if global_cooldown_timer > 0.0 or slot_cooldowns.get(selected_spell, 0.0) > 0.0:
		return
	
	var spell_info = GameManager.spells.get(selected_spell, {})
	var spell_key = spell_info.get("id", "")
	if spell_key.is_empty():
		var id_map = {
			1: "magic_bolt", 2: "fireball", 3: "summon_goblin", 4: "shockwave",
			5: "heal", 6: "teleport", 7: "ice_projectile", 8: "lightning", 9: "arcane_shield"
		}
		spell_key = id_map.get(selected_spell, "magic_bolt")
	
	# Validar que Fuente de Vida no se lance ni gaste maná si la vida está completa
	if (spell_key == "heal" or selected_spell == 5) and GameManager.player_health >= GameManager.player_max_health:
		GameManager.spawn_damage_number(global_position + Vector3(0, 1.8, 0), "💚 Vida completa", Color(0.4, 1.0, 0.4), 1.0)
		_pulse_staff(Color(0.2, 1.0, 0.5), 0.2)
		return
	
	var cost = spell_info.get("cost", 8.0)
	if GameManager.player_mana < cost:
		_pulse_staff(Color(1, 0.2, 0.2)) # Insufficient mana pulse
		cast_failed_no_mana.emit(selected_spell)
		return
	
	pending_spell = selected_spell
	var haste_factor = 0.5 if haste_timer > 0.0 else 1.0
	total_channel_time = spell_info.get("windup", spell_windups.get(pending_spell, 0.3)) * haste_factor
	channel_timer = total_channel_time
	is_channeling = true
	CursorManager.set_cursor(CursorManager.CursorType.TARGET)
	
	play_anim("Spell_Simple_Enter", 0.08)
	
	# Visual cue: staff gem glows element color during windup
	var elem_color = _get_spell_element_color(spell_key)
	_pulse_staff(elem_color, total_channel_time)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	hurt_cooldown = max(0.0, hurt_cooldown - delta)
	haste_timer = max(0.0, haste_timer - delta)
	
	# Cooldown timers
	if global_cooldown_timer > 0.0:
		global_cooldown_timer = max(0.0, global_cooldown_timer - delta)
	
	var finished_slots: Array = []
	for slot in slot_cooldowns:
		slot_cooldowns[slot] -= delta
		if slot_cooldowns[slot] <= 0.0:
			finished_slots.append(slot)
		else:
			var max_cd = slot_max_cooldowns.get(slot, 1.0)
			var prog = clamp(slot_cooldowns[slot] / max(0.01, max_cd), 0.0, 1.0)
			cast_progress_updated.emit(slot, prog)
	
	for slot in finished_slots:
		slot_cooldowns.erase(slot)
		cast_progress_updated.emit(slot, 0.0)
	
	# Channeling timer & spell execution
	if is_channeling:
		channel_timer -= delta
		var progress = clamp(1.0 - (channel_timer / max(0.01, total_channel_time)), 0.0, 1.0)
		play_anim("Spell_Simple_Idle", 0.12)
		
		if aim_marker and aim_marker.has_node("AimRing"):
			var ring = aim_marker.get_node("AimRing") as Node3D
			ring.scale = Vector3.ONE * (0.35 + (0.55 * progress))
			ring.rotation.y += delta * 6.0
		
		if channel_timer <= 0.0:
			is_channeling = false
			execute_spell(pending_spell)
			if aim_marker and aim_marker.has_node("AimRing"):
				var ring = aim_marker.get_node("AimRing") as Node3D
				ring.scale = Vector3.ONE * 0.6
				ring.rotation.y = 0.0
	
	# Mana natural regeneration with 1.5s pause after casting
	if mana_regen_pause_timer > 0.0:
		mana_regen_pause_timer = max(0.0, mana_regen_pause_timer - delta)
	else:
		GameManager.player_mana = min(GameManager.player_max_mana, GameManager.player_mana + (GameManager.mana_regen_rate * delta))
	mana_updated.emit(GameManager.player_mana, GameManager.player_max_mana)
	health_updated.emit(GameManager.player_health, GameManager.player_max_health)
	
	# Update mouse aiming
	update_aim_point()
	
	# Gravity and floor contact
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 19.6)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = -0.1
	
	# WASD 3D Camera Movement
	var input_x = Input.get_axis("move_left", "move_right")
	var input_y = Input.get_axis("move_up", "move_down")
	var has_move_input = abs(input_x) > 0.01 or abs(input_y) > 0.01
	
	if is_exhausted and current_stamina >= 15.0:
		is_exhausted = false
	
	var wants_sprint = (Input.is_key_pressed(KEY_SHIFT) or haste_timer > 0.0) and has_move_input
	var is_sprinting = wants_sprint and not is_exhausted and current_stamina > 0.0
	
	if is_sprinting:
		current_stamina = max(0.0, current_stamina - stamina_drain_rate * delta)
		if current_stamina <= 0.0:
			is_exhausted = true
	else:
		current_stamina = min(max_stamina, current_stamina + stamina_regen_rate * delta)
	
	stamina_updated.emit(current_stamina, max_stamina)
	
	var base_speed = move_speed if is_sprinting else walk_speed
	var current_move_speed = base_speed * (0.35 if is_channeling else (1.30 if haste_timer > 0.0 else 1.0))
	
	var move_dir: Vector3 = Vector3.ZERO
	var camera = get_viewport().get_camera_3d()
	if camera:
		var cam_forward = -camera.global_transform.basis.z
		cam_forward.y = 0.0
		cam_forward = cam_forward.normalized()
		
		var cam_right = camera.global_transform.basis.x
		cam_right.y = 0.0
		cam_right = cam_right.normalized()
		
		move_dir = (cam_right * input_x + cam_forward * -input_y).normalized()
		
		if move_dir.length_squared() > 0.01:
			var target_h_vel = move_dir * current_move_speed
			velocity.x = lerp(velocity.x, target_h_vel.x, delta * acceleration)
			velocity.z = lerp(velocity.z, target_h_vel.z, delta * acceleration)
			
			if not is_channeling and (anim_player and anim_player.current_animation != "Spell_Simple_Shoot"):
				var h_speed = Vector2(velocity.x, velocity.z).length()
				var stride_speed = 7.0 if is_sprinting else 4.5
				anim_player.speed_scale = clamp(h_speed / stride_speed, 0.7, 1.6)
				play_anim("Sprint" if is_sprinting else "Walk", 0.15)
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * acceleration)
			velocity.z = lerp(velocity.z, 0.0, delta * acceleration)
			if not is_channeling and (anim_player and anim_player.current_animation != "Spell_Simple_Shoot"):
				anim_player.speed_scale = 1.0
				play_anim("Idle", 0.2)
	
	# Smooth body rotation: face movement direction when moving, face aim when casting/channeling, preserve orientation when stopped
	var is_aiming_or_casting = is_channeling or (anim_player and anim_player.current_animation == "Spell_Simple_Shoot")
	var has_movement = move_dir.length_squared() > 0.001
	
	if has_movement:
		if is_aiming_or_casting:
			var aim_diff = aim_point - global_position
			aim_diff.y = 0.0
			if aim_diff.length_squared() > 0.04:
				var target_rot = atan2(-aim_diff.x, -aim_diff.z)
				rotation.y = lerp_angle(rotation.y, target_rot, delta * rotation_speed)
		else:
			var target_rot = atan2(-move_dir.x, -move_dir.z)
			rotation.y = lerp_angle(rotation.y, target_rot, delta * rotation_speed)
	else:
		if is_aiming_or_casting:
			var aim_diff = aim_point - global_position
			aim_diff.y = 0.0
			if aim_diff.length_squared() > 0.04:
				var target_rot = atan2(-aim_diff.x, -aim_diff.z)
				rotation.y = lerp_angle(rotation.y, target_rot, delta * rotation_speed)
		# When stopped and not casting, preserve existing orientation without jitter
	
	move_and_slide()

func update_aim_point() -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	
	var hit_found = false
	if is_inside_tree():
		var space_state = get_world_3d().direct_space_state
		if space_state:
			var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + (ray_dir * 120.0))
			query.exclude = [get_rid()]
			var res = space_state.intersect_ray(query)
			if not res.is_empty():
				aim_point = res.position
				hit_found = true
	
	# Fallback if no collider hit (e.g. aimed at sky or headless off-screen)
	if not hit_found:
		if abs(ray_dir.y) > 0.0001:
			var t = (global_position.y - ray_origin.y) / ray_dir.y
			if t >= 0:
				aim_point = ray_origin + (ray_dir * t)
			else:
				var forward_2d = Vector3(ray_dir.x, 0, ray_dir.z).normalized()
				aim_point = global_position + (forward_2d * 30.0)
		else:
			var forward_2d = Vector3(ray_dir.x, 0, ray_dir.z).normalized()
			aim_point = global_position + (forward_2d * 30.0)
		aim_point.y = MapConfig.get_height_at(aim_point.x, aim_point.z)
	
	if aim_marker:
		aim_marker.global_position = aim_point + Vector3(0, 0.05, 0)
	
	var hovered: Node = null
	var min_dist: float = 3.5
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and not enemy.get("is_dead"):
			var d = enemy.global_position.distance_to(aim_point)
			if d < min_dist:
				min_dist = d
				hovered = enemy
	if hovered != null:
		target_changed.emit(hovered)
	
	if is_channeling:
		CursorManager.set_cursor(CursorManager.CursorType.TARGET)
	elif hovered != null:
		CursorManager.set_cursor(CursorManager.CursorType.ENEMY)
	else:
		CursorManager.set_cursor(CursorManager.CursorType.DEFAULT)

func execute_spell(spell_id: int) -> void:
	var spell_info = GameManager.spells.get(spell_id, {})
	var spell_key = spell_info.get("id", "")
	if spell_key.is_empty():
		var id_map = {
			1: "magic_bolt", 2: "fireball", 3: "summon_goblin", 4: "shockwave",
			5: "heal", 6: "teleport", 7: "ice_projectile", 8: "lightning", 9: "arcane_shield"
		}
		spell_key = id_map.get(spell_id, "magic_bolt")
	
	# Fuente de Vida: no gastar maná ni lanzar si la vida está completa
	if (spell_key == "heal" or spell_id == 5) and GameManager.player_health >= GameManager.player_max_health:
		GameManager.spawn_damage_number(global_position + Vector3(0, 1.8, 0), "💚 Vida completa", Color(0.4, 1.0, 0.4), 1.0)
		return
	
	var cost = spell_info.get("cost", 8.0)
	if GameManager.player_mana < cost:
		_pulse_staff(Color(1, 0.2, 0.2)) # Insufficient mana pulse
		cast_failed_no_mana.emit(spell_id)
		return
	
	GameManager.player_mana -= cost
	mana_regen_pause_timer = 1.5
	
	var cd = spell_info.get("cooldown", 0.6)
	slot_cooldowns[spell_id] = cd
	slot_max_cooldowns[spell_id] = cd
	global_cooldown_timer = 0.3
	cast_progress_updated.emit(spell_id, 1.0)
	
	_pulse_staff(Color(0.2, 0.9, 1.0), 0.2)
	
	var elem_color = _get_spell_element_color(spell_key)
	element_flash_requested.emit(elem_color)
	
	play_anim("Spell_Simple_Shoot", 0.05)
	
	var spawn_pos = staff_gem.global_position if staff_gem else (global_position + Vector3(0, 1.4, 0))
	spawn_pos.y = max(spawn_pos.y, global_position.y + 0.8)
	
	match spell_key:
		"magic_bolt":
			var bolt = magic_bolt_scene.instantiate()
			get_parent().add_child(bolt)
			var dir = (aim_point - spawn_pos).normalized()
			if GameManager.arcana_empowered:
				if bolt.has_method("set_empowered"):
					bolt.set_empowered(true)
				else:
					bolt.damage = 40.0
					bolt.speed = 40.0
				_pulse_staff(Color(0.2, 0.95, 1.0), 0.4)
			bolt.init_bolt(spawn_pos, dir)
			
		"fireball":
			var fb = fireball_scene.instantiate()
			get_parent().add_child(fb)
			fb.init_trajectory(spawn_pos, aim_point)
			
		"summon_goblin":
			var circle = summon_circle_scene.instantiate()
			get_parent().add_child(circle)
			circle.global_position = aim_point
			
			var gob = goblin_scene.instantiate()
			get_parent().add_child(gob)
			gob.global_position = aim_point
			gob.leader = self
			GameManager.spawn_damage_number(aim_point, "🧙 ¡DUENDE INVOCADO!", Color(0.85, 0.45, 1.0), 1.1)
			
		"shockwave":
			var sw = shockwave_scene.instantiate()
			get_parent().add_child(sw)
			sw.global_position = global_position
			
		"heal":
			GameManager.player_health = min(GameManager.player_max_health, GameManager.player_health + 40.0)
			GameManager.spawn_damage_number(global_position, "💚 +40 HP", Color(0.2, 1.0, 0.4), 1.25)
			var heal = heal_scene.instantiate()
			add_child(heal)
			
		"teleport":
			cast_teleport(false, spell_id)
			
		"ice_projectile":
			cast_ice_projectile(false, spell_id)
			
		"lightning":
			cast_lightning_bolt(false, spell_id)
			
		"arcane_shield":
			cast_arcane_shield(false, spell_id)

		"earth_fissure":
			if earth_fissure_scene:
				var ef = earth_fissure_scene.instantiate()
				get_parent().add_child(ef)
				ef.global_position = aim_point
				if ef.has_method("_apply_fissure_effects"):
					ef._apply_fissure_effects()
				_pulse_staff(Color(0.72, 0.45, 0.2), 0.3)
				GameManager.spawn_damage_number(aim_point, "🌍 FISURA DE TIERRA", Color(0.85, 0.65, 0.3), 1.1)

		"arcane_vines":
			if arcane_vines_scene:
				var av = arcane_vines_scene.instantiate()
				get_parent().add_child(av)
				av.global_position = aim_point
				if av.has_method("_trap_enemies"):
					av._trap_enemies()
				_pulse_staff(Color(0.2, 0.85, 0.3), 0.3)
				GameManager.spawn_damage_number(aim_point, "🌿 ENREDADERAS ARCANAS", Color(0.3, 0.9, 0.4), 1.1)

func cast_teleport(deduct_mana: bool = true, from_slot: int = -1) -> void:
	var slot = from_slot if from_slot != -1 else _find_slot_for_spell("teleport")
	var cost = GameManager.spell_catalog["teleport"]["cost"]
	if deduct_mana:
		if global_cooldown_timer > 0.0:
			return
		if slot != -1 and slot_cooldowns.get(slot, 0.0) > 0.0:
			return
		if GameManager.player_mana < cost:
			_pulse_staff(Color(1, 0.2, 0.2))
			return
		GameManager.player_mana -= cost
		mana_regen_pause_timer = 1.5
		global_cooldown_timer = 0.3
		if slot != -1:
			var cd = GameManager.spell_catalog["teleport"]["cooldown"]
			slot_cooldowns[slot] = cd
			slot_max_cooldowns[slot] = cd
			cast_progress_updated.emit(slot, 1.0)
		mana_updated.emit(GameManager.player_mana, GameManager.player_max_mana)
	
	# Origin departure effect
	if teleport_effect_scene:
		var tp_origin = teleport_effect_scene.instantiate()
		get_parent().add_child(tp_origin)
		tp_origin.global_position = global_position
	
	# Compute clamped destination vector
	var diff = aim_point - global_position
	diff.y = 0.0
	var max_blink = 18.0
	if diff.length() > max_blink:
		diff = diff.normalized() * max_blink
	
	var target_pos = global_position + diff
	var map_limit = MapConfig.HALF_SIZE - 6.0
	target_pos.x = clamp(target_pos.x, -map_limit, map_limit)
	target_pos.z = clamp(target_pos.z, -map_limit, map_limit)
	target_pos.y = MapConfig.get_height_at(target_pos.x, target_pos.z) + 0.15
	
	global_position = target_pos
	velocity = Vector3.ZERO
	
	# Destination arrival effect
	if teleport_effect_scene:
		var tp_dest = teleport_effect_scene.instantiate()
		get_parent().add_child(tp_dest)
		tp_dest.global_position = global_position
	
	_pulse_staff(Color(0.85, 0.35, 1.0), 0.35)
	if has_node("Model"):
		var m = $Model as Node3D
		var orig_s = m.scale
		m.scale = Vector3(orig_s.x * 0.3, orig_s.y * 1.7, orig_s.z * 0.3)
		var mtween = create_tween()
		mtween.tween_property(m, "scale", orig_s, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	GameManager.spawn_damage_number(global_position, "✨ PARPADEO", Color(0.85, 0.45, 1.0), 1.0)

func cast_ice_projectile(deduct_mana: bool = true, from_slot: int = -1) -> void:
	var slot = from_slot if from_slot != -1 else _find_slot_for_spell("ice_projectile")
	var cost = GameManager.spell_catalog["ice_projectile"]["cost"]
	if deduct_mana:
		if global_cooldown_timer > 0.0:
			return
		if slot != -1 and slot_cooldowns.get(slot, 0.0) > 0.0:
			return
		if GameManager.player_mana < cost:
			_pulse_staff(Color(1, 0.2, 0.2))
			return
		GameManager.player_mana -= cost
		mana_regen_pause_timer = 1.5
		global_cooldown_timer = 0.3
		if slot != -1:
			var cd = GameManager.spell_catalog["ice_projectile"]["cooldown"]
			slot_cooldowns[slot] = cd
			slot_max_cooldowns[slot] = cd
			cast_progress_updated.emit(slot, 1.0)
		mana_updated.emit(GameManager.player_mana, GameManager.player_max_mana)
	
	play_anim("Spell_Simple_Shoot", 0.05)
	var spawn_pos = staff_gem.global_position if staff_gem else (global_position + Vector3(0, 1.4, 0))
	spawn_pos.y = max(spawn_pos.y, global_position.y + 0.8)
	var dir = (aim_point - spawn_pos).normalized()
	if ice_projectile_scene:
		var ice = ice_projectile_scene.instantiate()
		get_parent().add_child(ice)
		ice.init_projectile(spawn_pos, dir)
	
	_pulse_staff(Color(0.4, 0.85, 1.0), 0.2)

func cast_lightning_bolt(deduct_mana: bool = true, from_slot: int = -1) -> void:
	var slot = from_slot if from_slot != -1 else _find_slot_for_spell("lightning")
	var cost = GameManager.spell_catalog["lightning"]["cost"]
	if deduct_mana:
		if global_cooldown_timer > 0.0:
			return
		if slot != -1 and slot_cooldowns.get(slot, 0.0) > 0.0:
			return
		if GameManager.player_mana < cost:
			_pulse_staff(Color(1, 0.2, 0.2))
			return
		GameManager.player_mana -= cost
		mana_regen_pause_timer = 1.5
		global_cooldown_timer = 0.3
		if slot != -1:
			var cd = GameManager.spell_catalog["lightning"]["cooldown"]
			slot_cooldowns[slot] = cd
			slot_max_cooldowns[slot] = cd
			cast_progress_updated.emit(slot, 1.0)
		mana_updated.emit(GameManager.player_mana, GameManager.player_max_mana)
	
	play_anim("Spell_Simple_Shoot", 0.05)
	var spawn_pos = staff_gem.global_position if staff_gem else (global_position + Vector3(0, 1.4, 0))
	spawn_pos.y = max(spawn_pos.y, global_position.y + 0.8)
	var target_pos = aim_point
	if lightning_bolt_scene:
		var bolt = lightning_bolt_scene.instantiate()
		get_parent().add_child(bolt)
		bolt.init_lightning(spawn_pos, target_pos)
	
	_pulse_staff(Color(0.85, 0.95, 1.0), 0.2)
	GameManager.shake_camera(0.25)

func cast_arcane_shield(deduct_mana: bool = true, from_slot: int = -1) -> void:
	var slot = from_slot if from_slot != -1 else _find_slot_for_spell("arcane_shield")
	var cost = GameManager.spell_catalog["arcane_shield"]["cost"]
	if deduct_mana:
		if global_cooldown_timer > 0.0:
			return
		if slot != -1 and slot_cooldowns.get(slot, 0.0) > 0.0:
			return
		if GameManager.player_mana < cost:
			_pulse_staff(Color(1, 0.2, 0.2))
			return
		GameManager.player_mana -= cost
		mana_regen_pause_timer = 1.5
		global_cooldown_timer = 0.3
		if slot != -1:
			var cd = GameManager.spell_catalog["arcane_shield"]["cooldown"]
			slot_cooldowns[slot] = cd
			slot_max_cooldowns[slot] = cd
			cast_progress_updated.emit(slot, 1.0)
		mana_updated.emit(GameManager.player_mana, GameManager.player_max_mana)
	
	if active_shield and is_instance_valid(active_shield):
		active_shield.queue_free()
	
	if arcane_shield_scene:
		active_shield = arcane_shield_scene.instantiate()
		get_parent().add_child(active_shield)
		active_shield.activate(self, 7.5)
	
	_pulse_staff(Color(0.3, 0.75, 1.0), 0.4)
	GameManager.spawn_damage_number(global_position, "🛡️ ESCUDO MÁGICO", Color(0.4, 0.85, 1.0), 1.1)

func apply_haste_buff(duration: float) -> void:
	haste_timer = duration
	_pulse_staff(Color(0.9, 0.2, 1.0), duration)

func _pulse_staff(color: Color, duration: float = 0.3) -> void:
	if staff_gem and staff_gem.material_override:
		var orig = staff_gem.material_override.get("emission")
		staff_gem.material_override.set("emission", color)
		var tween = create_tween()
		tween.tween_property(staff_gem.material_override, "emission_energy_multiplier", 6.0, duration * 0.5)
		tween.tween_property(staff_gem.material_override, "emission_energy_multiplier", 2.0, duration * 0.5)
	if staff_light:
		staff_light.light_color = color

func take_damage(amount: float) -> void:
	if is_dead or hurt_cooldown > 0.0:
		return
	
	if active_shield and is_instance_valid(active_shield):
		amount *= 0.35 # Shield absorbs 65% of damage!
		if active_shield.has_method("absorb_hit"):
			active_shield.absorb_hit()
		GameManager.spawn_damage_number(global_position, "🛡️ ABSORBIDO", Color(0.4, 0.85, 1.0), 1.0)
	
	hurt_cooldown = 0.4
	GameManager.player_health -= amount
	health_updated.emit(GameManager.player_health, GameManager.player_max_health)
	
	GameManager.spawn_damage_number(global_position, "💔 -%d" % [int(amount)], Color(1.0, 0.25, 0.25), 1.2)
	GameManager.shake_camera(0.4)
	
	play_anim("Hit_Chest", 0.08)
	modulate_flash(Color(2.0, 0.3, 0.3))
	
	if GameManager.player_health <= 0.0:
		die()

func modulate_flash(c: Color) -> void:
	var meshes_with_mat: Array = []
	for child in find_children("*", "MeshInstance3D", true):
		if child.material_override:
			meshes_with_mat.append(child)
	if meshes_with_mat.size() > 0:
		var tween = create_tween()
		for child in meshes_with_mat:
			var orig = child.material_override.albedo_color
			child.material_override.albedo_color = c
			tween.tween_property(child.material_override, "albedo_color", orig, 0.2)

func die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	player_died.emit()
	play_anim("Death01", 0.12)
