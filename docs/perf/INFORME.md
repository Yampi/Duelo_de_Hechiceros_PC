# Informe de Rendimiento — Modo Supervivencia (Agente 0)

* **Fecha de Ejecución:** 2026-10-11
* **Motor:** Godot Engine 4.6.1 / 4.7
* **Escena de Prueba:** `scenes/BenchmarkSurvival.tscn`

## 📊 Métricas Clave

| Métrica | Resultado Obtenido | Objetivo de Especificación | Estado |
|---|---|---|---|
| **Tope de Enemigos Simultáneos** | **12** activos | Máximo 12 simultáneos | ✅ CUMPLIDO |
| **Tiempo de Frame Promedio** | **0.125 ms** (~7994.1 FPS) | < 16.6 ms (60 FPS) | ✅ CUMPLIDO |
| **Tiempo de Frame Máximo** | **4.000 ms** | < 33.3 ms (30 FPS spike) | ✅ CUMPLIDO |
| **Uso de Memoria Estática** | **229.97 MB** (Delta +8.52 MB) | Estable sin fugas | ✅ CUMPLIDO |
| **Reciclaje Object Pool (DamageNumber)** | **2** en pool activo | Capped a 40 nodos | ✅ CUMPLIDO |

## 🛠️ Optimizaciones Implementadas
1. **Tope de Supervivencia (scripts/main.gd):** Límite estricto de 12 enemigos activos. El exceso pasa a la cola de reserva `survival_spawn_queue`.
2. **IA de Separación Throttled (scripts/enemy.gd):** Cálculo espacial ejecutado cada 5 frames con ID offset y límite de 4 vecinos más cercanos (eliminando O(n²)).
3. **Línea de Visión (LOS) Escalonada (scripts/enemy.gd):** Raycasts diferidos entre 0.16s y 0.24s con almacenamiento en caché `_cached_los`.
4. **Hibernación de Enemigos (scripts/enemy.gd):** Enemigos a >52m sin alerta pausan su cálculo de navegación hasta que el jugador se aproxima.
5. **Object Pooling (scripts/game_manager.gd / damage_number.gd):** Reutilización de nodos `DamageNumber` con un pool máximo de 40 instancias.
6. **LOD y Rango de Visibilidad (scripts/map_generator.gd):** Culling automático por distancia en flora (50m), rocas (95m), columnas (110m) y árboles (100m).
