## MODIFIED Requirements

### Requirement: Modelo de paleta
Una paleta SHALL tener identificador único, nombre no vacío, descripción opcional, fechas de creación y modificación, un porcentaje recordado de escala de grises (entero opcional 0–100; nulo = 0 %: estado de presentación que no modifica colores ni fechas) y una lista ordenada de colores (identificador, nombre opcional, valor ARGB).

#### Scenario: Nueva paleta
- **WHEN** el usuario crea una paleta sin indicar nombre
- **THEN** se crea "Paleta sin título" (con sufijo numérico si ya existe), sin colores y con ambas fechas iguales

#### Scenario: El porcentaje no toca datos
- **WHEN** el porcentaje de escala de grises de la paleta pasa de 0 a 57
- **THEN** los colores, el orden y `modifiedAt` de la paleta quedan intactos y el 57 se conserva en `palettes.json`

### Requirement: Recargar la paleta en la rueda
"Recargar en la rueda" SHALL pedir confirmación ("Se cargará la paleta en la rueda cromática y se perderán las selecciones actuales.") y, al confirmar, el primer color SHALL pasar a ser el color actual (cambio confirmado) y principal, los restantes SHALL cargarse como secundarios con brillo propio que reproducen exactamente sus colores tal como se ven en la paleta (mezcla según el porcentaje vigente de escala de grises: bit a bit con el HEX visible de cada muestra; a 0 % los colores originales), el conjunto previo SHALL reemplazarse, el modo SHALL pasar a Personalizado y SHALL mostrarse la pestaña Crear. SHALL estar deshabilitado si la paleta no tiene colores. No SHALL modificar la paleta (ni su porcentaje ni sus datos).

#### Scenario: Carga completa en Personalizado
- **WHEN** el usuario confirma "Recargar" sobre "PuchiApp" con `#5246BC`, `#E24347`, `#F7F9FB`
- **THEN** el color actual es `#5246BC`, Personalizado tiene los puntos 1 (`#E24347`) y 2 (`#F7F9FB`) y se muestra Crear

#### Scenario: Recarga con la vista vigente
- **WHEN** con la escala de grises en 80 el usuario confirma "Recargar" sobre la paleta activa
- **THEN** la rueda carga los colores mezclados al 80 % bit a bit con lo que muestran las muestras, la paleta conserva su 80 % con el slider sin variar y sus datos intactos