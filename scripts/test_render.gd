extends Node3D

var rogue_tex = preload("res://assets/characters/rogue/Rogue_Texture.png")
var dagger_tex = preload("res://assets/characters/rogue/Rogue_Dagger_Texture.png")
var ranger_tex = preload("res://assets/characters/ranger/Ranger_Texture.png")
var bow_tex = preload("res://assets/characters/ranger/Ranger_Bow_Texture.png")

func _apply_rogue_mat(inst: Node3D) -> void:
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_texture = rogue_tex
	r_mat.albedo_color = Color(0.85, 1.05, 0.85)
	r_mat.roughness = 0.65
	var d_mat = StandardMaterial3D.new()
	d_mat.albedo_texture = dagger_tex
	d_mat.roughness = 0.65
	for m in inst.find_children("*", "MeshInstance3D", true):
		m.material_override = d_mat if m.name == "Rogue_Dagger" else r_mat

func _apply_ranger_mat(inst: Node3D) -> void:
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_texture = ranger_tex
	r_mat.albedo_color = Color(0.9, 0.92, 1.0)
	r_mat.roughness = 0.65
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_texture = bow_tex
	b_mat.roughness = 0.65
	for m in inst.find_children("*", "MeshInstance3D", true):
		m.material_override = b_mat if m.name == "Ranger_Bow" else r_mat

func _apply_bat_mat(inst: Node3D) -> void:
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = Color(1.0, 0.35, 0.1)
	f_mat.emission_enabled = true
	f_mat.emission = Color(1.0, 0.25, 0.0)
	f_mat.emission_energy_multiplier = 1.5
	f_mat.roughness = 0.5
	for m in inst.find_children("*", "MeshInstance3D", true):
		m.material_override = f_mat

func _apply_slime_mat(inst: Node3D) -> void:
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.35, 0.12, 0.55)
	s_mat.emission_enabled = true
	s_mat.emission = Color(0.65, 0.15, 0.95)
	s_mat.emission_energy_multiplier = 1.2
	s_mat.roughness = 0.3
	for m in inst.find_children("*", "MeshInstance3D", true):
		if m.name == "Eyes":
			var eye_mat = StandardMaterial3D.new()
			eye_mat.albedo_color = Color(1.0, 0.85, 0.2)
			eye_mat.emission_enabled = true
			eye_mat.emission = Color(1.0, 0.85, 0.2)
			m.material_override = eye_mat
		else:
			m.material_override = s_mat

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://docs/new_quaternius_enemies")
	
	var cam = Camera3D.new()
	add_child(cam)
	
	var light = DirectionalLight3D.new()
	add_child(light)
	light.rotation_degrees = Vector3(-35, 45, 0)
	light.light_energy = 1.2
	
	var ambient = DirectionalLight3D.new()
	add_child(ambient)
	ambient.rotation_degrees = Vector3(45, -135, 0)
	ambient.light_energy = 0.4
	
	var setups = [
		{
			"name": "0_goblin_rogue",
			"path": "res://assets/characters/rogue/Rogue.fbx",
			"scale": Vector3(0.55, 0.55, 0.55),
			"walk": "CharacterArmature|Walk",
			"attack": "CharacterArmature|Dagger_Attack",
			"cam_pos": Vector3(0, 1.1, 2.4),
			"cam_target": Vector3(0, 0.7, 0),
			"mat_type": "rogue"
		},
		{
			"name": "1_skeleton_warrior",
			"path": "res://assets/characters/monsters/Skeleton.fbx",
			"scale": Vector3(0.38, 0.38, 0.38),
			"walk": "SkeletonArmature|Skeleton_Running",
			"attack": "SkeletonArmature|Skeleton_Attack",
			"cam_pos": Vector3(0, 1.2, 2.5),
			"cam_target": Vector3(0, 0.8, 0),
			"mat_type": "none"
		},
		{
			"name": "2_skeleton_archer",
			"path": "res://assets/characters/ranger/Ranger.fbx",
			"scale": Vector3(0.58, 0.58, 0.58),
			"walk": "CharacterArmature|Walk",
			"attack": "CharacterArmature|Bow_Attack_Shoot",
			"cam_pos": Vector3(0, 1.2, 2.5),
			"cam_target": Vector3(0, 0.8, 0),
			"mat_type": "ranger"
		},
		{
			"name": "3_fire_imp_bat",
			"path": "res://assets/characters/monsters/Bat.fbx",
			"scale": Vector3(0.32, 0.32, 0.32),
			"walk": "BatArmature|Bat_Flying",
			"attack": "BatArmature|Bat_Attack",
			"cam_pos": Vector3(0, 1.0, 2.2),
			"cam_target": Vector3(0, 0.6, 0),
			"mat_type": "bat"
		},
		{
			"name": "4_shadow_imp_slime",
			"path": "res://assets/characters/monsters/Slime.fbx",
			"scale": Vector3(0.60, 0.60, 0.60),
			"walk": "Armature|Slime_Walk",
			"attack": "Armature|Slime_Attack",
			"cam_pos": Vector3(0, 0.8, 2.0),
			"cam_target": Vector3(0, 0.4, 0),
			"mat_type": "slime"
		},
		{
			"name": "5_boss_dragon",
			"path": "res://assets/characters/monsters/Dragon.fbx",
			"scale": Vector3(1.15, 1.15, 1.15),
			"walk": "DragonArmature|Dragon_Flying",
			"attack": "DragonArmature|Dragon_Attack",
			"cam_pos": Vector3(0, 2.5, 6.0),
			"cam_target": Vector3(0, 1.4, 0),
			"mat_type": "none"
		}
	]
	
	for s in setups:
		print("Rendering: ", s["name"])
		var scn = load(s["path"])
		var model = scn.instantiate()
		add_child(model)
		model.rotation.y = PI
		model.scale = s["scale"]
		
		match s["mat_type"]:
			"rogue": _apply_rogue_mat(model)
			"ranger": _apply_ranger_mat(model)
			"bat": _apply_bat_mat(model)
			"slime": _apply_slime_mat(model)
		
		cam.position = s["cam_pos"]
		cam.look_at(s["cam_target"])
		
		var ap = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		
		# 1. Capture Attack pose
		if ap and ap.has_animation(s["attack"]):
			ap.play(s["attack"])
			ap.advance(0.3)
		for f in range(6):
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://docs/new_quaternius_enemies/%s_attack.png" % s["name"])
		
		# 2. Capture Walk pose
		if ap and ap.has_animation(s["walk"]):
			ap.play(s["walk"])
			ap.advance(0.2)
		for f in range(6):
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://docs/new_quaternius_enemies/%s_walk.png" % s["name"])
		
		model.queue_free()
		for f in range(2):
			await get_tree().process_frame
			
	print("ALL NEW QUATERNIUS RENDERS SAVED!")
	get_tree().quit(0)
