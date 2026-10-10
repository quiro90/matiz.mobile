---
tags: [color, tests]
---
# Paridad con desktop
`tool/golden` (.NET) compila el `Matiz.Core` de desktop **leyendo** `../matiz/src/Matiz.Core` (no escribe allí) y genera `packages/matiz_core/test/fixtures/golden.json` con:
- `System.Random(1234)`: primeras salidas → `DotNetRandom`.
- 2.000 colores: HSL, HSV, CMYK, OKLCH, gris equivalente, escala (500 y automática), tints/shades, neutros y las 6 armonías (equilibradas y sin equilibrar).
- Puntos libres, extracción k-means sobre 3 imágenes sintéticas (1, 6, 9 y 64 colores) y los 6 formatos de código.

`golden_parity_test.dart` exige coincidencia exacta. Si cambia desktop, se regenera con `cd tool/golden && dotnet run`.
