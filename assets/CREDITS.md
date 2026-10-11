# Créditos y Licencias de Recursos de Interfaz de Usuario (UI) y Audio
## Duelo de Hechiceros - Crónicas Arcanas (Godot 4)

Este documento detalla la procedencia, autores, licencias y enlaces oficiales de todos los recursos gráficos, tipográficos y sonoros integrados en la interfaz de usuario del juego.

---

## 1. Tipografías (Fonts)

### Cinzel (Fuente Display para Títulos y Encabezados Arcanos)
* **Diseñador:** Natanael Gama
* **Repositorio Oficial:** https://github.com/NDISCOVER/Cinzel / https://fonts.google.com/specimen/Cinzel
* **Licencia:** SIL Open Font License (OFL-1.1)
* **Texto de Licencia:** Ver `assets/ui/fonts/Cinzel_OFL.txt`
* **Uso en el proyecto:** Títulos principales, nombres de hechizos, marcadores de zona, encabezados de modales.

### Inter (Fuente Sans-Serif para Texto de Lectura y Números)
* **Diseñador:** Rasmus Andersson
* **Repositorio Oficial:** https://github.com/rsms/inter / https://fonts.google.com/specimen/Inter
* **Licencia:** SIL Open Font License (OFL-1.1)
* **Texto de Licencia:** Ver `assets/ui/fonts/Inter_OFL.txt`
* **Uso en el proyecto:** Valores numéricos, descripciones de hechizos e ítems, botones, microtexto y tooltips.

---

## 2. Kenney Fantasy UI Borders (v1.0)
* **Autor / Distribuidor:** Kenney (Asset Jesus) - https://kenney.nl
* **Página Oficial:** https://kenney.nl/assets/fantasy-ui-borders
* **Licencia:** Creative Commons Zero (CC0 1.0 Universal) - Dominio Público
* **Texto de Licencia:** Ver `assets/ui/licenses/KENNEY_FANTASY_BORDERS_LICENSE.txt`
* **Uso en el proyecto:**
  - Marcos escalables NinePatch (`assets/ui/frames/panel-*.png`)
  - Bordes ornamentales (`assets/ui/frames/panel-border-*.png`)
  - Divisores decorativos arcanos (`assets/ui/frames/divider-*.png`)

---

## 3. Kenney UI Pack (v2.0)
* **Autor / Distribuidor:** Kenney - https://kenney.nl
* **Página Oficial:** https://kenney.nl/assets/ui-pack
* **Licencia:** Creative Commons Zero (CC0 1.0 Universal) - Dominio Público
* **Texto de Licencia:** Ver `assets/ui/licenses/KENNEY_UI_PACK_LICENSE.txt`
* **Uso en el proyecto:**
  - Botones interactivos (`assets/ui/buttons/`): estados normal, hover, pressed, disabled.
  - Barras y texturas de progreso (`assets/ui/bars/`): fondos, barras de vida, maná, lanzamiento y resistencia.

---

## 4. Game-Icons.net
* **Plataforma:** https://game-icons.net
* **Licencia General:** Creative Commons Attribution 3.0 Unported (CC BY 3.0)
* **Texto de Licencia:** Ver `assets/ui/licenses/GAME_ICONS_LICENSE.txt`
* **Autores:** Lorc, Delapouite, Carl Olsen, Sbed.
* **Uso en el proyecto:** Iconos de hechizos, consumibles, estados de combate y puntos de interés cartográficos (registrados exhaustivamente en `assets/ui/CREDITS_UI.md`).

---

## 5. Audio de Interfaz y Música Ambiental (Síntesis Procedural de Sonido)
* **Origen:** Diseñado y sintetizado proceduralmente mediante `scripts/generate_audio_assets.gd` (síntesis aditiva y modulación FM offline con formato WAV estándar 44.1kHz, 16-bit PCM).
* **Licencia:** CC0 1.0 Universal (Dominio Público).
* **Archivos Generados:**
  - `assets/audio/ui/ui_hover.wav`: Sweep sutil y aireado de alta frecuencia (480-720Hz, 45ms) para hover en botones e iconos.
  - `assets/audio/ui/ui_click.wav`: Golpe de pulsación pétrea/pergamino (340Hz + transiente de ruido, 70ms).
  - `assets/audio/ui/ui_open.wav`: Oleada etérea armónica C4-G4-C5 (220ms) para apertura de modales e inventario.
  - `assets/audio/ui/ui_close.wav`: Barrido descendente (440-180Hz, 180ms) para cierre de ventanas.
  - `assets/audio/ui/ui_error.wav`: Acorde disonante C3-C#3 con zumbido armónico para aviso de falta de maná o acción bloqueada.
  - `assets/audio/ui/ui_loot.wav`: Arpegio brillante C6-E6-G6-C7 de campana mágica para recogida de botín y gemas.
  - `assets/audio/ui/ui_shrine.wav`: Acorde de resonancia de poder D4-A4-D5-A5 con vibrato brillante para activación de santuarios y altares.
  - `assets/audio/ui/ui_victory.wav`: Fanfarria armónica F4-A4-C5-F5 con decaimiento prolongado para victoria.
  - `assets/audio/ui/ui_defeat.wav`: Campana sombría y cavernosa C2-G2-Eb3 en modo menor para derrota del hechicero.
  - `assets/audio/music/ambient_exploration.wav`: Drone atmosférico continuo en Mi menor (82Hz - 246Hz) con modulación coral lenta y bucle continuo de 8 segundos.
  - `assets/audio/music/ambient_boss.wav`: Pulso rítmico de tensión a 120 BPM con bombo sordo y armónicos disonantes en bucle continuo de 4 segundos.

---

## 6. Texturas de Efectos Visuales (VFX) y Shaders Procedurales
* **Origen:** Diseñado y generado proceduralmente mediante `tools/generate_vfx_textures.py` (algoritmos matemáticos y renderizado analítico en espacio RGBA 32 bits) y shaders espaciales en `assets/vfx/shaders/`.
* **Licencia:** CC0 1.0 Universal (Dominio Público).
* **Archivos:**
  - `assets/vfx/textures/glow_soft.png` (256x256 RGBA)
  - `assets/vfx/textures/spark_star.png` (256x256 RGBA)
  - `assets/vfx/textures/smoke_noise.png` (256x256 RGBA)
  - `assets/vfx/textures/ring_sharp.png` (256x256 RGBA)
  - `assets/vfx/textures/flame_tear.png` (256x256 RGBA)
  - `assets/vfx/textures/snowflake_crystal.png` (256x256 RGBA)
  - `assets/vfx/textures/lightning_flash.png` (256x256 RGBA)
  - `assets/vfx/textures/magic_circle_runes.png` (512x512 RGBA)
  - `assets/vfx/textures/light_mote.png` (128x128 RGBA)
  - `assets/vfx/textures/shockwave_ring.png` (256x256 RGBA)
  - `assets/vfx/textures/dust_puff.png` (256x256 RGBA)
  - `assets/vfx/shaders/fresnel_shield.gdshader` (Fresnel + Red Hexagonal + Reacción de Impacto)
  - `assets/vfx/shaders/dissolve_noise.gdshader` (Disolución con Ruido + Borde Incandescente)
  - `assets/vfx/shaders/scrolling_energy.gdshader` (Scroll UV de Ruido + Núcleo Luminoso)
  - `assets/vfx/shaders/shockwave_ring.gdshader` (Anillo Expansivo Radial + Distorsión)

