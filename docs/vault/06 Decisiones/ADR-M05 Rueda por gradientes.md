---
tags: [adr]
---
# ADR-M05 Rueda por gradientes
**Decisión**: dibujar la rueda con `SweepGradient` (6 primarios) + `RadialGradient` blanco con α = 1 − r^γ (32 pasos), en lugar de un bitmap por píxel.

**Por qué**: con V = 1, HSV es una mezcla lineal en sRGB entre blanco y el primario del ángulo, así que el resultado es exacto. Además no hay costo de rasterizado al cambiar el tamaño o el enfoque. El color se calcula siempre matemáticamente (`WheelMapping`), nunca leyendo píxeles.
