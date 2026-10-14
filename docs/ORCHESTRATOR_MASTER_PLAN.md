# PLAN MAESTRO DEL ORQUESTADOR — DUELO DE HECHICEROS
## Remake Táctico 3D de Combate Mágico en Tiempo Real (Godot 4.7.2 Forward+)

---

## 📖 1. Contexto Histórico y Fuente de Inspiración

En este directorio reside la herencia de **Magic & Mayhem** (1998, Mythos Games / Virgin Interactive), diseñado por **Julian Gollop** (creador de *X-COM* y *Chaos: The Battle of Wizards*), publicado en español bajo el título canónico **Duelo de Hechiceros**.

### El Núcleo de Oro del Juego Original:
1. **La Odisea Narrativa de Cornelius y Lucian:**
   El protagonista, Cornelius, emprende una búsqueda épica para hallar a su tío y mentor, el **Maestro Lucian**, desaparecido tras abrir las fuentes del **Maná Primordial** y advertir sobre la corrupción del Cónclave de Hechiceros.
2. **Mitología Tridimensional de Tres Reinos:**
   - **El Dominio Céltico (Avalon):** Bosques brumosos, dólmenes, druidas, trasgos y fuentes de vida.
   - **El Dominio Clásico (Grecia Mítica):** Templos helénicos derruidos, minotauros, centauros, oráculos y altares titánicos.
   - **El Dominio del Caos (Tártaro / Inframundo Gótico):** Gargantas volcánicas, ríos de azufre, dragones ancianos, nigromantes y ciudadelas corruptas.
3. **La Tríada Cósmica:**
   - **Ley (Law):** Orden, luz celestial, escudos protectores, paladines, rayos y sanación.
   - **Neutralidad (Neutral):** Fuerzas salvajes de la naturaleza, rocas, hielo, bestias de combate y teletransporte.
   - **Caos (Chaos):** Destrucción ígnea, terremotos, nigromancia de esqueletos, veneno y maldiciones.
4. **La Guerra Territorial del Maná:**
   El maná no es un recurso pasivo; emana directamente de los **Lugares de Poder (Places of Power)**. Quien controla los monolitos territoriales controla el flujo de energía arcana y el derecho a dominar el campo de batalla.
5. **Duelos de Hechiceros Auténticos:**
   Los enfrentamientos decisivos no son contra simples oleadas estúpidas, sino duelos tácticos 1v1 contra hechiceros rivales inteligentes (como Hermes o Malakor) equipados con báculos, grimorios propios, teletransporte de emergencia e invocaciones de distracción.

---

## 🏛️ 2. Los 5 Pilares de Transformación del Orquestador

El Orquestador estructura la evolución integral del proyecto sobre **cinco pilares inquebrantables**:

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

---

### 📜 PILAR I: Trama, Narrativa y Misiones Arcanas ("El Legado de Lucian")

* **Sistema de Lore Central (`scripts/lore/lore_manager.gd`):**
  - Registro de diarios de campo de Lucian, fragmentos de pergamino, oráculos parlantes y revelaciones místicas.
  - Recompensas inmediatas de maná e información táctica al descubrir cada pergamino o monumento.
* **Monolitos de los Oráculos (`scenes/OracleMonolith.tscn` / `scripts/oracle_monolith.gd`):**
  - Monumentos antiguos con anillos rúnicos giratorios y luz mística que el jugador consulta con `[E]`.
  - Integrados en el generador de mapas (`map_generator.gd`) a lo largo de las 4 zonas del mundo.
* **Capítulos Míticos por Zonas:**
  1. *Zona 1 (Pradera Inicial):* Diario de Lucian I — "El Despertar del Maná Primordial".
  2. *Zona 2 (Bosque Exterior):* Oráculo Céltico — "La Tríada Arcana (Ley, Neutralidad y Caos)".
  3. *Zona 3 (Corazón del Bosque):* Diario de Lucian II — "El Duelo contra Malakor".
  4. *Zona 4 (Ruinas Arcanas):* Inscripción Titánica — "La Caída del Cónclave de Hechiceros".

---

### ⚔️ PILAR II: Duelos de Hechiceros y Guerra Territorial de Maná

* **Captura Bidireccional de Lugares de Poder (`scripts/place_of_power.gd`):**
  - Estados territoriales: `NEUTRAL`, `PLAYER`, `ENEMY` y `CONTESTED`.
  - El Hechicero Rival puede arrebatar santuarios al jugador, reduciendo su capacidad máxima y regeneración de maná.
  - Si ambos están dentro del círculo, el territorio queda disputado sin avance de captura.
* **IA del Hechicero Rival (`scripts/rival_wizard.gd` / `scenes/RivalWizard.tscn`):**
  - **Archimago Malakor (Hereje del Caos):**
    - Combate a distancia con proyectiles de Centella y Bola de Fuego cargada.
    - **Teletransporte Evasivo (Blink):** Salta 12m dimensionalmente si el jugador se aproxima a cuerpo a cuerpo o al recibir impactos críticos.
    - **Escudo del Caos:** Barrera de energía reactiva que absorbe el 60% del daño al caer a < 50% de salud.
    - **Invocación Táctica:** Despliega esbirros de distracción para rodear al jugador.
    - **Guerra Territorial:** Se desplaza hacia los Lugares de Poder cercanos para conquistarlos.
* **Encuentro Canónico Integrado (`scripts/encounter_manager.gd`):**
  - Encuentro climáctico `z4_rival_wizard_duel` previo al portal final en la Avenida de las Columnas.

---

### 🌲 PILAR III: Escenarios Vivos y Fidelidad Gráfica Moderna (Godot 4.7 Forward+)

* **Motor Gráfico Forward+:**
  - Iluminación física con sombras de contacto (`directional_shadow_blend_splits`).
  - Niebla de altura exponencial por biomas (`WorldEnvironment.environment.fog`).
  - Oclusión ambiental de espacio en pantalla (SSAO) y resplandor (Glow) para gemas y runas mágicas.
* **Topografía y Arquitectura Mítica:**
  - Elevación progresiva continua: Pradera (0m) → Bosque (1.4m) → Garganta/Desfiladero (-1.8m) → Meseta Arcana (+7m).
  - Vías procesionales con columnas circulares, arcos de piedra helénicos, dólmenes célticos y monolitos.
  - Optimización de distancia de visión (`_apply_visibility_cull`) para mantener 60 FPS estables.

---

### 🐉 PILAR IV: Bestiario Mitológico e IA Táctica de Criaturas

* **Jerarquía de Criaturas en Combate:**
  1. *Esbirros Menores:* Duendes y Diablillos de Fuego (hostigadores rápidos pero frágiles, susceptibles a pánico ígneo).
  2. *Línea de Choque:* Esqueletos Lanceros (bloqueo táctico y empuje frontal) y Esqueletos Arqueros (kiting y flechas de hueso).
  3. *Duelistas Arcanos:* Hechiceros Rivales autónomos con grimorio y báculo.
  4. *Titanes Supremos:* Dragón mitológico (modelo ya disponible en assets) para fases de asedio.
* **Sistema de Debilidades y Bestiario Dinámico:**
  - Registro de vulnerabilidades elementales (Fuego, Hielo, Rayo, Tierra, Fuerza) que se descubre orgánicamente en combate y se anota en el Bestiario.

---

### 🛠️ PILAR V: Pipeline de Automatización y QA Headless

* **Herramienta CLI de Orquestación (`tools/orchestrator.py`):**
  - `python tools/orchestrator.py audit`: Auditoría estructural de scripts, escenas, shaders y assets.
  - `python tools/orchestrator.py test`: Ejecución desatendida headless de todas las suites.
  - `python tools/orchestrator.py status`: Emisión de informe actualizado en markdown.
  - `python tools/orchestrator.py all`: Pipeline integral (Auditoría + Pruebas + Estado).
* **Las 3 Suites de Verificación Automatizada (127 Pruebas):**
  1. `scenes/QASuite.tscn` — 36 pruebas aprobadas (UI, tokens, audio buses, inventario, modales).
  2. `scenes/TestGameplayDepthSuite.tscn` — 59 pruebas aprobadas (velocidades, IA, CC, topografía).
  3. `scenes/TestOrchestratorSuite.tscn` — 32 pruebas aprobadas (Lore, Oráculos, Rival Wizard, capturas territoriales).

---

## 🎯 3. Hoja de Ruta para Próximos Sprints

1. **Sprint A — Sistema de Invocaciones del Jugador (Alineación Ley / Neutralidad / Caos):**
   - Permitir al jugador invocar no solo duendes, sino esqueletos (Caos) o guardianes celestiales (Ley).
2. **Sprint B — Duelos Multizonales y Nuevos Duelistas Rivales:**
   - Hechicero Druídico en la Zona 2 (invoca zarzas y bestias) y Archimago Helénico en la Zona 3.
3. **Sprint C — Audio Inmersivo y Cinemáticas Ligeras:**
   - Incorporar pistas de audio dinámicas de duelo que aumentan de tempo al entrar en combate con un mago rival.
