# color-model Specification

## Purpose

Define cómo Matiz Android representa, convierte, redondea y parsea colores, con resultados idénticos a Matiz desktop, para que todo valor mostrado, copiado, guardado o intercambiado por `.mpalette` sea exacto y reproducible entre ambas apps.

## Requirements

### Requirement: Valor canónico sRGB de 8 bits con alpha
El sistema SHALL representar todo color persistido, copiado o mostrado como HEX a partir de un valor canónico sRGB de 8 bits por canal (R, G, B en 0–255) más un alpha de 8 bits (0–255, por defecto 255). Las coordenadas continuas del selector (hue, saturación, brillo) SHALL convertirse al valor canónico redondeando cada canal con `round(x × 255)` usando redondeo "away from zero" en el punto medio.

#### Scenario: Color opaco por defecto
- **WHEN** el usuario introduce `#5246BC`
- **THEN** el color canónico es R=82, G=70, B=188, A=255

#### Scenario: Redondeo determinista
- **WHEN** un canal calculado vale exactamente 127.5
- **THEN** el canal canónico es 128

### Requirement: Conversiones estándar
El sistema SHALL convertir el valor canónico a HEX, RGB, HSL, HSV/HSB, CMYK y OKLCH usando las fórmulas estándar de sRGB (HSL/HSV hexcónicos; OKLCH según Oklab de Björn Ottosson con la función de transferencia sRGB IEC 61966-2-1). Los valores mostrados SHALL redondearse a: hue en grados enteros, porcentajes enteros, OKLCH L y C con 3 decimales y h con 1 decimal.

#### Scenario: Conversión de #5246BC
- **WHEN** el color actual es `#5246BC`
- **THEN** se muestra RGB `82, 70, 188`, HSL `246°, 47%, 51%`, HSV `246°, 63%, 74%` y CMYK `56%, 63%, 0%, 26%`

#### Scenario: Ida y vuelta sin deriva
- **WHEN** cualquier color HEX de 6 dígitos se convierte a HSV/HSL/OKLCH de doble precisión y de vuelta al valor canónico
- **THEN** el HEX resultante es idéntico al original

### Requirement: Paridad numérica con desktop
Para una misma entrada, todas las conversiones, el parser, la Design Scale, las armonías, los tints/shades, los neutros y la extracción de colores SHALL producir exactamente los mismos valores canónicos que Matiz desktop. Los casos de prueba de `Matiz.Core.Tests` SHALL portarse y pasar sin cambios en sus valores esperados.

#### Scenario: Escala idéntica
- **WHEN** se genera la Design Scale de `#5246BC` con ancla "Base en 500" en Android y en desktop
- **THEN** los 11 HEX resultantes son idénticos en ambas apps

### Requirement: Hue y saturación de colores acromáticos
El sistema SHALL tratar el hue como indefinido cuando la saturación es 0 y la saturación como indefinida cuando el brillo es 0, mostrando `0°` / `0%` en los formatos de texto, sin alterar las coordenadas del selector (ver `current-color`).

#### Scenario: Gris puro
- **WHEN** el color es `#808080`
- **THEN** HSL se muestra como `0°, 0%, 50%` y HSV como `0°, 0%, 50%`

### Requirement: CMYK aproximado sin perfil
El sistema SHALL calcular CMYK con la fórmula ingenua sin perfil (K = 1 − max(R,G,B); C = (1 − R − K)/(1 − K), análogo para M e Y; negro puro C=M=Y=0, K=100%) y SHALL indicarlo en la UI como aproximado (marca `*` con explicación al tocarla).

#### Scenario: Negro puro
- **WHEN** el color es `#000000`
- **THEN** CMYK es `0%, 0%, 0%, 100%`

#### Scenario: Indicación de aproximación
- **WHEN** el usuario toca la marca `*` junto a CMYK
- **THEN** se muestra el texto "Aproximado, sin perfil ICC"

### Requirement: Parsing de entradas de color
El sistema SHALL aceptar como entrada de texto, ignorando espacios y mayúsculas/minúsculas: HEX de 3, 6 u 8 dígitos con o sin `#`; `0xAARRGGBB`; `rgb(r, g, b)`, `rgba(r, g, b, a)`; tres enteros separados por comas o espacios (RGB); `hsl(h, s%, l%)`; `hsv(h, s%, v%)`. Un HEX de 8 dígitos SHALL interpretarse como `#AARRGGBB`. Las entradas inválidas o fuera de rango SHALL rechazarse sin modificar el color actual.

#### Scenario: Formatos equivalentes
- **WHEN** el usuario introduce `5246bc`, `#5246BC`, `rgb(82, 70, 188)`, `82 70 188` o `0xFF5246BC`
- **THEN** en todos los casos el color resultante es `#5246BC` opaco

#### Scenario: HEX corto
- **WHEN** el usuario introduce `#5AC`
- **THEN** el color resultante es `#55AACC`

#### Scenario: HEX de 8 dígitos con alpha
- **WHEN** el usuario introduce `#805246BC`
- **THEN** el color resultante tiene A=128, R=82, G=70, B=188

#### Scenario: Entrada fuera de rango
- **WHEN** el usuario introduce `rgb(300, 0, 0)`
- **THEN** la entrada se marca como inválida y el color actual no cambia

### Requirement: Alpha como capacidad interna
El sistema SHALL conservar el alpha en el modelo, la persistencia, los `.mpalette` y los formatos que lo soportan, pero la UI SHALL operar con colores opacos y mostrar el alpha solo cuando sea distinto de 255.

#### Scenario: Color con transparencia
- **WHEN** el color actual tiene A=128 (por ejemplo, cargado desde una paleta importada)
- **THEN** la muestra se dibuja sobre un patrón de tablero y el detalle del color muestra el alpha
