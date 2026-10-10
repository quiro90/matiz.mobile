---
tags: [funcionalidad, plataforma]
---
# Burbuja flotante
Opcional (Ajustes) y desactivada por defecto. Es el reemplazo móvil del atajo global de desktop.
- Pide "Mostrar sobre otras apps" y notificaciones; corre como servicio en primer plano `specialUse` con notificación y "Detener".
- Se arrastra y se acopla al borde (recuerda la posición); arrastrarla a la ✕ la apaga. Se oculta mientras Matiz está en primer plano.
- Al tocarla: consentimiento del sistema (pantalla completa por defecto en Android 14+) → **una** instantánea → se abre en Matiz → [[Imagen]]. Ver [[ADR-M04 Captura de un fotograma]] y [[Flujo burbuja]].
- Limitaciones: consentimiento en cada captura; el contenido protegido sale negro; HDR y modos de color del fabricante.
