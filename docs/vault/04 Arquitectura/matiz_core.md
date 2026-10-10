---
tags: [arquitectura, core]
---
# matiz_core
Port 1:1 de `Matiz.Core`:
- `colors/`: Argb, ColorMath, ColorState, WheelMapping
- `parsing/` y `formatting/`
- `generation/`: DesignScale, PaletteGenerator, DominantColors, **DotNetRandom**, **FreePointSet**
- `palettes/`: Palette, PaletteFile, PaletteService
- `export/`, `history/`, `session/`, `persistence/` (JsonStore) y `settings/`

Trampas resueltas para la paridad:
- redondeo *away-from-zero*;
- el `%` de C# (en Dart, `remainder`);
- `cbrt` con un paso de Newton;
- ordenamientos estables (como LINQ);
- el generador aleatorio con semilla de .NET.

Ver [[Paridad con desktop]].
