---
tags: [funcionalidad, imagen]
---
# Imagen
- Entradas: selector de fotos (sin permisos), Pegar, [[Compartir hacia Matiz]], [[Cámara]] (Congelar) y [[Burbuja flotante]].
- La imagen reemplaza a la rueda; el conmutador Rueda | Imagen conserva zoom, posición, extraídos y Personalizado. Atrás vuelve a la rueda.
- **Un dedo**: lupa 11×11 por encima del dedo (o debajo cerca del borde) con el HEX; al soltar, el píxel exacto del búfer original pasa a ser el color actual. **Mantener quieto**: añade el píxel a [[Personalizado]]. **Dos dedos**: pinza y desplazamiento. **Doble toque**: ajustar ↔ 4×.
- Extracción automática (k-means++ en OKLab, en un `Isolate`) con la cantidad vigente (1–64, por defecto 6). Con PNG coincide con desktop ([[Paridad con desktop]]).
- Código: `lib/widgets/image_canvas.dart`, `lib/state/image_doc.dart`.
