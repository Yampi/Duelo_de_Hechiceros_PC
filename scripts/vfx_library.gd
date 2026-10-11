class_name VFXLibrary
extends Node

# Shared procedural textures cache
const TEX_GLOW = preload("res://assets/vfx/textures/glow_soft.png")
const TEX_SPARK = preload("res://assets/vfx/textures/spark_star.png")
const TEX_SMOKE = preload("res://assets/vfx/textures/smoke_noise.png")
const TEX_RING = preload("res://assets/vfx/textures/ring_sharp.png")
const TEX_FLAME = preload("res://assets/vfx/textures/flame_tear.png")
const TEX_SNOWFLAKE = preload("res://assets/vfx/textures/snowflake_crystal.png")
const TEX_LIGHTNING = preload("res://assets/vfx/textures/lightning_flash.png")
const TEX_RUNES = preload("res://assets/vfx/textures/magic_circle_runes.png")
const TEX_MOTE = preload("res://assets/vfx/textures/light_mote.png")
const TEX_SHOCKWAVE = preload("res://assets/vfx/textures/shockwave_ring.png")
const TEX_DUST = preload("res://assets/vfx/textures/dust_puff.png")

# Shaders
const SHADER_SHIELD = preload("res://assets/vfx/shaders/fresnel_shield.gdshader")
const SHADER_DISSOLVE = preload("res://assets/vfx/shaders/dissolve_noise.gdshader")
const SHADER_SCROLLING = preload("res://assets/vfx/shaders/scrolling_energy.gdshader")
const SHADER_SHOCKWAVE = preload("res://assets/vfx/shaders/shockwave_ring.gdshader")

# Budget limit: maximum 150 particles per effect
const MAX_PARTICLES_PER_EFFECT: int = 150

static func get_reduced_vfx() -> bool:
	return false # Can link to settings manager if configured

static func create_billboard_material(tex: Texture2D, tint: Color = Color.WHITE, additive: bool = true) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.albedo_texture = tex
	mat.albedo_color = tint
	return mat

static func spawn_spark_burst(parent: Node, pos: Vector3, color: Color = Color(0.3, 0.9, 1.0), count: int = 24) -> CPUParticles3D:
	if not parent or not is_instance_valid(parent):
		return null
	var actual_count = int(count * 0.5) if get_reduced_vfx() else count
	actual_count = mini(actual_count, MAX_PARTICLES_PER_EFFECT)
	
	var p = CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.94
	p.amount = actual_count
	p.lifetime = 0.45
	p.spread = 180.0
	p.initial_velocity_min = 3.5
	p.initial_velocity_max = 7.5
	p.gravity = Vector3(0, -5.0, 0)
	
	var quad = QuadMesh.new()
	quad.size = Vector2(0.22, 0.22)
	quad.material = create_billboard_material(TEX_SPARK, color, true)
	p.mesh = quad
	
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.get_tree().create_timer(0.7).timeout.connect(p.queue_free)
	return p

static func spawn_ground_runes(parent: Node, pos: Vector3, color: Color = Color(0.7, 0.2, 1.0), radius: float = 2.4, duration: float = 2.0) -> Node3D:
	if not parent or not is_instance_valid(parent):
		return null
	
	var root = Node3D.new()
	var mesh_inst = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(radius * 2.0, radius * 2.0)
	quad.orientation = PlaneMesh.FACE_Y
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = TEX_RUNES
	mat.albedo_color = color
	quad.material = mat
	mesh_inst.mesh = quad
	
	root.add_child(mesh_inst)
	parent.add_child(root)
	root.global_position = pos + Vector3(0, 0.04, 0)
	
	# Animate spin and fade
	var tween = root.create_tween()
	tween.tween_property(mesh_inst, "rotation:y", PI * 1.5, duration)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	tween.tween_callback(root.queue_free)
	return root

static func spawn_shockwave_ring(parent: Node, pos: Vector3, color: Color = Color(1.0, 0.85, 0.3), max_radius: float = 4.5, duration: float = 0.45) -> MeshInstance3D:
	if not parent or not is_instance_valid(parent):
		return null
		
	var mesh_inst = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(max_radius * 2.0, max_radius * 2.0)
	quad.orientation = PlaneMesh.FACE_Y
	
	var mat = ShaderMaterial.new()
	mat.shader = SHADER_SHOCKWAVE
	mat.set_shader_parameter("inner_color", color * Color(1, 1, 1, 0.6))
	mat.set_shader_parameter("rim_color", Color(1.0, 1.0, 0.8, 1.0))
	mat.set_shader_parameter("ring_progress", 0.0)
	mat.set_shader_parameter("ring_thickness", 0.14)
	mesh_inst.mesh = quad
	mesh_inst.material_override = mat
	
	parent.add_child(mesh_inst)
	mesh_inst.global_position = pos + Vector3(0, 0.05, 0)
	
	var tween = mesh_inst.create_tween()
	tween.tween_method(func(val): mat.set_shader_parameter("ring_progress", val), 0.0, 1.0, duration)
	tween.tween_callback(mesh_inst.queue_free)
	return mesh_inst
