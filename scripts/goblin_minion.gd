extends CharacterBody3D

@export var max_health: float = 60.0
@export var move_speed: float = 6.8
@export var attack_range: float = 1.9
@export var attack_damage: float = 18.0
@export var attack_cooldown: float = 0.75

var current_health: float = 60.0
var leader: Node3D = null
var current_target: Node3D = null
var attack_timer: float = 0.0
var current_anim: String = ""
var is_dead: bool = false

var is_recovering_attack: bool = false
var attack_recovery_timer: float = 0.0

@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer if has_node("Model/AnimationPlayer") else null

func _ready() -> void:
	current_health = max_health
	floor_snap_length = 0.35
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(48.0)
	scale = Vector3(0.72, 0.72, 0.72)
	if anim_player:
		anim_player.playback_default_blend_time = 0.16
		_setup_goblin_animations(anim_player)
		_setup_animation_loop_modes(anim_player)
	play_anim("combat_idle")
	add_to_group("minion")

func _setup_animation_loop_modes(ap: AnimationPlayer) -> void:
	if not ap:
		return
	for a_name in ap.get_animation_list():
		var anim = ap.get_animation(a_name)
		var lower = a_name.to_lower()
		if lower in ["idle", "walk", "walk-fast", "combat_idle"]:
			anim.loop_mode = Animation.LOOP_LINEAR
		elif lower in ["attack-two handedaction", "die-jump-ground-face4 test", "happy_002"]:
			anim.loop_mode = Animation.LOOP_NONE

func _setup_goblin_animations(ap: AnimationPlayer) -> void:
	if not ap:
		return
	var lib = ap.get_animation_library("")
	if not lib:
		return
	
	if not ap.has_animation("combat_idle") and ap.has_animation("Attack-two handedAction"):
		var src = ap.get_animation("Attack-two handedAction")
		var idle_anim = Animation.new()
		idle_anim.length = 1.4
		idle_anim.loop_mode = Animation.LOOP_LINEAR
		
		for trk in range(src.get_track_count()):
			var p = src.track_get_path(trk)
			var type = src.track_get_type(trk)
			var new_trk = idle_anim.add_track(type)
			idle_anim.track_set_path(new_trk, p)
			idle_anim.track_set_interpolation_type(new_trk, Animation.INTERPOLATION_LINEAR)
			
			var val_start = src.track_get_key_value(trk, 0) if src.track_get_key_count(trk) > 0 else null
			var val_mid = val_start
			for k in range(src.track_get_key_count(trk)):
				if src.track_get_key_time(trk, k) <= 0.32:
					val_mid = src.track_get_key_value(trk, k)
			
			if val_start != null:
				idle_anim.track_insert_key(new_trk, 0.0, val_start)
				idle_anim.track_insert_key(new_trk, 0.7, val_mid)
				idle_anim.track_insert_key(new_trk, 1.4, val_start)
		
		lib.add_animation("combat_idle", idle_anim)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	attack_timer = max(0.0, attack_timer - delta)
	
	# Gravity & floor contact
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 19.6)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = -0.1
	
	if is_recovering_attack:
		attack_recovery_timer -= delta
		velocity.x = lerp(velocity.x, 0.0, delta * 12.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 12.0)
		if attack_recovery_timer <= 0.0:
			is_recovering_attack = false
			attack_timer = attack_cooldown
			if anim_player:
				anim_player.speed_scale = 1.0
			play_anim("combat_idle", 0.15)
		move_and_slide()
		return
	
	# Find target: nearest enemy within 14m
	find_nearest_enemy()
	
	if current_target and is_instance_valid(current_target):
		var diff = current_target.global_position - global_position
		diff.y = 0.0
		var dist = diff.length()
		
		if dist <= attack_range:
			velocity.x = lerp(velocity.x, 0.0, delta * 14.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 14.0)
			if diff.length_squared() > 0.01:
				var target_rot = atan2(-diff.x, -diff.z)
				rotation.y = lerp_angle(rotation.y, target_rot, delta * 14.0)
			if attack_timer <= 0.0:
				if anim_player:
					anim_player.speed_scale = 1.45
				play_anim("Attack-two handedAction", 0.06)
				is_recovering_attack = true
				attack_recovery_timer = 1.46 / 1.45
				
				# Deliver damage at exact impact frame (~0.25s)
				get_tree().create_timer(0.25).timeout.connect(func():
					if is_instance_valid(current_target) and is_instance_valid(self) and not is_dead:
						if global_position.distance_to(current_target.global_position) <= attack_range * 1.35:
							if current_target.has_method("take_damage"):
								current_target.take_damage(attack_damage, diff.normalized() * 4.0)
				)
			else:
				if anim_player and (not anim_player.is_playing() or anim_player.current_animation != "Attack-two handedAction"):
					anim_player.speed_scale = 1.0
					play_anim("combat_idle", 0.2)
		else:
			var dir = diff.normalized()
			velocity.x = lerp(velocity.x, dir.x * move_speed, delta * 9.0)
			velocity.z = lerp(velocity.z, dir.z * move_speed, delta * 9.0)
			var h_vel = Vector3(velocity.x, 0.0, velocity.z)
			if h_vel.length_squared() > 0.04:
				var target_rot = atan2(-h_vel.x, -h_vel.z)
				rotation.y = lerp_angle(rotation.y, target_rot, delta * 12.0)
			if anim_player:
				var h_speed = Vector2(velocity.x, velocity.z).length()
				anim_player.speed_scale = clamp(h_speed / 4.2, 1.0, 1.8)
			play_anim("Walk-fast", 0.12)
	else:
		# Follow leader (player)
		if not leader or not is_instance_valid(leader) or leader.is_queued_for_deletion():
			leader = null
			for p in get_tree().get_nodes_in_group("player"):
				if is_instance_valid(p) and p.is_inside_tree() and not p.is_queued_for_deletion():
					leader = p
					break
			if not leader:
				move_and_slide()
				return
		
		var diff = leader.global_position - global_position
		diff.y = 0.0
		var dist = diff.length()
		
		if dist > 3.2:
			var dir = diff.normalized()
			velocity.x = lerp(velocity.x, dir.x * move_speed, delta * 8.0)
			velocity.z = lerp(velocity.z, dir.z * move_speed, delta * 8.0)
			var h_vel = Vector3(velocity.x, 0.0, velocity.z)
			if h_vel.length_squared() > 0.04:
				var target_rot = atan2(-h_vel.x, -h_vel.z)
				rotation.y = lerp_angle(rotation.y, target_rot, delta * 10.0)
			if anim_player:
				var h_speed = Vector2(velocity.x, velocity.z).length()
				anim_player.speed_scale = clamp(h_speed / 4.8, 0.8, 1.4)
			play_anim("Walk-fast", 0.15)
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * 8.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 8.0)
			if anim_player:
				anim_player.speed_scale = 1.0
			play_anim("combat_idle", 0.2)
	
	move_and_slide()

func find_nearest_enemy() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var closest: Node3D = null
	var min_dist: float = 14.0
	
	for e in enemies:
		if is_instance_valid(e) and e.is_inside_tree() and not e.get("is_dead") and not e.is_queued_for_deletion():
			var d = global_position.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				closest = e
	
	current_target = closest

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	current_health -= amount
	velocity += knockback
	if current_health <= 0.0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	remove_from_group("minion")
	velocity = Vector3.ZERO
	if has_node("CollisionShape3D"):
		($CollisionShape3D as CollisionShape3D).set_deferred("disabled", true)
	
	if anim_player and anim_player.has_animation("Die-jump-ground-face4 test"):
		anim_player.speed_scale = 2.4
		play_anim("Die-jump-ground-face4 test", 0.05)
		await get_tree().create_timer(0.85).timeout
		if is_instance_valid(anim_player):
			anim_player.pause()
	
	var tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.45)
	await tween.finished
	queue_free()

func play_anim(anim_name: String, blend_time: float = 0.2) -> void:
	if not anim_player or not anim_player.has_animation(anim_name):
		return
	if current_anim == anim_name and anim_player.is_playing():
		return
	current_anim = anim_name
	anim_player.play(anim_name, blend_time)
