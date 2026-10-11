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

# Player default spawn in safe Zone 1
const PLAYER_SPAWN_POS: Vector3 = Vector3(0.0, 0.0, 96.0)

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
	
	# 1. Base North-South zonal incline
	# Zone 1: Z in [64, 128] -> base 0.0m (gentle meadow)
	# Zone 2: Z in [0, 64] -> rises from 0.0m to 2.8m
	# Zone 3: Z in [-64, 0] -> 2.8m with a central gorge dip around Z = -28
	# Zone 4: Z in [-128, -64] -> elevated plateau 6.5m - 7.5m
	if z >= 64.0:
		# Zone 1: Pradera Inicial
		# Rolling knolls on the flanks (|x| > 18)
		var flank_dist = max(0.0, abs(x) - 18.0)
		h = min(2.0, flank_dist * 0.06) + sin(x * 0.08) * 0.25 * sin(z * 0.08)
	elif z >= 0.0:
		# Zone 2: Bosque Exterior
		var t = (64.0 - z) / 64.0 # 0.0 at Z=64 to 1.0 at Z=0
		h = smoothstep(0.0, 1.0, t) * 2.8
		# Flanking ridges
		var ridge = max(0.0, abs(x) - 14.0) * 0.08
		h += min(1.8, ridge)
		# Eastern secret clearing at (38, 32)
		var clear_dist = Vector2(x - 38.0, z - 32.0).length()
		if clear_dist < 14.0:
			var blend = 1.0 - (clear_dist / 14.0)
			h += blend * 0.6
	elif z >= -64.0:
		# Zone 3: Corazón del Bosque
		var t = -z / 64.0 # 0.0 at Z=0 to 1.0 at Z=-64
		h = 2.8 + smoothstep(0.0, 1.0, t) * 2.8 # rises towards 5.6m
		
		# Central gorge / depression around Z = -28
		var gorge_dist_z = abs(z - (-28.0))
		if gorge_dist_z < 18.0:
			var gorge_depth = (1.0 - (gorge_dist_z / 18.0)) * 2.4
			var gorge_width_mask = clamp((28.0 - abs(x)) / 10.0, 0.0, 1.0)
			# Road bridge at x ~ 0 is elevated above gorge floor
			var bridge_mask = clamp(1.0 - (abs(x) / 5.0), 0.0, 1.0)
			h -= gorge_depth * gorge_width_mask * (1.0 - (bridge_mask * 0.75))
		
		# Western Flanking Detour at (-42, -32) high ground ridge
		var west_flank = Vector2(x - (-38.0), z - (-32.0)).length()
		if west_flank < 20.0:
			h += (1.0 - (west_flank / 20.0)) * 1.6
		
		# Eastern Glade at (28, -42)
		var east_glade = Vector2(x - 28.0, z - (-42.0)).length()
		if east_glade < 16.0:
			h += (1.0 - (east_glade / 16.0)) * 1.0
	else:
		# Zone 4: Ruinas Arcanas
		var t = (-64.0 - z) / 64.0 # 0.0 at Z=-64 to 1.0 at Z=-128
		h = 5.6 + smoothstep(0.0, 1.0, t) * 1.4 # reaches ~7.0m
		# Central altar dais at (0, -98)
		var altar_dist = Vector2(x, z - (-98.0)).length()
		if altar_dist < 16.0:
			var dais = (1.0 - (altar_dist / 16.0)) * 0.8
			h += dais
	
	# Perimeter natural mountain walls
	var border_x = max(0.0, abs(x) - 98.0)
	var border_z_n = max(0.0, (-z) - 110.0)
	var border_z_s = max(0.0, z - 114.0)
	var border_dist = max(border_x, max(border_z_n, border_z_s))
	if border_dist > 0.0:
		var ramp = (border_dist / 18.0)
		h += ramp * ramp * 14.0
	
	return h
