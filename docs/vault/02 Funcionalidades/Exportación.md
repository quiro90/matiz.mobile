---
tags: [funcionalidad, export]
---
# Exportación
- **Código**: CSS, JSON, Dart/Flutter, C#, Tailwind v4 y lista HEX, con salida idéntica a desktop (verificada en [[Paridad con desktop]]).
- **PNG**: port de `PaletteImageRenderer` y `OverlayImageRenderer`, con la misma geometría.
  - Paleta: horizontal/vertical, 1×/2×/3×, fondo claro/oscuro/transparente, HSL/CMYK opcionales. Bloques sin antialiasing, con el centro exacto (cubierto por test).
  - Superpuestos: cuadrado/círculo/triángulo, orden configurable, hasta 64 anillos visibles.
- Destinos: Guardar en…, Galería (`Pictures/Matiz`, sin permisos) y Compartir.
