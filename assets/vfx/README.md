# Assets VFX — Duelo de Hechiceros

Librería de recursos visuales, shaders y texturas de partículas procedurales para los efectos de combate y hechizos.

## Texturas Procedurales (`assets/vfx/textures/`)
Todas las texturas fueron generadas procedimentalmente mediante el script `tools/generate_vfx_textures.py` (algoritmos matemáticos y renderizado analítico en espacio RGBA de 32 bits, sin dependencia de servicios externos).

| Archivo | Resolución | Descripción | Uso en Hechizos |
|---------|------------|-------------|-----------------|
| `glow_soft.png` | 256x256 | Halo radial suave con caída de coseno cuadrático | Báculos, proyectiles, orbes arcanos, destello de impacto |
| `spark_star.png` | 256x256 | Chispa estelar de 4 puntas con núcleo hiperbrillante | Impactos de Centella, chispas de Rayo, dispersión mágica |
| `smoke_noise.png` | 256x256 | Nube de humo turbulento multi-octava con máscara esférica | Estela y explosión de Bola de Fuego, humo de invocación |
| `ring_sharp.png` | 256x256 | Anillo luminoso estrecho con caída gausiana bilateral | Dispersión de impactos, ondas expansivas, auras concéntricas |
| `flame_tear.png` | 256x256 | Llama en gota estilizada con núcleo incandescente | Manto y estela de Bola de Fuego, brasas ascendentes |
| `snowflake_crystal.png` | 256x256 | Cristal de hielo hexagonal de 6 puntas con espuelas | Proyectil de Hielo, estela de escarcha, niebla gélida |
| `lightning_flash.png` | 256x256 | Descarga eléctrica zigzagueante con halo y ramificaciones | Rayo Arcano, descarga de suelo, chispas eléctricas |
| `magic_circle_runes.png` | 512x512 | Sello mágico arcano con círculos concéntricos, estrella de 8 puntas y glifos rúnicos | Círculo de invocación de duende, domo de protección |
| `light_mote.png` | 128x128 | Mota de luz puntual con corona etérea suave | Motas ascendentes de Fuente de Vida, espirales arcanas |
| `shockwave_ring.png` | 256x256 | Anillo de onda de choque con borde exterior cortante y cola de arrastre | Impacto masivo de Onda Expansiva, terremoto del Jefe |
| `dust_puff.png` | 256x256 | Racimo de polvo orgánico en terrones suaves | Escombros de tierra de Onda Expansiva, impacto de pisadas |

## Licencia y Créditos
- Texturas procedurales generadas in-house bajo dominio público (CC0 1.0 Universal).
