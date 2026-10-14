extends CharacterBody3D

const MapConfig = preload("res://scripts/map_config.gd")

enum EnemyType { GOBLIN, SKELETON_SPEAR, SKELETON_ARCHER, FIRE_IMP, SHADOW_IMP }

enum AIState {
	IDLE,
	PATROL,
	INVESTIGATE,
	ALERT,
	CHASE,
	ATTACK,
	SEARCH,
	RETURN,
	RECOVER
}

@export var enemy_type: EnemyType = EnemyType.GOBLIN
@export var is_boss: bool = false
@export var max_health: float = 60.0
@export var move_speed: float = 4.2
@export var attack_damage: float = 12.0
@export var attack_range: float = 1.8
@export var attack_cooldown: float = 1.2

var current_health: float = 60.0
var attack_timer: float = 0.0
var is_dead: bool = false
var current_anim: String = ""

# AI State Machine variables
var current_state: AIState = AIState.IDLE
var home_position: Vector3 = Vector3.ZERO
var patrol_target: Vector3 = Vector3.ZERO
var investigate_position: Vector3 = Vector3.ZERO
var state_timer: float = 0.0
var chase_timer: float = 0.0
var target_ref: Node3D = null

# Archetype behavioral parameters
var detection_radius: float = 16.0
var max_leash_distance: float = 24.0
var lose_target_distance: float = 22.0
var max_chase_duration: float = 10.0
var patrol_radius: float = 6.0
var attack_windup: float = 0.35
var is_winding_up_attack: bool = false
var is_recovering_attack: bool = false
var attack_recovery_timer: float = 0.0
var attack_clip_duration: float = 1.0
var attack_anim_speed: float = 1.0
var spit_recoil_squash: float = 0.0
var hit_stagger_timer: float = 0.0
var windup_timer: float = 0.0
var alert_duration: float = 0.35

# Tactical AI state variables
var is_fleeing: bool = false
var flee_timer: float = 0.0
var is_blocking: bool = false
var block_timer: float = 0.0
var boss_slam_timer: float = 6.0
var boss_summoned_help: bool = false
var is_charging_slam: bool = false
var slam_charge_timer: float = 0.0
var slam_recover_timer: float = 0.0
var proc_anim_time: float = 0.0
var base_scale: Vector3 = Vector3.ONE

var is_scout: bool = false
var boss_danger_ring: MeshInstance3D = null
var boss_vuln_ring: MeshInstance3D = null

# Spatial perception, memory and leash stabilization
var last_known_target_pos: Vector3 = Vector3.ZERO
var los_lost_timer: float = 0.0
var target_cooldown: float = 0.0

# Performance throttling caches
var _cached_separation: Vector3 = Vector3.ZERO
var _separation_calc_frame: int = -1
var _cached_los: bool = true
var _los_check_timer: float = 0.0

# Tactical CC (Crowd Control) & Elemental System
var chill_timer: float = 0.0
var chill_slow_factor: float = 0.55
var chill_vfx_node: CPUParticles3D = null
var ice_stacks: int = 0
var freeze_timer: float = 0.0
var stun_timer: float = 0.0
var burn_timer: float = 0.0
var burn_tick_timer: float = 0.0
var burn_dps: float = 6.0
var earth_sink_timer: float = 0.0
var earth_slow_factor: float = 0.30
var root_timer: float = 0.0
var lost_los_duration: float = 4.5

# Elemental Affinities & Resistances
var elemental_weaknesses: Array[String] = []
var elemental_resistances: Array[String] = []

var anim_walk: String = "Walk-fast"
var anim_attack: String = "Attack-two handed_002"
var anim_idle: String = "Happy_002"
var anim_combat_idle: String = "CharacterArmature|Attacking_Idle"
var anim_run: String = "CharacterArmature|Run"
var anim_hit: String = "CharacterArmature|RecieveHit_Attacking"
var anim_death: String = "Die-jump-ground-face4 test"

func get_current_idle() -> String:
	if target_ref != null or current_state in [AIState.ALERT, AIState.CHASE, AIState.ATTACK]:
		if anim_combat_idle != "" and anim_player and anim_player.has_animation(anim_combat_idle):
			return anim_combat_idle
		elif anim_player and anim_player.has_animation("combat_idle"):
			return "combat_idle"
	return anim_idle


@onready var hp_bar: Label3D = $HpLabel
@onready var model_container: Node3D = $Model

var anim_player: AnimationPlayer = null

var rogue_model_scene: PackedScene = preload("res://assets/characters/rogue/Rogue.fbx")
var skeleton_model_scene: PackedScene = preload("res://assets/characters/monsters/Skeleton.fbx")
var ranger_model_scene: PackedScene = preload("res://assets/characters/ranger/Ranger.fbx")
var bat_model_scene: PackedScene = preload("res://assets/characters/monsters/Bat.fbx")
var slime_model_scene: PackedScene = preload("res://assets/characters/monsters/Slime.fbx")
var dragon_model_scene: PackedScene = preload("res://assets/characters/monsters/Dragon.fbx")
var arcane_loot_scene: PackedScene = preload("res://scenes/ArcaneLoot.tscn")
var world_item_scene: PackedScene = preload("res://scenes/WorldItem.tscn")
var bone_arrow_scene: PackedScene = preload("res://scenes/BoneArrow.tscn")
var fire_spit_scene: PackedScene = preload("res://scenes/FireSpit.tscn")

var rogue_tex: Texture2D = preload("res://assets/characters/rogue/Rogue_Texture.png")
var dagger_tex: Texture2D = preload("res://assets/characters/rogue/Rogue_Dagger_Texture.png")
var ranger_tex: Texture2D = preload("res://assets/characters/ranger/Ranger_Texture.png")
var bow_tex: Texture2D = preload("res://assets/characters/ranger/Ranger_Bow_Texture.png")

var show_hp_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	floor_snap_length = 0.35
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(48.0)
	if home_position == Vector3.ZERO:
		home_position = global_position
	_setup_archetype()
	
	if is_boss:
		_setup_boss_visuals()
	
	current_health = max_health
	update_hp_display()
	if hp_bar and not is_boss:
		hp_bar.visible = false
	play_anim(anim_idle)

func set_archetype(type_index: int) -> void:
	enemy_type = type_index as EnemyType
	if is_inside_tree():
		_setup_archetype()
		if is_boss:
			_setup_boss_visuals()
		current_health = max_health
		update_hp_display()

func setup_as_scout() -> void:
	is_scout = true
	detection_radius = 13.0
	alert_duration = 0.45
	patrol_radius = 4.0

func set_fog_visibility(is_vis: bool) -> void:
	if has_node("Model"):
		$Model.visible = is_vis
	if has_node("HpLabel"):
		$HpLabel.visible = is_vis and (current_health < max_health or is_boss)
	if has_node("SinisterLight"):
		$SinisterLight.visible = is_vis

func _setup_archetype() -> void:
	if not has_node("Model"):
		return
	
	var container = $Model
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	
	var model_inst: Node3D = null
	var model_yaw: float = PI # Explicit front orientation offset for imported +Z character models
	anim_player = null
	
	if is_boss:
		model_inst = dragon_model_scene.instantiate()
		model_yaw = PI
		base_scale = Vector3(1.15, 1.15, 1.15)
		max_health = 600.0
		move_speed = 3.6
		attack_damage = 25.0
		attack_range = 3.8
		attack_cooldown = 1.8
		attack_windup = 0.40
		attack_clip_duration = 1.2
		attack_anim_speed = 1.1
		detection_radius = 28.0
		max_leash_distance = 36.0
		lose_target_distance = 32.0
		max_chase_duration = 20.0
		patrol_radius = 8.0
		anim_walk = "DragonArmature|Dragon_Flying"
		anim_attack = "DragonArmature|Dragon_Attack"
		anim_idle = "DragonArmature|Dragon_Flying"
		anim_death = "DragonArmature|Dragon_Death"
		elemental_weaknesses = ["ice"]
		elemental_resistances = ["fire"]
	else:
		match enemy_type:
			EnemyType.GOBLIN:
				model_inst = rogue_model_scene.instantiate()
				model_yaw = PI
				_apply_rogue_materials(model_inst, Color(0.85, 1.05, 0.85))
				base_scale = Vector3(0.55, 0.55, 0.55)
				max_health = 60.0
				move_speed = 3.8 # Slower than player walk (4.8 m/s)
				attack_damage = 13.0
				attack_range = 1.9
				attack_cooldown = 1.35
				attack_windup = 0.25
				attack_clip_duration = 0.75
				attack_anim_speed = 1.2
				detection_radius = 14.0
				max_leash_distance = 20.0
				lose_target_distance = 18.0
				max_chase_duration = 8.0
				patrol_radius = 5.0
				anim_walk = "CharacterArmature|Walk"
				anim_run = "CharacterArmature|Run"
				anim_attack = "CharacterArmature|Dagger_Attack"
				anim_idle = "CharacterArmature|Idle"
				anim_combat_idle = "CharacterArmature|Attacking_Idle"
				anim_hit = "CharacterArmature|RecieveHit_Attacking"
				anim_death = "CharacterArmature|Death"
				elemental_weaknesses = ["fire"]
				elemental_resistances = ["force"]
				
			EnemyType.SKELETON_SPEAR:
				model_inst = skeleton_model_scene.instantiate()
				model_yaw = PI
				base_scale = Vector3(0.38, 0.38, 0.38)
				max_health = 95.0
				move_speed = 3.4 # Heavy armored, player walks away cleanly
				attack_damage = 16.0
				attack_range = 2.4
				attack_cooldown = 1.6
				attack_windup = 0.32
				attack_clip_duration = 1.15
				attack_anim_speed = 1.2
				detection_radius = 15.0
				max_leash_distance = 22.0
				lose_target_distance = 19.0
				max_chase_duration = 9.0
				patrol_radius = 6.0
				anim_walk = "SkeletonArmature|Skeleton_Running"
				anim_attack = "SkeletonArmature|Skeleton_Attack"
				anim_idle = "SkeletonArmature|Skeleton_Idle"
				anim_death = "SkeletonArmature|Skeleton_Death"
				elemental_weaknesses = ["force"]
				elemental_resistances = ["ice"]
				
			EnemyType.SKELETON_ARCHER:
				model_inst = ranger_model_scene.instantiate()
				model_yaw = PI
				_apply_ranger_materials(model_inst, Color(0.90, 0.92, 1.0))
				base_scale = Vector3(0.58, 0.58, 0.58)
				max_health = 55.0
				move_speed = 3.6 # Tactical kiter, slower than player walking
				attack_damage = 14.0
				attack_range = 14.0
				attack_cooldown = 2.0
				attack_windup = 0.42
				attack_clip_duration = 1.25
				attack_anim_speed = 1.2
				detection_radius = 22.0
				max_leash_distance = 26.0
				lose_target_distance = 24.0
				max_chase_duration = 12.0
				patrol_radius = 7.0
				anim_walk = "CharacterArmature|Walk"
				anim_attack = "CharacterArmature|Bow_Attack_Shoot"
				anim_idle = "CharacterArmature|Idle"
				anim_death = "CharacterArmature|Death"
				elemental_weaknesses = ["lightning"]
				elemental_resistances = ["earth"]
				
			EnemyType.FIRE_IMP:
				model_inst = bat_model_scene.instantiate()
				model_yaw = PI
				model_inst.position.y = 0.35 # Predatory flying hover
				_apply_bat_materials(model_inst)
				base_scale = Vector3(0.32, 0.32, 0.32)
				max_health = 45.0 # Fragile glass cannon
				move_speed = 4.8 # Fast glass cannon; player walk is 4.8 m/s, sprint is 7.5 m/s (escape delta 2.7 m/s)
				attack_damage = 10.0
				attack_range = 9.0
				attack_cooldown = 1.8
				attack_windup = 0.20
				attack_clip_duration = 0.85
				attack_anim_speed = 1.15
				detection_radius = 16.0
				max_leash_distance = 22.0
				lose_target_distance = 20.0
				max_chase_duration = 10.0
				patrol_radius = 6.0
				anim_walk = "BatArmature|Bat_Flying"
				anim_attack = "BatArmature|Bat_Attack"
				anim_idle = "BatArmature|Bat_Flying"
				anim_death = "BatArmature|Bat_Death"
				elemental_weaknesses = ["ice"]
				elemental_resistances = ["fire"]
				
			EnemyType.SHADOW_IMP:
				model_inst = slime_model_scene.instantiate()
				model_yaw = PI
				_apply_slime_materials(model_inst)
				base_scale = Vector3(0.60, 0.60, 0.60)
				max_health = 50.0 # Fragile
				move_speed = 5.0 # Fast! Requires sprint/CC
				attack_damage = 11.0
				attack_range = 8.5
				attack_cooldown = 1.8
				attack_windup = 0.22
				attack_clip_duration = 0.80
				attack_anim_speed = 1.15
				detection_radius = 16.0
				max_leash_distance = 22.0
				lose_target_distance = 20.0
				max_chase_duration = 10.0
				patrol_radius = 6.0
				anim_walk = "Armature|Slime_Walk"
				anim_attack = "Armature|Slime_Attack"
				anim_idle = "Armature|Slime_Idle"
				anim_death = "Armature|Slime_Death"
				elemental_weaknesses = ["lightning"]
				elemental_resistances = ["force"]
	
	scale = base_scale
	if model_inst:
		model_inst.rotation.y = model_yaw
		container.add_child(model_inst)
		anim_player = model_inst.find_child("AnimationPlayer", true, false)
		if anim_player:
			anim_player.playback_default_blend_time = 0.16
			_setup_animation_aliases(anim_player)
			_setup_animation_loop_modes(anim_player)
			current_anim = ""
			play_anim(anim_idle)

func _setup_animation_aliases(ap: AnimationPlayer) -> void:
	if not ap:
		return
	var lib = ap.get_animation_library("")
	if not lib:
		return
	
	var candidates = {
		"idle": [anim_idle, "CharacterArmature|Idle", "SkeletonArmature|Skeleton_Idle", "BatArmature|Bat_Flying", "Armature|Slime_Idle", "DragonArmature|Dragon_Flying"],
		"combat_idle": [anim_combat_idle, "CharacterArmature|Attacking_Idle", "CharacterArmature|Idle_Attacking", "combat_idle", anim_idle],
		"walk": [anim_walk, "CharacterArmature|Walk", "SkeletonArmature|Skeleton_Running", "BatArmature|Bat_Flying", "Armature|Slime_Walk", "DragonArmature|Dragon_Flying"],
		"run": [anim_run, "CharacterArmature|Run", "SkeletonArmature|Skeleton_Running", "BatArmature|Bat_Flying", "Armature|Slime_Walk", "DragonArmature|Dragon_Flying"],
		"attack": [anim_attack, "CharacterArmature|Dagger_Attack", "CharacterArmature|Bow_Attack_Shoot", "SkeletonArmature|Skeleton_Attack", "BatArmature|Bat_Attack", "Armature|Slime_Attack", "DragonArmature|Dragon_Attack"],
		"death": [anim_death, "CharacterArmature|Death", "SkeletonArmature|Skeleton_Death", "BatArmature|Bat_Death", "Armature|Slime_Death", "DragonArmature|Dragon_Death"],
		"hit": [anim_hit, "CharacterArmature|RecieveHit_Attacking", "CharacterArmature|RecieveHit", "BatArmature|Bat_Hit", "DragonArmature|Dragon_Hit", "SkeletonArmature|Skeleton_Attack"]
	}
	
	for alias in candidates:
		if not lib.has_animation(alias):
			for candidate in candidates[alias]:
				if candidate != "" and lib.has_animation(candidate):
					lib.add_animation(alias, lib.get_animation(candidate))
					break

func _setup_animation_loop_modes(ap: AnimationPlayer) -> void:
	if not ap:
		return
	for a_name in ap.get_animation_list():
		var anim = ap.get_animation(a_name)
		var lower = a_name.to_lower()
		if lower in ["idle", "walk", "run", "chase", "combat_idle"] or lower.ends_with("idle") or lower.ends_with("walk") or lower.ends_with("run") or lower.ends_with("running") or lower.ends_with("flying"):
			anim.loop_mode = Animation.LOOP_LINEAR
		else:
			anim.loop_mode = Animation.LOOP_NONE

func _apply_rogue_materials(inst: Node3D, tint: Color = Color.WHITE) -> void:
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_texture = rogue_tex
	r_mat.albedo_color = tint
	r_mat.roughness = 0.65
	var d_mat = StandardMaterial3D.new()
	d_mat.albedo_texture = dagger_tex
	d_mat.roughness = 0.65
	for m in inst.find_children("*", "MeshInstance3D", true, false):
		m.material_override = d_mat if m.name == "Rogue_Dagger" else r_mat

func _apply_ranger_materials(inst: Node3D, tint: Color = Color.WHITE) -> void:
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_texture = ranger_tex
	r_mat.albedo_color = tint
	r_mat.roughness = 0.65
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_texture = bow_tex
	b_mat.roughness = 0.65
	for m in inst.find_children("*", "MeshInstance3D", true, false):
		m.material_override = b_mat if m.name == "Ranger_Bow" else r_mat

func _apply_bat_materials(inst: Node3D) -> void:
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = Color(1.0, 0.38, 0.12)
	f_mat.emission_enabled = true
	f_mat.emission = Color(1.0, 0.28, 0.05)
	f_mat.emission_energy_multiplier = 1.6
	f_mat.roughness = 0.5
	for m in inst.find_children("*", "MeshInstance3D", true, false):
		m.material_override = f_mat

func _apply_slime_materials(inst: Node3D) -> void:
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.32, 0.12, 0.52)
	s_mat.emission_enabled = true
	s_mat.emission = Color(0.60, 0.15, 0.90)
	s_mat.emission_energy_multiplier = 1.3
	s_mat.roughness = 0.35
	for m in inst.find_children("*", "MeshInstance3D", true, false):
		if m.name == "Eyes":
			var eye_mat = StandardMaterial3D.new()
			eye_mat.albedo_color = Color(1.0, 0.85, 0.2)
			eye_mat.emission_enabled = true
			eye_mat.emission = Color(1.0, 0.85, 0.2)
			m.material_override = eye_mat
		else:
			m.material_override = s_mat

func _setup_boss_visuals() -> void:
	if has_node("SinisterLight"):
		var light = $SinisterLight as OmniLight3D
		light.light_color = Color(0.75, 0.25, 0.95)
		light.light_energy = 1.8
		light.omni_range = 5.0
	if has_node("CollisionShape3D"):
		var col = $CollisionShape3D as CollisionShape3D
		if col.shape is CapsuleShape3D:
			var c = col.shape.duplicate() as CapsuleShape3D
			c.radius = 1.2
			c.height = 2.6
			col.shape = c
			col.position = Vector3(0, 1.3, 0)
	if hp_bar:
		hp_bar.text = "👑 DRAGÓN ARCANO"
		hp_bar.position.y = 3.6

func transition_to_state(new_state: AIState, duration: float = 0.0) -> void:
	if current_state == new_state and new_state != AIState.ATTACK:
		return
	current_state = new_state
	state_timer = duration
	match current_state:
		AIState.IDLE:
			target_ref = null
			is_winding_up_attack = false
			play_anim(anim_idle)
		AIState.PATROL:
			target_ref = null
			is_winding_up_attack = false
			play_anim(anim_walk)
		AIState.ALERT:
			state_timer = alert_duration if duration == 0.0 else duration
			is_winding_up_attack = false
			update_hp_display()
			play_anim(get_current_idle(), 0.15)
		AIState.CHASE:
			chase_timer = max_chase_duration if duration == 0.0 else duration
			is_winding_up_attack = false
			update_hp_display()
		AIState.ATTACK:
			is_winding_up_attack = false
		AIState.SEARCH:
			target_ref = null
			is_winding_up_attack = false
			state_timer = 3.0 if duration == 0.0 else duration
			update_hp_display()
			play_anim(anim_idle, 0.2)
		AIState.RETURN:
			target_ref = null
			is_winding_up_attack = false
			update_hp_display()
			play_anim(anim_walk, 0.15)
		AIState.RECOVER:
			target_ref = null
			is_winding_up_attack = false
			state_timer = 2.0 if duration == 0.0 else duration
			update_hp_display()
			play_anim(get_current_idle(), 0.2)

func has_line_of_sight_to(target: Node3D) -> bool:
	if not is_inside_tree() or target == null:
		return true
	if _los_check_timer > 0.0:
		return _cached_los
	_los_check_timer = randf_range(0.16, 0.24)
	
	var world_3d = get_world_3d()
	if not world_3d:
		return true
	var space_state = world_3d.direct_space_state
	if not space_state:
		return true
	
	var from_pos = global_position + Vector3(0, 1.2, 0)
	var to_pos = target.global_position + Vector3(0, 1.0, 0)
	
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	var exclusions: Array[RID] = [get_rid()]
	if target is CollisionObject3D:
		exclusions.append((target as CollisionObject3D).get_rid())
	query.exclude = exclusions
	query.collision_mask = 1 # Static geometry and obstacles
	
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		_cached_los = true
		return true
	
	var hit = result.get("collider")
	_cached_los = (hit == target or (hit and hit.get_parent() == target))
	return _cached_los

func detect_player() -> Node3D:
	if target_cooldown > 0.0:
		return null
	
	var potential_targets: Array = []
	potential_targets.append_array(get_tree().get_nodes_in_group("player"))
	potential_targets.append_array(get_tree().get_nodes_in_group("minion"))
	
	var closest: Node3D = null
	var min_dist: float = detection_radius
	for t in potential_targets:
		if is_instance_valid(t) and t.is_inside_tree() and not t.is_queued_for_deletion():
			if "is_dead" in t and t.is_dead:
				continue
			var d = global_position.distance_to(t.global_position)
			if d < min_dist:
				# In idle/patrol, verify awareness cone and line of sight
				if current_state in [AIState.IDLE, AIState.PATROL]:
					if d > 4.5:
						var fwd = -transform.basis.z
						fwd.y = 0.0
						var dir = (t.global_position - global_position).normalized()
						dir.y = 0.0
						if fwd.length_squared() > 0.01 and dir.length_squared() > 0.01:
							if fwd.normalized().dot(dir.normalized()) < -0.35:
								continue # Target is behind enemy's back!
				
				# Check line of sight
				if not has_line_of_sight_to(t):
					continue
				
				min_dist = d
				closest = t
	return closest

func alert_allies(target: Node3D, alert_pos: Vector3, radius: float = 12.0) -> void:
	for other in get_tree().get_nodes_in_group("enemy"):
		if other != self and is_instance_valid(other) and not other.get("is_dead"):
			if global_position.distance_to(other.global_position) <= radius:
				if other.has_method("notify_investigate"):
					other.notify_investigate(target, alert_pos)

func notify_investigate(new_target: Node3D, pos: Vector3) -> void:
	if current_state in [AIState.IDLE, AIState.PATROL, AIState.SEARCH]:
		target_ref = new_target
		investigate_position = pos
		transition_to_state(AIState.ALERT, alert_duration)

func get_separation_force() -> Vector3:
	var current_frame = Engine.get_physics_frames()
	if (current_frame + get_instance_id()) % 4 != 0 and _separation_calc_frame >= 0:
		return _cached_separation
	
	_separation_calc_frame = current_frame
	var total_force = Vector3.ZERO
	var checked_count = 0
	for other in get_tree().get_nodes_in_group("enemy"):
		if other != self and is_instance_valid(other) and not other.get("is_dead"):
			var sep_diff = global_position - other.global_position
			sep_diff.y = 0.0
			var d_sq = sep_diff.length_squared()
			if d_sq > 0.001 and d_sq < 3.24: # 1.8m radius
				var d = sqrt(d_sq)
				var push_mag = clamp((1.8 - d) * 2.6, 0.0, 3.0)
				total_force += (sep_diff / d) * push_mag
				checked_count += 1
				if checked_count >= 4:
					break
	if total_force.length() > 3.2:
		total_force = total_force.normalized() * 3.2
	_cached_separation = total_force
	return _cached_separation

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	_los_check_timer = max(0.0, _los_check_timer - delta)
	
	# Far-distance hibernation when unaggroed
	if target_ref == null:
		var p_nodes = get_tree().get_nodes_in_group("player")
		if p_nodes.size() > 0 and is_instance_valid(p_nodes[0]):
			var dist_sq = global_position.distance_squared_to(p_nodes[0].global_position)
			if dist_sq > 2704.0: # 52m
				velocity.x = 0.0
				velocity.z = 0.0
				return
	
	if not is_boss and hp_bar and hp_bar.visible:
		if show_hp_timer > 0.0:
			show_hp_timer -= delta
			if show_hp_timer <= 0.0:
				hp_bar.visible = false
	
	attack_timer = max(0.0, attack_timer - delta)
	flee_timer = max(0.0, flee_timer - delta)
	block_timer = max(0.0, block_timer - delta)
	state_timer = max(0.0, state_timer - delta)
	chase_timer = max(0.0, chase_timer - delta)
	target_cooldown = max(0.0, target_cooldown - delta)
	chill_timer = max(0.0, chill_timer - delta)
	if chill_timer <= 0.0 and chill_vfx_node and is_instance_valid(chill_vfx_node) and chill_vfx_node.emitting:
		chill_vfx_node.emitting = false
	hit_stagger_timer = max(0.0, hit_stagger_timer - delta)
	
	# Handle CC timers
	if freeze_timer > 0.0:
		freeze_timer -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		if model_container:
			model_container.modulate = Color(0.5, 0.9, 1.3)
		if freeze_timer <= 0.0 and model_container:
			model_container.modulate = Color.WHITE
		move_and_slide()
		return
	
	if stun_timer > 0.0:
		stun_timer -= delta
		velocity.x = lerp(velocity.x, 0.0, delta * 12.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 12.0)
		is_winding_up_attack = false
		if model_container:
			model_container.rotation.z = sin(stun_timer * 16.0) * 0.14
			model_container.rotation.x = -0.12 + cos(stun_timer * 12.0) * 0.08
		if stun_timer <= 0.0 and model_container:
			model_container.rotation.z = 0.0
			model_container.rotation.x = 0.0
			if anim_player:
				anim_player.speed_scale = 1.0
			play_anim(get_current_idle(), 0.15)
		move_and_slide()
		return
	
	if root_timer > 0.0:
		root_timer -= delta
		velocity.x = 0.0
		velocity.z = 0.0
	
	if earth_sink_timer > 0.0:
		earth_sink_timer -= delta
		if model_container:
			model_container.position.y = -0.18
		if earth_sink_timer <= 0.0 and model_container:
			model_container.position.y = 0.0
	
	if burn_timer > 0.0:
		burn_timer -= delta
		burn_tick_timer += delta
		if burn_tick_timer >= 0.5:
			burn_tick_timer = 0.0
			current_health -= (burn_dps * 0.5)
			GameManager.spawn_damage_number(global_position + Vector3(0, 1.2, 0), "🔥 -%d" % int(burn_dps * 0.5), Color(1.0, 0.45, 0.1), 0.9)
			_flash_hit()
			update_hp_display()
			if current_health <= 0.0:
				die()
				return
	
	if enemy_type in [EnemyType.FIRE_IMP, EnemyType.SHADOW_IMP]:
		_process_procedural_imp_animation(delta)
	
	# Gravity & floor contact
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 19.6)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = -0.1
	
	if is_boss:
		_process_boss_specials(delta)
	
	# Clean invalid target reference
	if target_ref and is_instance_valid(target_ref) and target_ref.is_inside_tree() and not target_ref.is_queued_for_deletion():
		if "is_dead" in target_ref and target_ref.is_dead:
			target_ref = null
			transition_to_state(AIState.SEARCH, 2.5)
	else:
		target_ref = null
	
	# Perception checks and leash boundaries
	if target_ref == null:
		if current_state in [AIState.IDLE, AIState.PATROL, AIState.INVESTIGATE, AIState.SEARCH, AIState.RETURN, AIState.RECOVER]:
			var detected = detect_player()
			if detected:
				var dist_det = global_position.distance_to(detected.global_position)
				if current_state == AIState.RETURN or current_state == AIState.RECOVER:
					# Defend self only if player gets into close defensive proximity while returning
					if dist_det <= 4.5:
						target_ref = detected
						transition_to_state(AIState.ALERT, alert_duration)
				elif current_state == AIState.SEARCH:
					# In search, re-detect if player is within 14m and has clear line of sight
					if dist_det <= 14.0 and has_line_of_sight_to(detected):
						target_ref = detected
						transition_to_state(AIState.ALERT, alert_duration)
				else:
					target_ref = detected
					transition_to_state(AIState.ALERT, alert_duration)
	else:
		# Target is present, evaluate leash distance and target distance
		var t_dist = global_position.distance_to(target_ref.global_position)
		var h_dist = global_position.distance_to(home_position)
		
		# Update last known position when in line of sight
		if has_line_of_sight_to(target_ref):
			last_known_target_pos = target_ref.global_position
			los_lost_timer = 0.0
		else:
			los_lost_timer += delta
			if los_lost_timer >= lost_los_duration: # 4.5 seconds lost behind obstacles
				target_ref = null
				investigate_position = last_known_target_pos if last_known_target_pos != Vector3.ZERO else global_position
				transition_to_state(AIState.SEARCH, 2.5)
		
		if target_ref != null:
			# Leash limit check (except boss within arena)
			if not is_boss and h_dist > max_leash_distance:
				target_ref = null
				transition_to_state(AIState.RETURN)
			elif t_dist > lose_target_distance:
				target_ref = null
				investigate_position = last_known_target_pos if last_known_target_pos != Vector3.ZERO else global_position
				transition_to_state(AIState.SEARCH, 2.5)
			elif current_state == AIState.CHASE and chase_timer <= 0.0 and t_dist > (attack_range * 2.5):
				target_ref = null
				investigate_position = last_known_target_pos if last_known_target_pos != Vector3.ZERO else global_position
				transition_to_state(AIState.SEARCH, 2.5)
	
	var current_effective_speed = move_speed
	if chill_timer > 0.0:
		current_effective_speed *= chill_slow_factor
	if earth_sink_timer > 0.0:
		current_effective_speed *= earth_slow_factor
	if root_timer > 0.0:
		current_effective_speed = 0.0
	
	# State execution logic
	match current_state:
		AIState.IDLE:
			velocity.x = lerp(velocity.x, 0.0, delta * 8.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 8.0)
			if anim_player and anim_idle != "":
				anim_player.speed_scale = 1.0
				play_anim(anim_idle)
			if state_timer <= 0.0:
				patrol_target = home_position + Vector3(randf_range(-patrol_radius, patrol_radius), 0, randf_range(-patrol_radius, patrol_radius))
				transition_to_state(AIState.PATROL, randf_range(4.0, 7.0))
				
		AIState.PATROL:
			var p_diff = patrol_target - global_position
			p_diff.y = 0.0
			if p_diff.length() < 1.0 or state_timer <= 0.0:
				transition_to_state(AIState.IDLE, randf_range(2.5, 5.0))
			else:
				var p_dir = p_diff.normalized()
				var p_speed = current_effective_speed * 0.45
				velocity.x = lerp(velocity.x, p_dir.x * p_speed, delta * 7.0)
				velocity.z = lerp(velocity.z, p_dir.z * p_speed, delta * 7.0)
				if anim_player and anim_walk != "":
					anim_player.speed_scale = 0.85
					play_anim(anim_walk, 0.15)
					
		AIState.INVESTIGATE:
			var i_diff = investigate_position - global_position
			i_diff.y = 0.0
			if i_diff.length() < 1.2 or state_timer <= 0.0:
				transition_to_state(AIState.SEARCH, 3.0)
			else:
				var i_dir = i_diff.normalized()
				var i_speed = current_effective_speed * 0.55
				velocity.x = lerp(velocity.x, i_dir.x * i_speed, delta * 7.0)
				velocity.z = lerp(velocity.z, i_dir.z * i_speed, delta * 7.0)
				if anim_player and anim_walk != "":
					anim_player.speed_scale = 0.95
					play_anim(anim_walk, 0.15)
					
		AIState.ALERT:
			velocity.x = lerp(velocity.x, 0.0, delta * 12.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 12.0)
			if state_timer <= 0.0:
				transition_to_state(AIState.CHASE, max_chase_duration)
				
		AIState.CHASE:
			if target_ref:
				var diff = target_ref.global_position - global_position
				diff.y = 0.0
				var dist = diff.length()
				if dist <= attack_range and enemy_type in [EnemyType.GOBLIN, EnemyType.SKELETON_SPEAR]:
					if attack_timer <= 0.0:
						transition_to_state(AIState.ATTACK)
					else:
						velocity.x = lerp(velocity.x, 0.0, delta * 12.0)
						velocity.z = lerp(velocity.z, 0.0, delta * 12.0)
						if anim_player and anim_idle != "":
							anim_player.speed_scale = 1.0
							play_anim(anim_idle, 0.2)
				elif dist <= attack_range and attack_timer <= 0.0:
					transition_to_state(AIState.ATTACK)
				else:
					match enemy_type:
						EnemyType.GOBLIN:
							_process_goblin_ai(delta, diff, dist, target_ref)
						EnemyType.SKELETON_SPEAR:
							_process_spear_ai(delta, diff, dist, target_ref)
						EnemyType.SKELETON_ARCHER:
							_process_archer_ai(delta, diff, dist, target_ref)
						EnemyType.FIRE_IMP, EnemyType.SHADOW_IMP:
							_process_imp_ai(delta, diff, dist, target_ref)
							_process_procedural_imp_animation(delta)
			else:
				transition_to_state(AIState.SEARCH, 3.0)
				
		AIState.ATTACK:
			if target_ref:
				var diff = target_ref.global_position - global_position
				diff.y = 0.0
				var dist = diff.length()
				match enemy_type:
					EnemyType.GOBLIN:
						_process_goblin_ai(delta, diff, dist, target_ref)
					EnemyType.SKELETON_SPEAR:
						_process_spear_ai(delta, diff, dist, target_ref)
					EnemyType.SKELETON_ARCHER:
						_process_archer_ai(delta, diff, dist, target_ref)
					EnemyType.FIRE_IMP, EnemyType.SHADOW_IMP:
						_process_imp_ai(delta, diff, dist, target_ref)
						_process_procedural_imp_animation(delta)
				if not is_winding_up_attack and attack_timer > 0.0 and dist > (attack_range * 1.35):
					transition_to_state(AIState.CHASE, max_chase_duration)
			else:
				transition_to_state(AIState.SEARCH, 3.0)
				
		AIState.SEARCH:
			var s_diff = (investigate_position - global_position) if investigate_position != Vector3.ZERO else Vector3.ZERO
			s_diff.y = 0.0
			var s_dist = s_diff.length()
			if s_dist > 1.2 and investigate_position != Vector3.ZERO:
				var s_dir = s_diff.normalized()
				var s_speed = current_effective_speed * 0.55
				velocity.x = lerp(velocity.x, s_dir.x * s_speed, delta * 7.0)
				velocity.z = lerp(velocity.z, s_dir.z * s_speed, delta * 7.0)
				if anim_player and anim_walk != "":
					anim_player.speed_scale = 0.85
					play_anim(anim_walk, 0.15)
			else:
				velocity.x = lerp(velocity.x, 0.0, delta * 8.0)
				velocity.z = lerp(velocity.z, 0.0, delta * 8.0)
				if anim_player and anim_idle != "":
					anim_player.speed_scale = 1.0
					play_anim(anim_idle, 0.2)
			if state_timer <= 0.0:
				target_cooldown = 3.0
				transition_to_state(AIState.RETURN)
				
		AIState.RETURN:
			var r_diff = home_position - global_position
			r_diff.y = 0.0
			if r_diff.length() < 1.8:
				transition_to_state(AIState.RECOVER, 2.5)
			else:
				var r_dir = r_diff.normalized()
				var r_speed = current_effective_speed * 0.55
				velocity.x = lerp(velocity.x, r_dir.x * r_speed, delta * 7.0)
				velocity.z = lerp(velocity.z, r_dir.z * r_speed, delta * 7.0)
				if anim_player and anim_walk != "":
					anim_player.speed_scale = 0.85
					play_anim(anim_walk, 0.15)
				# Gradual recovery prevents cheap kiting exploits
				current_health = min(max_health, current_health + (max_health * 0.08 * delta))
				update_hp_display()
					
		AIState.RECOVER:
			velocity.x = lerp(velocity.x, 0.0, delta * 8.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 8.0)
			if anim_player and anim_idle != "":
				anim_player.speed_scale = 1.0
				play_anim(anim_idle, 0.2)
			current_health = min(max_health, current_health + (max_health * 0.15 * delta))
			update_hp_display()
			if state_timer <= 0.0:
				transition_to_state(AIState.IDLE, randf_range(2.0, 4.0))
				target_cooldown = 2.5 # Prevent immediate re-acquisition snap loop!

	# Separation push from other enemies to prevent overlap blobs
	var sep_force = get_separation_force()
	velocity.x += sep_force.x
	velocity.z += sep_force.z
	
	# Respect player personal space capsule (prevent merging)
	if target_ref and is_instance_valid(target_ref):
		var p_sep = global_position - target_ref.global_position
		p_sep.y = 0.0
		var p_d = p_sep.length()
		if p_d > 0.001 and p_d < 1.1:
			var push_p = (p_sep / p_d) * (1.1 - p_d) * 5.0
			velocity.x += push_p.x
			velocity.z += push_p.z

	# Dynamic locomotion orientation based on movement velocity and tactical AI state
	var h_vel = Vector3(velocity.x, 0.0, velocity.z)
	var face_dir = Vector3.ZERO
	var diff_target = (target_ref.global_position - global_position) if (target_ref and is_instance_valid(target_ref)) else Vector3.ZERO
	diff_target.y = 0.0
	var dist_target = diff_target.length()
	
	if is_fleeing:
		# Huida: orientar corporalmente en la dirección en la que escapan
		face_dir = h_vel if h_vel.length_squared() > 0.04 else -diff_target
	elif is_winding_up_attack or is_recovering_attack:
		face_dir = diff_target
	elif enemy_type == EnemyType.SKELETON_ARCHER and dist_target < 6.0 and target_ref:
		# Retirada táctica mirando al objetivo ("flee shoot")
		face_dir = diff_target
	elif (enemy_type == EnemyType.FIRE_IMP or enemy_type == EnemyType.SHADOW_IMP) and is_winding_up_attack and target_ref:
		# Diablillos durante el disparo/telegraph de escupitajo de fuego
		face_dir = diff_target
	elif (enemy_type == EnemyType.FIRE_IMP or enemy_type == EnemyType.SHADOW_IMP) and h_vel.length_squared() > 0.04:
		# Diablillos en vuelo circular: orientar a lo largo de la trayectoria curva
		face_dir = h_vel
	elif (current_state == AIState.ALERT or current_state == AIState.ATTACK or (dist_target <= attack_range and enemy_type in [EnemyType.GOBLIN, EnemyType.SKELETON_SPEAR])) and target_ref:
		# En alerta, ataque o en rango estático de combate cuerpo a cuerpo: orientar hacia el objetivo
		face_dir = diff_target
	elif h_vel.length_squared() > 0.04:
		# Desplazamiento / Persecución / Deambulación: vector horizontal de movimiento
		face_dir = h_vel
	# Reposo: conserva orientación actual cuando h_vel <= 0.04 y sin acción de combate
	
	if face_dir.length_squared() > 0.001:
		var target_rot = atan2(-face_dir.x, -face_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, delta * 9.0)
	
	move_and_slide()

func get_effective_move_speed() -> float:
	return move_speed * (chill_slow_factor if chill_timer > 0.0 else 1.0)

func _process_goblin_ai(delta: float, diff: Vector3, dist: float, target: Node3D) -> void:
	var eff_speed = get_effective_move_speed()
	# Goblin flees when health < 35%
	if current_health / max_health < 0.35 and flee_timer <= 0.0 and not is_fleeing:
		is_fleeing = true
		flee_timer = 3.5
		play_anim("run" if (anim_player and anim_player.has_animation("run")) else anim_walk, 0.15)
	elif flee_timer <= 0.0:
		is_fleeing = false
	
	if is_fleeing:
		var away_dir = -diff.normalized()
		var flee_speed = eff_speed * 1.35
		velocity.x = lerp(velocity.x, away_dir.x * flee_speed, delta * 7.0)
		velocity.z = lerp(velocity.z, away_dir.z * flee_speed, delta * 7.0)
		if anim_player:
			anim_player.speed_scale = 1.35
		play_anim("run" if (anim_player and anim_player.has_animation("run")) else anim_walk, 0.15)
		return
	
	if is_recovering_attack:
		attack_recovery_timer -= delta
		velocity.x = lerp(velocity.x, 0.0, delta * 12.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 12.0)
		if attack_recovery_timer <= 0.0:
			is_recovering_attack = false
			attack_timer = attack_cooldown
			if anim_player:
				anim_player.speed_scale = 1.0
			play_anim(get_current_idle(), 0.18)
		return
	
	if dist <= attack_range:
		velocity.x = lerp(velocity.x, 0.0, delta * 12.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 12.0)
		if attack_timer <= 0.0 and not is_winding_up_attack:
			is_winding_up_attack = true
			windup_timer = attack_windup
			if anim_player:
				anim_player.speed_scale = attack_anim_speed
			play_anim(anim_attack, 0.06)
		elif is_winding_up_attack:
			windup_timer -= delta
			if windup_timer <= 0.0:
				is_winding_up_attack = false
				if is_instance_valid(target) and not is_dead:
					if global_position.distance_to(target.global_position) <= attack_range * 1.35:
						if target.has_method("take_damage"):
							target.take_damage(attack_damage)
				is_recovering_attack = true
				attack_recovery_timer = (attack_clip_duration / attack_anim_speed) - attack_windup
		else:
			if anim_player and (not anim_player.is_playing() or anim_player.current_animation != anim_attack):
				anim_player.speed_scale = 1.0
				play_anim(get_current_idle(), 0.18)
	else:
		if not is_winding_up_attack:
			var dir = diff.normalized()
			velocity.x = lerp(velocity.x, dir.x * eff_speed, delta * 7.0)
			velocity.z = lerp(velocity.z, dir.z * eff_speed, delta * 7.0)
			if anim_player:
				var h_speed = Vector2(velocity.x, velocity.z).length()
				if h_speed >= 2.6 and (anim_run != "" or anim_player.has_animation("run")):
					anim_player.speed_scale = clamp(h_speed / 3.6, 0.85, 1.35)
					play_anim("run", 0.12)
				else:
					anim_player.speed_scale = clamp(h_speed / 2.0, 0.8, 1.3)
					play_anim(anim_walk, 0.12)

func _process_spear_ai(delta: float, diff: Vector3, dist: float, target: Node3D) -> void:
	var eff_speed = get_effective_move_speed()
	# Skeleton spearman can raise block guard
	if block_timer > 0.0:
		velocity.x = lerp(velocity.x, 0.0, delta * 10.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 10.0)
		if anim_player:
			anim_player.speed_scale = 1.2
		play_anim("block" if (anim_player and anim_player.has_animation("block")) else anim_idle, 0.12)
		return
	
	# Chance to block when close
	if dist < 4.0 and randf() < 0.008 and attack_timer > 0.5:
		block_timer = 0.8
		is_blocking = true
		velocity.x = lerp(velocity.x, 0.0, delta * 10.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 10.0)
		if anim_player:
			anim_player.speed_scale = 1.2
		play_anim("block" if (anim_player and anim_player.has_animation("block")) else anim_idle, 0.12)
		return
	
	is_blocking = false
	
	if is_recovering_attack:
		attack_recovery_timer -= delta
		velocity.x = lerp(velocity.x, 0.0, delta * 12.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 12.0)
		if attack_recovery_timer <= 0.0:
			is_recovering_attack = false
			attack_timer = attack_cooldown
			if anim_player:
				anim_player.speed_scale = 1.0
			play_anim(anim_idle, 0.15)
		return
	
	if dist <= attack_range:
		velocity.x = lerp(velocity.x, 0.0, delta * 12.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 12.0)
		if attack_timer <= 0.0 and not is_winding_up_attack:
			is_winding_up_attack = true
			windup_timer = attack_windup
			if anim_player:
				anim_player.speed_scale = attack_anim_speed
			play_anim(anim_attack, 0.06)
		elif is_winding_up_attack:
			windup_timer -= delta
			if windup_timer <= 0.0:
				is_winding_up_attack = false
				if is_instance_valid(target) and not is_dead:
					if global_position.distance_to(target.global_position) <= attack_range * 1.35:
						if target.has_method("take_damage"):
							target.take_damage(attack_damage)
				is_recovering_attack = true
				attack_recovery_timer = (attack_clip_duration / attack_anim_speed) - attack_windup
		else:
			if anim_player and (not anim_player.is_playing() or anim_player.current_animation != anim_attack):
				anim_player.speed_scale = 1.0
				play_anim(anim_idle, 0.2)
	else:
		if not is_winding_up_attack:
			var dir = diff.normalized()
			velocity.x = lerp(velocity.x, dir.x * eff_speed, delta * 7.0)
			velocity.z = lerp(velocity.z, dir.z * eff_speed, delta * 7.0)
			if anim_player:
				var h_speed = Vector2(velocity.x, velocity.z).length()
				anim_player.speed_scale = clamp(h_speed / 3.5, 0.8, 1.5)
			play_anim(anim_walk, 0.12)

func _process_archer_ai(delta: float, diff: Vector3, dist: float, target: Node3D) -> void:
	var eff_speed = get_effective_move_speed()
	if is_recovering_attack:
		attack_recovery_timer -= delta
		velocity.x = lerp(velocity.x, 0.0, delta * 10.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 10.0)
		if attack_recovery_timer <= 0.0:
			is_recovering_attack = false
			attack_timer = attack_cooldown
			if anim_player:
				anim_player.speed_scale = 1.0
			play_anim(anim_idle, 0.2)
		return
	
	# Archer kites! If target gets closer than 6.0m, retreat backwards
	if dist < 6.0:
		is_winding_up_attack = false
		var back_dir = -diff.normalized()
		var kite_speed = eff_speed * 1.15
		velocity.x = lerp(velocity.x, back_dir.x * kite_speed, delta * 7.0)
		velocity.z = lerp(velocity.z, back_dir.z * kite_speed, delta * 7.0)
		if anim_player:
			anim_player.speed_scale = 1.25
		play_anim("flee shoot" if (anim_player and anim_player.has_animation("flee shoot")) else ("run" if (anim_player and anim_player.has_animation("run")) else anim_walk), 0.12)
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			_shoot_bone_arrow(target)
	elif dist <= attack_range:
		velocity.x = lerp(velocity.x, 0.0, delta * 10.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 10.0)
		if attack_timer <= 0.0 and not is_winding_up_attack:
			is_winding_up_attack = true
			windup_timer = attack_windup
			if anim_player:
				anim_player.speed_scale = attack_anim_speed
			play_anim(anim_attack, 0.08)
		elif is_winding_up_attack:
			windup_timer -= delta
			if windup_timer <= 0.0:
				is_winding_up_attack = false
				if is_instance_valid(target) and not is_dead:
					_shoot_bone_arrow(target)
				is_recovering_attack = true
				attack_recovery_timer = (attack_clip_duration / attack_anim_speed) - attack_windup
		else:
			if anim_player and (not anim_player.is_playing() or anim_player.current_animation != anim_attack):
				anim_player.speed_scale = 1.0
				play_anim(anim_idle, 0.2)
	else:
		if not is_winding_up_attack:
			var dir = diff.normalized()
			velocity.x = lerp(velocity.x, dir.x * eff_speed, delta * 7.0)
			velocity.z = lerp(velocity.z, dir.z * eff_speed, delta * 7.0)
			if anim_player:
				var h_speed = Vector2(velocity.x, velocity.z).length()
				anim_player.speed_scale = clamp(h_speed / 3.4, 0.8, 1.4)
			play_anim(anim_walk, 0.12)

func _process_imp_ai(delta: float, diff: Vector3, dist: float, target: Node3D) -> void:
	var eff_speed = get_effective_move_speed()
	if is_recovering_attack:
		attack_recovery_timer -= delta
		velocity.x = lerp(velocity.x, 0.0, delta * 9.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 9.0)
		if attack_recovery_timer <= 0.0:
			is_recovering_attack = false
			attack_timer = attack_cooldown
			if anim_player:
				anim_player.speed_scale = 1.0
			play_anim(anim_idle, 0.15)
		return
	
	# Fire Imp circles target at medium range with agility
	var perp = Vector3(-diff.z, 0, diff.x).normalized()
	var target_h = Vector3.ZERO
	if dist < 5.0:
		target_h = -diff.normalized() * eff_speed
	elif dist > attack_range:
		target_h = diff.normalized() * eff_speed
	else:
		target_h = perp * (eff_speed * 0.85)
	
	velocity.x = lerp(velocity.x, target_h.x, delta * 9.0)
	velocity.z = lerp(velocity.z, target_h.z, delta * 9.0)
	
	var h_speed = Vector2(velocity.x, velocity.z).length()
	if not is_winding_up_attack and anim_player:
		if h_speed > 0.5:
			anim_player.speed_scale = clamp(h_speed / 4.5, 0.8, 1.5)
			play_anim(anim_walk, 0.12)
		else:
			if not anim_player.is_playing() or anim_player.current_animation != anim_attack:
				anim_player.speed_scale = 1.0
				play_anim(anim_idle, 0.2)
	
	# Fire spit attack
	if dist <= attack_range and attack_timer <= 0.0 and not is_winding_up_attack:
		is_winding_up_attack = true
		windup_timer = attack_windup
		if anim_player:
			anim_player.speed_scale = attack_anim_speed
		play_anim(anim_attack, 0.06)
	elif is_winding_up_attack:
		windup_timer -= delta
		if windup_timer <= 0.0:
			is_winding_up_attack = false
			if is_instance_valid(target) and not is_dead:
				_shoot_fire_spit(target)
			is_recovering_attack = true
			attack_recovery_timer = (attack_clip_duration / attack_anim_speed) - attack_windup

func _process_boss_specials(delta: float) -> void:
	slam_recover_timer = max(0.0, slam_recover_timer - delta)
	
	# Update or remove vulnerability aura ring
	if slam_recover_timer > 0.0:
		velocity.x = lerp(velocity.x, 0.0, delta * 14.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 14.0)
		if not boss_vuln_ring and is_inside_tree():
			boss_vuln_ring = MeshInstance3D.new()
			var torus = TorusMesh.new()
			torus.inner_radius = 2.4
			torus.outer_radius = 2.8
			var vmat = StandardMaterial3D.new()
			vmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			vmat.albedo_color = Color(0.2, 0.9, 1.0, 0.85)
			boss_vuln_ring.mesh = torus
			boss_vuln_ring.material_override = vmat
			get_parent().add_child(boss_vuln_ring)
		if boss_vuln_ring and is_instance_valid(boss_vuln_ring):
			boss_vuln_ring.global_position = global_position + Vector3(0, 0.12, 0)
			boss_vuln_ring.rotation.y += delta * 3.5
			var pulse = 1.0 + sin(slam_recover_timer * 14.0) * 0.12
			boss_vuln_ring.scale = Vector3(pulse, 1.0, pulse)
	else:
		if boss_vuln_ring and is_instance_valid(boss_vuln_ring):
			boss_vuln_ring.queue_free()
			boss_vuln_ring = null
	
	if is_charging_slam:
		slam_charge_timer -= delta
		velocity.x = lerp(velocity.x, 0.0, delta * 12.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 12.0)
		
		# Telegraph danger ring expanding to 8.5m radius
		if not boss_danger_ring and is_inside_tree():
			boss_danger_ring = MeshInstance3D.new()
			var d_torus = TorusMesh.new()
			d_torus.inner_radius = 8.1
			d_torus.outer_radius = 8.5
			var dmat = StandardMaterial3D.new()
			dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			dmat.albedo_color = Color(1.0, 0.35, 0.1, 0.85)
			boss_danger_ring.mesh = d_torus
			boss_danger_ring.material_override = dmat
			get_parent().add_child(boss_danger_ring)
			boss_danger_ring.global_position = global_position + Vector3(0, 0.08, 0)
			boss_danger_ring.scale = Vector3(0.1, 1.0, 0.1)
		
		if boss_danger_ring and is_instance_valid(boss_danger_ring):
			var charge_progress = clamp(1.0 - (slam_charge_timer / 1.2), 0.1, 1.0)
			boss_danger_ring.global_position = global_position + Vector3(0, 0.08, 0)
			boss_danger_ring.scale = Vector3(charge_progress, 1.0, charge_progress)
			boss_danger_ring.rotation.y += delta * 4.0
		
		if slam_charge_timer <= 0.0:
			is_charging_slam = false
			if boss_danger_ring and is_instance_valid(boss_danger_ring):
				boss_danger_ring.queue_free()
				boss_danger_ring = null
			_execute_boss_earthquake()
		return
	else:
		if boss_danger_ring and is_instance_valid(boss_danger_ring):
			boss_danger_ring.queue_free()
			boss_danger_ring = null
	
	boss_slam_timer -= delta
	if boss_slam_timer <= 0.0 and current_state == AIState.CHASE and not is_winding_up_attack:
		boss_slam_timer = 9.0
		is_charging_slam = true
		slam_charge_timer = 1.2 # 1.2s clear visual & audio warning telegraph!
		GameManager.spawn_damage_number(global_position + Vector3(0, 2.5, 0), "⚠️ ¡GOLPE SÍSMICO!", Color(1.0, 0.35, 0.1), 1.35)
		GameManager.shake_camera(0.25)
	
	if current_health / max_health <= 0.5 and not boss_summoned_help:
		boss_summoned_help = true
		_summon_boss_minions()

func _execute_boss_earthquake() -> void:
	GameManager.shake_camera(0.65)
	GameManager.spawn_damage_number(global_position + Vector3(0, 1.8, 0), "💥 ¡TERREMOTO!", Color(1.0, 0.85, 0.2), 1.4)
	
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and global_position.distance_to(p.global_position) < 8.5:
			if p.has_method("take_damage"):
				p.take_damage(20.0)
	for m in get_tree().get_nodes_in_group("minion"):
		if is_instance_valid(m) and global_position.distance_to(m.global_position) < 8.5:
			if m.has_method("take_damage"):
				m.take_damage(35.0)
	
	# Boss enters a 2.0s vulnerability counter-attack window!
	slam_recover_timer = 2.0
	GameManager.spawn_damage_number(global_position + Vector3(0, 2.4, 0), "🛡️ ¡VULNERABLE!", Color(0.4, 0.9, 1.0), 1.25)
	
	if not boss_vuln_ring and is_inside_tree():
		boss_vuln_ring = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.inner_radius = 2.4
		torus.outer_radius = 2.8
		var vmat = StandardMaterial3D.new()
		vmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		vmat.albedo_color = Color(0.2, 0.9, 1.0, 0.85)
		boss_vuln_ring.mesh = torus
		boss_vuln_ring.material_override = vmat
		get_parent().add_child(boss_vuln_ring)
		boss_vuln_ring.global_position = global_position + Vector3(0, 0.12, 0)

func _summon_boss_minions() -> void:
	var enemy_scene = load("res://scenes/Enemy.tscn")
	for i in range(2):
		var minion = enemy_scene.instantiate()
		minion.is_boss = false
		get_parent().add_child(minion)
		minion.set_archetype(EnemyType.SKELETON_SPEAR)
		var m_pos = global_position + Vector3(randf_range(-3, 3), 0.5, randf_range(-3, 3))
		m_pos.y = MapConfig.get_height_at(m_pos.x, m_pos.z)
		minion.global_position = m_pos

func _shoot_bone_arrow(target: Node3D) -> void:
	var arrow = bone_arrow_scene.instantiate()
	get_parent().add_child(arrow)
	var spawn_pos = global_position + Vector3(0, 1.3, 0) + (-transform.basis.z * 0.6)
	var dir = (target.global_position + Vector3(0, 0.9, 0) - spawn_pos).normalized()
	arrow.init_arrow(spawn_pos, dir)

func _shoot_fire_spit(target: Node3D) -> void:
	var spit = fire_spit_scene.instantiate()
	get_parent().add_child(spit)
	var spawn_pos = global_position + Vector3(0, 1.1, 0) + (-transform.basis.z * 0.5)
	var dir = (target.global_position + Vector3(0, 0.8, 0) - spawn_pos).normalized()
	spit.init_spit(spawn_pos, dir)
	spit_recoil_squash = 0.35

func _process_procedural_imp_animation(delta: float) -> void:
	if is_dead:
		return
	proc_anim_time += delta
	spit_recoil_squash = lerp(spit_recoil_squash, 0.0, delta * 8.0)
	if model_container:
		model_container.position.y = 0.2 + sin(proc_anim_time * 5.0) * 0.15
		var breath = 1.0 + sin(proc_anim_time * 3.5) * 0.04
		var s_x = breath + spit_recoil_squash
		var s_y = (2.0 - breath) - (spit_recoil_squash * 0.7)
		model_container.scale = base_scale * Vector3(s_x, s_y, s_x)
		var speed_factor = clamp(velocity.length() / max(0.1, move_speed), 0.0, 1.0)
		model_container.rotation.x = speed_factor * 0.18
		model_container.rotation.z = sin(proc_anim_time * 4.0) * 0.08

func find_target() -> Node3D:
	return detect_player()

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, element: String = "") -> void:
	if is_dead:
		return
	
	# Block stance reduces damage by 75%
	var effective_damage = amount * 0.25 if is_blocking else amount
	
	# Elemental vulnerability and resistance checks
	if element != "":
		if element in elemental_weaknesses:
			effective_damage *= 1.5
			GameManager.spawn_damage_number(global_position + Vector3(0, 1.8, 0), "✨ ¡VULNERABLE! (x1.5)", Color(1.0, 0.85, 0.2), 1.3)
			GameManager.record_bestiary_entry(get_archetype_name(), element, true)
		elif element in elemental_resistances:
			effective_damage *= 0.6
			GameManager.spawn_damage_number(global_position + Vector3(0, 1.8, 0), "🛡️ ¡RESISTE! (-40%)", Color(0.6, 0.75, 0.95), 1.0)
			GameManager.record_bestiary_entry(get_archetype_name(), element, false)
	
	# Boss vulnerability window bonus (+50% damage during recovery!)
	if is_boss and slam_recover_timer > 0.0:
		effective_damage *= 1.5
		GameManager.spawn_damage_number(global_position + Vector3(0, 2.2, 0), "💥 ¡GOLPE VULNERABLE!", Color(0.3, 0.9, 1.0), 1.35)
	
	current_health -= effective_damage
	
	# Interruption mechanic: heavy damage or strong knockback interrupts attack windup
	if is_winding_up_attack and (effective_damage >= 18.0 or knockback.length() > 3.0):
		is_winding_up_attack = false
		is_recovering_attack = false
		transition_to_state(AIState.RECOVER, 1.2)
		GameManager.spawn_damage_number(global_position, "⚡ ¡INTERRUPCIÓN!", Color(1.0, 0.85, 0.2), 1.15)
	
	if is_blocking:
		GameManager.spawn_damage_number(global_position, "🛡️ BLOQUEO (-%d)" % [int(effective_damage)], Color(0.4, 0.85, 1.0), 0.95)
	else:
		velocity += knockback * 0.6
		if effective_damage >= 25.0 or is_boss:
			GameManager.spawn_damage_number(global_position, "💥 -%d" % [int(effective_damage)], Color(1.0, 0.35, 0.15), 1.35)
			GameManager.shake_camera(0.28)
		else:
			GameManager.spawn_damage_number(global_position, "-%d" % [int(effective_damage)], Color(1.0, 0.95, 0.8), 1.0)
		
		_trigger_hit_reaction(knockback)
	
	# Wake up and fight back if attacked during return or recover
	if current_state == AIState.RETURN or current_state == AIState.RECOVER:
		var attacker = detect_player()
		if attacker:
			target_ref = attacker
			transition_to_state(AIState.ALERT, alert_duration)
			alert_allies(attacker, global_position, 12.0)
	elif target_ref == null:
		# Aggro and alert allies on hit
		var potential = detect_player()
		if potential:
			target_ref = potential
			transition_to_state(AIState.CHASE, max_chase_duration)
			alert_allies(potential, global_position, 12.0)
	
	show_hp_timer = 4.0
	if hp_bar:
		hp_bar.visible = true
	update_hp_display()
	
	if current_health <= 0.0:
		die()

func _trigger_hit_reaction(knockback: Vector3) -> void:
	_flash_hit()
	
	if anim_player and (anim_player.has_animation(anim_hit) or anim_player.has_animation("hit")):
		var clip_to_play = anim_hit if (anim_hit != "" and anim_player.has_animation(anim_hit)) else "hit"
		var hit_speed = 3.8 if enemy_type == EnemyType.SKELETON_SPEAR else 1.35
		anim_player.speed_scale = hit_speed
		play_anim(clip_to_play, 0.05)
		hit_stagger_timer = 0.28
	else:
		# Procedural hit reaction: squash & stretch and knockback tilt
		hit_stagger_timer = 0.20
		if model_container:
			var tween = create_tween()
			var squash_scale = base_scale * Vector3(1.18, 0.78, 1.18)
			tween.tween_property(model_container, "scale", squash_scale, 0.06)
			tween.tween_property(model_container, "scale", base_scale, 0.14)
			
			var orig_rot_x = model_container.rotation.x
			var tilt_tween = create_tween()
			tilt_tween.tween_property(model_container, "rotation:x", orig_rot_x - 0.22, 0.07)
			tilt_tween.tween_property(model_container, "rotation:x", orig_rot_x, 0.14)

func _flash_hit() -> void:
	var meshes_with_mat: Array = []
	for mesh in find_children("*", "MeshInstance3D", true, false):
		if mesh.material_override:
			meshes_with_mat.append(mesh)
		elif mesh.get_active_material(0):
			meshes_with_mat.append(mesh)
	if meshes_with_mat.size() > 0:
		var flash_tween = create_tween()
		for mesh in meshes_with_mat:
			var mat = mesh.material_override if mesh.material_override else mesh.get_active_material(0)
			if mat is StandardMaterial3D:
				var orig_col = mat.albedo_color
				mat.albedo_color = Color(2.0, 1.8, 1.2)
				flash_tween.tween_property(mat, "albedo_color", orig_col, 0.14)

func _spawn_death_particles(color: Color, amount: int = 24) -> void:
	var p = CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = amount
	p.lifetime = 0.65
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.5
	p.gravity = Vector3(0, -4.5, 0)
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.albedo_texture = preload("res://assets/vfx/textures/dust_puff.png")
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.28, 0.28)
	mesh.material = mat
	p.mesh = mesh
	if get_parent():
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(0, 0.6, 0)
		p.emitting = true
		get_tree().create_timer(0.9).timeout.connect(p.queue_free)

func get_archetype_name() -> String:
	if is_boss:
		return "Dragon Arcano"
	match enemy_type:
		EnemyType.GOBLIN: return "Duende Hostil"
		EnemyType.SKELETON_SPEAR: return "Esqueleto Lancero"
		EnemyType.SKELETON_ARCHER: return "Esqueleto Arquero"
		EnemyType.FIRE_IMP: return "Diablillo de Fuego"
		EnemyType.SHADOW_IMP: return "Diablo Sombrío"
	return "Monstruo"

func apply_chill(slow_factor: float = 0.45, duration: float = 4.0) -> void:
	if is_dead:
		return
	ice_stacks += 1
	if ice_stacks >= 3:
		ice_stacks = 0
		freeze_timer = 2.0
		chill_timer = 0.0
		velocity = Vector3.ZERO
		GameManager.spawn_damage_number(global_position + Vector3(0, 1.8, 0), "🧊 ¡CONGELADO!", Color(0.5, 0.9, 1.0), 1.4)
		_flash_hit()
		return
	
	chill_timer = max(chill_timer, duration)
	var stack_slow = 0.55 if ice_stacks == 1 else 0.35
	chill_slow_factor = stack_slow
	GameManager.spawn_damage_number(global_position + Vector3(0, 1.4, 0), "❄️ ¡RALENTIZADO (%d)!" % ice_stacks, Color(0.4, 0.85, 1.0), 1.1)
	_flash_hit()
	
	# Spawn or restart chill snowflake aura particles
	if chill_vfx_node == null or not is_instance_valid(chill_vfx_node):
		chill_vfx_node = CPUParticles3D.new()
		chill_vfx_node.amount = 14
		chill_vfx_node.lifetime = 0.65
		chill_vfx_node.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		chill_vfx_node.emission_sphere_radius = 0.6
		chill_vfx_node.gravity = Vector3(0, -0.8, 0)
		var cmat = StandardMaterial3D.new()
		cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cmat.albedo_color = Color(0.65, 0.9, 1.0, 0.85)
		cmat.albedo_texture = preload("res://assets/vfx/textures/snowflake_crystal.png")
		cmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		cmat.billboard_keep_scale = true
		var cmesh = QuadMesh.new()
		cmesh.size = Vector2(0.2, 0.2)
		cmesh.material = cmat
		chill_vfx_node.mesh = cmesh
		add_child(chill_vfx_node)
		chill_vfx_node.position = Vector3(0, 0.6, 0)
	chill_vfx_node.emitting = true
	
	if current_health <= 0.0:
		die()

func apply_stun(duration: float = 0.4) -> void:
	if is_dead:
		return
	stun_timer = max(stun_timer, duration)
	is_winding_up_attack = false
	GameManager.spawn_damage_number(global_position + Vector3(0, 1.4, 0), "⚡ ¡ATURDIDO!", Color(1.0, 0.85, 0.2), 1.15)
	_flash_hit()

func apply_burn(duration: float = 4.0, dps: float = 6.0) -> void:
	if is_dead:
		return
	burn_timer = max(burn_timer, duration)
	burn_dps = dps
	burn_tick_timer = 0.0
	if enemy_type in [EnemyType.GOBLIN, EnemyType.FIRE_IMP, EnemyType.SHADOW_IMP] and not is_boss:
		is_fleeing = true
		flee_timer = 1.6
		GameManager.spawn_damage_number(global_position + Vector3(0, 1.5, 0), "😱 ¡PÁNICO ÍGNEO!", Color(1.0, 0.4, 0.1), 1.2)
	else:
		GameManager.spawn_damage_number(global_position + Vector3(0, 1.4, 0), "🔥 ¡EN LLAMAS!", Color(1.0, 0.5, 0.1), 1.1)

func apply_earth_sink(duration: float = 4.0, slow_pct: float = 0.70) -> void:
	if is_dead:
		return
	earth_sink_timer = max(earth_sink_timer, duration)
	earth_slow_factor = 1.0 - slow_pct
	GameManager.spawn_damage_number(global_position + Vector3(0, 1.3, 0), "🪨 ¡HUNDIDO (-70%)!", Color(0.7, 0.55, 0.35), 1.15)
	_flash_hit()

func apply_root(duration: float = 3.0) -> void:
	if is_dead:
		return
	root_timer = max(root_timer, duration)
	GameManager.spawn_damage_number(global_position + Vector3(0, 1.4, 0), "🌿 ¡ATADURA ARCANAS!", Color(0.3, 0.9, 0.4), 1.25)
	_flash_hit()

func update_hp_display() -> void:
	if hp_bar:
		var pct = int((current_health / max_health) * 100.0)
		var title = ""
		match enemy_type:
			EnemyType.GOBLIN: title = "Duende: "
			EnemyType.SKELETON_SPEAR: title = "Lancero: "
			EnemyType.SKELETON_ARCHER: title = "Arquero: "
			EnemyType.FIRE_IMP: title = "Diablillo: "
			EnemyType.SHADOW_IMP: title = "Diablo Sombrío: "
		
		var status_prefix = ""
		if is_boss:
			status_prefix = "👑 "
		elif current_state == AIState.ALERT:
			status_prefix = "❗ "
		elif current_state == AIState.SEARCH:
			status_prefix = "❓ "
		elif current_state == AIState.RETURN:
			status_prefix = "↩ "
		elif is_blocking:
			status_prefix = "🛡️ "
		
		hp_bar.text = "%s%s%d HP" % [status_prefix, title, int(current_health)]
		hp_bar.modulate = Color.RED if pct < 35 else (Color(1, 0.8, 0.2) if is_blocking else Color.WHITE)

func _exit_tree() -> void:
	if boss_danger_ring and is_instance_valid(boss_danger_ring):
		boss_danger_ring.queue_free()
	if boss_vuln_ring and is_instance_valid(boss_vuln_ring):
		boss_vuln_ring.queue_free()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	remove_from_group("enemy")
	velocity = Vector3.ZERO
	
	if has_node("CollisionShape3D"):
		($CollisionShape3D as CollisionShape3D).set_deferred("disabled", true)
	if hp_bar:
		hp_bar.visible = false
	if chill_vfx_node and is_instance_valid(chill_vfx_node):
		chill_vfx_node.queue_free()
		chill_vfx_node = null
	if boss_danger_ring and is_instance_valid(boss_danger_ring):
		boss_danger_ring.queue_free()
		boss_danger_ring = null
	if boss_vuln_ring and is_instance_valid(boss_vuln_ring):
		boss_vuln_ring.queue_free()
		boss_vuln_ring = null
	
	GameManager.enemies_defeated += 1
	GameManager.score += (1000 if is_boss else 100)
	
	if is_boss:
		GameManager.boss_defeated = true
	
	_drop_coherent_loot()
	
	var death_anim_to_play: String = ""
	if anim_player:
		if anim_death != "" and anim_player.has_animation(anim_death):
			death_anim_to_play = anim_death
		elif anim_player.has_animation("death"):
			death_anim_to_play = "death"

	match enemy_type:
		EnemyType.SKELETON_SPEAR, EnemyType.SKELETON_ARCHER:
			_spawn_death_particles(Color(0.88, 0.88, 0.82), 26)
		EnemyType.FIRE_IMP:
			_spawn_death_particles(Color(1.0, 0.4, 0.1), 32)
		EnemyType.SHADOW_IMP:
			_spawn_death_particles(Color(0.65, 0.15, 0.95), 32)
		EnemyType.GOBLIN:
			_spawn_death_particles(Color(0.4, 0.8, 0.4), 20)

	if death_anim_to_play != "" and anim_player:
		anim_player.speed_scale = 1.05 if is_boss else 1.0
		play_anim(death_anim_to_play, 0.05)
		var clip_len = anim_player.get_animation(death_anim_to_play).length / anim_player.speed_scale
		await get_tree().create_timer(clamp(clip_len, 0.6, 1.4)).timeout
		if is_instance_valid(anim_player):
			anim_player.pause()

	var tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.4)
	await tween.finished
	queue_free()

func play_anim(anim_name: String, blend_time: float = 0.2) -> void:
	if not anim_player or not anim_player.has_animation(anim_name):
		return
	if current_anim == anim_name and anim_player.is_playing():
		return
	current_anim = anim_name
	anim_player.play(anim_name, blend_time)

func _drop_coherent_loot() -> void:
	if not world_item_scene:
		return
	
	if is_boss:
		# Guaranteed high-tier rewards from the Boss
		_spawn_world_item("potion_health", 2, Vector3(-1.2, 0.4, 0))
		_spawn_world_item("potion_mana", 2, Vector3(1.2, 0.4, 0))
		_spawn_world_item("magic_scroll", 1, Vector3(0.0, 0.4, 1.2))
		return
	
	# Archetype-specific drop tables
	var drop_roll = randf()
	match enemy_type:
		EnemyType.GOBLIN:
			if drop_roll < 0.45:
				_spawn_world_item("potion_health" if randf() < 0.4 else "apple", 1)
		EnemyType.SKELETON_SPEAR:
			if drop_roll < 0.50:
				_spawn_world_item("potion_mana", 1)
		EnemyType.SKELETON_ARCHER:
			if drop_roll < 0.45:
				_spawn_world_item("magic_scroll" if randf() < 0.35 else "clover", 1)
		EnemyType.FIRE_IMP:
			if drop_roll < 0.55:
				_spawn_world_item("sulfur", 1)
		EnemyType.SHADOW_IMP:
			if drop_roll < 0.50:
				_spawn_world_item("potion_mana" if randf() < 0.5 else "magic_scroll", 1)

func _spawn_world_item(item_id: String, amount: int = 1, offset: Vector3 = Vector3(0, 0.4, 0)) -> void:
	var item = world_item_scene.instantiate()
	get_parent().add_child(item)
	item.global_position = global_position + offset
	item.setup(item_id, amount)
