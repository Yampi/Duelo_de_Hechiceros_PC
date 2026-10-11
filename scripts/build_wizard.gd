extends Node

func _ready() -> void:
	print("--- Building Quaternius Wizard Model & Scene ---")
	
	# 1. Load Wizard.fbx
	var wiz_fbx_scene = load("res://assets/characters/wizard/Wizard.fbx") as PackedScene
	var wiz_model = wiz_fbx_scene.instantiate()
	wiz_model.name = "Model"
	
	# 2. Extract and duplicate animations into new AnimationLibrary with standard names
	var ap = wiz_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		var orig_lib = ap.get_animation_library("")
		var new_lib = AnimationLibrary.new()
		
		# Copy all existing animations
		for anim_name in orig_lib.get_animation_list():
			var anim = orig_lib.get_animation(anim_name).duplicate()
			new_lib.add_animation(anim_name, anim)
		
		# Add standard canonical animation names
		var mapping = {
			"Idle": "CharacterArmature|Idle",
			"Walk": "CharacterArmature|Walk",
			"Sprint": "CharacterArmature|Run",
			"Spell_Simple_Enter": "CharacterArmature|Spell1",
			"Spell_Simple_Idle": "CharacterArmature|Idle_Attacking",
			"Spell_Simple_Shoot": "CharacterArmature|Spell2",
			"Hit_Chest": "CharacterArmature|RecieveHit",
			"Death01": "CharacterArmature|Death",
			"Staff_Attack": "CharacterArmature|Staff_Attack"
		}
		for alias in mapping:
			var src = mapping[alias]
			if new_lib.has_animation(src):
				new_lib.add_animation(alias, new_lib.get_animation(src).duplicate())
		
		# Save library to disk as resource so it persists in packed scenes
		var lib_path = "res://assets/characters/wizard/wizard_anim_lib.res"
		var save_lib_err = ResourceSaver.save(new_lib, lib_path)
		print("Saved anim lib: ", save_lib_err)
		var saved_lib = load(lib_path) as AnimationLibrary
		ap.remove_animation_library("")
		ap.add_animation_library("", saved_lib)
		print("Animation library rebuilt with %d animations" % saved_lib.get_animation_list().size())
	
	# 3. Setup materials with Quaternius high-resolution textures
	var wiz_tex = load("res://assets/characters/wizard/Wizard_Texture.png") as Texture2D
	var staff_tex = load("res://assets/characters/wizard/Wizard_Staff_Texture.png") as Texture2D
	
	var wizard_mat = StandardMaterial3D.new()
	wizard_mat.albedo_texture = wiz_tex
	wizard_mat.roughness = 0.65
	wizard_mat.rim_enabled = true
	wizard_mat.rim = 0.5
	wizard_mat.rim_tint = 0.3
	
	var staff_mat = StandardMaterial3D.new()
	staff_mat.albedo_texture = staff_tex
	staff_mat.roughness = 0.5
	
	for m in wiz_model.find_children("*", "MeshInstance3D", true, false):
		if m.name == "Wizard_Staff":
			m.material_override = staff_mat
		else:
			m.material_override = wizard_mat
	
	# 4. Attachments on Skeleton3D
	var skel = wiz_model.find_child("Skeleton3D", true, false) as Skeleton3D
	
	var staff_attach = BoneAttachment3D.new()
	staff_attach.name = "StaffAttachment"
	staff_attach.bone_name = "Weapon.R"
	skel.add_child(staff_attach)
	staff_attach.owner = wiz_model
	
	var staff = Node3D.new()
	staff.name = "Staff"
	staff_attach.add_child(staff)
	staff.owner = wiz_model
	
	var gem = MeshInstance3D.new()
	gem.name = "Gem"
	var gem_mesh = SphereMesh.new()
	gem_mesh.radius = 0.11
	gem_mesh.height = 0.22
	gem.mesh = gem_mesh
	gem.position = Vector3(0, 1.15, 0)
	
	var gem_mat = StandardMaterial3D.new()
	gem_mat.albedo_color = Color(0.2, 0.85, 1.0)
	gem_mat.emission_enabled = true
	gem_mat.emission = Color(0.2, 0.85, 1.0)
	gem_mat.emission_energy_multiplier = 4.5
	gem.material_override = gem_mat
	staff.add_child(gem)
	gem.owner = wiz_model
	
	var staff_light = OmniLight3D.new()
	staff_light.name = "StaffLight"
	staff_light.light_color = Color(0.2, 0.85, 1.0)
	staff_light.light_energy = 2.0
	staff_light.omni_range = 3.5
	gem.add_child(staff_light)
	staff_light.owner = wiz_model
	
	var hat_attach = BoneAttachment3D.new()
	hat_attach.name = "HatAttachment"
	hat_attach.bone_name = "Head"
	skel.add_child(hat_attach)
	hat_attach.owner = wiz_model
	
	# Save WizardModel.tscn
	var model_packed = PackedScene.new()
	model_packed.pack(wiz_model)
	ResourceSaver.save(model_packed, "res://assets/characters/wizard/WizardModel.tscn")
	print("Saved WizardModel.tscn successfully")
	
	# 5. Build full Wizard.tscn
	var root = CharacterBody3D.new()
	root.name = "Wizard"
	root.add_to_group("player")
	root.set_script(load("res://scripts/player.gd"))
	
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cap = CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 1.82
	col.shape = cap
	col.position = Vector3(0, 0.91, 0)
	root.add_child(col)
	col.owner = root
	
	var torus = TorusMesh.new()
	torus.inner_radius = 0.65
	torus.outer_radius = 0.75
	var sel_mat = StandardMaterial3D.new()
	sel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sel_mat.albedo_color = Color(0.2, 0.7, 1.0, 0.8)
	sel_mat.emission_enabled = true
	sel_mat.emission = Color(0.2, 0.7, 1.0)
	sel_mat.emission_energy_multiplier = 2.0
	
	var sel = MeshInstance3D.new()
	sel.name = "SelectionRing"
	sel.mesh = torus
	sel.material_override = sel_mat
	sel.position = Vector3(0, 0.02, 0)
	root.add_child(sel)
	sel.owner = root
	
	# Add the model instance
	root.add_child(wiz_model)
	wiz_model.owner = root
	_set_owner_recursive(wiz_model, root)
	
	var aim = Node3D.new()
	aim.name = "AimMarker"
	aim.top_level = true
	root.add_child(aim)
	aim.owner = root
	
	var aim_ring = MeshInstance3D.new()
	aim_ring.name = "AimRing"
	aim_ring.mesh = torus
	aim_ring.material_override = sel_mat
	aim_ring.position = Vector3(0, 0.05, 0)
	aim_ring.scale = Vector3(0.6, 0.6, 0.6)
	aim.add_child(aim_ring)
	aim_ring.owner = root
	
	var root_packed = PackedScene.new()
	root_packed.pack(root)
	ResourceSaver.save(root_packed, "res://scenes/Wizard.tscn")
	print("Saved Wizard.tscn successfully")
	
	get_tree().quit(0)

func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	for child in node.get_children():
		child.owner = new_owner
		_set_owner_recursive(child, new_owner)
