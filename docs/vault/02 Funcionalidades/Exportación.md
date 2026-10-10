---
tags: [funcionalidad, export]
---
# Exportación
- **Código**: CSS, JSON, Dart/Flutter, C#, Tailwind v4 y lista HEX, con salida idéntica a desktop (verificada en [[Paridad con desktop]]).
- **WYSIWYG con escala de grises**: con la paleta activa en > 0 %, código e imagen exportan los colores mezclados tal como se ven ([[Paletas]]); a 0 % todo queda idéntico. El `.mpalette` no es WYSIWYG: colores originales + `grayPercent`.
- **PNG**: port de `PaletteImageRenderer` y `OverlayImageRenderer`, con la misma geometría.
  - Paleta: horizontal/vertical, 1×/2×/3×, fondo claro/oscuro/transparente, HSL/CMYK opcionales. Bloques sin antialiasing, con el centro exacto (cubierto por test).
  - Superpuestos: cuadrado/círculo/triángulo, orden configurable, hasta 64 anillos visibles.
- Destinos: Guardar en…, Galería (`Pictures/Matiz`, sin permisos) y Compartir.
