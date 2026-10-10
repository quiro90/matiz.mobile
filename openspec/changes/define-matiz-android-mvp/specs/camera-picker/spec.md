## Purpose

Permite tomar colores del mundo real apuntando con la cámara: una retícula central muestra en vivo el color bajo ella para usarlo como principal, añadirlo como secundario o congelar el fotograma y seguir eligiendo con la lupa del modo Imagen.

## ADDED Requirements

### Requirement: Abrir la cámara con permiso explícito
Crear SHALL ofrecer una acción "Cámara" que abra una vista de cámara a pantalla completa. El permiso de cámara SHALL solicitarse solo en ese momento, con una explicación previa de para qué se usa; si se deniega, SHALL mostrarse un aviso con acceso a los ajustes del sistema y el resto de la app SHALL seguir funcionando. La app no SHALL grabar video, guardar fotos automáticamente ni enviar imágenes fuera del dispositivo.

#### Scenario: Primer uso
- **WHEN** el usuario toca "Cámara" por primera vez
- **THEN** se explica brevemente el uso, se solicita el permiso del sistema y, al concederlo, se muestra la vista previa en vivo

#### Scenario: Permiso denegado
- **WHEN** el usuario deniega el permiso de cámara
- **THEN** se muestra un aviso con "Abrir ajustes" y la app vuelve a Crear sin errores

### Requirement: Color en vivo bajo la retícula
La vista de cámara SHALL mostrar una retícula central y una muestra con el HEX del color bajo ella, actualizada en vivo (al menos 10 veces por segundo), promediando un área pequeña (5×5 píxeles del fotograma) para reducir el ruido del sensor. Tocar la vista SHALL mover la retícula a ese punto.

#### Scenario: Apuntar a una superficie
- **WHEN** el usuario apunta la retícula a una pared roja
- **THEN** la muestra y el HEX cambian en vivo a un tono rojo

### Requirement: Acciones de captura
La vista de cámara SHALL ofrecer: "Usar" (el color de la retícula pasa a ser el color actual como cambio confirmado, se añade a Recientes y se vuelve a Crear), "+ Secundario" (lo añade como secundario con brillo propio, ver `free-points`, y la cámara sigue abierta para tomar más) y "Congelar" (captura el fotograma actual y lo abre en Crear → Imagen para elegir con lupa y extraer colores, ver `image-picker`). Un aviso SHALL recordar que el color de la cámara depende de la luz y del balance de blancos.

#### Scenario: Tomar varios secundarios
- **WHEN** con la cámara abierta el usuario toca "+ Secundario" sobre 3 objetos distintos
- **THEN** Personalizado tiene 3 nuevos secundarios con esos colores, el color actual no cambió y la cámara sigue abierta

#### Scenario: Congelar fotograma
- **WHEN** el usuario toca "Congelar"
- **THEN** la cámara se cierra y Crear muestra el fotograma en modo Imagen con sus colores extraídos

### Requirement: Uso responsable de la cámara
La cámara SHALL liberarse al salir de la vista, al pasar la app a segundo plano o al bloquear la pantalla, y SHALL reanudarse al volver si la vista sigue abierta.

#### Scenario: App en segundo plano
- **WHEN** con la cámara abierta el usuario cambia a otra app
- **THEN** la cámara se libera (el indicador de cámara del sistema se apaga) y al volver la vista previa se reanuda
