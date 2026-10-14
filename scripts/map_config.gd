class_name MapConfig
extends RefCounted

# Centralized Map Dimensions and Spatial Governance
const MAP_SIZE: float = 256.0
const HALF_SIZE: float = 128.0
const WALL_HEIGHT: float = 12.0

# Zone Definitions (Structured from South (+Z) to North (-Z))
enum ZoneId {
	PRADERA_INICIAL = 1,
	BOSQUE_EXTERIOR = 2,
	CORAZON_BOSQUE = 3,
	RUINAS_ARCANAS = 4
}

const ZONE_BOUNDS = {
	ZoneId.PRADERA_INICIAL: {
		"name": "Pradera Inicial",
		"title": "🌿 ZONA 1: PRADERA ARCADIA",
		"subtitle": "Valle abierto y seguro — Aprende a moverte y canalizar",
		"min_z": 64.0,
		"max_z": 128.0,
		"color": Color(0.3, 0.9, 0.4)
	},
	ZoneId.BOSQUE_EXTERIOR: {
		"name": "Bosque Exterior",
		"title": "🌲 ZONA 2: BOSQUE EXTERIOR",
		"subtitle": "Senderos entre robles y patrullas de avanzadilla",
		"min_z": 0.0,
		"max_z": 64.0,
		"color": Color(0.2, 0.75, 0.35)
	},
	ZoneId.CORAZON_BOSQUE: {
		"name": "Corazón del Bosque",
		"title": "🌑 ZONA 3: CORAZÓN DEL BOSQUE",
		"subtitle": "Desfiladero sombrío y cruce de piedras arcanas",
		"min_z": -64.0,
		"max_z": 0.0,
		"color": Color(0.65, 0.35, 0.85)
	},
	ZoneId.RUINAS_ARCANAS: {
		"name": "Ruinas Arcanas",
		"title": "🏛️ ZONA 4: RUINAS ARCANAS",
		"subtitle": "Templo prohibido del Guardián del Portal",
		"min_z": -128.0,
		"max_z": -64.0,
		"color": Color(1.0, 0.45, 0.2)
	}
}

# Player default spawn in safe Zone 1 (Terrain height at (0, 96) is ~0.71m)
const PLAYER_SPAWN_POS: Vector3 = Vector3(0.0, 0.71, 96.0)

# Boss altar in heart of Zone 4
const BOSS_ALTAR_POS: Vector3 = Vector3(0.0, 0.0, -98.0)

static func get_zone_at_position(pos: Vector3) -> ZoneId:
	var z = pos.z
	if z >= 64.0:
		return ZoneId.PRADERA_INICIAL
	elif z >= 0.0:
		return ZoneId.BOSQUE_EXTERIOR
	elif z >= -64.0:
		return ZoneId.CORAZON_BOSQUE
	else:
		return ZoneId.RUINAS_ARCANAS

static func get_zone_data(zone_id: ZoneId) -> Dictionary:
	return ZONE_BOUNDS.get(zone_id, ZONE_BOUNDS[ZoneId.PRADERA_INICIAL])

static func get_height_at(x: float, z: float) -> float:
	var h: float = 0.0
	
	# 1. Base North-South zonal incline with dynamic topography, valleys, and plateaus
	if z >= 64.0:
		# Zone 1: Pradera Arcadia (Z in [64, 128])
		# Continuous gentle ascent towards Zone 2 entrance at Z=64
		var z1_t = clamp((128.0 - z) / 64.0, 0.0, 1.0)
		var z1_base = 0.2 + z1_t * 0.8
		var road_cx = 0.0
		if z < 78.0:
			var t_c = (78.0 - z) / 36.0
			road_cx = -4.0 * sin(t_c * 3.14159265)
		var road_dist = abs(x - road_cx)
		
		# Gentle roadside berms flanking the path at 2.4m - 7.5m
		var roadside_bank = clamp((road_dist - 2.2) / 4.8, 0.0, 1.0) * 0.50
		# Subtle natural wave along trail direction
		var path_undulation = sin(z * 0.14) * 0.14 * (1.0 - clamp(road_dist / 3.2, 0.0, 1.0))
		
		# Rolling hills on flanks rising to 3.5m - 4.5m with smooth slopes
		var flank_hills = max(0.0, road_dist - 8.5) * 0.15
		var knolls = sin(x * 0.09) * 0.85 * sin(z * 0.08) * clamp(road_dist / 5.5, 0.0, 1.0)
		h = z1_base + roadside_bank + path_undulation + min(4.2, flank_hills) + knolls
		# Sunken natural basin for Health Fountain at (16, 92)
		var f_dist = Vector2(x - 16.0, z - 92.0).length()
		if f_dist < 10.0:
			h -= (1.0 - (f_dist / 10.0)) * 0.7
	elif z >= 0.0:
		# Zone 2: Bosque Exterior (Z in [0, 64])
		# Smooth hillside ascent from 1.0m at Z=64 to 5.2m at Z=0
		var t = (64.0 - z) / 64.0
		h = 1.0 + smoothstep(0.0, 1.0, t) * 4.2
		# Terraced woodland mounds and rocky flanking ridges
		var road_mask = clamp(abs(x) / 8.0, 0.0, 1.0)
		var ridge = max(0.0, abs(x) - 10.0) * 0.16
		var woodland_mounds = cos(x * 0.11) * sin(z * 0.09) * 1.2 * road_mask
		h += min(3.8, ridge) + woodland_mounds
		# Eastern secret elevated clearing amphitheater at (38, 32)
		var clear_dist = Vector2(x - 38.0, z - 32.0).length()
		if clear_dist < 16.0:
			var blend = 1.0 - (clear_dist / 16.0)
			h += blend * 1.8
	elif z >= -64.0:
		# Zone 3: Corazón del Bosque y Gran Desfiladero (Z in [-64, 0])
		# Base elevation ascends from 5.2m to 8.6m
		var t = -z / 64.0
		h = 5.2 + smoothstep(0.0, 1.0, t) * 3.4
		
		# Canyon / Gorge depression cutting across Z = -28
		var gorge_dist_z = abs(z - (-28.0))
		if gorge_dist_z < 20.0:
			var gorge_depth = (1.0 - (gorge_dist_z / 20.0)) * 4.2
			var gorge_width_mask = clamp((30.0 - abs(x)) / 10.0, 0.0, 1.0)
			# Natural elevated rock bridge at x ~ 0 spanning the chasm (wide, walkable 14.4m span)
			var bridge_mask = clamp(1.0 - (abs(x) / 7.2), 0.0, 1.0)
			h -= gorge_depth * gorge_width_mask * (1.0 - (bridge_mask * 0.95))
		
		# Western Flanking High Ridge & Overlook at (-38, -28)
		var west_flank = max(0.0, Vector2(x - (-38.0), z - (-28.0)).length() - 6.0)
		if west_flank < 18.0:
			h += (1.0 - (west_flank / 18.0)) * 2.8
		
		# Eastern Mystic Shrine Glade at (28, -42)
		var east_glade = Vector2(x - 28.0, z - (-42.0)).length()
		if east_glade < 18.0:
			h += (1.0 - (east_glade / 18.0)) * 2.2
	else:
		# Zone 4: Ruinas Arcanas (Z in [-128, -64])
		# Towering Sacred Mountain Plateau rising to 12.0m - 14.5m
		var t = (-64.0 - z) / 64.0
		h = 8.6 + smoothstep(0.0, 1.0, t) * 3.2
		# Elevated Boss Altar Dais & Ceremonial Temple Crest at (0, -98)
		var altar_dist = Vector2(x, z - (-98.0)).length()
		if altar_dist < 22.0:
			var dais = (1.0 - (altar_dist / 22.0)) * 2.4
			h += dais
	
	# Perimeter natural mountain amphitheater enclosing the arena
	var border_x = max(0.0, abs(x) - 96.0)
	var border_z_n = max(0.0, (-z) - 108.0)
	var border_z_s = max(0.0, z - 114.0)
	var border_dist = max(border_x, max(border_z_n, border_z_s))
	if border_dist > 0.0:
		var ramp = (border_dist / 16.0)
		h += ramp * ramp * 15.0
	
	return h

