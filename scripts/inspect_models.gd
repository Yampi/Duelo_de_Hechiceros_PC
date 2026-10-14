extends Node3D

func check_face_direction(model_path: String, name: String):
	var inst = load(model_path).instantiate()
	add_child(inst)
	# Check Head bone position or Nose bone or face mesh
	var sk = inst.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk:
		var head_idx = sk.find_bone("Head")
		var neck_idx = sk.find_bone("Neck")
		if head_idx != -1 and neck_idx != -1:
			var head_rest = sk.get_bone_rest(head_idx).origin
			var neck_rest = sk.get_bone_rest(neck_idx).origin
			print(name, " Head rest: ", head_rest, " (relative to neck: ", head_rest - neck_rest, ")")
		
		# Also check Nose or Face bone if present
		var nose_idx = sk.find_bone("Nose")
		if nose_idx != -1:
			print(name, " Nose rest: ", sk.get_bone_rest(nose_idx).origin)
	inst.queue_free()

func check_anims(path: String, name: String):
	var inst = load(path).instantiate()
	var ap = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		print("--- ", name, " Animations: ---")
		for anim in ap.get_animation_list():
			print("  ", anim)
	else:
		print("--- ", name, " NO AnimationPlayer found ---")
	inst.queue_free()

func _ready():
	print("\n=== CHECKING GLB ANIMATIONS ===")
	check_anims("res://assets/characters/Imp.glb", "Imp")
	check_anims("res://assets/characters/GoblinAnimated.glb", "GoblinAnimated")
	check_anims("res://assets/characters/skelly/Archer.glb", "Archer")
	check_anims("res://assets/characters/SPK/Spear skeleton.glb", "Spear skeleton")
	get_tree().quit(0)
