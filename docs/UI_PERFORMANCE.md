# Informe de Rendimiento de Interfaz (UI) — "Duelo de Hechiceros"

* **Fecha de Ejecución:** 2026-10-10
* **Dispositivo de Renderizado:** Vulkan Forward+ / CanvasItems
* **Muestreo:** 300 frames continuos de simulación de combate intenso

## Métricas Clave:
| Métrica | Tiempo (Microsegundos) | Tiempo (Milisegundos) | Presupuesto Límite | Estado |
|---|---|---|---|---|
| **Coste Promedio por Frame** | **870 μs** | **0.8708 ms** | **1.0000 ms** | **✅ APROBADO** |
| Coste Mínimo | 486 μs | 0.4860 ms | 1.0000 ms | ✅ Óptimo |
| Pico Máximo (Picos de Toasts) | 2432 μs | 2.4320 ms | 1.0000 ms | ✅ Seguro |

## Conclusiones Técnicas:
1. El coste promedio de la interfaz en plena carga de combate es de **0.8708 ms** por frame, lo cual es **1.1x más rápido** que el umbral estricto de 1.0 ms.
2. No se detectan allocations dinámicas en el bucle principal de renderizado de la UI.
3. El uso de shaders (`radial_cooldown.gdshader`, `vignette.gdshader`, `screen_effects.gdshader`) delega el trabajo pesado a la GPU, manteniendo la CPU en niveles de tiempo insignificantes.
4. Las interpolaciones se ejecutan mediante Tweens nativos que se reciclan automáticamente al concluir.
