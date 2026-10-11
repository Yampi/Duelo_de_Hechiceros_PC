class_name UIConstants
extends RefCounted

## UI Design Tokens & Constants for Duelo de Hechiceros
## Estilo: Dark Fantasy Arcano (DLG-INNOV)
## Paleta, tipografías, duraciones y curvas para componentes de interfaz.

# --- PALETA CROMÁTICA (TOKENS) ---
# Fondos oscuros de piedra y noche arcana
const BG_DARK: Color = Color(0.05, 0.06, 0.09, 0.92)         # #0d0f17
const BG_DARKER: Color = Color(0.03, 0.04, 0.06, 0.98)       # #080a0f
const BG_PANEL: Color = Color(0.07, 0.09, 0.13, 0.90)        # #121721
const BG_SLOT: Color = Color(0.04, 0.05, 0.08, 0.85)         # #0a0d14
const BG_OVERLAY: Color = Color(0.02, 0.03, 0.05, 0.80)      # #05080d con 80% alfa

# Metales y Acentos Ornamentales
const GOLD_BASE: Color = Color(0.85, 0.72, 0.35, 1.0)        # #d9b859 (Oro envejecido)
const GOLD_BRIGHT: Color = Color(1.0, 0.90, 0.50, 1.0)       # #ffe680 (Oro radiante / Hover)
const GOLD_DIM: Color = Color(0.55, 0.45, 0.22, 0.85)        # #8c7338 (Oro desgastado)
const IRON_BASE: Color = Color(0.40, 0.44, 0.50, 0.90)       # #667080 (Hierro forjado)
const IRON_LIGHT: Color = Color(0.60, 0.65, 0.72, 1.0)       # #99a6b8 (Hierro pulido)
const BORDER_MUTED: Color = Color(0.25, 0.28, 0.35, 0.65)    # #404759

# Magia Arcana y Estados
const ARCANE_CYAN: Color = Color(0.25, 0.85, 1.0, 1.0)       # #40d9ff (Maná / Éter arcano)
const ARCANE_CYAN_GLOW: Color = Color(0.50, 0.95, 1.0, 1.0)  # #80f2ff
const ARCANE_PURPLE: Color = Color(0.75, 0.35, 1.0, 1.0)     # #bf59ff (Vacío / Poder sombrío)
const NATURE_GREEN: Color = Color(0.25, 0.85, 0.45, 1.0)     # #40d973 (Vigor / Curación)
const FIRE_ORANGE: Color = Color(1.0, 0.45, 0.15, 1.0)       # #ff7326 (Fuego)

# Combate y Alerta
const HP_RED: Color = Color(0.90, 0.22, 0.24, 1.0)           # #e6383d (Salud viva)
const HP_TRAIL: Color = Color(0.95, 0.60, 0.20, 0.90)        # #f29933 (Damage trail)
const MANA_BLUE: Color = Color(0.18, 0.65, 1.0, 1.0)         # #2ea6ff (Maná actual)
const MANA_TRAIL: Color = Color(0.50, 0.85, 1.0, 0.85)       # #80d9ff (Mana trail)
const DANGER_RED: Color = Color(0.92, 0.25, 0.25, 1.0)       # #eb4040 (Botón Peligro / Alerta)
const DANGER_RED_HOVER: Color = Color(1.0, 0.35, 0.35, 1.0)  # #ff5959

# Tipografía
const TEXT_TITLE: Color = Color(1.0, 0.90, 0.65, 1.0)        # #ffe6a6 (Oro claro)
const TEXT_BODY: Color = Color(0.90, 0.92, 0.95, 1.0)         # #e6ebf2 (Blanco hueso suave)
const TEXT_MUTED: Color = Color(0.60, 0.65, 0.72, 1.0)        # #99a6b8 (Gris pálido legible)
const TEXT_HINT: Color = Color(0.80, 0.85, 0.75, 0.80)       # #ccdfbf (Guías de tecla)
const TEXT_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.95)        # Sombra de alto contraste

# --- RUTAS DE FUENTES ---
const FONT_DISPLAY_PATH: String = "res://assets/ui/fonts/Cinzel.ttf"
const FONT_BODY_PATH: String = "res://assets/ui/fonts/Inter.ttf"

# --- JERARQUÍA TIPOGRÁFICA ---
const FONT_SIZE_TITLE_LARGE: int = 36
const FONT_SIZE_TITLE: int = 28
const FONT_SIZE_SUBTITLE: int = 20
const FONT_SIZE_BODY: int = 14
const FONT_SIZE_CAPTION: int = 12

# --- ANIMACIONES Y CURVAS (TWEENS) ---
const DURATION_FAST: float = 0.08
const DURATION_POP: float = 0.12
const DURATION_FADE: float = 0.20
const DURATION_SLIDE: float = 0.25
const DURATION_TRAIL_DELAY: float = 0.35
const DURATION_TRAIL_DROP: float = 0.40
const DURATION_PULSE_LOW_HP: float = 0.65

const TRANS_SMOOTH: Tween.TransitionType = Tween.TRANS_QUAD
const EASE_OUT: Tween.EaseType = Tween.EASE_OUT
const EASE_IN: Tween.EaseType = Tween.EASE_IN
