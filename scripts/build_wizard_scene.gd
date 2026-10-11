extends SceneTree

func _init():
	var root = CharacterBody3D.new()
	root.name = "Wizard"
	root.add_to_group("player")
	root.set_script(load("res://scripts/player.gd"))
	
	# CollisionShape3D
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cap = CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 1.82
	col.shape = cap
	col.position = Vector3(0, 0.91, 0)
	root.add_child(col)
	col.owner = root
	
	# SelectionRing
	var sel = MeshInstance3D.new()
	sel.name = "SelectionRing"
	var torus = TorusMesh.new()
	torus.inner_radius = 0.65
	torus.outer_radius = 0.75
	sel.mesh = torus
	var sel_mat = StandardMaterial3D.new()
	sel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sel_mat.albedo_color = Color(0.2, 0.7, 1.0, 0.8)
	sel_mat.emission_enabled = true
	sel_mat.emission = Color(0.2, 0.7, 1.0)
	sel_mat.emission_energy_multiplier = 2.0
	sel.material_override = sel_mat
	sel.position = Vector3(0, 0.02, 0)
	root.add_child(sel)
	sel.owner = root
	
	# Model: instance WizardModel.tscn
	var model_scene = load("res://assets/characters/wizard/WizardModel.tscn")
	var model = model_scene.instantiate()
	model.name = "Model"
	root.add_child(model)
	model.owner = root
	
	# AimMarker
	var aim = Node3D.new()
	aim.name = "AimMarker"
	aim.top_level = true
	var aim_ring = MeshInstance3D.new()
	aim_ring.name = "AimRing"
	aim_ring.mesh = torus
	aim_ring.material_override = sel_mat
	aim_ring.position = Vector3(0, 0.05, 0)
	aim_ring.scale = Vector3(0.6, 0.6, 0.6)
	aim.add_child(aim_ring)
	aim_ring.owner = root
	root.add_child(aim)
	aim.owner = root
	
	var packed = PackedScene.new()
	var err = packed.pack(root)
	print("Pack Wizard: ", err)
	if err == OK:
		var save_err = ResourceSaver.save(packed, "res://scenes/Wizard.tscn")
		print("Saved Wizard.tscn: ", save_err)
	quit(0)
