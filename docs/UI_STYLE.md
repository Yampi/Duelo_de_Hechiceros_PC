# Guía de Estilo y Sistema de Diseño UI: "Duelo de Hechiceros"
## Dirección Visual: Dark Fantasy Arcano (DLG-INNOV)

### 1. Filosofía de Diseño
* **Línea de Gobernanza:** `DLG-INNOV` (Inmersión, ambientación viva, juego en tiempo real).
* **Premisa Central:** *La interfaz debe sentirse como un artefacto arcano dentro del mundo 3D, no una presentación de diapositivas superpuesta.*
* **Regla de Ocupación de Pantalla:** La UI de combate no debe cubrir más del 20% del área de pantalla; el 80% central del campo visual 3D debe permanecer despejado para lectura táctica de proyectiles, enemigos y terreno.
* **Contraste y Accesibilidad (WCAG AA para Videojuegos):** Todos los textos y números cuentan con sombra/contorno oscuro para garantizar legibilidad contra fondos 3D claros y oscuros. Ningún estado o información vital depende exclusivamente del color (los slots y barras usan texto de valor, iconos, badges de atajo y cambios de forma/escala).

---

### 2. Paleta Cromática y Tokens (ui_constants.gd)

| Token | Hex | Muestra / Uso |
|---|---|---|
| `BG_DARK` | `#0d0f17` | Fondo primario de modales y paneles profundos con 92% alfa |
| `BG_DARKER` | `#080a0f` | Fondos de slots, cajas de diálogo y overlays oscuros |
| `BG_PANEL` | `#121721` | Contenedores flotantes y fondos de tarjetas con 90% alfa |
| `BG_OVERLAY` | `#05080dcc` | Fondo atenuador para menú de pausa y modales modales |
| `GOLD_BASE` | `#d9b859` | Oro envejecido — Bordes principales, marcos NinePatch normales |
| `GOLD_BRIGHT` | `#ffe680` | Oro radiante — Hover en botones primarios, slot seleccionado, brillo |
| `GOLD_DIM` | `#8c7338` | Oro desgastado — Bordes secundarios o estados inactivos |
| `IRON_BASE` | `#667080` | Hierro forjado — Bordes y fondos de botones secundarios |
| `IRON_LIGHT` | `#99a6b8` | Hierro pulido — Hover de botones secundarios |
| `ARCANE_CYAN` | `#40d9ff` | Éter arcano — Valores de maná, recargas, acentos de exploración |
| `ARCANE_CYAN_GLOW` | `#80f2ff` | Brillo de hechizos, destellos de maná y runas de portal |
| `ARCANE_PURPLE` | `#bf59ff` | Magia sombría y transmutación arcana |
| `HP_RED` | `#e6383d` | Vitalidad activa — Relleno de barra de salud |
| `HP_TRAIL` | `#f29933` | Damage trail — Relleno retrasado tras recibir daño |
| `MANA_BLUE` | `#2ea6ff` | Maná disponible — Relleno de barra de maná |
| `MANA_TRAIL` | `#80d9ff` | Mana trail — Relleno animado de consumo/recuperación |
| `DANGER_RED` | `#eb4040` | Peligro / Nigromancia — Botones destructivos y paneles de derrota |
| `DANGER_RED_HOVER` | `#ff5959` | Hover de botón de peligro |
| `TEXT_TITLE` | `#ffe6a6` | Títulos y encabezados arcanos con brillo cálido |
| `TEXT_BODY` | `#e6ebf2` | Texto legible de descripciones, cuerpo y números |
| `TEXT_MUTED` | `#99a6b8` | Etiquetas secundarias, atajos y subtítulos de bajo ruido |
| `TEXT_SHADOW` | `#000000f2` | Sombra negra de contorno para 100% de legibilidad en 3D |

---

### 3. Tipografía y Jerarquía

* **Display (Títulos y Rótulos):** `Cinzel` (`res://assets/ui/fonts/Cinzel.ttf`, OFL 1.1).
  - Título Grande / Menú / Victoria: `32 - 40 px` (con sombra (2, 2) `#000000`).
  - Subtítulos y Banners de Zona: `20 - 24 px`.
* **Lectura / UI (Cuerpo, Datos, Botones):** `Inter` (`res://assets/ui/fonts/Inter.ttf`, OFL 1.1).
  - Cuerpo / Botones: `14 - 16 px`.
  - Microtexto, Badges de Teclas y Costos: `11 - 12 px` (con contorno o sombra reforzada).

---

### 4. Estilos de Botones y Componentes

1. **Botón Primario (Oro Arcano):**
   - Normal: Fondo piedra oscura modulada (`#283347`), borde NinePatch oro envejecido (`#d9b859`), texto dorado claro (`#ffe6a6`).
   - Hover: Brillo dorado radiante (`#ffe680`), escala `1.04x` con sonido de shimmer sutil.
   - Pressed: Atenuación táctil (`#1a2433`), escala `0.97x` con sonido de click seco.
   - Disabled: Tinte grisáceo apagado (`#59606d`) con 50% alfa.
   - Focus: Borde dorado pulsante para navegación por teclado/gamepad.
2. **Botón Secundario (Hierro Forjado):**
   - Normal: Modulación metálica azul-grisácea (`#1a202c`), borde hierro forjado (`#667080`), texto `#e6ebf2`.
   - Hover: Aclarado a `#2d3748`, borde `#99a6b8`.
3. **Botón de Peligro (Carmesí Nigromante):**
   - Normal: Modulación carmesí oscuro (`#3d1414`), borde carmesí (`#c53030`), texto `#ffb3b3`.
   - Hover: Borde `#e53e3e`, brillo cálido.
   - Pressed: `#260b0b`.
4. **Ranuras Tácticas (`SpellSlot` e `InventorySlotButton`):**
   - Razón de aspecto 1:1, borde por categoría (Consumible = Esmeralda, Material = Ámbar, Clave = Amatista).
   - Barrido de enfriamiento radial por GPU (`radial_cooldown.gdshader`).
   - Indicador de tecla en esquina superior izquierda, costo/cantidad en esquina inferior derecha.

---

### 5. Duraciones de Animación y Curvas de Transición (Tweens)

* **Hover / Micro-interacción:** `0.08 s`, curva `TRANS_QUAD`, `EASE_OUT`.
* **Press / Pop:** `0.12 s` (escala 0.95 -> 1.0), curva `TRANS_QUAD`, `EASE_OUT`.
* **Apertura de Modales (Slide + Fade):** `0.22 s`, `TRANS_BACK`, `EASE_OUT` (escala 0.92 -> 1.0).
* **Cierre de Modales:** `0.15 s`, `TRANS_QUAD`, `EASE_IN` (escala 1.0 -> 0.94).
* **Damage Trail (Barra de Vida):**
  - Retardo antes de caer: `0.35 s`.
  - Duración de caída: `0.40 s`, `TRANS_QUAD`, `EASE_OUT`.
* **Pulso de Vida Baja (<25%):** Ciclo seno oscilante continuo de `0.65 s`.

---

### 6. Sistema de Audio de Interfaz (`AudioManager`)

* **Buses de Sonido:**
  - `Master`: Bus raíz.
  - `Music`: Enrutado a Master (-6.0 dB estándar). Soporta crossfade dinámico entre pistas.
  - `SFX`: Efectos de combate y entorno en 3D.
  - `UI`: Efectos táctiles de interacción y notificaciones.
* **Catálogo de SFX Integrados:**
  - `ui_hover`: Sweep rápido aireado (45ms) al posar el cursor o cambiar de foco.
  - `ui_click`: Impacto pétreo táctil (70ms) al accionar botones.
  - `ui_open`: Oleada etérea C4-G4-C5 (220ms) al desplegar inventario, mapa o menús.
  - `ui_close`: Barrido descendente (180ms) al cerrar modales.
  - `ui_error`: Acorde disonante C3-C#3 al intentar conjurar sin maná.
  - `ui_loot`: Arpegio cristalino C6-E6-G6-C7 al recoger botín.
  - `ui_shrine`: Acorde místico D4-A4-D5-A5 al despertar altares o capturar santuarios.
  - `ui_victory`: Fanfarria armónica F4-A4-C5-F5 al completar nivel.
  - `ui_defeat`: Campana fúnebre grave C2-G2-Eb3 al caer en combate.

---

### 7. Shaders y Post-Procesado (`canvas_item`)

1. **`radial_cooldown.gdshader`**:
   - Calcula coordenadas polares en tiempo real sobre el UV (`atan(uv.y, uv.x)`).
   - Dibuja un barrido radial con borde luminoso dorado sin necesidad de texturas precargadas de máscara.
2. **`vignette.gdshader`**:
   - Viñeta oscura o rojiza perimetral con caída cuadrática suave.
   - Parámetro dinámico `vignette_intensity` controlado por la salud del mago y golpes recibidos.
3. **`screen_effects.gdshader`**:
   - `desaturation`: Desaturación progresiva a escala de grises para secuencias dramáticas de muerte.
   - `flash_color` y `flash_power`: Micro-destellos cromáticos elementales al lanzar hechizos.

---

### 8. Guía para Nuevas Pantallas y Componentes

Para agregar una nueva pantalla o modal al juego respetando el sistema:
1. **Estructura de Escena:**
   - Crear una escena `scenes/ui/NuevaPantalla.tscn` con nodo raíz `Control` (anchors preset 15 / `PRESET_FULL_RECT`).
   - Agregar un `DimOverlay` (`ColorRect` negro con modulación alfa).
   - Agregar un `CenterContainer` con un `Panel` interior (`custom_minimum_size`, NinePatch ornamental con `panel-border-001.png` y modulación `GOLD_BASE`).
2. **Tipografía y Estilos:**
   - Título en `Cinzel.ttf` tamaño 20-28 px con sombra negra.
   - Textos de contenido en `Inter.ttf` con tema `FantasyTheme.tres`.
3. **Control por Código (`scripts/ui/nueva_pantalla.gd`):**
   - Preload obligatorio:
     ```gdscript
     const UIConstants = preload("res://scripts/ui/ui_constants.gd")
     const SettingsManager = preload("res://scripts/settings_manager.gd")
     ```
   - Conectar atajos de teclado y `ui_cancel` en `_unhandled_input`.
   - Utilizar funciones de entrada y salida con Tweens sobre escala (0.92 a 1.0) y opacidad (0.0 a 1.0).
   - Llamar a `AudioManager.play_ui("open")` y `AudioManager.play_ui("close")`.

---

### 9. Adaptabilidad Multi-Resolución y Ultrawide

El proyecto utiliza `window/stretch/mode="canvas_items"` y `window/stretch/aspect="expand"`.
* **1280x720 (Base 16:9):** Escala de referencia estándar; todo texto visible a >= 14 px.
* **1920x1080 (Full HD):** Escala nítida sin pixelación; bordes NinePatch preservan esquinas de 32 px.
* **2560x1080 (Ultrawide 21:9):**
  - Los clusters de HUD están anclados a los extremos (`PRESET_BOTTOM_LEFT`, `PRESET_BOTTOM_RIGHT`, `PRESET_TOP_RIGHT`).
  - La barra central de hechizos está anclada a `PRESET_CENTER_BOTTOM`.
  - Los modales utilizan `CenterContainer` manteniendo el área de interacción centrada y segura.

---

### 10. Catálogo de Capturas de Verificación en `docs/ui_captures/`

* **Galería y Componentes:** `phase1_gallery_1280x720.png`, `phase1_gallery_1920x1080.png`
* **HUD y Combate:** `phase2_combat_1280x720.png`, `phase2_combat_1920x1080.png`, `phase2_damaged_*.png`, `phase2_low_hp_*.png`
* **Feedback y Efectos:** `phase3_spell_cast_*.png`, `phase3_loot_toast_*.png`, `phase3_interact_prompt_*.png`, `phase3_death_desaturate_*.png`
* **Menús y Ajustes:** `phase5_main_menu_*.png`, `phase5_mode_selection_*.png`, `phase5_pause_menu_*.png`, `phase5_settings_modal_*.png`, `phase5_game_over_*.png`, `phase5_victory_*.png`
* **Inventario y Mapa:** `phase6_inventory_*.png`, `phase6_map_*.png`
* **Multi-Resolución y Ultrawide:** `phase7_hud_1600x900.png`, `phase7_hud_2560x1080_ultrawide.png`, `phase7_inventory_2560x1080_ultrawide.png`
