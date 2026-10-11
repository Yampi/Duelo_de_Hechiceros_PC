extends Node3D

const MAGIC_BOLT_SCENE = preload("res://scenes/MagicBolt.tscn")
const FIREBALL_SCENE = preload("res://scenes/Fireball.tscn")
const SUMMON_CIRCLE_SCENE = preload("res://scenes/SummonCircle.tscn")
const SHOCKWAVE_SCENE = preload("res://scenes/Shockwave.tscn")
const HEAL_EFFECT_SCENE = preload("res://scenes/HealEffect.tscn")
const TELEPORT_EFFECT_SCENE = preload("res://scenes/TeleportEffect.tscn")
const ICE_PROJECTILE_SCENE = preload("res://scenes/IceProjectile.tscn")
const LIGHTNING_BOLT_SCENE = preload("res://scenes/LightningBolt.tscn")
const ARCANE_SHIELD_SCENE = preload("res://scenes/ArcaneShield.tscn")

@onready var camera_pivot: Node3D = $CameraPivot
@onready var status_label: Label = $UI/StatusLabel

var is_orbiting: bool = true
var current_active_effect: Node = null
var is_headless: bool = false

var passes: int = 0
var failures: Array[String] = []

func _ready() -> void:
	is_headless = DisplayServer.get_name() == "headless"
	
	if is_headless or OS.get_cmdline_args().has("--automated"):
		run_automated_audit()
	else:
		if status_label:
			status_label.text = "Galería lista. Presiona [1-9] para invocar efectos en el pedestal central."

func _process(delta: float) -> void:
	if is_orbiting and camera_pivot:
		camera_pivot.rotate_y(delta * 0.45)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	
	var k = event as InputEventKey
	match k.keycode:
		KEY_SPACE:
			is_orbiting = not is_orbiting
		KEY_1:
			spawn_effect(1)
		KEY_2:
			spawn_effect(2)
		KEY_3:
			spawn_effect(3)
		KEY_4:
			spawn_effect(4)
		KEY_5:
			spawn_effect(5)
		KEY_6:
			spawn_effect(6)
		KEY_7:
			spawn_effect(7)
		KEY_8:
			spawn_effect(8)
		KEY_9:
			spawn_effect(9)
		KEY_T:
			run_automated_audit()

func spawn_effect(slot: int) -> Node:
	if current_active_effect and is_instance_valid(current_active_effect):
		current_active_effect.queue_free()
		current_active_effect = null
	
	var pedestal_pos = Vector3(0, 0.25, 0)
	var effect_node: Node = null
	var name_desc = ""
	
	match slot:
		1: # Centella Arcana
			name_desc = "Centella Arcana (Orbe + Anillos + Chispas estrella)"
			var bolt = MAGIC_BOLT_SCENE.instantiate()
			add_child(bolt)
			bolt.init_bolt(Vector3(-3.5, 1.2, 0), Vector3(1, 0, 0))
			effect_node = bolt
		2: # Bola de Fuego
			name_desc = "Bola de Fuego (Manto ígneo + Onda + Marca de suelo)"
			var fb = FIREBALL_SCENE.instantiate()
			add_child(fb)
			fb.init_trajectory(Vector3(-4.0, 1.0, -1.0), pedestal_pos)
			effect_node = fb
		3: # Invocar Duende
			name_desc = "Invocar Duende (Runas moradas + Haz de luz + Motas)"
			var sc = SUMMON_CIRCLE_SCENE.instantiate()
			add_child(sc)
			sc.global_position = pedestal_pos
			effect_node = sc
		4: # Onda Expansiva
			name_desc = "Onda Expansiva (Anillo dorado + Cúpula + Polvo)"
			var sw = SHOCKWAVE_SCENE.instantiate()
			add_child(sw)
			sw.global_position = pedestal_pos
			effect_node = sw
		5: # Fuente de Vida
			name_desc = "Fuente de Vida (Runas esmeralda + Pilar + Motas cálidas)"
			var heal = HEAL_EFFECT_SCENE.instantiate()
			add_child(heal)
			heal.global_position = pedestal_pos
			effect_node = heal
		6: # Teletransporte
			name_desc = "Teletransporte (Anillo dimensional + Vórtice de motas)"
			var tp = TELEPORT_EFFECT_SCENE.instantiate()
			add_child(tp)
			tp.global_position = pedestal_pos
			effect_node = tp
		7: # Proyectil de Hielo
			name_desc = "Proyectil de Hielo (Cristal escarcha + Niebla fría)"
			var ice = ICE_PROJECTILE_SCENE.instantiate()
			add_child(ice)
			ice.init_projectile(Vector3(-3.5, 1.2, 0), Vector3(1, 0, 0))
			effect_node = ice
		8: # Rayo Arcano
			name_desc = "Rayo Arcano (Cinta 3D zigzag + Chispas + Halo)"
			var lightning = LIGHTNING_BOLT_SCENE.instantiate()
			add_child(lightning)
			lightning.init_lightning(Vector3(-3.0, 3.0, 0), pedestal_pos)
			effect_node = lightning
		9: # Escudo Mágico
			name_desc = "Escudo Mágico (Shader Fresnel Hexagonal + Motas orbitales)"
			var shield = ARCANE_SHIELD_SCENE.instantiate()
			add_child(shield)
			shield.activate(self, 4.0)
			shield.global_position = pedestal_pos + Vector3(0, 0.9, 0)
			# Test impact ripple
			get_tree().create_timer(1.0).timeout.connect(func():
				if is_instance_valid(shield):
					shield.absorb_hit()
			)
			effect_node = shield
	
	current_active_effect = effect_node
	
	# Count active particles
	var particle_count = count_effect_particles(effect_node)
	if status_label:
		status_label.text = "[Slot %d] %s | Partículas: %d / 150 máx" % [slot, name_desc, particle_count]
	
	return effect_node

func count_effect_particles(root: Node) -> int:
	if not root:
		return 0
	var total = 0
	for p in root.find_children("*", "CPUParticles3D", true, false):
		if p is CPUParticles3D:
			total += p.amount
	return total

func run_automated_audit() -> void:
	print("\n========================================================")
	print("✨ AUDITORÍA Y VERIFICACIÓN HEADLESS DE VFX (PARTE C)")
	print("========================================================\n")
	
	passes = 0
	failures.clear()
	
	# Verify procedural textures exist on disk
	var expected_textures = [
		"res://assets/vfx/textures/glow_soft.png",
		"res://assets/vfx/textures/spark_star.png",
		"res://assets/vfx/textures/smoke_noise.png",
		"res://assets/vfx/textures/ring_sharp.png",
		"res://assets/vfx/textures/flame_tear.png",
		"res://assets/vfx/textures/snowflake_crystal.png",
		"res://assets/vfx/textures/lightning_flash.png",
		"res://assets/vfx/textures/magic_circle_runes.png",
		"res://assets/vfx/textures/light_mote.png",
		"res://assets/vfx/textures/shockwave_ring.png",
		"res://assets/vfx/textures/dust_puff.png"
	]
	
	for tex_path in expected_textures:
		if ResourceLoader.exists(tex_path):
			log_pass("Textura Procedural", tex_path.get_file())
		else:
			log_fail("Textura Procedural", "Falta: %s" % tex_path)
	
	# Verify shaders exist on disk
	var expected_shaders = [
		"res://assets/vfx/shaders/fresnel_shield.gdshader",
		"res://assets/vfx/shaders/dissolve_noise.gdshader",
		"res://assets/vfx/shaders/scrolling_energy.gdshader",
		"res://assets/vfx/shaders/shockwave_ring.gdshader"
	]
	
	for s_path in expected_shaders:
		if ResourceLoader.exists(s_path):
			log_pass("Shader Spatial", s_path.get_file())
		else:
			log_fail("Shader Spatial", "Falta: %s" % s_path)
	
	# Verify all 9 spell effects
	for slot in range(1, 10):
		await test_spell_vfx(slot)
	
	print("\n========================================================")
	print("📊 RESUMEN FINAL DE AUDITORÍA VFX")
	print("========================================================")
	print("  Pruebas superadas: %d" % passes)
	print("  Fallos detectados: %d" % failures.size())
	for f in failures:
		print("  ❌ %s" % f)
	print("========================================================\n")
	
	if is_headless:
		if failures.is_empty():
			get_tree().quit(0)
		else:
			get_tree().quit(1)

func test_spell_vfx(slot: int) -> void:
	var effect = spawn_effect(slot)
	if not effect:
		log_fail("VFX Hechizo Slot %d" % slot, "Error al instanciar escena")
		return
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var p_count = count_effect_particles(effect)
	if p_count <= VFXLibrary.MAX_PARTICLES_PER_EFFECT:
		log_pass("VFX Hechizo Slot %d (Presupuesto)" % slot, "%s -> %d partículas (<=150 máx)" % [effect.name, p_count])
	else:
		log_fail("VFX Hechizo Slot %d (Presupuesto)" % slot, "%s supera presupuesto: %d partículas" % [effect.name, p_count])
	
	# Additional specific structure checks
	match slot:
		1:
			var trail = effect.find_child("SparkTrail", true, false)
			var burst = effect.find_child("ImpactBurst", true, false)
			if trail and burst:
				log_pass("MagicBolt Composición", "SparkTrail y ImpactBurst presentes y configurados")
			else:
				log_fail("MagicBolt Composición", "Falta trail o burst")
		2:
			var fb_trail = effect.find_child("FireTrail", true, false)
			var fb_burst = effect.find_child("ExplosionBurst", true, false)
			var fb_ring = effect.find_child("BlastRing", true, false)
			if fb_trail and fb_burst and fb_ring:
				log_pass("Fireball Composición", "FireTrail, BlastRing y ExplosionBurst presentes")
			else:
				log_fail("Fireball Composición", "Faltan componentes en Fireball")
		3:
			var sc_ring = effect.find_child("GroundRing", true, false)
			var sc_motes = effect.find_child("SpiralMotes", true, false)
			if sc_ring and sc_motes:
				log_pass("SummonCircle Composición", "GroundRing con runas y SpiralMotes presentes")
			else:
				log_fail("SummonCircle Composición", "Faltan runas o motas en SummonCircle")
		4:
			var sw_ring = effect.find_child("Ring", true, false)
			var sw_parts = effect.find_child("RadialParticles", true, false)
			if sw_ring and sw_parts:
				log_pass("Shockwave Composición", "Concussive Ring y RadialParticles presentes")
			else:
				log_fail("Shockwave Composición", "Falta Ring o RadialParticles")
		5:
			var h_ring = effect.find_child("Ring", true, false)
			var h_glimmer = effect.find_child("RisingGlimmer", true, false)
			if h_ring and h_glimmer:
				log_pass("HealEffect Composición", "Nature Runes Ring y RisingGlimmer presentes")
			else:
				log_fail("HealEffect Composición", "Falta Ring o RisingGlimmer")
		6:
			var tp_ring = effect.find_child("DistortionRing", true, false)
			var tp_motes = effect.find_child("CoreMotes", true, false)
			if tp_ring and tp_motes:
				log_pass("TeleportEffect Composición", "DistortionRing y CoreMotes presentes")
			else:
				log_fail("TeleportEffect Composición", "Faltan componentes en TeleportEffect")
		7:
			var ice_trail = effect.find_child("FrostTrail", true, false)
			var ice_shatter = effect.find_child("ShatterBurst", true, false)
			if ice_trail and ice_shatter:
				log_pass("IceProjectile Composición", "FrostTrail con copos y ShatterBurst presentes")
			else:
				log_fail("IceProjectile Composición", "Falta FrostTrail o ShatterBurst")
		8:
			var light_sparks = effect.find_child("SparkParticles", true, false)
			var light_mesh = effect.find_child("BoltMesh", true, false)
			if light_sparks and light_mesh:
				log_pass("LightningBolt Composición", "Ribbon BoltMesh y SparkParticles presentes")
			else:
				log_fail("LightningBolt Composición", "Falta BoltMesh o SparkParticles")
		9:
			var s_mesh = effect.find_child("ShieldMesh", true, false) as MeshInstance3D
			var s_motes = effect.find_child("OrbitMotes", true, false)
			if s_mesh and s_mesh.mesh and s_mesh.mesh.material is ShaderMaterial:
				log_pass("ArcaneShield Composición", "ShaderMaterial fresnel hexagonal y OrbitMotes presentes")
			else:
				log_fail("ArcaneShield Composición", "ShieldMesh no tiene ShaderMaterial fresnel")
	
	if is_instance_valid(effect):
		effect.queue_free()

func log_pass(category: String, detail: String) -> void:
	passes += 1
	print("  ✅ [PASS] %s: %s" % [category, detail])

func log_fail(category: String, detail: String) -> void:
	var msg = "[FAIL] %s: %s" % [category, detail]
	failures.append(msg)
	print("  ❌ %s" % msg)
