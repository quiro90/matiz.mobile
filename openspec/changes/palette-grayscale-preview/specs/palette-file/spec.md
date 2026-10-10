## MODIFIED Requirements

### Requirement: Formato de archivo compatible con desktop
Un `.mpalette` SHALL ser un JSON legible con `schemaVersion`, nombre, descripción (opcional), fechas de creación y modificación, un porcentaje opcional de escala de grises (`grayPercent`, omitido si nulo o 0) y la lista ordenada de colores (nombre opcional, `hex` `#RRGGBB` y `alpha` solo si ≠ 255), con la misma estructura que escribe y lee Matiz desktop. Los colores del archivo SHALL ser siempre los originales (la mezcla no se hornea en los hex: viaja solo por `grayPercent`). Un archivo sin `grayPercent` SHALL tratarse como 0 % y el campo SHALL conservarse en la ida y vuelta con desktop (que ya lo escribe y lo lee). Archivos con `schemaVersion` mayor a la vigente SHALL rechazarse con error sin modificar la biblioteca.

#### Scenario: Ida y vuelta con desktop
- **WHEN** se exporta "PuchiApp" (`#5246BC`, `#E24347`, `#F7F9FB`) desde Android y se importa en Matiz desktop
- **THEN** desktop crea la paleta "PuchiApp" con los 3 colores, nombres, orden y fechas

#### Scenario: Archivo de desktop en Android
- **WHEN** se importa en Android un `.mpalette` exportado por desktop con un color de alfa 128
- **THEN** la paleta se crea con todos sus colores y el alfa 128 se conserva

#### Scenario: Versión futura
- **WHEN** se importa un `.mpalette` con `schemaVersion` mayor a la vigente
- **THEN** aparece un aviso de error y la biblioteca no cambia

#### Scenario: El porcentaje viaja sin hornear el gris
- **WHEN** con la escala en 57 se exporta la paleta "ChewisPalette" (color `#8065A1`) y se abre el archivo
- **THEN** el JSON contiene `"grayPercent": 57` y el hex del color sigue siendo `#8065A1` (sin mezcla aplicada)

#### Scenario: Importar restaura el porcentaje
- **WHEN** se importa un `.mpalette` con `grayPercent: 57`
- **THEN** la paleta importada queda marcada con 57 % y su vista muestra las muestras mezcladas a ese porcentaje

#### Scenario: Archivo antiguo sin el campo
- **WHEN** se importa un `.mpalette` sin `grayPercent`
- **THEN** la paleta importada queda con 0 % y se muestra normal