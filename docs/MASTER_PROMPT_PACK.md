# MASTER PROMPT PACK — DUELO DE HECHICEROS

Este paquete contiene los prompts definitivos y sin ambigüedades, estructurados con base en **todas las respuestas y decisiones de diseño confirmadas por el usuario**.

---

## 📌 REGLAS COMUNES PARA TODOS LOS AGENTES (PREÁMBULO OBLIGATORIO)

```text
CONTEXTO: Proyecto Godot "Duelo de Hechiceros" (d:\Duelo_de_Hechiceros_PC), 3D, dark fantasy arcano, mapa 256x256 m en 4 zonas, 3 modos (Supervivencia, Exploración, Objetivo).
Godot Engine: tools\Godot_v4.7.2-stable_win64_console.exe (o C:\Users\soulw\OneDrive\Escritorio\GODOT 4.6.1\Godot_v4.6.1-stable_win64_console.exe).
Eres un agente AUTÓNOMO: decide con criterio técnico estricto, documenta decisiones en docs/ y NO asumas ni inventes mecánicas fuera de esta especificación.

DIRECTIVAS OBLIGATORIAS DE PROYECTO:
1. GIT: El repositorio ya está inicializado. Trabaja en tu propia rama (git checkout -b <tu-rama>) y haz commits atómicos tras cada hito.
2. CÓDIGO Y ARCHIVOS COMPARTIDOS: No reescribas scripts gigantes existentes si puedes modularizar en archivos nuevos. En scripts compartidos (player.gd, enemy.gd, hud.gd, main.gd) coloca llamadas/hooks limpios.
3. PRUEBAS HEADLESS: Toda prueba automatizada debe correrse como ESCENA (.tscn), NUNCA con --script suelto, para que carguen los Autoloads (GameManager, AudioManager, ThemeDB, etc.).
4. SIN NÚMEROS MÁGICOS: Parámetros de balance, atributos y recetas residen en recursos (.tres) o diccionarios tipados.
5. SIN FUEGO AMIGO HACIA EL MAGO: Los hechizos del jugador (como la Bola de Fuego) NO dañan al propio mago (daño = 0).
6. TECLAS Y CONTROLES: Teclado y ratón son la prioridad principal.
   - Selección de hechizos: Teclas 1 al 9 (Grimorio equipa 9 de N).
   - Interacción de mundo / recoger / activar: Tecla [E].
   - Poción rápida de salud: Tecla [Q].
   - Poción rápida de maná / pergamino: Tecla [Z].
   - Sprint / Correr: [Shift] (consume Estamina con barra HUD).
   - Lanzar hechizo: Clic izquierdo (con windup y cooldown).
```

---

## 🤖 AGENTE 0: RENDIMIENTO Y ESTABILIDAD (SUPERVIVENCIA 60 FPS)

```text
ROL: Agente 0 — Rendimiento y Estabilidad del Motor.
OBJETIVO: Eliminar los tirones y congelamientos que ocurren a los ~3 minutos en modo Supervivencia, asegurando 60 FPS estables en calidad alta.

DIAGNÓSTICO PREVIO:
1. Supervivencia genera 4 + (2 * oleada) enemigos cada 22s sin tope duro. A los 3 minutos se acumulan más de 20 enemigos vivos simultáneos.
2. O(n²) en enemy.gd: Cada enemigo en cada physics_frame calcula fuerzas de separación contra todos los demás y raycasts de línea de visión sin caché.
3. Instanciación y fugas: Creación continua de Label3D de números de daño, anillos de jefe y proyectiles que no siempre se reciclan.
4. Renderizado: Centenares de nodos individuales en el mapa de 256x256m sin instanciado MultiMesh ni LOD por distancia.

TAREAS ESPECÍFICAS:
1. TOPE DURO Y OLEADAS EN SUPERVIVENCIA (scripts/main.gd):
   - Establecer un tope máximo de 12 enemigos activos simultáneos en pantalla en Supervivencia.
   - Si una oleada requiere más enemigos, los excedentes quedan en cola de reserva (spawn queue) y aparecen a medida que los actuales mueren.
   - Las oleadas son INFINITAS, con un jefe garantizado cada 3 oleadas (Oleadas 3, 6, 9, etc.).
2. OPTIMIZACIÓN DE IA DE ENEMIGOS (scripts/enemy.gd):
   - Sustituir la fuerza de separación O(n²) por una cuadrícula espacial sencilla (Spatial Hash Grid) o limitarla a comprobar solo los 3 vecinos más cercanos.
   - Escalonar el cálculo de línea de visión (LOS): no ejecutarlo cada frame en todos los enemigos, sino cada 0.2s con offset aleatorio por enemigo.
   - Desactivar process_mode de enemigos a más de 45 metros del jugador (hibernación espacial) hasta que el jugador se aproxime.
3. POOLING Y LIMPIEZA DE NODOS:
   - Implementar Object Pooling para `DamageNumber.tscn` (reciclar instancias de números flotantes).
   - Garantizar que todos los efectos temporales (proyectiles, anillos, partículas) llamen a queue_free() con temporizadores seguros.
4. OPTIMIZACIÓN DE ENTORNO (scripts/map_generator.gd):
   - Agrupar rocas y vegetación decorativa repetitiva mediante MultiMeshInstance3D o configurar `visibility_range_end` para ocultar decorados lejanos.
5. ENTREGABLE:
   - Escena `scenes/BenchmarkSurvival.tscn` que corre 5 minutos en Supervivencia automatizada registrando FPS y memoria en `docs/perf/INFORME.md`. Meta: 60 FPS estables sin fugas.
```

---

## ⚔️ AGENTE A: BESTIAS, IA TÁCTICA, ESQUELETOS Y COMBATE CC

```text
ROL: Agente A — Comportamiento de Enemigos, Esqueletos/Animaciones y Sistema de Control de Masas (CC).
OBJETIVO: Hacer que los enemigos dejen de comportarse como imanes idénticos y ultra-rápidos, dotarlos de esqueletos/animaciones fluidas y funcionales, e implementar el sistema de CC y debilidades.

DECISIONES DE DISEÑO CONFIRMADAS:
1. Velocidades escalonadas: El jugador camina a 4.8 m/s y corre a 7.5 m/s. Ningún enemigo común corre a más de 5.5 m/s.
   - Enemigos lentos (3.2 a 3.8 m/s): El jugador puede escapar simplemente caminando.
   - Enemigos rápidos (4.8 a 5.4 m/s): Son frágiles; el jugador debe usar sprint o control de masas para alejarse.
2. Abandono de persecución real: Se pierde el rastro si:
   - Distancia > radio de abandono (18 a 24m según arquetipo).
   - O pérdida de visión (LOS) durante más de 4 a 6 segundos.
   - Al perder el rastro: el enemigo entra en estado SEARCH (mira alrededor), pasa a RETURN a su origen, y tiene un cooldown de 3s antes de volver a detectar al jugador.
3. Sprint con Estamina:
   - Activar la barra de estamina (`bar_stamina_fill.png`).
   - Correr consume estamina (duración base ~6-8s de sprint continuo). Se regenera al caminar o estar quieto.
4. Esqueletos y Animaciones (Auditoría real):
   - El Lancero (`Spear skeleton.glb`) solo tiene 2 huesos en su importación base: auditar y sustituir el modelo del Jefe por un modelo con rig completo (ej. `Dragon.fbx` o esqueleto con rig completo de 20+ huesos).
   - Todos los clips de patrulla/caminar/correr deben tener `loop_mode = LOOP_LINEAR`.
   - Ataques de enemigos sincronizados: El daño solo se aplica en el fotograma real del golpe, y la animación se completa sin cortarse abruptamente a los 0.3s.
   - Imps/Puglins: Rehacer su animación procedural de modo que respete las rotaciones relativas a la pose de reposo incluyendo piernas y sin deformar mallas.
   - Al morir: Desactivar colisión inmediatamente, remover del grupo "enemy", detener procesamiento de IA y ejecutar animación de muerte o disolución procedural limpia.
5. Sistema de CC (Control de Masas) y Debilidades Ocultas:
   - Hielo: Ralentización acumulativa (-45% a -80%) y CONGELAMIENTO total (inmovilizado 2.0s) tras 3 impactos seguidos.
   - Rayo: Aturdimiento instantáneo (micro-stun 0.4s) y encadenamiento eléctrico a 2 enemigos cercanos.
   - Onda Expansiva: Empuje masivo + aturdimiento de 1.0s.
   - Fuego: Quemadura DoT (daño por segundo durante 4s) y efecto pánico (huida breve) en enemigos tipo duende.
   - Tierra: Hunde a los enemigos en el lodo/suelo reduciendo velocidad en 70%.
   - Enredadera: Inmoviliza totalmente (Root/Atadura) durante 3.0s con ramas que brotan del suelo.
   - Debilidades y Bestiario: Cada arquetipo tiene resistencias y debilidades elementales ocultas. Al descubrirlas en combate, aparece un texto emergente ("¡Vulnerable!" / "¡Resiste!") y se registra la entrada en el Bestiario accesible desde el menú/grimorio.
```

---

## 📖 AGENTE B: GRIMORIO ARCANO Y NUEVOS HECHIZOS (TIERRA Y ENREDADERA)

```text
ROL: Agente B — Grimorio, Hechizos Nuevos y Balance Táctico.
OBJETIVO: Implementar los 2 nuevos hechizos (Tierra y Enredadera), el sistema de Grimorio donde el jugador elige y equipa 9 hechizos de su catálogo, y aplicar cooldowns reales en HUD.

TAREAS ESPECÍFICAS:
1. GRIMORIO DE HECHIZOS (Equipar 9 de N):
   - Pantalla modal / panel de Grimorio (accesible desde el Menú Principal y en pausa/inicio de partida).
   - El jugador visualiza su catálogo total de hechizos desbloqueados (11 iniciales: Centella, Fuego, Duende, Onda, Cura, Teleport, Hielo, Rayo, Escudo, Tierra, Enredadera).
   - 9 ranuras activas asignadas a las teclas numéricas [1] a [9].
   - Posibilidad de arrastrar o seleccionar qué hechizo va en cada número.
2. HECHIZO 10: FISURA / PANTANO DE TIERRA:
   - Costo: 22 MP. Windup: 0.35s. Cooldown: 2.5s.
   - Invoca una zona de fango/tierra removida de 4m de radio en el punto de mira.
   - Los enemigos que la pisan se hunden visualmente unos centímetros y su velocidad se reduce en un 70% durante 4s.
   - Malla de terreno deformada sutilmente + partículas de rocas y polvo.
3. HECHIZO 11: ENREDADERA ARCANAS (ROOT / ATADURA):
   - Costo: 25 MP. Windup: 0.40s. Cooldown: 3.5s.
   - Hace brotar zarzas mágicas en un radio de 3m. Inmoviliza por completo a los enemigos atrapados por 3.0 segundos (no pueden moverse, pero pueden atacar si el jugador está a su alcance cuerpo a cuerpo).
   - Efecto visual de ramas verdes entrelazadas + hojas.
4. COOLDOWNS REALES Y MANÁ EN HUD:
   - Conectar los cooldowns reales de cada hechizo al shader de barrido radial (`radial_cooldown.gdshader`) en `SpellSlot.tscn`.
   - Cooldown global de 0.3s entre lanzamientos para evitar macros/spam de un solo frame.
   - Costo de Centella Arcana aumentado de 5 a 8 MP.
   - Pausa de 1.5s en la regeneración pasiva de maná tras cada lanzamiento.
5. SIN DAÑO AL MAGO:
   - Garantizar que la Bola de Fuego y cualquier área elemental dañen ÚNICAMENTE a los enemigos y nunca al propio jugador.
```

---

## 🌫️ AGENTE C: NIEBLA DE GUERRA (FOG OF WAR) Y EXPLORACIÓN

```text
ROL: Agente C — Niebla de Exploración y Atmósfera 3D.
OBJETIVO: Ocultar el mapa inexplorado para que cada partida sea un descubrimiento, revelando terreno únicamente por donde camina el jugador, con enemigos visibles solo bajo línea de visión directa.

DECISIONES DE DISEÑO CONFIRMADAS:
1. Niebla por Partida:
   - En cada nueva partida el mapa inicia 100% cubierto por la niebla (se resetea, no es permanente entre partidas).
   - El mapa de 256x256m se divide en una cuadrícula de exploración (128x128 celdas, 2m por celda).
2. Radio de Visión y Borde Suave:
   - El jugador despeja la niebla en un radio de 20 metros a su alrededor.
   - El minimapa circular y el mapa modal despliegan un shader que aplica la máscara de niebla con textura de pergamino envejecido/sombra en las zonas no descubiertas.
3. Visibilidad de Enemigos y Objetivos:
   - Los enemigos NO aparecen en el minimapa como radar global: solo se dibujan marcadores de enemigos si están dentro del radio de visión Y con línea de visión despejada hacia el jugador.
   - Los objetivos lejanos se indican como una "Zona aproximada" difusa, no como un punto exacto en coordenadas.
4. Niebla Atmosférica 3D:
   - Configurar `WorldEnvironment.environment.fog` (niebla exponencial/altura, de muy bajo costo computacional).
   - Color adaptado a cada una de las 4 zonas (verde pálido en Pradera, esmeralda sombrío en Bosque, violeta brumoso en Corazón, rojizo-ceniza en Ruinas).
   - Transición suave de color de niebla al cruzar los límites de zona.
```

---

## 🧙 AGENTE D: PERSONALIZACIÓN DEL MAGO (COSMÉTICA PURA)

```text
ROL: Agente D — Personalización Visual del Mago.
OBJETIVO: Crear la pantalla de personalización del personaje manteniendo el modelo actual, con 4 a 6 opciones de alta calidad por categoría, como capa cosmética independiente del equipo.

DECISIONES DE DISEÑO CONFIRMADAS:
1. Modelo Base:
   - Mantener el modelo actual de mago (`WizardModel.tscn`).
   - Las opciones cosméticas son PURAMENTE VISUALES y no alteran las estadísticas del combate.
   - La capa de equipo (de la forja) proporciona las estadísticas en segundo plano sin pisar la personalización cosmética elegida por el jugador.
2. Catálogo de Opciones (4 a 6 por categoría):
   - Tono de piel: Paleta de 6 tonos (desde pálido arcano hasta bronceado).
   - Ojos: 6 variantes de diseño/color (iris azul arcano, fuego ámbar, esmeralda, vacío violeta, etc.).
   - Nariz y Boca: Atlas de variantes en la textura facial del modelo.
   - Pelo: 5 estilos de peinado modelados con mallas acopladas al hueso de la cabeza (`Head`).
   - Barba: 4 estilos (mago anciano, perilla rúnica, recortada, afeitado).
   - Sombrero: 5 variantes (clásico puntiagudo, birrete arcano, capucha mística, tiara rúnica, sin sombrero).
   - Túnica: Selector de color primario y secundario mediante parámetros de shader sobre los materiales del mago.
3. Pantalla de Creación (`scenes/ui/CharacterCreator.tscn`):
   - Vista 3D del mago en un SubViewport con iluminación de estudio, cámara orbital con ratón y animación idle.
   - Pestañas organizadas: Cabeza/Cara, Cabello y Barba, Sombrero y Túnica, Colores.
   - Botones: "Aleatorio", "Restablecer", "Guardar y Salir".
   - Integrada en el Menú Principal (botón "Personalizar Mago").
   - La apariencia elegida se guarda en `user://character_appearance.cfg` y se aplica automáticamente en todas las partidas y en el menú principal.
```

---

## 🧪 AGENTE E: GRAN SISTEMA DE ÍTEMS, ALQUIMIA, FORJA Y COCINA

```text
ROL: Agente E — Sistema Completo de Ítems, Recolección, Forja, Alquimia y Cocina.
OBJETIVO: Unificar el sistema de inventario (eliminando el diccionario legacy `reagents`), implementar más de 40 ítems y 15 recetas entre Alquimia, Forja, Cocina, Encantamiento y Reciclaje.

DECISIONES DE DISEÑO CONFIRMADAS:
1. Fuente Única de Verdad:
   - Eliminar `GameManager.reagents`. Todo ítem físico ahora es un `ItemDefinition` dentro de `InventoryManager`.
   - Persistencia: En modo Exploración el inventario y recetas descubiertas se guardan en `user://save_exploration.cfg`. En Supervivencia cada partida empieza desde cero.
2. Catálogo de Más de 40 Ítems (recursos en `data/items/*.tres`):
   - Consumibles / Pociones (8): Poción Salud menor/media/mayor, Poción Maná menor/media/mayor, Elixir de Regeneración, Frasco de Celeridad.
   - Comidas (8): Manzana silvestre, Guiso de raíces, Seta salteada, Pan de viajero, Asado de bosque, Caldo reconstituyente, Baya amarga, Manjar arcano. (Efectos: Curación lenta en el tiempo, saciedad, buffs temporales).
   - Hierbas y Flora (8): Trébol rúnico, Flor de fuego, Raíz de escarcha, Hoja de sombra, Hongo venenoso, Musgo vital, Rama de roble milenario, Flor de loto de maná.
   - Minerales y Metales (8): Lingote de hierro, Azufre alquímico, Fragmento de amatista, Cristal arcano, Núcleo de tormenta, Piedra de afilar, Polvo de mithril, Ceniza ígnea.
   - Equipo Forjado (8): Báculo de sauce, Báculo de cristal, Sombrero de erudito, Túnica de tejedor de runas, Anillo de protección, Cinturón de alquimista, Guantes de canalización, Botas ligeras. (Aportan estadísticas pasivas: +Maná Máximo, +Regeneración, +Resistencia elemental, +Estamina).
3. 5 Sistemas de Elaboración (15+ Recetas en `data/recipes/*.tres`):
   - Alquimia: Destilación de pociones y elixires combinando hierbas y reactivos minerales.
   - Cocina: Preparación de comidas con efectos nutritivos y de regeneración prolongada.
   - Forja de Equipo: Creación de piezas de armadura y báculos con metales y maderas arcanas.
   - Encantamiento: Mejora de báculos y túnicas insertando gemas elementales para añadir resistencia o reducción de costos de maná.
   - Reciclaje / Desarmado: Descomponer equipo obsoleto o artefactos encontrados en lingotes y polvos reutilizables.
4. Recolección en el Mundo (en los 3 modos de juego):
   - Nodos interactuables con tecla [E] en el mapa 3D: Arbustos de bayas, vetas de mineral, plantas raras y árboles.
   - Regeneración lenta de recursos para evitar vaciado permanente en sesiones largas de exploración.
5. Iconografía:
   - Reutilizar al máximo los iconos existentes en `assets/ui/icons/` a través de `IconRegistry`.
   - Para ítems sin icono definitivo, el generador procedural dibuja iconos vectoriales limpios (marco de rareza + silueta temática) y deja el registro listo para reemplazo gráfico.
```
