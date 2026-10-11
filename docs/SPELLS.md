# Grimorio de Hechizos — Duelo de Hechiceros

Documento de referencia canónica para los 9 hechizos del jugador, sus parámetros de combate, teclas asociadas, efectos secundarios y estado de auditoría.

## Tabla de Hechizos

| # | Hechizo | Tecla | Costo (MP) | Windup (s) | Cooldown (s) | Daño | Área | Efectos Secundarios | Estado |
|---|---------|-------|------------|------------|--------------|------|------|---------------------|--------|
| **1** | **Centella Arcana** | `[1]` | 5.0 | 0.18 | 0.40 | 25.0 *(42.0 pot.)* | Directo *(2.8m AoE pot.)* | Empuje 6.0m (12.0m pot.); se potencia con santuarios arcanos | **OK** |
| **2** | **Bola de Fuego** | `[2]` | 20.0 | 0.55 | 1.20 | 65.0 | 3.2m radio | Gran retroceso de área, sacudida de cámara (0.35s) | **OK** |
| **3** | **Invocar Duende** | `[3]` | 30.0 | 0.70 | 2.50 | 36.0 (impacto) | 2.5m radio círculo | Invoca un esbirro duende aliado que combate y sigue al mago | **OK** |
| **4** | **Onda Expansiva** | `[4]` | 25.0 | 0.50 | 1.80 | 35.0 | 5.0m radio | Empuje radial masivo aleja a todos los enemigos circundantes | **OK** |
| **5** | **Fuente de Vida** | `[5]` | 35.0 | 0.85 | 3.00 | 0.0 (Cura +40 HP) | Sobre el jugador | No consume maná si la vida está al 100% ("Vida completa") | **Arreglado** |
| **6** | **Teletransporte** | `[6]` | 15.0 | 0.20 | 1.00 | 0.0 | Desplazamiento 18.0m | Teletransporte instantáneo hacia el cursor con parpadeo arcano | **OK** |
| **7** | **Proyectil de Hielo** | `[7] / [T]` | 12.0 | 0.25 | 0.60 | 35.0 | Proyectil | Aplica *Slow* (-45% velocidad durante 4.0s); proyectil estable | **Arreglado** |
| **8** | **Rayo Arcano** | `[8] / [R]` | 18.0 | 0.30 | 0.80 | 35.0 | Raycast directo + 2.6m impacto | Descarga con cinta de quads (núcleo blanco + halo cian), daña trayectoria y encadena a 1-2 enemigos | **Arreglado** |
| **9** | **Escudo Mágico** | `[9] / [C]` | 20.0 | 0.35 | 4.00 | 0.0 (Defensivo) | Esfera personal | Absorbe 65% del daño recibido durante 7.5s; indicador temporal en HUD | **Arreglado** |

---

## Modificaciones y Correcciones Implementadas

1. **Rayo Arcano (`scripts/lightning_bolt.gd`)**:
   - Reemplazado el renderizado previo de `PRIMITIVE_LINES` de 1px por una geometría volumétrica de doble cinta cruzada (quads) con núcleo blanco radiante y halo arcano cian (`StandardMaterial3D` aditivo no sombreado).
   - Detección precisa de objetivos en la trayectoria entre la gema del báculo y el destino mediante `PhysicsRayQueryParameters3D`.
   - Explosión radial en punto de impacto y bifurcación/encadenamiento eléctrico hacia hasta 2 enemigos adicionales en un radio de 5.5 metros.
   - Feedback acústico/visual con sacudida de pantalla calibrada (0.25s) y chispas de impacto.

2. **Atajos de Teclado y HUD (`player.gd`, `HUD.tscn`, `hud.gd`)**:
   - Integración nativa de teclas `1` a `9` (`KEY_1` .. `KEY_9`) y combinaciones ergonómicas alternativas (`[T]` para slot 7, `[R]` para slot 8, `[C]` para slot 9).
   - Inclusión de los 9 slots en la barra inferior con badges claros de acceso rápido y tooltips detallados con el nombre, costo de maná y descripción funcional en una sola línea.

3. **Conflicto de Interacción (`KEY_E`)**:
   - Desacoplado el uso de consumibles del botón de interacción de mundo.
   - `KEY_E`: Acción unificada de interacción contextual de máxima prioridad con el objeto interactuable más cercano (`WorldItem`, `AncientAltar`, `FruitTree`) consumiendo el evento con `get_viewport().set_input_as_handled()`.
   - `KEY_Z`: Atajo exclusivo para pergamino / consumible de maná rápido (`KEY_Q` se conserva para pociones y manzanas de salud).

4. **Validación Fuente de Vida**:
   - La canalización y ejecución de *Fuente de Vida* evalúan preventivamente si la salud del jugador se encuentra al tope (`GameManager.player_health >= GameManager.player_max_health`).
   - Se muestra retroalimentación visual (`💚 Vida completa`) y no se descuenta ningún punto de maná ni se activa cooldown innecesario.

5. **Retroalimentación de Estado en HUD**:
   - El *Escudo Mágico* registra su duración en la barra de estados del HUD (`StatusIconBar`), mostrando la barra de tiempo restante.
   - El *Teletransporte* genera feedback de llegada y origen con partículas de parpadeo violeta y número flotante `✨ PARPADEO`.

6. **Sistema de Efectos Visuales (VFX) y Shaders (PARTE C)**:
   - **Centella Arcana**: Núcleo cian, anillos orbitales contrarrotantes, estela de motas (`glow_soft.png`) y burst explosivo de chispas en estrella (`spark_star.png`). Luz dinámica con flicker de alta frecuencia.
   - **Bola de Fuego**: Núcleo incandescente blanco-amarillo, manto esférico pulsante, estela de gotas de llama (`flame_tear.png`), explosión con chispas incandescentes y marca de quemadura persistente en el suelo (`smoke_noise.png`) que se disuelve en 3.5s.
   - **Invocar Duende**: Círculo rúnico arcano en el suelo (`magic_circle_runes.png`) con giro dinámico, haz de luz vertical, motas ascendentes moradas (`light_mote.png`) y estallido mágico al aparecer el duende.
   - **Onda Expansiva**: Anillo concéntrico brillante con adición luminosa, cúpula de energía y estallido radial de polvo y fragmentos (`dust_puff.png`).
   - **Fuente de Vida**: Sello rúnico de naturaleza en esmeralda/oro (`magic_circle_runes.png`), pilar cilíndrico de luz suave y motas curativas ascendentes (`light_mote.png`).
   - **Teletransporte**: Anillo de portal dimensional estilizado (`ring_sharp.png`), implosión y explosión de motas violetas (`spark_star.png`) y elongación dimensional transitoria del modelo del hechicero.
   - **Proyectil de Hielo**: Núcleo cilíndrico de carámbano con giro axial, estela de copos de nieve (`snowflake_crystal.png`), impacto con fragmentos de hielo y aura de escarcha persistente en enemigos ralentizados.
   - **Rayo Arcano**: Malla volumétrica de cinta 3D con doble capa (núcleo blanco + halo azul), ramificaciones secundarias, estallido de chispas eléctricas y bifurcación entre objetivos.
   - **Escudo Mágico**: Domo esférico con shader spatial hexagonal Fresnel (`fresnel_shield.gdshader`), onda de choque reactiva al recibir impactos (`hit_intensity`), anillos giroscópicos y motas arcanas orbitales (`light_mote.png`).
   - **Presupuesto de Rendimiento**: Todos los hechizos se mantienen estrictamente dentro del presupuesto de ≤150 partículas activas simultáneas a 60 FPS.

