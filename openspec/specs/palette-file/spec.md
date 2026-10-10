# palette-file Specification

## Purpose

Formato de archivo de paleta `.mpalette`, idéntico al de Matiz desktop, para guardar una paleta completa, compartirla e importarla siempre como paleta nueva, de modo que las paletas viajen entre el teléfono y el escritorio.

## Requirements

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

### Requirement: Exportar la paleta marcada
"Exportar .mpalette" SHALL ofrecer dos destinos: "Guardar en…" (diálogo de guardado del sistema con nombre sugerido "<nombre>.mpalette") y "Compartir" (hoja de compartir del sistema con el archivo adjunto). SHALL estar deshabilitado si la paleta no tiene colores. Cancelar el diálogo no SHALL escribir nada.

#### Scenario: Compartir por mensajería
- **WHEN** el usuario elige Exportar → Compartir sobre "PuchiApp" y elige una app de mensajería
- **THEN** la app de mensajería recibe el archivo "PuchiApp.mpalette" con la paleta completa

#### Scenario: Guardar en archivos
- **WHEN** el usuario elige Exportar → Guardar en…, elige la carpeta Descargas y confirma
- **THEN** se crea "PuchiApp.mpalette" en Descargas y aparece el aviso de exportación

### Requirement: Importar siempre como paleta nueva
"Importar" SHALL abrir el selector de archivos del sistema y crear siempre una paleta nueva (nunca modificar una existente), conservando nombre, descripción, colores, nombres, orden y fechas, con identificadores nuevos. Un nombre repetido SHALL recibir sufijo (" 2"). La importada SHALL quedar marcada y confirmarse con un aviso con su nombre. Más de 64 colores SHALL conservarse completos. Un archivo inválido SHALL avisarse sin cambiar la biblioteca. Las mismas reglas SHALL aplicar a los archivos recibidos por `share-intake`.

#### Scenario: Importar con nombre duplicado
- **WHEN** ya existe "PuchiApp" y el usuario importa otro "PuchiApp.mpalette"
- **THEN** se crea "PuchiApp 2", la existente queda intacta y la nueva queda marcada
