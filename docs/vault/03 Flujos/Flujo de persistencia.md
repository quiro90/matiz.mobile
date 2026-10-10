---
tags: [flujo, persistencia]
---
# Flujo de persistencia
- `palettes.json`, `history.json` y `settings.json` se guardan en el directorio de soporte de la app con el `JsonStore` de [[matiz_core]]: escritura atómica con `.bak`, guardado diferido de 300 ms, `flush()` al pasar a segundo plano, recuperación de archivos corruptos (`*.corrupt-<fecha>.json` + aviso) y migración v0→v1.
- Paletas e historial usan el mismo esquema que desktop; los ajustes usan claves móviles ([[Esquema settings móvil]]). Todo se incluye en la copia de seguridad de Android.
