---
tags: [arquitectura, plataforma]
---
# Canal de plataforma
`MethodChannel('matiz/platform')` + `EventChannel('matiz/incoming')` (`lib/platform/platform_bridge.dart` ⇄ `MainActivity.kt`):

| Método | Qué hace |
|---|---|
| `getInitialContent` / evento | Contenido de Compartir / Abrir con / burbuja (ruta en caché, MIME, nombre, tipo, cantidad) |
| `getClipboardImage` | Bytes de una imagen del portapapeles |
| `saveToGallery` | PNG a `Pictures/Matiz` vía MediaStore |
| `setAppLocale` | Idioma por app (Android 13+) |
| `openAppSettings` | Ajustes de la app (permiso de cámara denegado) |
| `canDrawOverlays`, `requestOverlayPermission`, `requestNotificationPermission`, `startBubble`, `stopBubble`, `isBubbleRunning` | [[Burbuja flotante]] |

En otras plataformas devuelve valores neutros y las funciones se ocultan (código preparado para iOS).
