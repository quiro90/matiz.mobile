# free-points Specification

## Purpose

Modo Personalizado: paletas a medida de 1 a 65 colores —el color actual como principal y hasta 64 secundarios con posición relativa en la rueda—, construidas con gestos táctiles (mantener pulsado reemplaza al clic derecho de desktop) desde la rueda, la imagen, la cámara o la burbuja.

## Requirements

### Requirement: Conjunto de puntos libres
Personalizado SHALL mostrar el principal (el color actual, tarjeta base con indicador) y de 0 a 64 secundarios. Cada secundario SHALL definirse por Δhue (grados), Δsat (fracción) y, opcionalmente, Δbrillo propio; su color SHALL calcularse desde esas coordenadas continuas y SHALL ser sRGB válido. Los secundarios con brillo propio SHALL reproducir exactamente su brillo (v = clamp(brillo del principal + Δbrillo)) y los que no lo tienen SHALL seguir la regla "Equilibrar" de las armonías. Al iniciar la app el conjunto SHALL contener solo el principal; SHALL conservarse durante la sesión (cambios de pestaña, de color, de modo Rueda/Imagen) y no SHALL persistirse entre sesiones. Las tarjetas de los secundarios SHALL etiquetarse 1, 2, … y al añadirse a la paleta o exportarse SHALL nombrarse "Prefijo N". Con Personalizado activo, la rueda SHALL mostrar un punto por secundario con líneas tenues al centro.

#### Scenario: Personalizado vacío por defecto
- **WHEN** la app inicia y el usuario abre Personalizado
- **THEN** solo se ve el principal con su indicador, sin secundarios

#### Scenario: Punto con posición relativa
- **WHEN** el color actual es hue 246.1°, S 63% y existe un punto con Δhue +120° y Δsat 0
- **THEN** su tarjeta muestra hue 6.1° y saturación 63%

#### Scenario: Punto con brillo propio
- **WHEN** "Equilibrar" está activa y un punto fue tomado de la imagen como `#22A2C3`
- **THEN** su tarjeta muestra exactamente `#22A2C3` y "Equilibrar" no altera su brillo

### Requirement: Añadir secundarios manteniendo pulsado
Mantener pulsado (≥ 500 ms sin desplazarse más de 8 dp) SHALL añadir un secundario en estas vías equivalentes: sobre la rueda (en la posición hue/saturación del dedo); sobre la imagen en modo Imagen (el píxel exacto de la imagen bajo la lupa, con brillo propio); con el botón "+ Secundario" de la cámara y de la burbuja (el color tomado, con brillo propio). Cada adición SHALL dar respuesta háptica, no SHALL cambiar el color actual, SHALL pasar el modo generado a Personalizado y SHALL mostrar un aviso "Añadido a Personalizado (N)" con la acción "Ver" que abre Generar. Al alcanzar 64 secundarios SHALL no añadirse nada y SHALL mostrarse "Máximo 64 colores por paleta".

#### Scenario: Mantener pulsado en la rueda desde Escala
- **WHEN** en Escala con color hue 246.1° el usuario mantiene pulsada la rueda en hue 66.1°, S 63%
- **THEN** vibra levemente, el modo pasa a Personalizado con un secundario en esa posición y el color actual no cambia

#### Scenario: Mantener pulsado en la imagen reproduce el píxel
- **WHEN** en modo Imagen el usuario mantiene pulsado sobre un píxel `#22A2C3`
- **THEN** se añade un secundario de brillo propio que reproduce exactamente `#22A2C3` y el color actual no cambia

#### Scenario: Límite de 64
- **WHEN** el conjunto ya tiene 64 secundarios y el usuario mantiene pulsado en la rueda
- **THEN** no se añade nada y aparece el aviso "Máximo 64 colores por paleta"

### Requirement: Botón "+" y conversión desde Armonías
El botón "+" (fila de "Equilibrar" en Generar) SHALL añadir un punto opuesto al principal (Δhue 180°, Δsat 0) si no hay secundarios y, si los hay, al lado del último (avanzando 30° hasta una posición libre, conservando su Δsat), y SHALL pasar a Personalizado. Al llegar al límite SHALL verse deshabilitado. Añadir desde Armonías (mantener pulsado o "+") SHALL reemplazar el conjunto previo por la figura de la armonía (en sus posiciones canónicas, Monocromática solo aporta el principal) más el punto nuevo.

#### Scenario: Pulsaciones consecutivas no se solapan
- **WHEN** Personalizado tiene un secundario en Δhue 180° y el usuario toca "+" dos veces
- **THEN** se añaden puntos a ~210° y ~240°

#### Scenario: "+" en Armonías convierte la armonía
- **WHEN** en Triádica con `#5246BC` el usuario toca "+"
- **THEN** Personalizado contiene el base, puntos en +120° y +240° y uno nuevo a +270°

### Requirement: Personalizar desde la imagen
En el modo "De la imagen", el botón "Personalizar" SHALL cargar los colores extraídos como secundarios (con brillo propio, en orden de extracción) conservando el principal y pasando a Personalizado. Si ya hay 2 o más colores en Personalizado SHALL pedir confirmación ("Esta acción reemplazará todos los colores cargados en Personalizado.") y sin confirmar no SHALL cambiar nada. Sin secundarios SHALL aplicarse directamente con el aviso "Se cargaron N colores extraídos en Personalizado".

#### Scenario: Personalizar 5 extraídos
- **WHEN** hay 5 colores extraídos, Personalizado solo tiene el principal y el usuario toca "Personalizar"
- **THEN** Personalizado tiene 5 secundarios que reproducen exactamente los extraídos y aparece "Se cargaron 5 colores extraídos en Personalizado"

### Requirement: Arrastre y seguimiento rígido
Arrastrar un secundario en la rueda con Personalizado activo SHALL moverlo en vivo sin cambiar el principal ni el color actual, limitando la saturación al disco. Cambiar el principal por cualquier vía (rueda, brillo, campos, historial, imagen, cámara, burbuja, entrada manual, deshacer/rehacer, tarjeta) SHALL trasladar rígidamente la figura. Usar un secundario como principal (tocar su tarjeta) SHALL re-anclar la figura en él conservando los desfases del resto.

#### Scenario: Seguimiento rígido
- **WHEN** el punto 1 tiene Δhue +120° y el usuario gira el principal 5°
- **THEN** el punto queda a 125° del hue original del principal y su tarjeta refleja el nuevo color

### Requirement: Quitar puntos
En Personalizado cada tarjeta quitable SHALL mostrar siempre un botón "−" y el menú de mantener pulsado SHALL ofrecer "Quitar". El doble toque sobre un secundario en la rueda SHALL quitarlo (desde Armonías pasa a Personalizado sin ese punto). El botón "Borrar" (visible en Personalizado solo con secundarios) SHALL quitar todos los secundarios tras confirmación, conservando el principal. Quitar el principal con secundarios SHALL promover al primero (pasa a ser el color actual como cambio confirmado; los demás conservan sus posiciones absolutas). Siempre SHALL quedar al menos un color: el principal único no muestra "−". Quitar no es deshacible.

#### Scenario: Quitar el principal promueve al siguiente
- **WHEN** Personalizado tiene principal en hue 0° y puntos 1 (hue 30°) y 2 (hue 90°) y el usuario quita el principal
- **THEN** el color actual pasa a ser el del punto 1 y el punto 2 queda en hue 90°

#### Scenario: Doble toque elimina
- **WHEN** Personalizado tiene principal + 3 secundarios y el usuario hace doble toque sobre el punto 2 en la rueda
- **THEN** el punto 2 desaparece de la rueda y de las tarjetas y nada más cambia
