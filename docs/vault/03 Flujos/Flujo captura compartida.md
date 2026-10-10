---
tags: [flujo]
---
# Flujo: captura → Compartir → colores
1. El usuario toma una captura y elige **Compartir → Matiz**.
2. `MainActivity` recibe `ACTION_SEND`, copia el contenido a `cache/incoming/` y lo publica: con `getInitialContent` (arranque en frío) o por el `EventChannel` (en caliente). Ver [[Canal de plataforma]].
3. `Shell` lee los bytes una sola vez y llama a `AppController.handleIncoming`.
4. Si es imagen: `ImageDoc.decode` → modo [[Imagen]] → extracción en un `Isolate` → modo "De la imagen" y aviso.
5. El usuario arrastra para elegir, mantiene para sumar a [[Personalizado]] y añade a la paleta.
