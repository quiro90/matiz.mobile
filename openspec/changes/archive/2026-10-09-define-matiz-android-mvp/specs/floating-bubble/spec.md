## Purpose

Reemplazo móvil del atajo global de captura de desktop: una burbuja flotante sobre otras apps que, con el consentimiento de captura de pantalla del sistema, toma una instantánea de lo que se ve y la abre en Matiz para elegir píxeles exactos con lupa. Es una función opcional y desactivada por defecto.

## ADDED Requirements

### Requirement: Activación opcional con consentimiento
La burbuja SHALL estar desactivada por defecto y activarse desde Ajustes ("Burbuja flotante"). Al activarla SHALL explicarse qué hace y solicitarse, en este orden, el permiso "Mostrar sobre otras apps" y el permiso de notificaciones (necesario para el servicio en primer plano). Si alguno se deniega SHALL quedar desactivada con un aviso y el resto de la app SHALL funcionar igual. Mientras la burbuja esté activa SHALL existir una notificación persistente con la acción "Detener".

#### Scenario: Activar la burbuja
- **WHEN** el usuario activa "Burbuja flotante" y concede ambos permisos
- **THEN** aparece una burbuja con el ícono de Matiz sobre la pantalla y una notificación "Matiz: burbuja activa" con "Detener"

#### Scenario: Permiso de superposición denegado
- **WHEN** el usuario no concede "Mostrar sobre otras apps"
- **THEN** el interruptor queda desactivado y un aviso explica que la burbuja necesita ese permiso

### Requirement: Comportamiento de la burbuja
La burbuja SHALL poder arrastrarse a cualquier posición y acoplarse al borde más cercano al soltarla; arrastrarla hasta una zona "✕" que aparece abajo SHALL desactivarla. Tocarla SHALL iniciar una captura. Su posición SHALL recordarse. La burbuja SHALL ser pequeña (≤ 56 dp) y semitransparente cuando está inactiva.

#### Scenario: Descartar arrastrando
- **WHEN** el usuario arrastra la burbuja hasta la zona "✕"
- **THEN** la burbuja desaparece, se detiene el servicio y el ajuste queda desactivado

### Requirement: Captura de pantalla consentida
Al tocar la burbuja SHALL solicitarse el consentimiento de captura de pantalla del sistema (que el sistema puede pedir en cada sesión); con consentimiento, la burbuja SHALL ocultarse, tomarse una única instantánea de la pantalla y terminarse la sesión de captura de inmediato. La instantánea SHALL abrirse en Matiz en Crear → Imagen con extracción automática y SHALL reutilizar la lupa táctil, los secundarios por mantener pulsado y demás funciones del modo Imagen. No SHALL grabarse video, ni capturarse de forma continua, ni guardarse ni enviarse la instantánea fuera de la app. Si el usuario cancela el consentimiento no SHALL ocurrir nada más.

#### Scenario: Capturar un color de otra app
- **WHEN** el usuario está en el navegador, toca la burbuja y acepta el consentimiento del sistema
- **THEN** Matiz se abre en Crear → Imagen con la instantánea del navegador (sin la burbuja visible en ella) y sus colores extraídos

#### Scenario: Cancelar el consentimiento
- **WHEN** el usuario toca la burbuja y cancela el diálogo del sistema
- **THEN** no se toma ninguna captura, la burbuja sigue visible y no se abre Matiz

#### Scenario: Contenido protegido
- **WHEN** la app en primer plano protege su contenido (por ejemplo, un video con DRM o una app bancaria)
- **THEN** la instantánea puede mostrarse en negro y la ayuda de la burbuja documenta esta limitación

### Requirement: Limitaciones documentadas
La ayuda de la burbuja (accesible desde Ajustes) SHALL documentar que: el sistema puede pedir consentimiento en cada captura; el contenido protegido puede verse negro; y en pantallas HDR o con modos de color del fabricante el valor capturado puede no coincidir con el original.

#### Scenario: Consultar la ayuda
- **WHEN** el usuario toca "¿Cómo funciona?" junto al ajuste de la burbuja
- **THEN** se muestran las limitaciones de consentimiento, contenido protegido y HDR/modos de color
