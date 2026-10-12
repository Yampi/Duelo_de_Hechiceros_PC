class_name IconRegistry
extends RefCounted

## Registro centralizado de iconos del proyecto.
## Provee acceso por categoria e ID con cache en memoria y fallback seguro.

const DEFAULT_FALLBACK_PATH: String = "res://assets/ui/icons/states/state_ability_locked.png"

const SPELLS: Dictionary = {
	"magic_bolt": "res://assets/ui/icons/spells/arcane_bolt.png",
	"fireball": "res://assets/ui/icons/spells/spell_fireball.png",
	"summon_goblin": "res://assets/ui/icons/spells/summon_goblin.png",
	"shockwave": "res://assets/ui/icons/spells/shockwave.png",
	"heal": "res://assets/ui/icons/spells/spell_healing.png",
	"teleport": "res://assets/ui/icons/spells/spell_teleport.png",
	"ice_projectile": "res://assets/ui/icons/spells/spell_ice_projectile.png",
	"lightning": "res://assets/ui/icons/spells/spell_lightning.png",
	"arcane_shield": "res://assets/ui/icons/spells/spell_arcane_shield.png",
	"earth_fissure": "res://assets/ui/icons/spells/shockwave.png",
	"arcane_vines": "res://assets/ui/icons/spells/nature_tree.png",
	# Alias y hechizos complementarios
	"spell_fireball": "res://assets/ui/icons/spells/spell_fireball.png",
	"spell_ice_projectile": "res://assets/ui/icons/spells/spell_ice_projectile.png",
	"spell_lightning": "res://assets/ui/icons/spells/spell_lightning.png",
	"spell_healing": "res://assets/ui/icons/spells/spell_healing.png",
	"spell_teleport": "res://assets/ui/icons/spells/spell_teleport.png",
	"spell_arcane_shield": "res://assets/ui/icons/spells/spell_arcane_shield.png",
	"spell_book": "res://assets/ui/icons/spells/spell_book.png",
	"arcane_aura": "res://assets/ui/icons/spells/arcane_aura.png",
	"nature_tree": "res://assets/ui/icons/spells/nature_tree.png",
	"fire_flame": "res://assets/ui/icons/spells/fire_flame.png",
	"basic_attack": "res://assets/ui/icons/abilities/ability_basic_attack.png"
}

const ITEMS: Dictionary = {
	"potion_health": "res://assets/ui/icons/consumables/potion_health.png",
	"potion_mana": "res://assets/ui/icons/consumables/potion_mana.png",
	"potion_health_greater": "res://assets/ui/icons/consumables/potion_health.png",
	"potion_mana_greater": "res://assets/ui/icons/consumables/potion_mana.png",
	"potion_elixir": "res://assets/ui/icons/_unused/potion_elixir.png",
	"potion_invulnerability": "res://assets/ui/icons/spells/spell_arcane_shield.png",
	"magic_scroll": "res://assets/ui/icons/items/item_magic_scroll.png",
	"scroll_teleport": "res://assets/ui/icons/spells/spell_teleport.png",
	"apple": "res://assets/ui/icons/items/item_apple.png",
	"baked_apple": "res://assets/ui/icons/items/item_apple.png",
	"berry": "res://assets/ui/icons/spells/nature_tree.png",
	"mushroom_stew": "res://assets/ui/icons/consumables/potion_mana.png",
	"roasted_meat": "res://assets/ui/icons/spells/fire_flame.png",
	"sorcerer_banquet": "res://assets/ui/icons/status/buff_health.png",
	"clover": "res://assets/ui/icons/items/item_clover.png",
	"blood_root": "res://assets/ui/icons/spells/nature_tree.png",
	"bioluminescent_mushroom": "res://assets/ui/icons/spells/arcane_bolt.png",
	"star_lotus": "res://assets/ui/icons/spells/arcane_aura.png",
	"sulfur": "res://assets/ui/icons/spells/fire_flame.png",
	"arcane_iron": "res://assets/ui/icons/status/shield_physical.png",
	"obsidian_shard": "res://assets/ui/icons/status/shield_magic.png",
	"gold_nugget": "res://assets/ui/icons/status/shield_lightning.png",
	"crystallized_ether": "res://assets/ui/icons/items/item_arcane_crystal.png",
	"skeleton_bone": "res://assets/ui/icons/abilities/ability_basic_attack.png",
	"goblin_tooth": "res://assets/ui/icons/target/target_enemy.png",
	"wyvern_scale": "res://assets/ui/icons/_unused/creature_dragon.png",
	"fire_core": "res://assets/ui/icons/spells/spell_fireball.png",
	"amulet_vitality": "res://assets/ui/icons/status/buff_health.png",
	"ring_mana_flow": "res://assets/ui/icons/status/shield_magic.png",
	"talisman_swiftness": "res://assets/ui/icons/items/item_magic_scroll.png",
	"brooch_pyromancer": "res://assets/ui/icons/spells/fire_flame.png",
	"arcane_crystal": "res://assets/ui/icons/items/item_arcane_crystal.png",
	"forest_heart": "res://assets/ui/icons/items/item_arcane_crystal.png",
	# Alias para compatibilidad con sistema de reactivos
	"scroll": "res://assets/ui/icons/items/item_magic_scroll.png",
	"core": "res://assets/ui/icons/items/item_arcane_crystal.png"
}

const STATUS: Dictionary = {
	"burn": "res://assets/ui/icons/status/status_burn.png",
	"freeze": "res://assets/ui/icons/status/status_freeze.png",
	"poison": "res://assets/ui/icons/status/status_poison.png",
	"buff_health": "res://assets/ui/icons/status/buff_health.png",
	"debuff_vulnerable": "res://assets/ui/icons/status/debuff_vulnerable.png",
	"shield_physical": "res://assets/ui/icons/status/shield_physical.png",
	"shield_magic": "res://assets/ui/icons/status/shield_magic.png",
	"shield_healing": "res://assets/ui/icons/status/shield_healing.png",
	"shield_lightning": "res://assets/ui/icons/status/shield_lightning.png",
	# Alias para efectos del jugador
	"haste": "res://assets/ui/icons/items/item_magic_scroll.png",
	"arcane_shield": "res://assets/ui/icons/spells/spell_arcane_shield.png"
}

const UI: Dictionary = {
	"ability_locked": "res://assets/ui/icons/states/state_ability_locked.png",
	"target_enemy": "res://assets/ui/icons/target/target_enemy.png",
	"target_reticule": "res://assets/ui/icons/target/target_reticule.png",
	"inventory": "res://assets/ui/icons/spells/spell_book.png",
	"map": "res://assets/ui/icons/items/item_magic_scroll.png",
	"shrine": "res://assets/ui/icons/spells/arcane_aura.png",
	"crafting": "res://assets/ui/icons/_unused/potion_elixir.png"
}

const POI: Dictionary = {
	"claro_bosque": "res://assets/ui/icons/spells/nature_tree.png",
	"puente_arco": "res://assets/ui/icons/status/shield_physical.png",
	"mirador_occidental": "res://assets/ui/icons/target/target_reticule.png",
	"fuente_ruinas": "res://assets/ui/icons/consumables/potion_health.png",
	"altar_transmutacion": "res://assets/ui/icons/items/item_arcane_crystal.png",
	"altar_jefe": "res://assets/ui/icons/target/target_enemy.png",
	"shrine": "res://assets/ui/icons/spells/arcane_aura.png"
}

static var _cache: Dictionary = {}
static var _fallback_texture: Texture2D = null

## Retorna la textura Texture2D correspondiente a categoria e identificador.
## Utiliza cache y fallback seguro en caso de id desconocido o recurso fallido.
static func get_icon(category: String, id: String) -> Texture2D:
	var cat_lower = category.to_lower()
	var id_lower = id.to_lower()
	var cache_key = "%s:%s" % [cat_lower, id_lower]
	
	if _cache.has(cache_key):
		return _cache[cache_key]
	
	var path: String = _resolve_path(cat_lower, id_lower)
	var texture: Texture2D = null
	
	if not path.is_empty() and ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	
	if texture:
		_cache[cache_key] = texture
		return texture
	
	push_warning("IconRegistry: No se encontro icono para categoria '%s' e id '%s'. Usando fallback." % [category, id])
	var fallback = _get_fallback_icon()
	_cache[cache_key] = fallback
	return fallback

static func _resolve_path(category: String, id: String) -> String:
	match category:
		"spells", "spell":
			if SPELLS.has(id):
				return SPELLS[id]
		"items", "item":
			if ITEMS.has(id):
				return ITEMS[id]
		"status":
			if STATUS.has(id):
				return STATUS[id]
		"ui":
			if UI.has(id):
				return UI[id]
		"poi":
			if POI.has(id):
				return POI[id]
			# Verificacion por prefijo (p. ej. shrine_0, shrine_1)
			if id.begins_with("shrine"):
				return POI.get("shrine", "")
	
	# Busqueda cruzada si la categoria no coincide exactamente
	if SPELLS.has(id):
		return SPELLS[id]
	if ITEMS.has(id):
		return ITEMS[id]
	if STATUS.has(id):
		return STATUS[id]
	if UI.has(id):
		return UI[id]
	if POI.has(id):
		return POI[id]
	
	return ""

static func _get_fallback_icon() -> Texture2D:
	if not _fallback_texture:
		if ResourceLoader.exists(DEFAULT_FALLBACK_PATH):
			_fallback_texture = load(DEFAULT_FALLBACK_PATH) as Texture2D
	return _fallback_texture

## Obtiene la lista completa de rutas registradas para pruebas y validaciones.
static func get_all_registered_paths() -> Array[String]:
	var paths: Array[String] = []
	for dict in [SPELLS, ITEMS, STATUS, UI, POI]:
		for key in dict:
			var p = dict[key] as String
			if not p in paths:
				paths.append(p)
	if not DEFAULT_FALLBACK_PATH in paths:
		paths.append(DEFAULT_FALLBACK_PATH)
	return paths
