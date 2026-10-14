# INFORME TÉCNICO MAESTRO DEL PROYECTO PARA AUDITORÍA
# "Duelo de Hechiceros — Crónicas Arcanas" (PC)

**Motor Gráfico:** Godot Engine 4.7.2 Forward+  
**Lenguaje:** GDScript 2.0 (Tipado Estático Estricto)  
**Género:** RPG de Acción y Estrategia Táctica Mágica en Tiempo Real (Perspectiva 3D Cenital / Isométrica)  
**Línea de Diseño UI:** `DLG-INNOV` (Dark Fantasy Arcano)  
**Cobertura de QA:** 127 / 127 Pruebas Aprobadas (100%)  
**Rendimiento de UI:** 0.83 ms por frame (Presupuesto < 1.0 ms)  

---

## 📖 1. Contexto, Visión y Herencia Histórica

### 1.1 El Legado de Julian Gollop (1998)
Este proyecto es una modernización táctica en 3D de **Magic & Mayhem** (1998, Mythos Games / Virgin Interactive), diseñado por **Julian Gollop** (creador de *X-COM* y *Chaos: The Battle of Wizards*), publicado en español como **Duelo de Hechiceros**.

### 1.2 Núcleo Narrativo y Mecánico
1. **La Odisea de Cornelius y Lucian:** El hechicero Cornelius emprende una travesía para hallar a su mentor, el Maestro Lucian, quien descubrió los secretos del Maná Primordial y la corrupción del Cónclave de Hechiceros.
2. **Los Tres Reinos Mitológicos:**
   * **El Dominio Céltico (Avalon):** Bosques brumosos, dólmenes, oráculos antiguos y manantiales sagrados.
   * **El Dominio Clásico (Grecia Mítica):** Templos helénicos en ruinas, minotauros y altares titánicos.
   * **El Dominio del Caos (Tártaro / Inframundo Gótico):** Ríos de azufre, dragones ancianos y la fortaleza del Archimago Malakor.
3. **La Tríada Cósmica:**
   * **Ley (Law):** Luz celestial, escudos protectores, rayos y purificación.
   * **Neutralidad (Neutral):** Fuerzas de la naturaleza, rocas, hielo y enredaderas arcanas.
   * **Caos (Chaos):** Fuego destructivo, fisuras tectónicas, veneno e invocaciones nigrománticas.
4. **Guerra Territorial por Lugares de Poder:** El maná no se regenera de forma pasiva trivial; brota exclusivamente de los **Lugares de Poder (Places of Power)**. Controlar los monolitos es la clave para mantener el flujo de hechizos y dominar el mapa.
5. **Duelos de Hechiceros Auténticos:** Enfrentamientos contra hechiceros rivales autónomos (como el Archimago Malakor), equipados con báculos, grimorios propios, teletransporte de emergencia y telequinesis.

---

## 🏛️ 2. Los 5 Pilares del Orquestador Maestro

```
                       ┌───────────────────────────────────────────────┐
                       │           ORQUESTADOR MAESTRO                 │
                       │    Duelo de Hechiceros: Crónicas Arcanas      │
                       └───────────────────────┬───────────────────────┘
                                               │
     ┌───────────────────┬─────────────────────┼─────────────────────┬───────────────────┐
     ▼                   ▼                     ▼                     ▼                   ▼
┌──────────────┐  ┌──────────────┐     ┌──────────────┐      ┌──────────────┐    ┌──────────────┐
│   PILAR I    │  │   PILAR II   │     │  PILAR III   │      │   PILAR IV   │    │   PILAR V    │
│ Trama y Lore │  │ Duelos y     │     │ Escenarios y │      │  Bestiario   │    │ Pipeline y   │
│ de Lucian    │  │ Maná Guerra  │     │ Render 4.7   │      │  Táctico     │    │ QA Autónomo  │
└──────────────┘  └──────────────┘     └──────────────┘      └──────────────┘    └──────────────┘
```

### 📜 PILAR I: Trama, Narrativa y Misiones Arcanas ("El Legado de Lucian")
* **Gestor de Lore (`scripts/lore/lore_manager.gd`):** Códice indexado de 4 capítulos con diarios de Lucian, profecías célticas y advertencias de los oráculos. Recompensa al jugador con incrementos permanentes de maná al descubrir cada monumento.
* **Monolitos de los Oráculos (`scenes/OracleMonolith.tscn` / `scripts/oracle_monolith.gd`):** Estructuras arcanas en 3D con anillos rúnicos procedurales y luces de pulso místico. Al pulsar `[E]`, revelan fragmentos de historia en el HUD.

### ⚔️ PILAR II: Duelos y Guerra Territorial por Lugares de Poder
* **Lugares de Poder (`scenes/PlaceOfPower.tscn` / `scripts/place_of_power.gd`):** Mecánica de captura bidireccional continua con detección de disputas (`⚔️ ¡ZONA DISPUTADA! ⚔️`). Controlar un nodo incrementa la capacidad máxima y regeneración de maná de `GameManager`.
* **Hechicero Rival Inteligente (`scenes/RivalWizard.tscn` / `scripts/rival_wizard.gd`):** Archimago Malakor cuenta con máquina de estados finita:
  `IDLE` ➔ `SEEK_SHRINE` ➔ `APPROACH_PLAYER` ➔ `CAST_BOLT` ➔ `CAST_FIREBALL` ➔ `TELEPORT_EVADE` ➔ `SUMMON_MINIONS` ➔ `RETREAT`.
  Posee escudo de barrera temporal, teletransporte evasivo con cooldown de 6s e invocación de esbirros de distracción.

### 🌲 PILAR III: Escenarios Vivos y Render Godot 4.7 Forward+
* **Generación Procedural (`scripts/map_generator.gd`, `scripts/map_config.gd`):** Cuadrícula 256m x 256m dividida en 4 zonas de bioma diferenciadas:
  1. *Zona 1:* Pradera Inicial y Claro Esmeralda.
  2. *Zona 2:* Bosque Exterior y Arboleda Brumosa.
  3. *Zona 3:* Corazón del Bosque y Santuario Central.
  4. *Zona 4:* Ruinas Arcanas y Altar de Malakor.
* **Pipeline de Shaders GLSL Forward+:**
  * `shaders/terrain.gdshader`: Mezcla procedural multicapa (hierba, tierra, roca) con perturbación matemática de vértices.
  * `shaders/fog_of_war_3d.gdshader`: Shader de post-procesado espacial que reconstruye la posición de mundo a partir del depth-buffer y aplica una niebla volumétrica animada con bruma etérea (`sin(x) * cos(z)`).
  * `shaders/foliage_grass.gdshader`: Simulación de viento y ondulación en GPU.
  * `shaders/wizard_body.gdshader` y `wizard_face.gdshader`: Modificación dinámica de albedo y propiedades de materiales para el creador de personajes.

### 🐉 PILAR IV: Bestiario y Combate Táctico
* **Esbirros y Hostiles:** Duendes minion (`GoblinMinion.tscn`), arqueros esqueléticos (`BoneArrow.tscn`), lanceros esqueléticos, murciélagos y slimes elementales.
* **Jefe Dragón:** Modelo con rig de 33 huesos, patrones de ataque aéreo y escupitajo ígneo (`FireSpit.tscn`).
* **Sistema Completo de CC (Control de Masas):**
  * `Freeze`: Inmovilización total con shader cristalino.
  * `Stun`: Aturdimiento con interrupción de casteo.
  * `Burn`: Daño por segundo continuo con partículas ígneas.
  * `Sink`: Ralentización de locomoción al atravesar fisuras terrestres.
  * `Root`: Enraizamiento por enredaderas arcanas.

### 🧪 PILAR V: Pipeline Multimedia y QA Autónomo
* **Cobertura de Pruebas Headless:**
  * `scenes/QASuite.tscn`: 36 / 36 pruebas aprobadas (100%).
  * `scenes/TestGameplayDepthSuite.tscn`: 59 / 59 pruebas aprobadas (100%).
  * `scenes/TestOrchestratorSuite.tscn`: 32 / 32 pruebas aprobadas (100%).
  * **Total Consolidado:** **127 / 127 Pruebas Aprobadas (100%)**.
* **Benchmark de Rendimiento:** Frame time de UI medido en **0.83 ms** (presupuesto < 1.0 ms).

---

## 🤖 3. Matriz de Agentes de Desarrollo (Agentes 0 a E)

| Agente | Nombre | Objetivos Técnicos Implementados | Archivos Afectados |
|---|---|---|---|
| **Agente 0** | **Rendimiento & Optimización** | Toque de 12 enemigos simultáneos en Supervivencia, throttling O(1) de árboles de comportamiento de IA, sistema de pooling de objetos para números de daño (`DamageNumber.tscn`) y partículas VFX, LOD de props. | `scripts/enemy.gd`, `scripts/damage_number.gd`, `scripts/vfx_library.gd` |
| **Agente A** | **Combate & IA Hostil** | Velocidades escalonadas por arquetipo, desenganche táctico inteligente con retirada estratégica, máquina de estados de CC completa y debilidades elementales. | `scripts/enemy.gd`, `scripts/player.gd` |
| **Agente B** | **Grimorio y Magia Arcana** | Catálogo de 11 hechizos con afinidad elemental (Perno Mágico, Bola de Fuego, Proyectil de Hielo, Rayo Relámpago, Fisura Terrestre, Escudo Arcano, Enredaderas, Onda de Choque, Teletransporte, Círculo de Invocación, Curación). Shaders de cooldown radial en GPU y modal de asignación de hotbar. | `scripts/ui/grimoire_modal.gd`, `scripts/hud.gd`, `scripts/magic_bolt.gd`, `scripts/fireball.gd`, etc. |
| **Agente C** | **Niebla de Guerra (Fog of War)** | Rejilla lógica de 128x128 con persistencia de exploración en `PackedByteArray`, ocultamiento de enemigos fuera de visión en el minimapa, y shader de pantalla 3D volumétrico en espacio de mundo. | `scripts/fog/fog_of_war.gd`, `shaders/fog_of_war_3d.gdshader`, `scripts/ui/minimap.gd` |
| **Agente D** | **Creador de Personajes 3D** | SubViewport aislado con turntable 3D e iluminación de estudio de tres puntos. Selección de 3 clases (Mago, Pícaro, Guardabosques). Personalización de paleta de túnica, cabello, piel y ojos mediante shaders con persistencia en sesión. | `scenes/ui/CharacterCreator.tscn`, `scripts/ui/character_creator.gd`, `scripts/character_appearance.gd` |
| **Agente E** | **Crafteo, Nodos e Inventario** | Base de datos de más de 40 ítems (`ItemDB`), tres mesas de taller (Alquimia, Forja, Cocina) con validación de recetas e ingredientes. Nodos de recolección en el mundo (`GatheringNode.tscn`, hierbas, vetas de mineral, árboles frutales) con animaciones de sacudida y recolección. | `scripts/crafting/crafting_manager.gd`, `scripts/inventory/item_db.gd`, `scripts/gathering_node.gd`, `scenes/ui/CraftingModal.tscn` |

---

## 🎨 4. Directiva de Diseño UI/UX: Dark Fantasy Arcano (`DLG-INNOV`)

1. **Minimalismo en Combate:** Ocupación visual del HUD menor al 12% de la pantalla para garantizar legibilidad espacial inmediata de proyectiles y telegrafiado de enemigos.
2. **Distribución en 3 Clusters Funcionales:**
   * *Cluster Vital (Superior Izquierdo):* Barras de Salud, Maná y Estamina con Damage Trail diferido de 400ms para impacto cinemático claro.
   * *Cluster Mágico (Inferior Central):* Hotbar de 4 slots de hechizos con shaders de cooldown radial en GPU y ranuras rápidas para consumibles (1 a 4).
   * *Cluster Táctico (Superior Derecho):* Minimapa circular con brújula de Lugares de Poder y oclusión dinámica por niebla de guerra.
3. **Accesibilidad Integrada:** Modales accesibles con soporte para reducción de temblores de cámara (*screen shake*), eliminación de parpadeos estroboscópicos y paletas de alto contraste.

---

## 💻 5. Extractos de Código de los Subsistemas Clave

### 5.1 IA del Hechicero Rival (`scripts/rival_wizard.gd`)
```gdscript
class_name RivalWizard
extends CharacterBody3D

enum DuelState {
	IDLE,
	SEEK_SHRINE,
	APPROACH_PLAYER,
	CAST_BOLT,
	CAST_FIREBALL,
	TELEPORT_EVADE,
	SUMMON_MINIONS,
	RETREAT
}

@export var wizard_name: String = "Archimago Malakor"
@export var max_health: float = 240.0
@export var move_speed: float = 4.2
@export var is_boss: bool = true

var current_health: float = 240.0
var state: DuelState = DuelState.IDLE
var target_player: CharacterBody3D = null
var teleport_cooldown: float = 6.0
var teleport_timer: float = 0.0
var summon_cooldown: float = 16.0
var summon_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	teleport_timer -= delta
	summon_timer -= delta
	
	match state:
		DuelState.IDLE:
			_check_tactical_priorities()
		DuelState.SEEK_SHRINE:
			_execute_seek_shrine(delta)
		DuelState.APPROACH_PLAYER:
			_execute_approach_player(delta)
		DuelState.CAST_BOLT:
			_execute_cast_bolt()
		DuelState.CAST_FIREBALL:
			_execute_cast_fireball()
		DuelState.TELEPORT_EVADE:
			_execute_teleport_evade()
		DuelState.SUMMON_MINIONS:
			_execute_summon_minions()
		DuelState.RETREAT:
			_execute_retreat(delta)

func take_damage(amount: float, source_type: String = "magic") -> void:
	if shield_active:
		amount *= 0.25 # Escudo absorbe 75% del impacto
	current_health -= amount
	# Reacción táctica: si la vida cae por debajo del 40% y el teleport está listo, evadir
	if current_health < max_health * 0.4 and teleport_timer <= 0.0:
		state = DuelState.TELEPORT_EVADE
```

### 5.2 Lugares de Poder y Guerra Territorial (`scripts/place_of_power.gd`)
```gdscript
extends Area3D

signal control_changed(new_owner: String)

enum OwnerState { NEUTRAL, PLAYER, ENEMY }

@export var capture_speed: float = 0.35 # Captura en ~3 segundos
@export var mana_bonus_rate: float = 8.0 # Maná otorgado por segundo al poseedor

var current_owner: OwnerState = OwnerState.NEUTRAL
var capture_progress: float = 0.0
var player_inside: bool = false
var enemies_inside_count: int = 0

func _process(delta: float) -> void:
	var has_enemies = enemies_inside_count > 0

	# Zona en disputa: ambos bandos presentes, progreso congelado
	if player_inside and has_enemies:
		if label_status:
			label_status.text = "LUGAR DE PODER\n⚔️ ¡ZONA DISPUTADA! ⚔️"
			label_status.modulate = contested_color
		return

	# Captura o liberación por el jugador
	if player_inside and not has_enemies:
		if current_owner == OwnerState.ENEMY:
			capture_progress -= capture_speed * delta
			if capture_progress <= 0.0:
				current_owner = OwnerState.NEUTRAL
				control_changed.emit("neutral")
		elif current_owner != OwnerState.PLAYER:
			capture_progress += capture_speed * delta
			if capture_progress >= 1.0:
				capture_progress = 1.0
				current_owner = OwnerState.PLAYER
				GameManager.active_shrines += 1
				GameManager.update_mana_capacity()
				control_changed.emit("player")
```

### 5.3 Niebla de Guerra 128x128 (`scripts/fog/fog_of_war.gd`)
```gdscript
class_name FogOfWar
extends RefCounted

const GRID_SIZE: int = 128
const MAP_SIZE: float = 256.0
const HALF_SIZE: float = 128.0
const CELL_SIZE: float = 2.0 # 2m por celda
const REVEAL_RADIUS: float = 20.0

var explored_grid: PackedByteArray = PackedByteArray()
var visible_grid: PackedByteArray = PackedByteArray()
var fog_image: Image = null
var fog_texture: ImageTexture = null

func update_player_vision(player_pos: Vector3) -> bool:
	var pc = world_to_grid(player_pos)
	var radius_cells = int(ceil(REVEAL_RADIUS / CELL_SIZE))
	
	for gz in range(pc.y - radius_cells, pc.y + radius_cells + 1):
		for gx in range(pc.x - radius_cells, pc.x + radius_cells + 1):
			if gx < 0 or gx >= GRID_SIZE or gz < 0 or gz >= GRID_SIZE:
				continue
			var cell_world = grid_to_world(Vector2i(gx, gz))
			if player_pos.distance_to(cell_world) <= REVEAL_RADIUS:
				var idx = _get_cell_index(gx, gz)
				explored_grid[idx] = 1 # Persistencia de exploración
				visible_grid[idx] = 2  # Visibilidad activa
				fog_image.set_pixel(gx, gz, Color(0, 0, 0, 0.0)) # Revelar píxel
	
	fog_texture.update(fog_image)
	return true
```

### 5.4 Shader GLSL de Niebla Volumétrica 3D (`shaders/fog_of_war_3d.gdshader`)
```glsl
shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D fog_texture : filter_linear;

uniform vec3 player_pos = vec3(0.0, 0.0, 96.0);
uniform float reveal_radius = 26.0;
uniform vec3 fog_color_unexplored : source_color = vec3(0.06, 0.08, 0.12);

void fragment() {
	vec4 screen_col = texture(screen_texture, SCREEN_UV);
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	vec4 world = INV_VIEW_MATRIX * vec4(view.xyz, 1.0);
	vec3 world_pos = world.xyz;
	
	vec2 fog_uv = (world_pos.xz + vec2(128.0)) / 256.0;
	float dist_to_player = length(world_pos.xz - player_pos.xz);
	float player_reveal = 1.0 - smoothstep(reveal_radius - 3.5, reveal_radius + 1.5, dist_to_player);
	
	vec4 fog_sample = texture(fog_texture, fog_uv);
	float active_fog = clamp(fog_sample.a - player_reveal, 0.0, 1.0);
	
	// Bruma etérea animada en zonas ocultas
	float mist_wave = sin(world_pos.x * 0.14 + TIME * 0.45) * cos(world_pos.z * 0.14 + TIME * 0.35) * 0.03;
	vec3 final_fog_col = fog_color_unexplored + vec3(mist_wave);
	
	ALBEDO = mix(screen_col.rgb, final_fog_col, active_fog * 0.94);
}
```

---

## 🎯 6. Preguntas y Ejes de Auditoría para Gemini 4 Argon

Te solicitamos realizar un análisis riguroso y en profundidad cubriendo estos 5 aspectos clave:

1. **Arquitectura y Modularidad de Godot 4:**
   * ¿Qué tan desacoplados están los autoloads (`GameManager`, `AudioManager`, `ItemDB`, `LoreManager`, `CraftingManager`) respecto a los nodos instanciados (`Player`, `Enemy`, `RivalWizard`)?
   * ¿Recomiendas migrar ciertas dependencias directas a un patrón Event Bus centralizado con señales tipadas?

2. **Calidad de GDScript 2.0 y Ciclos de Vida:**
   * ¿El manejo de memoria en proyectiles, números de daño y efectos visuales (`vfx_library.gd`) es óptimo frente a fugas de memoria o stuttering del Garbage Collector?
   * ¿Es adecuada la división de trabajo entre `_process` y `_physics_process` en los controladores de IA y locomoción?

3. **Game Design y Sinergias del Core Loop:**
   * ¿Cómo interactúan el ritmo de exploración con niebla, la recolección de reactivos, el crafteo de elixires y el combate territorial por los Lugares de Poder?
   * ¿Hay hechizos redundantes o nichos tácticos descuidados en el catálogo de los 11 hechizos frente a las 3 clases disponibles?

4. **Shaders y Optimización GPU Forward+:**
   * Evalúa la reconstrucción de coordenadas de mundo en el shader de niebla 3D (`fog_of_war_3d.gdshader`) y el shader de terreno (`terrain.gdshader`). ¿Existen cuellos de botella para hardware modesto o integradas?

5. **Hoja de Ruta hacia Próximas Fases:**
   * ¿Cuál debería ser el enfoque prioritario:
     a) Implementación de multijugador en red 1v1 PvP / Co-op con sincronización ENet en Godot 4.
     b) Sistema de metaprogresión y árbol de talentos roguelite entre partidas.
     c) Soporte integral de gamepad y navegación por menús radiales.
