class_name ArcaneShield
extends Node3D

@export var duration: float = 7.5
@export var follow_target: Node3D = null

@onready var shield_mesh: MeshInstance3D = $ShieldMesh
@onready var edge_ring: MeshInstance3D = $EdgeRing
@onready var light: OmniLight3D = $OmniLight3D

var time_alive: float = 0.0
var life_timer: float:
	get: return max(0.0, duration - time_alive)
var is_deactivating: bool = false
var gyro_ring: MeshInstance3D = null

func _ready() -> void:
	if shield_mesh and shield_mesh.mesh and shield_mesh.mesh.material:
		shield_mesh.material_override = shield_mesh.mesh.material.duplicate()
		var mat = shield_mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color.a = 0.55
	
	# Create secondary gyroscopic ring dynamically
	gyro_ring = MeshInstance3D.new()
	if edge_ring and edge_ring.mesh:
		gyro_ring.mesh = edge_ring.mesh
	gyro_ring.rotation_degrees = Vector3(90, 45, 0)
	add_child(gyro_ring)

func activate(target: Node3D, dur: float = 7.5) -> void:
	follow_target = target
	duration = dur
	if follow_target:
		global_position = follow_target.global_position + Vector3(0, 0.9, 0)
	
	# Activation pulse
	scale = Vector3(0.1, 0.1, 0.1)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if light:
		tween.tween_property(light, "light_energy", 3.5, 0.28)

func _process(delta: float) -> void:
	if follow_target and is_instance_valid(follow_target):
		global_position = follow_target.global_position + Vector3(0, 0.9, 0)
	
	time_alive += delta
	
	# Energetic rotation & breathing shimmer
	if shield_mesh:
		shield_mesh.rotate_y(delta * 1.5)
	if edge_ring:
		edge_ring.rotate_y(delta * -2.2)
		var breathe = 1.0 + sin(time_alive * 6.0) * 0.04
		edge_ring.scale = Vector3(breathe, breathe, breathe)
	if gyro_ring:
		gyro_ring.rotate_x(delta * 2.8)
		gyro_ring.rotate_z(delta * 1.4)
	
	if time_alive >= duration and not is_deactivating:
		deactivate()

func absorb_hit() -> void:
	# Visual reaction upon receiving impacts
	var tween = create_tween()
	scale = Vector3(1.22, 1.22, 1.22)
	if light:
		light.light_energy = 8.0
	
	var smat = shield_mesh.material_override as ShaderMaterial if shield_mesh else null
	if smat:
		smat.set_shader_parameter("hit_intensity", 3.0)
		var hit_tween = create_tween()
		hit_tween.tween_method(func(val): smat.set_shader_parameter("hit_intensity", val), 3.0, 0.0, 0.35)
	
	var mat = shield_mesh.material_override as StandardMaterial3D if shield_mesh else null
	if mat:
		mat.emission_energy_multiplier = 4.0
	
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	if light:
		tween.tween_property(light, "light_energy", 3.5, 0.22)
	if mat:
		tween.tween_property(mat, "emission_energy_multiplier", 1.2, 0.22)

func deactivate() -> void:
	if is_deactivating:
		return
	is_deactivating = true
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector3(1.3, 1.3, 1.3), 0.22)
	
	var smat = shield_mesh.material_override as ShaderMaterial if shield_mesh else null
	if smat:
		var col = smat.get_shader_parameter("shield_color")
		if col is Color:
			var fade_tween = create_tween()
			fade_tween.tween_method(func(a): smat.set_shader_parameter("shield_color", Color(col.r, col.g, col.b, a)), col.a, 0.0, 0.22)
	
	var mat = shield_mesh.material_override as StandardMaterial3D if shield_mesh else null
	if mat:
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.22)
	if light:
		tween.tween_property(light, "light_energy", 0.0, 0.22)
	
	await tween.finished
	queue_free()
