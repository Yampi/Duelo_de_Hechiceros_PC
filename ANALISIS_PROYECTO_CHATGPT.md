# GUÍA DE ANÁLISIS DE PROYECTO PARA CHATGPT
## Proyecto: "Duelo de Hechiceros — Crónicas Arcanas" (PC)

> **Nota para ChatGPT / LLM:**  
> Este archivo resume el contexto, la arquitectura, el estado de desarrollo y las directrices para que realices una auditoría y análisis exhaustivo de este proyecto en Godot Engine. Todos los scripts (`.gd`), escenas (`.tscn`), shaders (`.gdshader`), configuraciones (`project.godot`) y documentación técnica (`docs/`) están incluidos en este paquete.

---

## 📋 1. Ficha Técnica

* **Nombre del Juego:** Duelo de Hechiceros — Crónicas Arcanas (PC)
* **Motor Gráfico:** Godot Engine 4.7.2 (Renderer: Forward+ / CanvasItems)
* **Lenguaje:** GDScript 2.0 (con tipado estático extensivo)
* **Género:** RPG de Acción y Estrategia Táctica Mágica en Tiempo Real (Perspectiva 3D isométrica / cenital táctica)
* **Inspiración:** Remake y modernización táctica del clásico juego de PC / MS-DOS *Duelo de Hechiceros*, enriquecido con mecánicas modernas de acción RPG (crafteo, niebla de guerra, personalización, árboles de hechizos, conquista territorial).
* **Filosofía de Interfaz:** Dark Fantasy Arcano (`DLG-INNOV`) — Minimalismo en combate (cobertura < 12%), microinteracciones fluidas, shaders de cooldown en GPU y accesibilidad completa.

---

## 🏛️ 2. Arquitectura General del Código

### 2.1 Autoloads y Gestores Globales (`project.godot`)
* `AudioManager` (`scripts/audio_manager.gd`): Gestor de audio polifónico con crossfade musical, buses `Master`, `Music`, `SFX`, `UI`, y generación de SFX táctiles procedurales.
* `GameManager` (`scripts/game_manager.gd`): Estado global de partida, modos de juego (Supervivencia, Exploración, Campaña), control de flujo y puntuaciones.

### 2.2 Sistema de Combate y Magia
* `Player` (`scripts/player.gd`): Controlador del personaje con locomoción por teclado/gamepad, apuntado táctico, canalización de hechizos, esquiva y gestión de estamina/salud/maná.
* `CharacterAppearance` (`scripts/character_appearance.gd`): Modificación dinámica de materiales y colores de modelo 3D (túnica, piel, accesorios).
* `Spells` (`scripts/`):
  * `magic_bolt.gd`, `fireball.gd`, `ice_projectile.gd`, `lightning_bolt.gd`, `earth_fissure.gd`, `arcane_shield.gd`, `arcane_vines.gd`, `shockwave.gd`, `teleport_effect.gd`, `summon_circle.gd`, `heal_effect.gd`.
* `Enemies & Bosses`:
  * `enemy.gd`: IA enemiga con velocidades escalonadas, desenganche táctico, estados alterados (Freeze, Stun, Burn, Sink, Root) y debilidades elementales.
  * `goblin_minion.gd`, `bone_arrow.gd`, `rival_wizard.gd` (Archimago Malakor).
* `VFX Library` (`scripts/vfx_library.gd`): Creación programática y pooling de efectos arcanos con shaders GPU.

### 2.3 Generación Procedural y Escenario
* `MapGenerator` (`scripts/map_generator.gd`): Generación de mapas por cuadrícula con biomas, caminos, vegetación, monolitos y fuentes sagradas.
* `FogOfWar` (`scripts/fog/fog_of_war.gd`): Cuadrícula 128x128 con persistencia de exploración, oclusión de enemigos en minimapa y shader volumétrico 3D (`shaders/fog_of_war_3d.gdshader`).
* `PlaceOfPower` (`scripts/place_of_power.gd`): Mecánica territorial de captura y disputa de nodos mágicos.
* `GatheringNode` (`scripts/gathering_node.gd`): Nodos interactivos de recolección en el mundo (hierbas, vetas de mineral, árboles frutales).

### 2.4 Economía, Inventario y Crafteo
* `ItemDB` (`scripts/inventory/item_db.gd`): Catálogo extensible de consumibles, reactivos, gemas y pergaminos.
* `InventoryManager` (`scripts/inventory/inventory_manager.gd`): Rejilla de 16 slots, persistencia, drag-and-drop, filtros y atajos de consumibles rápidos.
* `CraftingManager` (`scripts/crafting/crafting_manager.gd`): Mesas de trabajo (Alquimia, Forja, Cocina) con validación de recetas e ingredientes.
* `LoreManager` (`scripts/lore/lore_manager.gd`): Fragmentos de historia, oráculos y diarios coleccionables.

### 2.5 Interfaz de Usuario y HUD (`scripts/ui/` y `scenes/ui/`)
* `HUD` (`scripts/hud.gd`): 3 clusters flotantes (Vida/Buffs, Spellbar/Pociones, Maná/Minimap), Damage Trail diferido.
* `CharacterCreator` (`scripts/ui/character_creator.gd`): Turntable 3D aislado con iluminación de estudio para personalización de clase y apariencia.
* `WorldMapModal` (`scripts/ui/world_map_modal.gd`): Mapa táctico con zoom, paneo, orientación en tiempo real y niebla descubierta.
* `GrimoireModal` (`scripts/ui/grimoire_modal.gd`): Consulta y asignación de 11 hechizos a la barra rápida.
* `CraftingModal` (`scripts/ui/crafting_modal.gd`): Interfaz de taller con preview de resultados y recetas disponibles.
* `SettingsModal` (`scripts/ui/settings_modal.gd`): Volumen, pantalla completa, accesibilidad (reducir destellos y sacudidas) persistente en config.

---

## 📈 3. Estado de Avance y Pruebas de QA

El proyecto cuenta con un sistema de orquestación y suites de pruebas automatizadas headless:
1. **QA Suite Principal (`scenes/QASuite.tscn`):** 36/36 pruebas aprobadas (100%).
2. **Gameplay Depth Suite (`scenes/TestGameplayDepthSuite.tscn`):** 59/59 pruebas aprobadas (100%).
3. **Orchestrator Suite (`scenes/TestOrchestratorSuite.tscn`):** 32/32 pruebas aprobadas (100%).
4. **Total de Pruebas Automatizadas:** **127/127 aprobadas (100%)**.
5. **Benchmark de Rendimiento:** Frame time de UI medido en **0.83 ms** (presupuesto < 1.0 ms).

### Hitos Recientes del Repositorio (Git History):
* **Launcher & Direct Play:** Accesos directos y scripts batch de ejecución en un clic.
* **Agente E (Crafteo y Nodos):** Sistema de recolección en tiempo real, 40+ ítems y modal de taller.
* **Agente D (Creador de Personaje):** Vista 3D rotatoria en Viewport aislado, arquetipos (Mago, Pícaro, Guardabosques).
* **Agente C (Niebla de Guerra):** Cuadrícula 128x128 con shader volumétrico y ocultamiento en minimapa.
* **Agente B (Grimorio):** 11 hechizos con cooldown radial GPU y asignación de hotbar.
* **Agente A (Combate & IA):** IA con desenganche, estados alterados (CC) y boss dragón.
* **Agente 0 (Rendimiento):** Throttling O(1), pooling de números de daño y LOD de vegetación.

---

## 🎯 4. Preguntas y Áreas para el Análisis de ChatGPT

Por favor, realiza un análisis integral del estado del proyecto cubriendo los siguientes ejes:

1. **Arquitectura y Modularidad en Godot 4:**
   - ¿Qué tan desacoplados y mantenibles están los subsistemas (Combate, Inventario, Crafteo, Generación de Mapas, UI)?
   - ¿Hay cuellos de botella de acoplamiento excesivo o dependencias directas que deban reemplazarse por señales o eventos?

2. **Calidad de Código y Buenas Prácticas GDScript:**
   - Uso de tipado estático, manejo de ciclos de vida (`_ready`, `_process`, `_physics_process`).
   - Gestión de memoria y prevención de fugas (nodos instanciados, partículas, tweens y timers).

3. **Game Design y Balance de Mecánicas:**
   - ¿Cómo se articulan el bucle de juego básico (Exploración -> Recolección -> Combate -> Crafteo -> Captura Territorial)?
   - Evaluación del sistema de 11 hechizos y debilidades elementales: ¿hay redundancias o nichos tácticos vacíos?
   - Progresión del jugador y escalabilidad de la economía de ítems.

4. **Rendimiento y Escalabilidad:**
   - Análisis de las soluciones de pooling implementadas frente al aumento de enemigos en oleadas.
   - Evaluación del uso de Shaders en GPU vs procesamiento en CPU (niebla, cooldowns, terreno).

5. **Hoja de Ruta y Próximos Pasos Recomendados:**
   - ¿Cuáles deberían ser las prioridades técnicas y de diseño para la siguiente fase de desarrollo (ej. multijugador en red, árboles de talentos, soporte de mandos mejorado, narrativa procedural)?

---

## 📁 5. Estructura de Archivos en este Paquete

```
Duelo_de_Hechiceros/
├── project.godot                  # Configuración principal del motor Godot 4.7.2
├── default_bus_layout.tres        # Configuración de buses de audio (Master, Music, SFX, UI)
├── README.md                      # Documentación para desarrolladores y jugadores
├── ASSET_MANIFEST.md              # Registro y trazabilidad de assets
├── ANALISIS_PROYECTO_CHATGPT.md   # Este documento maestro de contexto
├── docs/                          # Documentación arquitectónica, planes de QA y guías de estilo
│   ├── MASTER_PROMPT_PACK.md      # Especificación completa de agentes de desarrollo
│   ├── ORCHESTRATOR_MASTER_PLAN.md# Los 5 pilares de evolución
│   ├── ORCHESTRATOR_STATUS.md     # Estado actual de los 5 pilares
│   ├── QA_REPORT.md               # Informe maestro de 36 pruebas de QA
│   ├── UI_STYLE.md                # Guía de estilo Dark Fantasy Arcano (DLG-INNOV)
│   ├── UI_CHANGELOG.md            # Registro de evolución de la interfaz
│   ├── UI_PERFORMANCE.md          # Benchmark de frametime (< 1.0 ms)
│   ├── SPELLS.md                  # Especificación de hechizos
│   ├── VFX_REPORT.md              # Sistema de efectos visuales y shaders
│   └── perf/INFORME.md            # Métricas de optimización y pooling
├── scenes/                        # Escenas Godot (.tscn) de juego, entidades y UI
│   ├── Main.tscn, MainMenu.tscn, HUD.tscn, Wizard.tscn, RivalWizard.tscn, ...
│   └── ui/                        # Modales (CharacterCreator, GrimoireModal, CraftingModal, etc.)
├── scripts/                       # Código fuente en GDScript (.gd)
│   ├── player.gd, enemy.gd, map_generator.gd, audio_manager.gd, game_manager.gd, ...
│   ├── crafting/                  # Lógica de crafteo y recetas
│   ├── fog/                       # Niebla de guerra
│   ├── inventory/                 # Inventario e ítems
│   ├── lore/                      # Gestor de historia y pergaminos
│   ├── tests/                     # Suites automatizadas de testeo
│   └── ui/                        # Controladores de interfaz y shaders de pantalla
├── shaders/                       # Shaders GLSL/Godot (.gdshader) de terreno, niebla y modelos
├── tests/                         # Pruebas adicionales
└── tools/                         # Scripts de orquestación y herramientas auxiliares (.py, .gd)
```
