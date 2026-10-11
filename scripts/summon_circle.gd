extends Node3D

@onready var ground_ring: MeshInstance3D = $GroundRing
@onready var light_beam: MeshInstance3D = $LightBeam
@onready var motes: CPUParticles3D = $SpiralMotes
@onready var light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	# Animate expanding summoning rune ring
	var tween = create_tween().set_parallel(true)
	tween.tween_property(ground_ring, "scale", Vector3(1.0, 1.0, 1.0), 0.35)
	tween.tween_property(ground_ring, "rotation:y", PI * 2.0, 0.75)
	
	# Flash vertical beam of light & spawn summon burst
	get_tree().create_timer(0.2).timeout.connect(func():
		if light_beam:
			light_beam.visible = true
			var beam_tween = create_tween()
			beam_tween.tween_property(light_beam, "scale", Vector3(1.0, 1.0, 1.0), 0.2)
			beam_tween.tween_property(light_beam, "scale", Vector3(0.01, 1.0, 0.01), 0.35)
		if get_parent():
			VFXLibrary.spawn_spark_burst(get_parent(), global_position + Vector3(0, 0.4, 0), Color(0.85, 0.35, 1.0), 20)
	)
	
	# Fade out after 0.8s
	get_tree().create_timer(0.7).timeout.connect(func():
		if motes:
			motes.emitting = false
		var fade_tween = create_tween().set_parallel(true)
		if light:
			fade_tween.tween_property(light, "light_energy", 0.0, 0.35)
		if ground_ring:
			fade_tween.tween_property(ground_ring, "scale", Vector3(0.01, 0.01, 0.01), 0.35)
		get_tree().create_timer(0.4).timeout.connect(queue_free)
	)
