---
tags: [funcionalidad, plataforma]
---
# Compartir hacia Matiz
- Matiz aparece en la hoja **Compartir** para imágenes (`image/*`, una o varias: se usa la primera) y archivos `.mpalette` (`application/octet-stream`, `application/json`), y en **Abrir con**.
- El contenido se copia a la caché y se entrega a Dart por el [[Canal de plataforma]] (en arranque en frío o en caliente, `singleTask`, una sola vez aunque se rote la pantalla).
- Imagen → [[Crear]] en modo [[Imagen]] con extracción automática. `.mpalette` → se valida por contenido y se importa como paleta nueva ([[Archivo mpalette]]).
Flujo: [[Flujo captura compartida]].
