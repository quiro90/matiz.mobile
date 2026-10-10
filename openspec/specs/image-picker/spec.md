# image-picker Specification

## Purpose

Permite tomar colores de una imagen (capturas, fotos, mockups) con el dedo: la imagen pasa a ser el foco de la pestaña Crear, se navega con pinza, se eligen píxeles exactos con una lupa que no queda tapada por el dedo y se extraen automáticamente sus colores predominantes.

## Requirements

### Requirement: Cargar imagen
El sistema SHALL permitir cargar una imagen PNG, JPEG, WebP, GIF (primer fotograma), BMP o HEIC (si el sistema la decodifica) mediante: el selector de fotos del sistema (sin solicitar permisos de almacenamiento ni de medios), "Pegar" cuando el portapapeles contiene una imagen, "Compartir"/"Abrir con" desde otras apps (ver `share-intake`), la cámara (ver `camera-picker`) y la burbuja (ver `floating-bubble`). Los archivos no decodificables SHALL rechazarse con un aviso de error sin cambiar el estado. Las imágenes mayores a 24 megapíxeles SHALL reducirse para visualización conservando el muestreo exacto de píxeles de la imagen decodificada usada.

#### Scenario: Abrir desde la galería
- **WHEN** el usuario toca "Abrir imagen" y elige una foto en el selector del sistema
- **THEN** la imagen se muestra en Crear en modo Imagen sin que la app haya pedido permisos

#### Scenario: Archivo no soportado
- **WHEN** se recibe un archivo que no es una imagen decodificable
- **THEN** se muestra un aviso de error y el estado no cambia

### Requirement: Conmutador Rueda | Imagen
Con una imagen cargada, Crear SHALL mostrar un conmutador "Rueda | Imagen". El modo Imagen SHALL ocupar el área de la rueda (la imagen es el foco); volver a Rueda (conmutador o gesto Atrás) SHALL conservar la imagen, su zoom/posición, los colores extraídos y el conjunto Personalizado, para volver a Imagen sin recargarla. Una acción "Cerrar imagen" SHALL descartarla y ocultar el conmutador y el modo "De la imagen".

#### Scenario: Ida y vuelta sin pérdida
- **WHEN** el usuario tiene una imagen con zoom 3× y 6 colores extraídos, pasa a Rueda, cambia el color y vuelve a Imagen
- **THEN** la imagen aparece con el mismo zoom y posición y los 6 extraídos siguen disponibles

#### Scenario: Atrás desde Imagen
- **WHEN** el usuario está en modo Imagen y usa el gesto Atrás
- **THEN** pasa a modo Rueda sin cerrar la app ni descartar la imagen

### Requirement: Elegir color con lupa táctil
En modo Imagen, apoyar y arrastrar un dedo SHALL mostrar una lupa desplazada por encima del dedo (o al costado cerca de los bordes) con cuadrícula de píxeles ampliados sin suavizado (11×11 por defecto), el píxel central resaltado y su HEX; al levantar el dedo el píxel bajo el centro de la lupa SHALL pasar a ser el color actual (cambio confirmado, añadido a Recientes y copiado si "Copiar al tomar color" está activo). El color SHALL tomarse de la imagen original decodificada, no del render escalado. Mantener pulsado sin moverse SHALL añadir un secundario (ver `free-points`) en lugar de cambiar el principal.

#### Scenario: Píxel exacto
- **WHEN** la imagen se muestra reducida al 25% y el usuario suelta la lupa sobre un área
- **THEN** el color actual es el valor exacto del píxel correspondiente de la imagen original

#### Scenario: Lupa no tapada
- **WHEN** el usuario arrastra el dedo cerca del borde superior de la imagen
- **THEN** la lupa se reubica para seguir completamente visible y no queda bajo el dedo

### Requirement: Zoom y desplazamiento
En modo Imagen, el gesto de pinza con dos dedos SHALL hacer zoom (desde ajustar a pantalla hasta al menos 32×) y el arrastre con dos dedos SHALL desplazar la imagen; el doble toque SHALL alternar entre ajustar a pantalla y 4× sobre el punto tocado. El gesto de dos dedos no SHALL cambiar el color.

#### Scenario: Pinza no cambia el color
- **WHEN** el color actual es `#5246BC` y el usuario hace zoom con pinza sobre la imagen
- **THEN** la imagen se amplía y el color actual sigue siendo `#5246BC`

### Requirement: Extraer colores principales
Al cargar una imagen el sistema SHALL extraer automáticamente, en segundo plano y sin bloquear la UI, sus colores predominantes con la cantidad vigente (1–64, por defecto 6; k-means++ en OKLab, determinista), mostrarlos en el modo "De la imagen" de Generar y avisar la cantidad. La cantidad SHALL ajustarse con un control −/+ etiquetado "Cantidad de colores" y SHALL existir "Extraer de nuevo". Para una imagen sin pérdida (PNG) y la misma cantidad, el resultado SHALL ser idéntico al de desktop (en formatos con pérdida, el decodificador de cada plataforma puede variar algunos píxeles).

#### Scenario: Paridad con desktop en PNG
- **WHEN** se extraen 6 colores de la misma captura PNG en Android y en desktop
- **THEN** ambas listas de HEX son idénticas y en el mismo orden

#### Scenario: Extracción automática al recibir una captura
- **WHEN** el usuario comparte una captura de pantalla hacia Matiz con la cantidad por defecto
- **THEN** se abre Crear en modo Imagen y el modo "De la imagen" contiene 6 colores, sin pulsar "Extraer"

#### Scenario: Determinismo
- **WHEN** se extrae dos veces sobre la misma imagen con 6 colores
- **THEN** ambos resultados son idénticos

#### Scenario: Imagen grande
- **WHEN** la imagen es de 4000×3000 píxeles
- **THEN** la UI sigue respondiendo durante la extracción y el resultado aparece en menos de 2 segundos en un dispositivo de gama media
