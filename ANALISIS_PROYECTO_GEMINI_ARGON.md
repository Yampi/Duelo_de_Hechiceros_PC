# GUÍA DE ANÁLISIS DE PROYECTO PARA GEMINI 4 ARGON
## Proyecto: "Duelo de Hechiceros — Crónicas Arcanas" (PC)
**Versión del Motor:** Godot Engine 4.7.2 Forward+ (GDScript 2.0 estático)  
**Fecha de Corte:** Octubre 2026  
**Línea de Diseño UI/UX:** Dark Fantasy Arcano (`DLG-INNOV`)  

> **Nota para Gemini 4 Argon:**  
> Este documento resume el contexto histórico, la arquitectura técnica, las mecánicas de combate y exploración, las implementaciones multi-agente y los resultados de control de calidad (QA) del proyecto.  
> Se acompaña en este paquete ZIP con la totalidad del código fuente (`scripts/`), árboles de escenas (`scenes/`), shaders GLSL (`shaders/`), configuraciones (`project.godot`), suites de pruebas (`tests/` y `scripts/tests/`) y documentación técnica completa (`docs/`).

---

## 📋 1. Ficha Técnica y Visión del Proyecto

* **Nombre:** Duelo de Hechiceros — Crónicas Arcanas (PC)
* **Motor Gráfico:** Godot Engine 4.7.2 Forward+ (Renderer Vulkan/Forward+ para iluminación física, niebla volumétrica y shaders GPU).
* **Lenguaje:** GDScript 2.0 con tipado estático estricto en el 100% de los controladores.
* **Género:** RPG de Acción y Estrategia Táctica Mágica en Tiempo Real con perspectiva isométrica / cenital táctica 3D.
* **Inspiración y Legado:** Remake y modernización táctica del clásico de 1998 *Magic & Mayhem* (Julian Gollop / Mythos Games / Virgin Interactive), comercializado en español como *Duelo de Hechiceros*.
* **Trama Principal:** El hechicero Cornelius emprende una travesía a través de tres dominios mitológicos (Avalon Céltico, Grecia Mítica y Tártaro Gótico) para desentrañar la desaparición de su mentor, el Maestro Lucian, y evitar que el Archimago Malakor corrompa los Manantiales del Maná Primordial.

---

## 🏛️ 2. Los 5 Pilares de Evolución (Master Orchestrator)

El desarrollo del proyecto se rige por un marco de orquestación técnica dividido en cinco pilares activos:

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

1. **Pilar I: Trama y Lore Mitológico ("El Legado de Lucian"):**
   * Gestor central de conocimiento: `LoreManager` (`scripts/lore/lore_manager.gd`).
   * Elementos interactivos en el mundo: Monolitos de los Oráculos (`scenes/OracleMonolith.tscn` / `scripts/oracle_monolith.gd`) con anillos rúnicos procedurales y revelación de códice con recompensas arcanas al pulsar `[E]`.
   * Integración de diarios de campo, profecías célticas y oráculos antiguos a lo largo de las 4 zonas del mapa.

2. **Pilar II: Duelos y Guerra Territorial:**
   * Lugares de Poder (`scenes/PlaceOfPower.tscn` / `scripts/place_of_power.gd`): Captura territorial bidireccional basada en radio de presencia. El maná no se regenera de forma trivial; quien domina los nodos territoriales controla la tasa de regeneración de maná.
   * IA Hechicero Rival (`scenes/RivalWizard.tscn` / `scripts/rival_wizard.gd`): Archimago Malakor implementa una máquina de estados de combate con teletransporte evasivo, escudos de protección, invocación de esbirros de distracción y canalización de hechizos de largo alcance.

3. **Pilar III: Escenarios Vivos y Render Godot 4.7 Forward+:**
   * Generador de mapas por cuadrícula con 4 zonas de bioma diferenciadas (`scripts/map_generator.gd`, `scripts/map_config.gd`).
   * Shaders GLSL personalizados:
     * `shaders/terrain.gdshader`: Mezcla procedural de texturas de terreno con perturbación de vértices para romper la monotonía visual.
     * `shaders/foliage_grass.gdshader`: Deformación por viento y sombreado estilizado de vegetación.
     * `shaders/fog_of_war_3d.gdshader`: Niebla volumétrica tridimensional suave sincronizada con la cuadrícula de exploración.

4. **Pilar IV: Bestiario y Combate Táctico:**
   * Esbirros y criaturas: Duendes ladrones (`GoblinMinion.tscn`), arqueros y lanceros esqueléticos (`BoneArrow.tscn`), diablillos ígneos y sombríos.
   * Jefe Dragón con rig cinemático de 33 huesos.
   * Sistema de Control de Masas (CC): Estados de Congelación (*Freeze*), Aturdimiento (*Stun*), Quemadura (*Burn*), Hundimiento/Ralentización (*Sink*), y Enraizamiento (*Root*).
   * Sistema elemental de debilidades y resistencias (Tríada Cósmica: Ley vs Caos vs Neutralidad).

5. **Pilar V: Pipeline Multimedia y QA Autónomo:**
   * Scripts de orquestación headless (`tools/orchestrator.py`).
   * **127 de 127 pruebas automatizadas aprobadas (100%)** en ejecución continua:
     * *Master QA Suite* (`scenes/QASuite.tscn`): 36/36 tests.
     * *Gameplay Depth Suite* (`scenes/TestGameplayDepthSuite.tscn`): 59/59 tests.
     * *Orchestrator Suite* (`scenes/TestOrchestratorSuite.tscn`): 32/32 tests.
   * Frame time de render de UI medido en **0.83 ms** (presupuesto estricto < 1.0 ms).

---

## ⚡ 3. Arquitectura Multi-Agente Implementada

El proyecto ha completado los hitos técnicos de seis sub-agentes arquitectónicos:

| Agente | Enfoque | Logros y Archivos Clave |
|---|---|---|
| **Agente 0** | **Rendimiento & Optimización** | Throttling O(1) de procesamiento de IA; límite estricto de 12 enemigos en modo Supervivencia; object pooling para números de daño flotantes (`damage_number.gd`) y VFX; LOD procedural de vegetación. |
| **Agente A** | **Combate & IA Hostil** | Velocidades de movimiento escalonadas por tipo de enemigo; desenganche táctico inteligente al recibir daño crítico; 5 estados alterados de CC; IA del Boss Dragón. (`scripts/enemy.gd`, `scripts/player.gd`). |
| **Agente B** | **Grimorio y Magia Arcana** | 11 hechizos implementados (`magic_bolt.gd`, `fireball.gd`, `ice_projectile.gd`, `lightning_bolt.gd`, `earth_fissure.gd`, `arcane_shield.gd`, `arcane_vines.gd`, `shockwave.gd`, `teleport_effect.gd`, `summon_circle.gd`, `heal_effect.gd`); shaders de cooldown radial en GPU; modal interactivo de Grimorio (`scripts/ui/grimoire_modal.gd`). |
| **Agente C** | **Niebla de Guerra (Fog of War)** | Rejilla lógica de 128x128 (`scripts/fog/fog_of_war.gd`); persistencia de cuadrantes explorados; ocultamiento estricto de enemigos en el minimapa (`scripts/ui/minimap.gd`); niebla volumétrica 3D (`shaders/fog_of_war_3d.gdshader`). |
| **Agente D** | **Creador de Personaje 3D** | SubViewport aislado con turntable 3D (`scenes/ui/CharacterCreator.tscn`); 3 arquetipos de clase (Mago, Pícaro, Guardabosques); personalización dinámica de túnica, cabello y ojos (`scripts/character_appearance.gd`); persistencia en sesión. |
| **Agente E** | **Crafteo, Inventario y Nodos** | Catálogo de más de 40 ítems (`scripts/inventory/item_db.gd`); tres disciplinas de taller (Alquimia, Forja, Cocina) en `CraftingManager`; nodos de recolección en el mundo (`GatheringNode.tscn`, hierbas, vetas, árboles frutales); modal de taller (`CraftingModal.tscn`). |

---

## 🎨 4. Directiva de Diseño UI/UX (`DLG-INNOV`)

Siguiendo la gobernanza *Design Line Governance (DLG-INNOV - Dark Fantasy Arcano)*:
* **Cobertura en Combate:** Menor al 12% del área visible para priorizar la lectura espacial de proyectiles y telegrafiado de enemigos.
* **Clusters de HUD:** 
  1. *Superior Izquierdo:* Salud, Estamina, Maná y barra de efectos de estado con *Damage Trail* diferido.
  2. *Inferior Centro:* Hotbar de hechizos con shaders de cooldown radial GPU y accesos rápidos a consumibles.
  3. *Superior Derecho:* Minimapa táctico con oclusión por niebla de guerra y brújula de Lugares de Poder.
* **Accesibilidad Universal:** Configuración persistente (`SettingsModal`) para reducción de sacudida de cámara (*screen shake*), eliminación de destellos estroboscópicos y soporte de navegación completa.

---

## 🎯 5. Guía de Auditoría para Gemini 4 Argon

Agradecemos que realices un análisis crítico, profundo y propositivo del proyecto centrándote en los siguientes 5 ejes fundamentales:

### Eje 1: Arquitectura y Desacoplamiento en Godot 4
* Evalúa la relación entre Autoloads (`GameManager`, `AudioManager`, `ItemDB`, `InventoryManager`, `CraftingManager`, `LoreManager`, `SettingsManager`) y los nodos de juego. ¿Existe un acoplamiento excesivo que vulnere los principios SOLID o patrones de arquitectura limpia?
* ¿Cómo evaluarías la implementación de un Bus de Eventos global vs Señales directas en el árbol de escenas para los eventos de combate, crafteo y captura de territorio?

### Eje 2: Calidad de GDScript 2.0 y Ciclos de Vida
* Revisa el uso de tipado estático, constantes tipadas y diccionarios de datos en `scripts/player.gd`, `scripts/enemy.gd`, `scripts/rival_wizard.gd` y `scripts/map_generator.gd`.
* Evalúa la gestión de memoria y el ciclo de vida: instanciación de proyectiles, pooling de efectos visuales (`vfx_library.gd`), manejo de `QueueFree()`, uso de Tweens y Timers huérfanos.

### Eje 3: Game Design, Curva de Dificultad y Balance Táctico
* ¿Cómo se articula el bucle principal de juego (*Core Loop*): Exploración en Niebla ➔ Recolección de Reactivos ➔ Crafteo en Taller ➔ Duelo Táctico / Conquista Territorial?
* ¿Es coherente la curva de gasto y regeneración de maná condicionada a los Lugares de Poder frente al ritmo de lanzamiento de los 11 hechizos?
* Analiza el comportamiento táctico de la IA de Archimago Malakor (`rival_wizard.gd`): ¿ofrece un reto justo, telegrafiado adecuado y variedad táctica frente a las 3 clases de personaje?

### Eje 4: Shaders y Rendimiento Gráfico Forward+
* Revisa los shaders GLSL en `shaders/`: `terrain.gdshader`, `fog_of_war_3d.gdshader`, `foliage_grass.gdshader`, `wizard_body.gdshader` y `fog_minimap.gdshader`.
* ¿Hay operaciones costosas por fragmento que puedan optimizarse o transferirse a texturas precalculadas?
* ¿Cómo calificarías el balance entre fidelidad visual Dark Fantasy y rendimiento en máquinas de gama media/baja?

### Eje 5: Hoja de Ruta Tecnológica y Próximos Pasos
* Proporciona una recomendación priorizada para las siguientes etapas:
  1. Arquitectura de multijugador en red (Duelo de Hechiceros 1v1 PvP o Cooperativo PvE en Godot 4 vía High-Level Multiplayer / ENet).
  2. Árboles de talentos pasivos y progresión de personaje entre partidas (meta-progreso roguelite).
  3. Soporte formal para mandos / Gamepads con navegación radial.
  4. Narrativa procedural dinámica inspirada en los mitos artúricos y helénicos.

---

## 🗂️ 6. Mapa de Archivos Clave del Repositorio

```
Duelo_de_Hechiceros/
├── project.godot                     # Configuración Forward+, input map, autoloads y display
├── default_bus_layout.tres           # Master, Music, SFX, UI
├── README.md                         # Documentación técnica y manual de juego
├── ANALISIS_PROYECTO_GEMINI_ARGON.md # Esta guía maestra de auditoría
├── docs/                             # Especificaciones de diseño, QA y rendimiento
│   ├── ORCHESTRATOR_MASTER_PLAN.md   # Los 5 Pilares de evolución detallados
│   ├── ORCHESTRATOR_STATUS.md        # Estado actual de los 5 Pilares
│   ├── ORCHESTRATOR_QA_REPORT.md     # Informe consolidado de 127 pruebas
│   ├── QA_REPORT.md                  # Especificación de casos de prueba
│   ├── UI_STYLE.md                   # Guía de estilo DLG-INNOV
│   ├── UI_PERFORMANCE.md             # Benchmark de frametime (< 1.0 ms)
│   ├── SPELLS.md                     # Catálogo formal de hechizos y balance
│   └── VFX_REPORT.md                 # Arquitectura de efectos visuales y shaders
├── scenes/                           # Escenas de juego, entidades y modales
│   ├── Main.tscn, MainMenu.tscn, Wizard.tscn, RivalWizard.tscn, PlaceOfPower.tscn, ...
│   └── ui/                           # CharacterCreator, GrimoireModal, CraftingModal, WorldMapModal, HUD
├── scripts/                          # Código fuente GDScript 2.0
│   ├── player.gd, enemy.gd, rival_wizard.gd, map_generator.gd, audio_manager.gd, ...
│   ├── crafting/                     # crafting_manager.gd, crafting_recipe.gd
│   ├── fog/                          # fog_of_war.gd (Rejilla 128x128)
│   ├── inventory/                    # item_db.gd, inventory_manager.gd
│   ├── lore/                         # lore_manager.gd (Oráculos y diarios)
│   ├── tests/                        # test_agent_d_suite.gd, test_agent_e_suite.gd
│   └── ui/                           # hud.gd, character_creator.gd, grimoire_modal.gd, minimap.gd, etc.
├── shaders/                          # Shaders GLSL Forward+
│   ├── terrain.gdshader, fog_of_war_3d.gdshader, foliage_grass.gdshader, wizard_body.gdshader, etc.
├── tests/                            # Pruebas de integración
└── tools/                            # orchestrator.py, benchmark_terrain.gd, categorize_faces.py
```
