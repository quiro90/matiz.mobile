---
tags: [arquitectura]
---
# AppController
Equivalente móvil del `MainViewModel` de desktop (`lib/state/app_controller.dart`). Reúne:
- color actual (`ColorSession`) y copiar/pegar;
- paletas generadas, con caché por versión;
- [[Personalizado]] (`FreePointSet`);
- paletas (`PaletteService` + autoguardado);
- [[Imagen]] (`ImageDoc`, extracción en un `Isolate`);
- contenido entrante y ajustes.

Emite avisos (`Toast`) que `Shell` muestra como SnackBar. La navegación se controla con `tab` y `showImage`.
