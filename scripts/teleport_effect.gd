extends Node3D

@onready var distortion_ring: MeshInstance3D = $DistortionRing
@onready var core_motes: CPUParticles3D = $CoreMotes
@onready var light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	# Dimensional implosion then explosion
	scale = Vector3(1.5, 0.2, 1.5)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector3(0.1, 2.5, 0.1), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_property(self, "scale", Vector3(2.0, 0.1, 2.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if distortion_ring and distortion_ring.mesh and distortion_ring.mesh.material:
		distortion_ring.material_override = distortion_ring.mesh.material.duplicate()
		var mat = distortion_ring.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color.a = 0.85
			tween.tween_property(mat, "albedo_color:a", 0.0, 0.4)
	
	if light:
		tween.tween_property(light, "light_energy", 0.0, 0.38)
	
	get_tree().create_timer(0.45).timeout.connect(queue_free)
