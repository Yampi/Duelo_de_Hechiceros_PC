extends Node

func _ready() -> void:
	print("Testing Shockwave twice...")
	var sw_scene = preload("res://scenes/Shockwave.tscn")
	
	print("--- Cast 1 ---")
	var sw1 = sw_scene.instantiate()
	add_child(sw1)
	var rmat1 = sw1.get_node("Ring").mesh.material as StandardMaterial3D
	var dmat1 = sw1.get_node("EnergyDome").mesh.material as StandardMaterial3D
	print("Initial alpha: ring=%.2f, dome=%.2f" % [rmat1.albedo_color.a if rmat1 else -1, dmat1.albedo_color.a if dmat1 else -1])
	
	# Simulate 30 frames
	for f in range(30):
		await get_tree().physics_frame
	
	print("After Cast 1 finished:")
	print("Material in memory: ring=%.2f, dome=%.2f" % [rmat1.albedo_color.a if rmat1 else -1, dmat1.albedo_color.a if dmat1 else -1])
	
	print("--- Cast 2 ---")
	var sw2 = sw_scene.instantiate()
	add_child(sw2)
	var rmat2 = sw2.get_node("Ring").mesh.material as StandardMaterial3D
	var dmat2 = sw2.get_node("EnergyDome").mesh.material as StandardMaterial3D
	var ov_ring = sw2.get_node("Ring").material_override as StandardMaterial3D
	var ov_dome = sw2.get_node("EnergyDome").material_override as StandardMaterial3D
	var ring_alpha = ov_ring.albedo_color.a if ov_ring else (rmat2.albedo_color.a if rmat2 else 0.0)
	var dome_alpha = ov_dome.albedo_color.a if ov_dome else (dmat2.albedo_color.a if dmat2 else 0.0)
	print("Active alpha of Cast 2: ring=%.2f, dome=%.2f" % [ring_alpha, dome_alpha])
	if ring_alpha > 0.01:
		print("✅ SUCCESS: Shockwave repeat cast is fully visible!")
	get_tree().quit(0)
