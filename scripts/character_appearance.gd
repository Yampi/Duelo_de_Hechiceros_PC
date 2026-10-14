class_name CharacterAppearance
extends RefCounted

const CONFIG_PATH = "user://character_appearance.cfg"
const FACE_SHADER = preload("res://shaders/wizard_face.gdshader")
const BODY_SHADER = preload("res://shaders/wizard_body.gdshader")

# --- OPCIONES DE PERSONALIZACIÓN ---
const SKIN_TONES = [
	{ "id": "skin_fair", "name": "Claro Clásico", "color": Color(0.96, 0.82, 0.72) },
	{ "id": "skin_tan", "name": "Bronceado Solar", "color": Color(0.82, 0.63, 0.48) },
	{ "id": "skin_pale", "name": "Místico Pálido", "color": Color(0.88, 0.90, 0.96) },
	{ "id": "skin_dark", "name": "Oscuro Ébano", "color": Color(0.42, 0.30, 0.22) },
	{ "id": "skin_golden", "name": "Dorado Arcano", "color": Color(0.92, 0.76, 0.42) },
	{ "id": "skin_elven", "name": "Noche Élfica", "color": Color(0.55, 0.60, 0.82) }
]

const EYE_COLORS = [
	{ "id": "eye_arcane", "name": "Arcano Celeste", "color": Color(0.20, 0.75, 1.0) },
	{ "id": "eye_fire", "name": "Fuego Carmesí", "color": Color(1.0, 0.35, 0.10) },
	{ "id": "eye_emerald", "name": "Esmeralda Druídico", "color": Color(0.20, 0.90, 0.40) },
	{ "id": "eye_void", "name": "Vacío Amatista", "color": Color(0.80, 0.30, 0.95) },
	{ "id": "eye_sun", "name": "Divino Solar", "color": Color(1.0, 0.90, 0.30) },
	{ "id": "eye_shadow", "name": "Sombra Abisal", "color": Color(0.35, 0.35, 0.45) }
]

const EYE_SHAPES = [
	{ "id": "shape_classic", "name": "Sabio Clásico", "desc": "Pupila redonda tradicional, serena y noble." },
	{ "id": "shape_draconic", "name": "Dracónico / Felino", "desc": "Hendidura vertical rasgada de bestia arcana." },
	{ "id": "shape_star", "name": "Estrella Cósmica", "desc": "Cruz celestial de cuatro puntas estelares." },
	{ "id": "shape_eclipse", "name": "Eclipse Rúnico", "desc": "Halo exterior brillante con núcleo abisal oscuro." },
	{ "id": "shape_orb", "name": "Orbe Elemental", "desc": "Resplandor puro y ceguera mística sin pupila." },
	{ "id": "shape_vortex", "name": "Vórtice Hipnótico", "desc": "Espiral concéntrica de energía del vacío." }
]

const HAIR_COLORS = [
	{ "id": "hair_silver", "name": "Canoso Plateado", "color": Color(1.0, 1.0, 1.0) },
	{ "id": "hair_black", "name": "Negro Azabache", "color": Color(0.22, 0.22, 0.25) },
	{ "id": "hair_brown", "name": "Castaño Sabio", "color": Color(0.48, 0.32, 0.20) },
	{ "id": "hair_blonde", "name": "Rubio Arcano", "color": Color(0.92, 0.82, 0.50) },
	{ "id": "hair_copper", "name": "Fuego Cobrizo", "color": Color(0.78, 0.35, 0.18) },
	{ "id": "hair_astral", "name": "Celeste Astral", "color": Color(0.45, 0.70, 0.95) }
]

const BEARD_STYLES = [
	{ "id": "beard_archmage", "name": "Archimago Venerable", "desc": "Barba y bigote largos tradicionales del maestro arcano." },
	{ "id": "beard_trimmed", "name": "Barba Recortada", "desc": "Vello facial recortado de hechicero de combate." },
	{ "id": "beard_compact", "name": "Barba Corta / Compacta", "desc": "Perfil pulido y recogido de adepto activo." }
]

const ROBE_COLORS = [
	{ "id": "robe_cornelius", "name": "Cornelius Real (Azul)", "color": Color(0.12, 0.22, 0.65) },
	{ "id": "robe_pyro", "name": "Piromante (Carmesí)", "color": Color(0.72, 0.15, 0.12) },
	{ "id": "robe_druid", "name": "Druida (Esmeralda)", "color": Color(0.14, 0.55, 0.25) },
	{ "id": "robe_shadow", "name": "Obsidiana (Sombra)", "color": Color(0.15, 0.15, 0.20) },
	{ "id": "robe_gold", "name": "Arcano (Oro Real)", "color": Color(0.85, 0.68, 0.20) },
	{ "id": "robe_white", "name": "Sabio Blanco (Marfil)", "color": Color(0.88, 0.86, 0.82) },
	{ "id": "robe_necro", "name": "Nigromante (Amatista)", "color": Color(0.42, 0.16, 0.52) },
	{ "id": "robe_frost", "name": "Glacial (Escarcha)", "color": Color(0.35, 0.65, 0.85) }
]

const TRIM_COLORS = [
	{ "id": "trim_gold", "name": "Oro Ancestral", "color": Color(0.90, 0.75, 0.30) },
	{ "id": "trim_silver", "name": "Plata Élfica", "color": Color(0.80, 0.85, 0.92) },
	{ "id": "trim_bronze", "name": "Bronce Titán", "color": Color(0.70, 0.45, 0.25) },
	{ "id": "trim_amethyst", "name": "Amatista Rúnico", "color": Color(0.65, 0.30, 0.80) },
	{ "id": "trim_iron", "name": "Hierro Forjado", "color": Color(0.25, 0.25, 0.28) }
]

const GEM_COLORS = [
	{ "id": "gem_arcane", "name": "Celeste Arcano", "color": Color(0.20, 0.85, 1.0) },
	{ "id": "gem_inferno", "name": "Inferno Rojo", "color": Color(1.0, 0.25, 0.05) },
	{ "id": "gem_storm", "name": "Rayo Fulgor", "color": Color(1.0, 0.95, 0.25) },
	{ "id": "gem_poison", "name": "Veneno Esmeralda", "color": Color(0.20, 0.90, 0.30) },
	{ "id": "gem_void", "name": "Vacío Cósmico", "color": Color(0.75, 0.20, 0.95) }
]

const EXPRESSION_STYLES = [
	{ "id": "expr_classic", "name": "Sabio Clásico", "desc": "Sereno y centrado en los arcanos." },
	{ "id": "expr_illuminated", "name": "Místico Iluminado", "desc": "Brillo arcano intenso en la mirada." },
	{ "id": "expr_adept", "name": "Adepto Joven", "desc": "Mirada ágil y semblante audaz." },
	{ "id": "expr_archmage", "name": "Archimago Cósmico", "desc": "Aura rúnica profunda y poder estelar." }
]

static func get_default_config() -> Dictionary:
	return {
		"character_name": "Cornelius",
		"skin_tone_idx": 0,
		"eye_type_idx": 0,
		"eye_shape_idx": 0,
		"hair_color_idx": 0,
		"beard_style_idx": 0,
		"robe_color_idx": 0,
		"trim_color_idx": 0,
		"staff_gem_idx": 0,
		"expression_idx": 0
	}

static func load_config() -> Dictionary:
	var cfg = ConfigFile.new()
	var err = cfg.load(CONFIG_PATH)
	if err != OK:
		return get_default_config()
	
	var res = get_default_config()
	res["character_name"] = cfg.get_value("appearance", "character_name", res["character_name"])
	res["skin_tone_idx"] = clampi(cfg.get_value("appearance", "skin_tone_idx", res["skin_tone_idx"]), 0, SKIN_TONES.size() - 1)
	res["eye_type_idx"] = clampi(cfg.get_value("appearance", "eye_type_idx", res["eye_type_idx"]), 0, EYE_COLORS.size() - 1)
	res["eye_shape_idx"] = clampi(cfg.get_value("appearance", "eye_shape_idx", res["eye_shape_idx"]), 0, EYE_SHAPES.size() - 1)
	res["hair_color_idx"] = clampi(cfg.get_value("appearance", "hair_color_idx", res["hair_color_idx"]), 0, HAIR_COLORS.size() - 1)
	res["beard_style_idx"] = clampi(cfg.get_value("appearance", "beard_style_idx", res["beard_style_idx"]), 0, BEARD_STYLES.size() - 1)
	res["robe_color_idx"] = clampi(cfg.get_value("appearance", "robe_color_idx", res["robe_color_idx"]), 0, ROBE_COLORS.size() - 1)
	res["trim_color_idx"] = clampi(cfg.get_value("appearance", "trim_color_idx", res["trim_color_idx"]), 0, TRIM_COLORS.size() - 1)
	res["staff_gem_idx"] = clampi(cfg.get_value("appearance", "staff_gem_idx", res["staff_gem_idx"]), 0, GEM_COLORS.size() - 1)
	res["expression_idx"] = clampi(cfg.get_value("appearance", "expression_idx", res["expression_idx"]), 0, EXPRESSION_STYLES.size() - 1)
	return res

static func save_config(data: Dictionary) -> bool:
	var cfg = ConfigFile.new()
	for k in data:
		cfg.set_value("appearance", k, data[k])
	var err = cfg.save(CONFIG_PATH)
	return err == OK

static func apply_to_model(root_node: Node, config: Dictionary = {}) -> void:
	if config.is_empty():
		config = load_config()
	
	var skin_col: Color = SKIN_TONES[config.get("skin_tone_idx", 0)]["color"]
	var eye_col: Color = EYE_COLORS[config.get("eye_type_idx", 0)]["color"]
	var eye_shape_idx: int = config.get("eye_shape_idx", 0)
	var hair_col: Color = HAIR_COLORS[config.get("hair_color_idx", 0)]["color"]
	var beard_style_idx: int = config.get("beard_style_idx", 0)
	var robe_col: Color = ROBE_COLORS[config.get("robe_color_idx", 0)]["color"]
	var trim_col: Color = TRIM_COLORS[config.get("trim_color_idx", 0)]["color"]
	var gem_col: Color = GEM_COLORS[config.get("staff_gem_idx", 0)]["color"]
	var expr_idx: int = config.get("expression_idx", 0)
	
	var wiz_tex = load("res://assets/characters/wizard/Wizard_Texture.png")
	var staff_tex = load("res://assets/characters/wizard/Wizard_Staff_Texture.png")
	
	# Material de Túnica / Ropa y Piel corporal (mediante Shader para desacoplar color de túnica y piel)
	var body_mat = ShaderMaterial.new()
	body_mat.shader = BODY_SHADER
	if wiz_tex:
		body_mat.set_shader_parameter("albedo_texture", wiz_tex)
	body_mat.set_shader_parameter("robe_color", robe_col)
	body_mat.set_shader_parameter("skin_color", skin_col)
	body_mat.set_shader_parameter("hair_color", hair_col)
	body_mat.set_shader_parameter("trim_color", trim_col)
	
	# Material de Rostro / Piel y Ojos Místicos mediante Shader en geometría nativa
	var face_mat = ShaderMaterial.new()
	face_mat.shader = FACE_SHADER
	if wiz_tex:
		face_mat.set_shader_parameter("albedo_texture", wiz_tex)
	face_mat.set_shader_parameter("skin_color", skin_col)
	face_mat.set_shader_parameter("eye_color", eye_col)
	face_mat.set_shader_parameter("hair_color", hair_col)
	face_mat.set_shader_parameter("eye_shape", eye_shape_idx)
	face_mat.set_shader_parameter("beard_trim", beard_style_idx)
	var emission_energy: float = 3.6
	if expr_idx == 1:
		emission_energy = 5.2 # Místico Iluminado
	elif expr_idx == 2:
		emission_energy = 3.2 # Adepto Joven
	elif expr_idx == 3:
		emission_energy = 6.2 # Archimago Cósmico
	face_mat.set_shader_parameter("eye_emission_energy", emission_energy)
	face_mat.set_shader_parameter("expression_style", expr_idx)
	
	# Material de Hombreras, Bolsas y Acentos Metálicos
	var trim_mat = StandardMaterial3D.new()
	if wiz_tex:
		trim_mat.albedo_texture = wiz_tex
	trim_mat.albedo_color = trim_col
	trim_mat.roughness = 0.35
	trim_mat.metallic = 0.6
	trim_mat.rim_enabled = true
	trim_mat.rim = 0.5
	
	# Material de Bastón
	var staff_mat = StandardMaterial3D.new()
	if staff_tex:
		staff_mat.albedo_texture = staff_tex
	staff_mat.roughness = 0.5
	
	# Material de Gema mágica
	var gem_mat = StandardMaterial3D.new()
	gem_mat.albedo_color = gem_col
	gem_mat.emission_enabled = true
	gem_mat.emission = gem_col
	gem_mat.emission_energy_multiplier = 3.0
	
	# Aplicar a los MeshInstances correspondientes
	for child in root_node.find_children("*", "MeshInstance3D", true, false):
		var mesh_name = child.name
		if mesh_name == "Face":
			child.material_override = face_mat
			# Limpiar cualquier nodo auxiliar residual previo
			var old_eyes = child.get_node_or_null("WizardEyes")
			if old_eyes:
				old_eyes.queue_free()
			# Ajuste sutil de escala según porte
			if expr_idx == 2:
				child.scale = Vector3(0.96, 1.02, 0.98)
			else:
				child.scale = Vector3.ONE
		elif mesh_name in ["ShoulderPad_L", "ShoulderPad_R", "Pouch"]:
			child.material_override = trim_mat
		elif mesh_name == "Wizard_Staff":
			child.material_override = staff_mat
		elif mesh_name == "Gem":
			child.material_override = gem_mat
		elif mesh_name in ["Wizard_001", "Wizard", "Mannequin"]:
			child.material_override = body_mat
	
	# Actualizar luz del bastón si existe
	for light in root_node.find_children("*", "OmniLight3D", true, false):
		if light.name == "StaffLight":
			light.light_color = gem_col
			light.light_energy = 0.45
			light.omni_range = 1.8


