# MANIFIESTO DE ASSETS: FANTASY UI ASSET PACK V1
**Proyecto:** Duelo de Hechiceros - Crónicas Arcanas (Godot 4)  
**Fecha:** 2026-10-10  
**Versión:** 2.0.0 (Auditoría e Integración Completa)  
**Especificación Técnica:** PNG RGBA, 512x512 px (excepto preview sheet), sRGB, canal alfa con transparencia real, filtrado `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS` (`texture_filter = 4`), `EXPAND_IGNORE_SIZE` y `STRETCH_KEEP_ASPECT_CENTERED`.

---

## 1. Catálogo de Íconos Activos Integrados en el Juego (32 Íconos)

| # | Nombre Conceptual | Categoría | Ruta Godot (`res://`) | Resolución | Dónde se usa en el juego |
|---|-------------------|-----------|-----------------------|------------|--------------------------|
| 1 | Centella Arcana | spells | `res://assets/ui/icons/spells/arcane_bolt.png` | 512x512 | HUD Slot 1, StatBar Lanzamiento |
| 2 | Bola de Fuego | spells | `res://assets/ui/icons/spells/spell_fireball.png` | 512x512 | HUD Slot 2 |
| 3 | Invocación Duende | spells | `res://assets/ui/icons/spells/summon_goblin.png` | 512x512 | HUD Slot 3 |
| 4 | Onda Expansiva | spells | `res://assets/ui/icons/spells/shockwave.png` | 512x512 | HUD Slot 4 |
| 5 | Fuente de Vida | spells | `res://assets/ui/icons/spells/spell_healing.png` | 512x512 | HUD Slot 5 |
| 6 | Teletransporte | spells | `res://assets/ui/icons/spells/spell_teleport.png` | 512x512 | HUD Slot 6 (Espacio / 6) |
| 7 | Proyectil de Hielo | spells | `res://assets/ui/icons/spells/spell_ice_projectile.png` | 512x512 | HUD Slot 7 (T) |
| 8 | Rayo Arcano | spells | `res://assets/ui/icons/spells/spell_lightning.png` | 512x512 | HUD Slot 8 (R) |
| 9 | Escudo Arcano | spells | `res://assets/ui/icons/spells/spell_arcane_shield.png` | 512x512 | HUD Slot 9 (C), StatusBar |
| 10 | Libro de Conjuros | spells | `res://assets/ui/icons/spells/spell_book.png` | 512x512 | Botón Inventario (`[I]`), POI Mirador |
| 11 | Aura Arcana | spells | `res://assets/ui/icons/spells/arcane_aura.png` | 512x512 | HUD Santuarios 1-3, POI Santuarios |
| 12 | Claro Natural / Árbol | spells | `res://assets/ui/icons/spells/nature_tree.png` | 512x512 | POI Claro del Bosque |
| 13 | Fuego Alquímico | spells | `res://assets/ui/icons/spells/fire_flame.png` | 512x512 | HUD Chip Azufre, Item Azufre |
| 14 | Ataque Básico | abilities | `res://assets/ui/icons/abilities/ability_basic_attack.png` | 512x512 | Habilidades primarias |
| 15 | Poción de Salud | consumables | `res://assets/ui/icons/consumables/potion_health.png` | 512x512 | HUD StatBar Salud, Chip Poción Salud (`[Q]`), Inventario, POI Fuente |
| 16 | Poción de Maná | consumables | `res://assets/ui/icons/consumables/potion_mana.png` | 512x512 | HUD StatBar Maná, Chip Poción Maná (`[E]`), Inventario |
| 17 | Manzana Silvestre | items | `res://assets/ui/icons/items/item_apple.png` | 512x512 | HUD Chip Manzana, Inventario |
| 18 | Trébol de la Suerte | items | `res://assets/ui/icons/items/item_clover.png` | 512x512 | HUD Chip Trébol, Inventario |
| 19 | Pergamino de Celeridad | items | `res://assets/ui/icons/items/item_magic_scroll.png` | 512x512 | HUD Chip Pergamino, Inventario, Botón Mapa (`[M]`), StatusBar Haste |
| 20 | Cristal Arcano | items | `res://assets/ui/icons/items/item_arcane_crystal.png` | 512x512 | HUD Chip Cristal, Inventario, POI Altar de Transmutación |
| 21 | Habilidad Bloqueada | states | `res://assets/ui/icons/states/state_ability_locked.png` | 512x512 | Slot bloqueado, Niebla inexplorada, Fallback global |
| 22 | Quemadura | status | `res://assets/ui/icons/status/status_burn.png` | 512x512 | Estado alterado Quemadura |
| 23 | Congelación | status | `res://assets/ui/icons/status/status_freeze.png` | 512x512 | Estado alterado Congelación |
| 24 | Envenenamiento | status | `res://assets/ui/icons/status/status_poison.png` | 512x512 | Estado alterado Veneno |
| 25 | Potenciador de Vitalidad | status | `res://assets/ui/icons/status/buff_health.png` | 512x512 | Buff de vida máxima |
| 26 | Vulnerabilidad | status | `res://assets/ui/icons/status/debuff_vulnerable.png` | 512x512 | Debuff de resistencia |
| 27 | Escudo Físico | status | `res://assets/ui/icons/status/shield_physical.png` | 512x512 | Barrera física, POI Puente de Arco |
| 28 | Escudo Mágico | status | `res://assets/ui/icons/status/shield_magic.png` | 512x512 | Barrera mágica elemental |
| 29 | Escudo de Regeneración | status | `res://assets/ui/icons/status/shield_healing.png` | 512x512 | Barrera regenerativa |
| 30 | Escudo de Relámpago | status | `res://assets/ui/icons/status/shield_lightning.png` | 512x512 | Barrera de chispas reactivas |
| 31 | Retícula de Objetivo | target | `res://assets/ui/icons/target/target_reticule.png` | 512x512 | TargetIndicator (HUD), Leyenda de Mapa |
| 32 | Objetivo Hostil | target | `res://assets/ui/icons/target/target_enemy.png` | 512x512 | Marcador Hostil / Boss, POI Altar Jefe |

---

## 2. Hoja de Vista Previa (Recurso de Verificación QA)

- **Ruta Godot:** `res://assets/ui/icons/preview_sheet.png`
- **Resolución:** 980x1284 px
- **Uso:** Utilizada en la suite de verificación de assets (`scenes/QASuite.tscn`).

---

## 3. Íconos Descartados y Reubicados en `_unused/` (.gdignore)

Se aislaron 14 archivos obsoletos, planos o duplicados para evitar contaminación visual y consolidar un estilo canónico de alta resolución:

| Archivo Descartado | Motivo de Descarte | Ícono Canónico Conservado |
|--------------------|--------------------|---------------------------|
| `_unused/fireball.png` | Silueta plana monocromática | `spells/spell_fireball.png` (Ilustración a color 512x512) |
| `_unused/fire_wave.png` | Solapamiento conceptual con shockwave | `spells/shockwave.png` |
| `_unused/frost_snowflake.png` | Glifo plano de baja lectura | `spells/spell_ice_projectile.png` |
| `_unused/frostfire.png` | Concepto híbrido no usado en el juego | `spells/spell_fireball.png` / `spell_ice_projectile.png` |
| `_unused/ice_bolt.png` | Duplicado de menor calidad visual | `spells/spell_ice_projectile.png` |
| `_unused/lightning_spark.png` | Gráfico vectorial simple | `spells/spell_lightning.png` |
| `_unused/lightning_strike.png` | Gráfico vectorial simple | `spells/spell_lightning.png` |
| `_unused/potion_health.png` | Duplicado en raíz de icons | `consumables/potion_health.png` |
| `_unused/potion_mana.png` | Duplicado en raíz de icons | `consumables/potion_mana.png` |
| `_unused/potion_elixir.png` | Tipo de poción no existente en ItemDB | `consumables/potion_health.png` / `potion_mana.png` |
| `_unused/item_scroll.png` | Boceto plano no integrado | `items/item_magic_scroll.png` |
| `_unused/item_crystal_core.png` | Gráfico plano no canónico | `items/item_arcane_crystal.png` |
| `_unused/summon_fairy.png` | Invocación no definida en el juego | `spells/summon_goblin.png` |
| `_unused/creature_dragon.png` | Criatura no implementada en el diseño actual | `target/target_enemy.png` |

---

## 4. Archivos Raw en `source/` (.gdignore)

Se encuentran excluidos de la importación del motor de Godot mediante `.gdignore`:
- `source/ability_basic_attack_raw.png`
- `source/item_magic_scroll_raw.png`
- `source/state_ability_locked_raw.png`
