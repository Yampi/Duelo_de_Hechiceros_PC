class_name LoreManager
extends Node

## LoreManager — Archivo Canónico de Trama y Crónicas Arcanas
## Inspirado en la búsqueda mítica de Magic & Mayhem (Duelo de Hechiceros, 1998)
## Registra los diarios de campo de Lucian, advertencias de los Oráculos y la Herejía del Caos.

signal lore_discovered(entry_id: String, entry_data: Dictionary)

const LORE_DATABASE: Dictionary = {
	"lucian_journal_1": {
		"id": "lucian_journal_1",
		"zone": "Pradera Inicial",
		"title": "Diario de Lucian: El Despertar del Maná Primordial",
		"author": "Maestro Lucian",
		"text": "Si encuentras esto, mi joven aprendiz, la Gran Convergencia ha comenzado. El Maná no fluye de la nada: mana de las entrañas de los antiguos Lugares de Poder. Quien controle los monolitos gobernará las leyes de la realidad. Temo que los hechiceros del Cónclave ya han sido tentados por el Caos...",
		"chapter": 1,
		"shrine_clue": "Busca el monolito en el Claro Esmeralda antes de cruzar al bosque.",
		"reward_mana": 25.0
	},
	"oracle_avalon_whisper": {
		"id": "oracle_avalon_whisper",
		"zone": "Bosque Exterior",
		"title": "Voz del Oráculo Céltico: La Tríada Arcana",
		"author": "El Espíritu del Roble Milenario",
		"text": "La magia no es una, sino tres vertientes entrelazadas: la Ley que defiende y purifica, el Caos que consume e incendia, y la Neutralidad salvaje que convoca las fuerzas de la tierra. Aquel que domine los tres senderos jamás será doblegado en duelo.",
		"chapter": 2,
		"shrine_clue": "Las enredaderas y la tierra responden solo a quienes respetan el equilibrio.",
		"reward_mana": 30.0
	},
	"lucian_journal_2": {
		"id": "lucian_journal_2",
		"zone": "Corazón del Bosque",
		"title": "Diario de Lucian: El Duelo contra Malakor",
		"author": "Maestro Lucian",
		"text": "Malakor ya no es humano. Se ha proclamado Archimago del Caos y ha vinculado su alma a las llamas del Tártaro. Me emboscó cerca de las ruinas; sus esbirros rodearon el Santuario y arrebataron el flujo de maná. Me vi obligado a usar el portal hacia el norte...",
		"chapter": 3,
		"shrine_clue": "Para vencer a un hechicero rival, debes arrebatarle sus Lugares de Poder antes de asestar el golpe final.",
		"reward_mana": 35.0
	},
	"ancient_monolith_ruins": {
		"id": "ancient_monolith_ruins",
		"zone": "Ruinas Arcanas",
		"title": "Inscripción Titánica: La Caída del Cónclave",
		"author": "Antiguos Maestros",
		"text": "Aquí libraron batalla los Doce Hechiceros. El cielo se tiñó de escarcha y azufre hasta que las torres colapsaron. Solo un verdadero duelista capaz de invocar, canalizar y resistir podrá reclamar el Báculo Primordial.",
		"chapter": 4,
		"shrine_clue": "El Portal del Juicio solo se abrirá cuando el Hechicero Rival sea derrotado.",
		"reward_mana": 50.0
	}
}

var unlocked_lore: Array[String] = []

func is_unlocked(entry_id: String) -> bool:
	return entry_id in unlocked_lore

func unlock_lore(entry_id: String) -> Dictionary:
	if not LORE_DATABASE.has(entry_id):
		return {}
	
	var data: Dictionary = LORE_DATABASE[entry_id]
	if not is_unlocked(entry_id):
		unlocked_lore.append(entry_id)
		lore_discovered.emit(entry_id, data)
		
		# Otorgar recompensa de maná al descubrir la historia
		if data.has("reward_mana") and float(data["reward_mana"]) > 0.0:
			GameManager.player_mana = min(GameManager.player_max_mana, GameManager.player_mana + float(data["reward_mana"]))
			GameManager.spawn_damage_number(
				Vector3.ZERO,
				"📜 LORE DESBLOQUEADO: +" + str(int(data["reward_mana"])) + " MP",
				Color(0.9, 0.8, 0.2),
				1.25
			)
	return data

func get_total_entries_count() -> int:
	return LORE_DATABASE.size()

func get_unlocked_entries_count() -> int:
	return unlocked_lore.size()
