extends Node3D

@export var damage: float = 45.0
@export var path_damage: float = 35.0
@export var chain_damage: float = 28.0
@export var lifetime: float = 0.35
@export var path_hit_radius: float = 1.4
@export var endpoint_radius: float = 2.8
@export var chain_radius: float = 6.0
@export var max_chains: int = 2

@onready var spark_particles: CPUParticles3D = $SparkParticles
@onready var light: OmniLight3D = $OmniLight3D
@onready var bolt_mesh_inst: MeshInstance3D = $BoltMesh

var hit_targets: Array[Node] = []

func init_lightning(start_pos: Vector3, target_pos: Vector3) -> void:
	global_position = start_pos
	
	# Create multi-mesh ribbons (White core quads + Cyan electric halo)
	var main_mesh = ArrayMesh.new()
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate zigzag points for main bolt
	var segments = 12
	var main_vec = target_pos - start_pos
	var main_dist = main_vec.length()
	var main_dir = main_vec.normalized()
	
	var points: Array[Vector3] = [Vector3.ZERO]
	var jitter_scale = clamp(main_dist * 0.05, 0.25, 0.65)
	
	for i in range(1, segments):
		var frac = float(i) / float(segments)
		var base_pt = main_vec * frac
		# Calculate orthogonal jitter
		var rand_offset = Vector3(randf_range(-1, 1), randf_range(-0.6, 0.8), randf_range(-1, 1))
		var ortho = (rand_offset - (main_dir * rand_offset.dot(main_dir))).normalized() * jitter_scale * randf_range(0.4, 1.0)
		points.append(base_pt + ortho)
	points.append(main_vec)
	
	# Build 3D cross-quad ribbons along path for core and halo
	_add_ribbon_to_surface(surface_tool, points, 0.12, Color(1.0, 1.0, 1.0, 1.0)) # White Core
	_add_ribbon_to_surface(surface_tool, points, 0.38, Color(0.25, 0.75, 1.0, 0.55)) # Arcane Blue Halo
	
	# Secondary fork branches
	for i in range(2, segments - 2, 3):
		var branch_origin = points[i]
		var fork_dir = (main_dir + Vector3(randf_range(-0.7, 0.7), randf_range(-0.5, 0.5), randf_range(-0.7, 0.7))).normalized()
		var fork_len = randf_range(1.2, 2.4)
		var fork_pts: Array[Vector3] = [branch_origin]
		fork_pts.append(branch_origin + fork_dir * (fork_len * 0.5) + Vector3(randf_range(-0.2, 0.2), 0.2, randf_range(-0.2, 0.2)))
		fork_pts.append(branch_origin + fork_dir * fork_len)
		_add_ribbon_to_surface(surface_tool, fork_pts, 0.07, Color(1.0, 1.0, 1.0, 0.9))
		_add_ribbon_to_surface(surface_tool, fork_pts, 0.24, Color(0.2, 0.65, 1.0, 0.45))
	
	# Target impact point and primary damage
	var enemies = get_tree().get_nodes_in_group("enemy")
	var primary_hit: Node = null
	
	# 1. Damage along the trajectory path (segment distance test)
	for e in enemies:
		if is_instance_valid(e) and e.is_inside_tree() and not e.get("is_dead"):
			var d_seg = _dist_to_segment(e.global_position, start_pos, target_pos)
			if d_seg <= path_hit_radius:
				if not e in hit_targets:
					hit_targets.append(e)
					if e.has_method("take_damage"):
						var knock = (e.global_position - start_pos).normalized() * 8.0
						e.take_damage(path_damage, knock, "lightning")
					if e.has_method("apply_stun"):
						e.apply_stun(0.4)
	
	# 2. Damage at endpoint target area
	for e in enemies:
		if is_instance_valid(e) and e.is_inside_tree() and not e.get("is_dead"):
			var d_end = e.global_position.distance_to(target_pos)
			if d_end <= endpoint_radius:
				if not e in hit_targets:
					hit_targets.append(e)
					primary_hit = e
					if e.has_method("take_damage"):
						var knock = (e.global_position - target_pos).normalized() * 12.0
						e.take_damage(damage, knock, "lightning")
					if e.has_method("apply_stun"):
						e.apply_stun(0.4)
				elif primary_hit == null:
					primary_hit = e
	
	# 3. Chain lightning to 1-2 nearby enemies
	var chain_origin = primary_hit.global_position if (primary_hit and is_instance_valid(primary_hit)) else target_pos
	var chained_count = 0
	
	for e in enemies:
		if chained_count >= max_chains:
			break
		if is_instance_valid(e) and e.is_inside_tree() and not e.get("is_dead") and not e in hit_targets:
			var d = e.global_position.distance_to(chain_origin)
			if d <= chain_radius and d > 0.4:
				chained_count += 1
				hit_targets.append(e)
				
				# Generate secondary chain ribbon from chain_origin to enemy
				var chain_start_local = chain_origin - start_pos
				var chain_target_local = e.global_position + Vector3(0, 0.8, 0) - start_pos
				var chain_pts: Array[Vector3] = [chain_start_local]
				var mid = chain_start_local.lerp(chain_target_local, 0.5) + Vector3(randf_range(-0.4, 0.4), randf_range(0.2, 0.5), randf_range(-0.4, 0.4))
				chain_pts.append(mid)
				chain_pts.append(chain_target_local)
				_add_ribbon_to_surface(surface_tool, chain_pts, 0.09, Color(1.0, 1.0, 1.0, 0.95))
				_add_ribbon_to_surface(surface_tool, chain_pts, 0.28, Color(0.3, 0.8, 1.0, 0.5))
				
				if e.has_method("take_damage"):
					var knock = (e.global_position - chain_origin).normalized() * 7.0
					e.take_damage(chain_damage, knock, "lightning")
				if e.has_method("apply_stun"):
					e.apply_stun(0.4)
				GameManager.spawn_damage_number(e.global_position, "⚡ ¡ENLACE!", Color(0.4, 0.85, 1.0), 1.1)
	
	# Material and commit
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	surface_tool.set_material(mat)
	surface_tool.commit(main_mesh)
	
	if bolt_mesh_inst:
		bolt_mesh_inst.mesh = main_mesh
	
	# Visual feedback if spell failed to hit any enemy
	if hit_targets.is_empty():
		GameManager.spawn_damage_number(target_pos + Vector3(0, 0.6, 0), "⚡ Descarga al suelo", Color(0.65, 0.75, 0.85), 1.0)
	
	# Target impact flash and spark particles
	if light:
		light.global_position = target_pos + Vector3(0, 0.8, 0)
		light.light_energy = 9.5
	
	if spark_particles:
		spark_particles.global_position = target_pos
		spark_particles.emitting = true
	
	# Ground electric scorch decal/ring
	var ground_ring = MeshInstance3D.new()
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.5
	ring_mesh.outer_radius = 0.85
	var r_mat = StandardMaterial3D.new()
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r_mat.albedo_color = Color(0.7, 0.92, 1.0, 0.9)
	ground_ring.mesh = ring_mesh
	ground_ring.material_override = r_mat
	add_child(ground_ring)
	ground_ring.global_position = target_pos + Vector3(0, 0.05, 0)
	ground_ring.scale = Vector3(0.2, 0.2, 0.2)
	
	var r_tween = create_tween().set_parallel(true)
	r_tween.tween_property(ground_ring, "scale", Vector3(2.6, 1.0, 2.6), lifetime)
	r_tween.tween_property(r_mat, "albedo_color:a", 0.0, lifetime)
	
	# Animate lightning fade and flicker
	var tween = create_tween().set_parallel(true)
	if light:
		tween.tween_property(light, "light_energy", 0.0, lifetime)
	if bolt_mesh_inst:
		tween.tween_property(mat, "albedo_color:a", 0.0, lifetime)
	
	get_tree().create_timer(lifetime + 0.08).timeout.connect(queue_free)

func _add_ribbon_to_surface(st: SurfaceTool, pts: Array[Vector3], width: float, color: Color) -> void:
	if pts.size() < 2:
		return
	
	var half_w = width * 0.5
	# Create ribbons in two orthogonal planes (cross-quads) for 3D visibility from all camera angles
	for plane_idx in range(2):
		for i in range(pts.size() - 1):
			var p1 = pts[i]
			var p2 = pts[i + 1]
			var seg_dir = (p2 - p1).normalized()
			
			var normal_plane = Vector3.UP if plane_idx == 0 else Vector3.RIGHT
			if abs(seg_dir.dot(normal_plane)) > 0.9:
				normal_plane = Vector3.FORWARD
			
			var side = seg_dir.cross(normal_plane).normalized() * half_w
			
			var v1 = p1 - side
			var v2 = p1 + side
			var v3 = p2 + side
			var v4 = p2 - side
			
			st.set_color(color)
			st.add_vertex(v1)
			st.set_color(color)
			st.add_vertex(v2)
			st.set_color(color)
			st.add_vertex(v3)
			
			st.set_color(color)
			st.add_vertex(v1)
			st.set_color(color)
			st.add_vertex(v3)
			st.set_color(color)
			st.add_vertex(v4)

func _dist_to_segment(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab = b - a
	var ab_len_sq = ab.length_squared()
	if ab_len_sq < 0.0001:
		return p.distance_to(a)
	var t = clamp((p - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	var proj = a + ab * t
	return p.distance_to(proj)
