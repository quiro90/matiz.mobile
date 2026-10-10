---
tags: [flujo]
---
# Flujo: burbuja
1. `BubbleService` (FGS `specialUse`) muestra la vista superpuesta.
2. Al tocarla: `CaptureActivity` (transparente) → `createScreenCaptureIntent` → el usuario consiente.
3. El servicio pasa a `mediaProjection`, oculta la burbuja, espera 400 ms, crea un `VirtualDisplay` con un `ImageReader`, toma **el primer fotograma**, detiene la proyección y vuelve a `specialUse`.
4. Guarda un PNG en `cache/captures/` y abre `MainActivity` con `matiz.capture=<ruta>`; desde ahí sigue el mismo camino que el [[Flujo captura compartida]].
