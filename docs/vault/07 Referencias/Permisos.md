---
tags: [referencia, play]
---
# Permisos (APK verificado con aapt2)
| Permiso | Para qué | Cuándo se pide |
|---|---|---|
| `CAMERA` | [[Cámara]] | Al abrirla (con explicación previa) |
| `SYSTEM_ALERT_WINDOW` | [[Burbuja flotante]] | Al activarla |
| `FOREGROUND_SERVICE`, `_SPECIAL_USE`, `_MEDIA_PROJECTION` | Burbuja y su captura | — |
| `POST_NOTIFICATIONS` | Notificación de la burbuja | Al activarla |

Se eliminan explícitamente `INTERNET`, `ACCESS_NETWORK_STATE`, los de almacenamiento, `READ_MEDIA_*` y `RECORD_AUDIO`. La cámara se declara **no obligatoria**. `minSdk` 29, `targetSdk` 36.
