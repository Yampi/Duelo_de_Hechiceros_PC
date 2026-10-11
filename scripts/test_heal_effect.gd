extends Node

func _ready() -> void:
	print("Testing HealEffect twice...")
	var heal_scene = preload("res://scenes/HealEffect.tscn")
	
	print("--- Cast 1 ---")
	var h1 = heal_scene.instantiate()
	add_child(h1)
	var rmat1 = h1.get_node("Ring").mesh.material as StandardMaterial3D
	var pmat1 = h1.get_node("LightPillar").mesh.material as StandardMaterial3D
	print("Initial alpha: ring=%.2f, pillar=%.2f" % [rmat1.albedo_color.a, pmat1.albedo_color.a])
	
	# Wait for h1 to finish and free
	for f in range(60):
		await get_tree().physics_frame
	
	print("After Cast 1 finished:")
	print("Material in memory: ring=%.2f, pillar=%.2f" % [rmat1.albedo_color.a, pmat1.albedo_color.a])
	
	print("--- Cast 2 ---")
	var h2 = heal_scene.instantiate()
	add_child(h2)
	var rmat2 = h2.get_node("Ring").mesh.material as StandardMaterial3D
	var pmat2 = h2.get_node("LightPillar").mesh.material as StandardMaterial3D
	var ov_ring = h2.get_node("Ring").material_override as StandardMaterial3D
	var ov_pillar = h2.get_node("LightPillar").material_override as StandardMaterial3D
	var ring_alpha = ov_ring.albedo_color.a if ov_ring else rmat2.albedo_color.a
	var pillar_alpha = ov_pillar.albedo_color.a if ov_pillar else pmat2.albedo_color.a
	print("Active alpha on Cast 2: ring=%.2f, pillar=%.2f" % [ring_alpha, pillar_alpha])
	
	if ring_alpha <= 0.01:
		print("🚨 CRITICAL BUG DETECTED: HealEffect ring/pillar is permanently invisible on subsequent casts!")
	else:
		print("✅ SUCCESS: Cast 2 has normal visible alpha (ring=%.2f, pillar=%.2f)" % [ring_alpha, pillar_alpha])
	
	get_tree().quit(0)
