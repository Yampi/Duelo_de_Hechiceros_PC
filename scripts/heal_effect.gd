extends Node3D

@onready var ring: MeshInstance3D = $Ring
@onready var pillar: MeshInstance3D = $LightPillar
@onready var glimmer: CPUParticles3D = $RisingGlimmer
@onready var light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(1.6, 1.6, 1.6), 0.7)
	tween.tween_property(ring, "position:y", 1.8, 0.7)
	tween.tween_property(pillar, "scale", Vector3(1.2, 1.0, 1.2), 0.7)
	
	if ring.mesh and ring.mesh.material:
		ring.material_override = ring.mesh.material.duplicate()
		var rmat = ring.material_override as StandardMaterial3D
		if rmat:
			rmat.albedo_color.a = 0.85
			tween.tween_property(rmat, "albedo_color:a", 0.0, 0.7)
	
	if pillar.mesh and pillar.mesh.material:
		pillar.material_override = pillar.mesh.material.duplicate()
		var pmat = pillar.material_override as StandardMaterial3D
		if pmat:
			pmat.albedo_color.a = 0.3
			tween.tween_property(pmat, "albedo_color:a", 0.0, 0.7)
	
	if light:
		tween.tween_property(light, "light_energy", 0.0, 0.7)
	
	await tween.finished
	queue_free()
