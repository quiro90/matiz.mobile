## Purpose

Genera en vivo, a partir del color actual, escalas y paletas útiles para interfaces y design systems, y las presenta en la pestaña Generar como tarjetas compactas táctiles listas para usar, copiar o guardar.

## ADDED Requirements

### Requirement: Tipos de paleta generada
El sistema SHALL generar a partir del color actual: Design Scale (50–950), Tints (base + 10–50% hacia blanco), Shades (base + 10–50% hacia negro), Neutros (11 grises teñidos), y las armonías Complementaria (2), Análoga (5, pasos de 30°), Complementaria dividida (3, ±150°), Triádica (3, 120°), Tetrádica (4, 90°) y Monocromática (5). El color base SHALL aparecer en su posición en cada paleta.

#### Scenario: Triádica
- **WHEN** el color actual es `#5246BC` y el usuario elige "Triádica"
- **THEN** se muestran 3 colores: el base y dos con hue del selector rotado +120° y +240°

### Requirement: Armonías geométricas con luminosidad equilibrada
Las armonías SHALL calcularse girando el hue del selector (rueda HSV) el ángulo exacto y conservando la saturación del base, desde las coordenadas continuas del color actual. Con "Equilibrar" activa (por defecto) el brillo de cada color SHALL ajustarse para igualar la L OKLab del base (o el brillo alcanzable más cercano); desactivada, todos conservan el brillo del base. Todos los resultados SHALL ser sRGB válidos.

#### Scenario: Geometría exacta
- **WHEN** el color actual es hue 246.1°, S 63%, B 74% y se genera una triádica
- **THEN** los otros dos colores están en hue 6.1° y 126.1° con saturación 63%

#### Scenario: Equilibrar activa
- **WHEN** "Equilibrar" está activa y la luminosidad del base es alcanzable para un color de la armonía
- **THEN** su L OKLab difiere de la del base en menos de 0.01

#### Scenario: Sin equilibrar
- **WHEN** "Equilibrar" está desactivada
- **THEN** todos los colores de la armonía tienen el mismo brillo HSV que el base

### Requirement: Tints y shades convencionales
Tint N% SHALL ser la mezcla sRGB del base con blanco al N% y Shade N% la mezcla con negro al N% (definición Sass/Bootstrap).

#### Scenario: Tint y shade 50%
- **WHEN** el color base es `#5246BC`
- **THEN** Tint 50% es `#A9A3DE` y Shade 50% es `#29235E`

### Requirement: Design Scale perceptual
El sistema SHALL generar 11 pasos (50…950) en OKLCH con L estrictamente decreciente según la curva de referencia, croma del base reducida hacia los extremos, hue constante, ajuste a gama reduciendo croma y ΔL ≥ 0.02 entre pasos. El base SHALL quedar exactamente en el paso ancla: "Base en 500" (por defecto) o "Automático", configurable en Ajustes.

#### Scenario: Base en 500
- **WHEN** el color base es `#5246BC` y el anclaje es "Base en 500"
- **THEN** el paso 500 es exactamente `#5246BC`, 50–400 son más claros y 600–950 más oscuros

#### Scenario: Anclaje automático con color claro
- **WHEN** el color base es `#FACC15` y el anclaje es "Automático"
- **THEN** el base se ubica en el paso 300 o inferior y los pasos mantienen L estrictamente decreciente con ΔL ≥ 0.02

### Requirement: Neutros teñidos
"Neutros" SHALL producir 11 pasos con las L de referencia de la escala, el hue del color actual y croma ≤ min(0.015, C·0.12); para un color acromático SHALL producir grises puros.

#### Scenario: Neutros de un violeta
- **WHEN** el color base es `#5246BC`
- **THEN** los neutros son grises ligeramente violáceos con croma OKLCH ≤ 0.015

### Requirement: Pestaña Generar
La pestaña Generar SHALL presentar arriba una fila desplazable de chips con los modos, en este orden: Escala, Tints/Shades, Neutros, Armonías, Personalizado y De la imagen (este último solo cuando hay colores extraídos). En Armonías SHALL aparecer una segunda fila de chips con los tipos de armonía. Con Armonías o Personalizado activos, SHALL mostrarse encima de las tarjetas una rueda compacta interactiva (la misma del selector, a menor tamaño) con el marcador principal y los puntos del modo, para que la relación geométrica sea visible sin cambiar de pestaña; en los demás modos SHALL mostrarse la barra compacta Anterior | Actual. El modo elegido SHALL persistir entre sesiones.

#### Scenario: Orden de los modos
- **WHEN** el usuario abre Generar sin imagen cargada
- **THEN** ve los chips Escala, Tints/Shades, Neutros, Armonías y Personalizado en ese orden

#### Scenario: Rueda compacta en Armonías
- **WHEN** el usuario elige Armonías → Triádica con `#5246BC`
- **THEN** sobre las tarjetas se ve la rueda compacta con el marcador principal y 2 puntos en +120° y +240° unidos al centro con líneas tenues

### Requirement: Tarjetas compactas táctiles
Los colores generados SHALL mostrarse como tarjetas en una grilla (3 columnas en un ancho de 360 dp, más columnas en pantallas anchas) con muestra, etiqueta (paso, ángulo o número) y HEX. Cada tarjeta SHALL tener siempre visibles, sin depender de hover, las acciones "Copiar" (formato principal) y "Añadir a paleta", con área táctil ≥ 40 dp. Tocar el cuerpo de la tarjeta SHALL usar ese color como principal (cambio confirmado; en Personalizado los demás puntos conservan sus posiciones relativas). Mantener pulsada la tarjeta SHALL abrir un menú con: Usar como principal, Copiar (formato principal), Copiar HEX, Copiar RGB, Añadir a paleta y —solo en Personalizado— Quitar. La tarjeta base SHALL llevar un indicador.

#### Scenario: Usar un color generado
- **WHEN** el usuario toca el cuerpo de la tarjeta del paso 300
- **THEN** ese color pasa a ser el actual como cambio confirmado y las paletas se regeneran desde él

#### Scenario: Copiar desde la tarjeta
- **WHEN** el usuario toca "Copiar" en la tarjeta del paso 300
- **THEN** se copia en el formato principal con aviso, se registra en Recientes y el color actual no cambia

#### Scenario: Menú contextual
- **WHEN** el usuario mantiene pulsada la tarjeta del paso 700
- **THEN** aparece el menú con Usar como principal, Copiar, Copiar HEX, Copiar RGB y Añadir a paleta

### Requirement: Acciones del panel
La parte inferior de Generar SHALL ofrecer: campo "Prefijo" (p. ej. "Primary") que nombra los colores al añadirlos o copiarlos; "Añadir todo" a la paleta activa (respetando el límite de 64, ver `saved-palettes`); y "Copiar como" con los formatos de `palette-export`. La fila de "Equilibrar" (interruptor, visible en Armonías y Personalizado) SHALL contener además los botones "+" (añadir punto) y, cuando corresponda, "Borrar" y "Personalizar" (ver `free-points`).

#### Scenario: Añadir escala completa
- **WHEN** el usuario toca "Añadir todo" sobre la Design Scale de `#5246BC` con prefijo "Primary"
- **THEN** la paleta activa recibe 11 colores nombrados `Primary 50` … `Primary 950`

### Requirement: Puntos de armonía en la rueda
Con el modo Armonías activo, la rueda (compacta en Generar y principal en Crear) SHALL mostrar un punto discreto por cada color de la armonía con líneas tenues al centro; la armonía SHALL permanecer canónica. Tocar un punto SHALL seleccionarlo (resaltando su tarjeta) y ofrecer "Copiar" en un aviso con acción, sin cambiar el color actual. Arrastrar un punto SHALL pasar a Personalizado con la figura convertida en conjunto libre y el punto en su destino. El doble toque sobre un punto SHALL pasar a Personalizado sin ese punto. El marcador principal SHALL tener prioridad: un arrastre que empieza sobre él mueve el color actual. En los modos sin geometría los puntos no SHALL mostrarse.

#### Scenario: Tocar un punto
- **WHEN** en Triádica el usuario toca el punto +120°
- **THEN** el punto y su tarjeta quedan resaltados, se ofrece "Copiar" con su HEX y el color actual no cambia

#### Scenario: Arrastrar un punto
- **WHEN** el usuario arrastra el punto +120° a otra posición
- **THEN** el modo pasa a Personalizado, el punto queda en el destino, los demás conservan su posición canónica y el color actual no cambia

### Requirement: Vista previa en Crear
La pestaña Crear SHALL mostrar una tira de miniaturas con los colores del modo generado activo (desplazable si no caben) con el nombre del modo; tocar la tira SHALL llevar a la pestaña Generar.

#### Scenario: Ver lo que se está armando
- **WHEN** el modo activo es Personalizado con principal + 3 puntos y el usuario está en Crear
- **THEN** la tira muestra los 4 colores bajo el título "Personalizado" y al tocarla se abre Generar en Personalizado
