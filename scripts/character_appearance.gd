class_name CharacterAppearance
extends RefCounted

const CONFIG_PATH = "user://character_appearance.cfg"

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
	var robe_col: Color = ROBE_COLORS[config.get("robe_color_idx", 0)]["color"]
	var trim_col: Color = TRIM_COLORS[config.get("trim_color_idx", 0)]["color"]
	var gem_col: Color = GEM_COLORS[config.get("staff_gem_idx", 0)]["color"]
	var expr_idx: int = config.get("expression_idx", 0)
	
	var wiz_tex = load("res://assets/characters/wizard/Wizard_Texture.png")
	var staff_tex = load("res://assets/characters/wizard/Wizard_Staff_Texture.png")
	
	# Material de Túnica / Ropa
	var robe_mat = StandardMaterial3D.new()
	if wiz_tex:
		robe_mat.albedo_texture = wiz_tex
	robe_mat.albedo_color = robe_col
	robe_mat.roughness = 0.55
	robe_mat.rim_enabled = true
	robe_mat.rim = 0.6
	robe_mat.rim_tint = 0.35
	
	# Material de Rostro / Piel con brillo de mirada
	var face_mat = StandardMaterial3D.new()
	if wiz_tex:
		face_mat.albedo_texture = wiz_tex
	face_mat.albedo_color = skin_col
	face_mat.roughness = 0.65
	face_mat.rim_enabled = true
	face_mat.rim = 0.75
	face_mat.rim_tint = 0.4
	face_mat.emission_enabled = true
	var emission_mult = 0.4 if expr_idx == 1 or expr_idx == 3 else 0.15
	face_mat.emission = eye_col * emission_mult
	
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
			child.material_override = robe_mat
	
	# Actualizar luz del bastón si existe
	for light in root_node.find_children("*", "OmniLight3D", true, false):
		if light.name == "StaffLight":
			light.light_color = gem_col
			light.light_energy = 2.5
