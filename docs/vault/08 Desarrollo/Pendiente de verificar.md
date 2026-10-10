---
tags: [desarrollo]
---
# Pendiente de verificar
Verificado en el emulador (Pixel 7, API 36): rueda (tocar, arrastrar, mantener), Generar con figura, imagen (lupa, mantener, extracción), hoja de detalle, paletas, exportación PNG, Atrás, idioma, tema y persistencia, cámara, burbuja de punta a punta (captura → Imagen) y release con R8.

Falta verificar en un teléfono real:
- "Compartir" real desde Galería/Fotos. En el emulador, `adb am start` no puede otorgar acceso a URIs de MediaStore, así que el camino de la imagen se validó con la ruta de la burbuja.
- Pegar una imagen copiada (por ejemplo, desde el navegador).
- Ida y vuelta de `.mpalette` con Matiz desktop, y "Abrir con" desde gestores de archivos y adjuntos.
- TalkBack y texto al 130%, el layout ≥ 600 dp (tablet u horizontal) y el rendimiento en gama media (arranque < 2 s en release).
