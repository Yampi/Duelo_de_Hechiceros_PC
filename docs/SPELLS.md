# Grimorio de Hechizos — Duelo de Hechiceros

Documento de referencia canónica para los 11 hechizos arcanos del juego, sus parámetros de combate exactos (`GameManager.spell_catalog`), controles, efectos secundarios y arquitectura de ejecución.

## Tabla Canónica de Hechizos

| # | Id Interno | Hechizo | Tecla / Slot | Costo (MP) | Windup (s) | Cooldown (s) | Efecto / Daño | Área / Alcance | Efectos Secundarios y Mecánicas |
|---|------------|---------|--------------|------------|------------|--------------|---------------|----------------|---------------------------------|
| **1** | `magic_bolt` | **Centella Arcana** | `[1]` | 8.0 | 0.15 | 0.60 | 25.0 *(40.0 pot.)* | Directo *(2.8m AoE pot.)* | Empuje 6.0m (12.0m pot.); se potencia con santuarios arcanos |
| **2** | `fireball` | **Bola de Fuego** | `[2]` | 20.0 | 0.55 | 2.00 | 65.0 | 3.2m radio | Gran retroceso de área, sacudida de pantalla (0.35s), DoT ígneo |
| **3** | `summon_goblin` | **Invocar Duende** | `[3]` | 30.0 | 0.75 | 8.00 | 36.0 (impacto) | 2.5m radio círculo | Invoca un esbirro duende aliado que combate y acompaña al hechicero |
| **4** | `shockwave` | **Onda Expansiva** | `[4]` | 18.0 | 0.50 | 3.00 | 35.0 | 5.0m radio | Empuje radial masivo y aturdimiento de 1.0s a enemigos cercanos |
| **5** | `heal` | **Fuente de Vida** | `[5]` | 25.0 | 0.85 | 5.00 | +40 HP | Personal | Bloqueo preventivo anti-desperdicio si HP está al 100% ("Vida completa") |
| **6** | `teleport` | **Teletransporte** | `[6] / [Espacio]` | 15.0 | 0.20 | 3.00 | Movilidad | 18.0m hacia cursor | Parpadeo dimensional instantáneo, partículas de origen y llegada |
| **7** | `ice_projectile` | **Proyectil de Hielo** | `[7] / [T]` | 12.0 | 0.25 | 1.20 | 35.0 | Proyectil | Aplica lentitud (-45% vel. 4.0s); 3 impactos acumulan congelación (2.0s) |
| **8** | `lightning` | **Rayo Arcano** | `[8] / [R]` | 24.0 | 0.30 | 2.80 | 35.0 | Cinta volumétrica 3D | Raycast balístico instantáneo; aturde y encadena hasta 2 enemigos (5.5m) |
| **9** | `arcane_shield` | **Escudo Mágico** | `[9] / [F]` | 20.0 | 0.35 | 6.00 | Defensivo | Esfera Fresnel personal | Absorbe 65% de daño recibido por 7.5s; smart fallback en `[F]` |
| **10** | `earth_fissure` | **Fisura de Tierra** | Grimoire `[G]` | 22.0 | 0.35 | 2.50 | 20.0 | 4.0m radio | Pantano de fango sísmico: hunde y ralentiza 70% a enemigos durante 4.0s |
| **11** | `arcane_vines` | **Enredaderas Arcanas** | Grimoire `[G]` | 25.0 | 0.40 | 3.50 | 15.0 | 3.0m radio | Zarzas arcanas: inmovilizan completamente (enraízan) durante 3.0s |

---

## Controles e Integración de Interacción

- **Slots 1 a 9 (`[1]` .. `[9]`)**: Selección y lanzamiento directo de los 9 hechizos equipados en la barra de combate.
- **Acceso Rápido Ergonómico**:
  - `[Espacio]`: Teletransporte rápido hacia la dirección del cursor.
  - `[T]`: Proyectil de Hielo (slot 7).
  - `[R]`: Rayo Arcano (slot 8).
  - `[F]`: Smart key — Si el jugador se encuentra frente a un interactuable (`WorldItem`, `AncientAltar`, `FruitTree`, `GatheringNode`), interactúa de inmediato. Si no hay objeto en rango, ejecuta Escudo Mágico.
- **Interacción Universal Directa**:
  - `[E]`: Prioridad absoluta de interacción con cualquier elemento del mundo (recoger botín, activar santuarios arcanos, recolectar nodos botánicos y minerales).
- **Consumibles Rápidos**:
  - `[Q]`: Poción de salud / Manzana (cura HP).
  - `[Z]`: Poción de maná / Pergamino arcano (regenera MP y aplica Haste).
- **Grimorio y Personalización**:
  - `[G]`: Modal de Grimorio para intercambiar hechizos entre el catálogo de 11 y las 9 ranuras activas.

---

## Modificaciones y Correcciones Integradas

1. **Rayo Arcano (`scripts/lightning_bolt.gd`)**:
   - Geometría volumétrica de doble cinta cruzada (quads) con núcleo blanco radiante y halo arcano cian (`StandardMaterial3D` aditivo no sombreado).
   - Raycast balístico preciso con `PhysicsRayQueryParameters3D`.
   - Bifurcación eléctrica hacia hasta 2 objetivos secundarios en un radio de 5.5 metros.

2. **Escudo Mágico y Shader Fresnel (`shaders/fresnel_shield.gdshader`)**:
   - Domo esférico con shader Fresnel reactivo a impactos (`hit_intensity`).
   - Las pruebas automatizadas verifican la atenuación alfa tanto en `StandardMaterial3D` como en `ShaderMaterial`.

3. **Fuente de Vida (`scripts/player.gd`)**:
   - Bloqueo preventivo si `GameManager.player_health >= GameManager.player_max_health`.
   - Muestra indicador flotante `💚 Vida completa` sin coste de maná ni activación de cooldown.

4. **Corrección de Trayectoria de Bola de Fuego (`scripts/fireball.gd`)**:
   - Actualización explícita de `global_position = target_point` previa al llamado de `explode()` al completar la trayectoria parabólica, garantizando detonación exacta en el punto de impacto.

5. **IA y Locomoción Enemiga (`scripts/enemy.gd`)**:
   - Rango de detección calibrado en 22.0m para `SKELETON_ARCHER`.
   - Desacople de rotación forzada durante la recarga de ataque en `FIRE_IMP`, permitiendo maniobras orbitales fluidas de kiting.
   - Estado `CHASE` selectivo: congelamiento de avance solo para unidades cuerpo a cuerpo (`GOBLIN`, `SKELETON_SPEAR`), manteniendo movimiento táctico en enemigos a distancia.
