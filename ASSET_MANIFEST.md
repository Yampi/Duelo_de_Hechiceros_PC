# MANIFIESTO DE ASSETS: FANTASY UI ASSET PACK V1
**Proyecto:** Duelo de Hechiceros - Crónicas Arcanas (Godot 4)  
**Fecha:** 2026-10-10  
**Versión:** 1.0.0  
**Especificación Técnica:** PNG RGBA, 512x512 px, espacio sRGB, transparencia real en canal alfa, iluminación cenital izquierda, margen seguro 8-12%, sin texto ni marcas de agua.

---

## 1. Catálogo General de Assets (12 Íconos)

| # | Nombre | Categoría | Ruta Godot (res://) | Archivo Fuente (Source) | Res. | Formato | Margen Seg. | Estado |
|---|--------|-----------|---------------------|--------------------------|------|---------|-------------|--------|
| 1 | Poción de vida | Consumibles | 
es://assets/ui/icons/consumables/potion_health.png | source/potion_health_raw.jpg | 512x512 | PNG RGBA | 10.0% Y / 23.4% X | VALID |
| 2 | Vial de maná | Consumibles | 
es://assets/ui/icons/consumables/potion_mana.png | source/potion_mana_raw.jpg | 512x512 | PNG RGBA | 10.0% Y / 39.3% X | VALID |
| 3 | Bola de fuego | Hechizos | 
es://assets/ui/icons/spells/spell_fireball.png | source/spell_fireball_raw.jpg | 512x512 | PNG RGBA | 10.0% Y / 10.7% X | VALID |
| 4 | Proyectil de hielo | Hechizos | 
es://assets/ui/icons/spells/spell_ice_projectile.png | source/spell_ice_projectile_raw.jpg | 512x512 | PNG RGBA | 10.0% Y / 10.5% X | VALID |
| 5 | Rayo | Hechizos | 
es://assets/ui/icons/spells/spell_lightning.png | source/spell_lightning_raw.jpg | 512x512 | PNG RGBA | 10.7% Y / 14.6% X | VALID |
| 6 | Escudo mágico | Hechizos | 
es://assets/ui/icons/spells/spell_arcane_shield.png | source/spell_arcane_shield_raw.jpg | 512x512 | PNG RGBA | 10.4% Y / 18.2% X | VALID |
| 7 | Curación | Hechizos | 
es://assets/ui/icons/spells/spell_healing.png | source/spell_healing_raw.jpg | 512x512 | PNG RGBA | 10.2% Y / 16.8% X | VALID |
| 8 | Teletransporte | Hechizos | 
es://assets/ui/icons/spells/spell_teleport.png | source/spell_teleport_raw.jpg | 512x512 | PNG RGBA | 10.4% Y / 10.9% X | VALID |
| 9 | Pergamino mágico | Objetos | 
es://assets/ui/icons/items/item_magic_scroll.png | source/item_magic_scroll_raw.png | 512x512 | PNG RGBA | 9.6% Y / 10.7% X | VALID |
| 10 | Cristal arcano | Objetos | 
es://assets/ui/icons/items/item_arcane_crystal.png | source/item_arcane_crystal_raw.jpg | 512x512 | PNG RGBA | 10.0% Y / 20.5% X | VALID |
| 11 | Ataque básico | Habilidades | 
es://assets/ui/icons/abilities/ability_basic_attack.png | source/ability_basic_attack_raw.png | 512x512 | PNG RGBA | 9.2% Y / 15.0% X | VALID |
| 12 | Habilidad bloqueada | Estados | 
es://assets/ui/icons/states/state_ability_locked.png | source/state_ability_locked_raw.png | 512x512 | PNG RGBA | 9.4% Y / 9.4% X | VALID |

---

## 2. Hoja de Vista Previa y Verificación Visual

- **Archivo de Inspección:** 
es://assets/ui/icons/preview_sheet.png
- **Condiciones verificadas:**
  1. **Fondo Oscuro (#11141C):** Integración nativa con la interfaz de usuario en Godot. Comprobada ausencia de halos oscuros o cortes.
  2. **Fondo Claro (#F8FAFC):** Comprobada ausencia de franjas negras residuales, halos blanquecinos o artefactos en bordes suaves.
  3. **Patrón de Transparencia:** Comprobada transparencia real y ausencia de cuadrículas dibujadas.
  4. **Lectura en tamaños pequeños (48x48 y 64x64 px):** Siluetas nítidas, contrastes de color distinguibles al instante.

---

## 3. Trazabilidad, Herramientas y Metodología

- **Generador Visual Primario:** Gemini 3.1 Flash Image (generate_image). Utilizado para generar los masters de poción de vida, vial de maná, bola de fuego, proyectil de hielo, rayo, escudo mágico, curación, teletransporte y cristal arcano (9 assets).
- **Procesamiento de Transparencia:** Pipeline programático en Python (OpenCV, NumPy, PIL) con algoritmo de matizado de canal alfa suave, des-premultiplicación y descontaminación de borde para eliminar cualquier halo residual.
- **Límite de Capacidad / Quota:** Al alcanzar la cuota del modelo de generación tras producir 9 assets (HTTP 429 Resource Exhausted), se procedió de acuerdo con la directiva:
  - Se conservó y documentó con total veracidad el bloqueo concreto.
  - Para completar el pack sin dejar huecos ni dependencias rotas, se sintetizaron y renderizaron de forma programática los 3 assets complementarios (item_magic_scroll, bility_basic_attack, state_ability_locked) a 512x512 RGBA respetando la geometría, dirección de luz cenital izquierda y paleta del pack a partir de los vectores con licencia abierta CC-BY 3.0 / CC0 del propio proyecto.
