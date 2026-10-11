extends Node3D

const MapConfig = preload("res://scripts/map_config.gd")
const EncounterManager = preload("res://scripts/encounter_manager.gd")

@onready var map_generator: Node3D = $MapGenerator
@onready var player: CharacterBody3D = $Wizard
@onready var hud = $HUD
@onready var camera_rig: Node3D = $CameraRig

var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
var encounter_manager: EncounterManager = null

var wave_timer: float = 0.0
var wave_interval: float = 22.0
var boss_announced: bool = false

func _ready() -> void:
	# Generate 256x256m bounded 4-zone map
	map_generator.generate_map()
	
	# Position player in safe Zone 1 (Pradera Inicial)
	player.global_position = MapConfig.PLAYER_SPAWN_POS
	camera_rig.follow_target = player
	hud.set_player_reference(player)
	
	# Initial discovery of starter zone & points of interest
	GameManager.discover_zone(MapConfig.ZoneId.PRADERA_INICIAL)
	GameManager.discover_poi("plaza_inicio", "Plaza de Inicio", MapConfig.PLAYER_SPAWN_POS, "mirador_occidental")
	GameManager.discover_poi("fuente_pradera", "Fuente de Vida", Vector3(16.0, 0.0, 92.0), "fuente_ruinas")
	
	# Instantiate and initialize EncounterManager
	encounter_manager = EncounterManager.new()
	encounter_manager.name = "EncounterManager"
	add_child(encounter_manager)
	encounter_manager.set_player(player)
	encounter_manager.zone_changed.connect(_on_zone_changed)
	encounter_manager.encounter_started.connect(_on_encounter_started)
	encounter_manager.boss_encounter_started.connect(_on_boss_encounter_started)
	
	# Connect player signals
	player.spell_changed.connect(hud.update_active_spell)
	player.health_updated.connect(hud.update_hp)
	player.mana_updated.connect(func(c, m): hud.update_mana(c, m, GameManager.mana_regen_rate))
	player.player_died.connect(func(): hud.trigger_player_death_sequence(hud.show_game_over))
	player.cast_progress_updated.connect(hud.update_cast_progress)
	player.target_changed.connect(hud.set_target_enemy)
	player.element_flash_requested.connect(hud.trigger_element_flash)
	player.cast_failed_no_mana.connect(hud.trigger_no_mana_slot)
	
	# Connect HUD signals
	hud.spell_button_pressed.connect(player.select_spell_slot)
	
	# Welcome banner for Zone 1
	var z1_data = MapConfig.get_zone_data(MapConfig.ZoneId.PRADERA_INICIAL)
	hud.show_zone_banner(z1_data["title"], z1_data["subtitle"], z1_data["color"])
	
	# Start ambient exploration soundtrack
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_music"):
		am.play_music("exploration", 1.5)
	
	# Setup initial game mode
	if GameManager.current_mode == GameManager.GameMode.OBJECTIVE or GameManager.current_mode == GameManager.GameMode.EXPLORATION:
		if map_generator.portal_instance:
			map_generator.portal_instance.level_completed.connect(hud.show_victory)
	elif GameManager.current_mode == GameManager.GameMode.SURVIVAL:
		_spawn_survival_wave(1)

func _process(delta: float) -> void:
	_check_poi_discovery()
	match GameManager.current_mode:
		GameManager.GameMode.SURVIVAL:
			_process_survival(delta)
		GameManager.GameMode.EXPLORATION:
			_process_exploration(delta)
		GameManager.GameMode.OBJECTIVE:
			_process_objective(delta)

func _check_poi_discovery() -> void:
	if not player:
		return
	var p_pos = player.global_position
	if map_generator:
		for i in range(map_generator.shrine_positions.size()):
			var s_pos = map_generator.shrine_positions[i]
			if p_pos.distance_to(s_pos) <= 24.0:
				GameManager.discover_poi("shrine_%d" % i, "Santuario de Poder %d" % (i + 1), s_pos, "shrine")
	
	var other_pois = [
		{"id": "claro_bosque", "name": "Claro Secreto del Este", "pos": Vector3(38.0, 0.0, 32.0), "icon": "claro_bosque", "dist": 22.0},
		{"id": "puente_arco", "name": "Puente de Piedra del Desfiladero", "pos": Vector3(0.0, 0.0, -28.0), "icon": "puente_arco", "dist": 20.0},
		{"id": "mirador_occidental", "name": "Mirador de la Cresta Occidental", "pos": Vector3(-38.0, 0.0, -28.0), "icon": "mirador_occidental", "dist": 20.0},
		{"id": "fuente_ruinas", "name": "Fuente de las Ruinas", "pos": Vector3(-18.0, 0.0, -74.0), "icon": "fuente_ruinas", "dist": 20.0},
		{"id": "altar_transmutacion", "name": "Altar de Transmutación Arcana", "pos": Vector3(-36.0, 0.0, -68.0), "icon": "altar_transmutacion", "dist": 22.0},
		{"id": "altar_jefe", "name": "Altar del Guardián de las Ruinas", "pos": MapConfig.BOSS_ALTAR_POS, "icon": "altar_jefe", "dist": 28.0}
	]
	for p in other_pois:
		if p_pos.distance_to(p["pos"]) <= p["dist"]:
			GameManager.discover_poi(p["id"], p["name"], p["pos"], p["icon"])

func _on_zone_changed(zone_id: int, zone_data: Dictionary) -> void:
	GameManager.discover_zone(zone_id)
	hud.show_zone_banner(zone_data["title"], zone_data["subtitle"], zone_data.get("color", Color(1, 0.85, 0.4)))

func _on_encounter_started(enc_id: String, count: int) -> void:
	GameManager.spawn_damage_number(player.global_position + Vector3(0, 1.8, 0), "⚔ ¡ENEMIGOS AL ACECHO! (%d)" % count, Color(1.0, 0.45, 0.2), 1.2)

func _on_boss_encounter_started() -> void:
	GameManager.boss_spawned = true
	hud.show_zone_banner("⚠️ ¡EL GUARDIÁN DE LAS RUINAS HA DESPERTADO!", "Derrota al Señor de las Sombras en el Altar para abrir el portal", Color(1.0, 0.35, 0.2))
	GameManager.shake_camera(0.6)
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_music"):
		am.play_music("boss", 1.2)

func _process_survival(delta: float) -> void:
	GameManager.survival_time += delta
	wave_timer += delta
	
	var mins = int(GameManager.survival_time) / 60
	var secs = int(GameManager.survival_time) % 60
	var enemies_alive = get_tree().get_nodes_in_group("enemy").size()
	
	hud.update_mode_hud(
		"⚔ MODO SUPERVIVENCIA",
		"Oleada %d | Tiempo: %02d:%02d" % [GameManager.wave, mins, secs],
		"Enemigos restantes: %d (Bajas: %d)" % [enemies_alive, GameManager.enemies_defeated]
	)
	
	# Spawn next wave if timer expires or all enemies cleared
	if wave_timer >= wave_interval or (enemies_alive == 0 and wave_timer > 4.0):
		wave_timer = 0.0
		GameManager.wave += 1
		_spawn_survival_wave(GameManager.wave)

func _spawn_survival_wave(wave_num: int) -> void:
	var count = 4 + (wave_num * 2)
	for i in range(count):
		var angle = randf() * TAU
		var dist = randf_range(26.0, 44.0)
		var spawn_pos = player.global_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		
		var enemy = enemy_scene.instantiate()
		var type_roll = randi() % 5
		enemy.set_archetype(type_roll)
		
		# Boss enemy in later waves
		if wave_num % 3 == 0 and i == 0:
			enemy.is_boss = true
			enemy.set_archetype(1) # Skeleton Spear
		
		enemy.position = spawn_pos
		add_child(enemy)

func _process_exploration(_delta: float) -> void:
	var z_data = MapConfig.get_zone_data(encounter_manager.current_zone) if encounter_manager else {}
	var z_name = z_data.get("name", "Tierras Arcanas")
	var active_enc_count = encounter_manager.active_enemies.size() if encounter_manager else 0
	
	if GameManager.boss_defeated:
		if map_generator.portal_instance and not map_generator.portal_instance.is_active:
			map_generator.portal_instance.update_state(true)
		hud.update_mode_hud(
			"✨ ¡PORTAL ACTIVADO!",
			"¡Cruza el portal arcano en las Ruinas para triunfar!",
			"Guardián derrotado. Bajas: %d | Puntuación: %d" % [GameManager.enemies_defeated, GameManager.score]
		)
	else:
		hud.update_mode_hud(
			"🧭 EXPLORACIÓN: %s" % z_name.to_upper(),
			"Lugares de Poder: %d / %d | Enemigos cercanos: %d" % [GameManager.active_shrines, GameManager.total_shrines, active_enc_count],
			"Bajas enemigas: %d | Puntuación: %d" % [GameManager.enemies_defeated, GameManager.score]
		)

func _process_objective(_delta: float) -> void:
	if GameManager.active_shrines < 3:
		hud.update_mode_hud(
			"🏆 SUPERAR EL NIVEL",
			"Misión: Captura los 3 Lugares de Poder (%d / 3)" % [GameManager.active_shrines],
			"Explora las 4 zonas y captura los círculos rúnicos"
		)
	elif not GameManager.boss_spawned:
		GameManager.boss_spawned = true
		hud.update_mode_hud(
			"⚠️ ¡ALERTA ARCANO!",
			"¡El Guardián del Portal ha despertado en las Ruinas!",
			"Dirígete al Altar en la Zona 4 para el combate final"
		)
	elif not GameManager.boss_defeated:
		hud.update_mode_hud(
			"⚔ OBJETIVO: DERROTA AL GUARDIÁN",
			"Elimina al Señor de las Sombras en el Altar de las Ruinas",
			"Lugares de Poder: 3 / 3 (Maná al máximo)"
		)
	else:
		if map_generator.portal_instance and not map_generator.portal_instance.is_active:
			map_generator.portal_instance.update_state(true)
		
		hud.update_mode_hud(
			"✨ ¡PORTAL ACTIVADO!",
			"¡Cruza el portal arcano en las Ruinas para triunfar!",
			"Sigue la luz turquesa al norte del mapa"
		)
