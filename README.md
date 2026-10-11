# Duelo de Hechiceros — Crónicas Arcanas

Remake táctico 3D de combate mágico en tiempo real para PC, desarrollado sobre **Godot Engine 4.7.2** (Forward+ / CanvasItems).

---

## 🚀 Inicio Rápido y Ejecución

El motor de Godot correspondiente a este proyecto se encuentra en la carpeta de herramientas locales `tools/`:

### 1. Iniciar el Juego (Menú Principal)
```powershell
& ".\tools\Godot_v4.7.2-stable_win64.exe"
```

### 2. Ejecutar la Suite Maestra de QA Automatizado
Recorre y valida de forma autónoma los 36 puntos de aceptación (tokens, buses de audio, persistencia de ajustes, inventario, mapa, combate, pausa y modales):
```powershell
& ".\tools\Godot_v4.7.2-stable_win64.exe" scenes/QASuite.tscn
```

### 3. Ejecutar el Benchmark de Rendimiento de UI (300 frames)
Mide el tiempo de procesamiento por frame de la interfaz bajo combate intenso (< 1.0 ms):
```powershell
& ".\tools\Godot_v4.7.2-stable_win64.exe" scenes/BenchmarkUIPerformance.tscn
```

---

## 🎮 Controles de Juego

| Acción | Teclado / Ratón | Mando / Gamepad |
|---|---|---|
| **Moverse / Desplazarse** | `W`, `A`, `S`, `D` (Shift para correr) | Stick Izquierdo |
| **Apuntar / Mirar** | Movimiento del Ratón | Stick Derecho |
| **Canalizar Hechizo Activo** | Clic Izquierdo | Gatillo Derecho (RT) |
| **Orbitar Cámara Táctica** | Clic Derecho + Arrastrar | Stick Derecho |
| **Zoom de Cámara** | Rueda del Ratón | Botones de hombro |
| **Selección de Hechizos (1-9)** | Teclas numéricas `1` al `9` | Cruceta / Selector |
| **Poción de Salud Inmediata** | Tecla `Q` | Botón X |
| **Poción de Maná Inmediata** | Tecla `E` | Botón Y |
| **Interactuar / Recoger / Activar** | Tecla `F` | Botón A |
| **Inventario Arcano** | Tecla `I` o `Tab` | Botón Select / Back |
| **Cartografía Arcana (Mapa)** | Tecla `M` | Botón Mapa |
| **Menú de Pausa / Cancelar** | Tecla `Escape` | Botón Start |
| **Conmutar Ayudas de Control** | Tecla `H` | — |

---

## 🏛️ Arquitectura UI/UX (`DLG-INNOV`)

La interfaz fue diseñada bajo la línea de gobernanza **Dark Fantasy Arcano** (`DLG-INNOV`):
* **Bajo Impacto Visual:** Cobertura de UI reducida al **11.5%** de la pantalla en combate.
* **3 Clusters Flotantes:** Salud/Buffs a la izquierda, Spellbar/Pociones al centro, Maná/Navegación a la derecha.
* **Daño Retrasado ("Damage Trail"):** Interpolación visual de salud con amortiguación dual.
* **Shaders de GPU:** Barrido radial de cooldown en GPU (`radial_cooldown.gdshader`), viñeta de peligro (`vignette.gdshader`) y efectos de muerte/casteo (`screen_effects.gdshader`).
* **Audio Polyphonic:** Autoload `AudioManager` con buses `Master`, `Music`, `SFX`, `UI`.
* **Navegabilidad 100%:** Soporte de teclado, ratón y mando en todos los modales.
* **Accesibilidad:** Soporte de reducción de sacudidas de cámara (`reduce_shake`), reducción de destellos (`reduce_flashes`) y escala UI en `user://settings.cfg`.

---

## 📚 Documentación Técnica

* [`docs/UI_STYLE.md`](docs/UI_STYLE.md) — Guía de estilo, paleta de colores, tokens, tipografías y recetas de componentes.
* [`docs/UI_CHANGELOG.md`](docs/UI_CHANGELOG.md) — Bitácora completa de las 7 fases de transformación.
* [`docs/UI_PERFORMANCE.md`](docs/UI_PERFORMANCE.md) — Informe de rendimiento de frame (< 1 ms).
* [`docs/QA_REPORT.md`](docs/QA_REPORT.md) — Informe formal de las 36 pruebas automatizadas aprobadas.
* [`assets/CREDITS.md`](assets/CREDITS.md) — Registro de fuentes OFL y efectos de sonido CC0.
* [`docs/ui_captures/`](docs/ui_captures/) — Catálogo de capturas a 1280x720, 1600x900, 1920x1080 y 2560x1080 (Ultrawide).
