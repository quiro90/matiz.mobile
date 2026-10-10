# saved-palettes Specification

## Purpose

Permite crear, organizar y conservar paletas con nombre en la pestaña Paletas —la paleta activa como destino de todo "Añadir" y la biblioteca—, guardadas automáticamente en el dispositivo con el mismo esquema que Matiz desktop.

## Requirements

### Requirement: Modelo de paleta
Una paleta SHALL tener identificador único, nombre no vacío, descripción opcional, fechas de creación y modificación y una lista ordenada de colores (identificador, nombre opcional, valor ARGB).

#### Scenario: Nueva paleta
- **WHEN** el usuario crea una paleta sin indicar nombre
- **THEN** se crea "Paleta sin título" (con sufijo numérico si ya existe), sin colores y con ambas fechas iguales

### Requirement: Paleta activa
El sistema SHALL mantener una paleta activa, destino de "Añadir a paleta" (barra del color actual, tarjetas, "Añadir todo", cámara). Si no existe ninguna paleta, añadir SHALL crear "Paleta sin título" automáticamente y marcarla activa. La pestaña Paletas SHALL mostrar arriba la paleta activa con su nombre (editable al tocarlo), su descripción y sus colores en una grilla de muestras con nombre y HEX. Tocar una muestra SHALL usarla como color actual; mantenerla pulsada SHALL abrir un menú con: Copiar, Renombrar, Reemplazar con el color actual, Mover al inicio/al final, Eliminar (con "Deshacer" en el aviso).

#### Scenario: Primera vez
- **WHEN** no hay paletas y el usuario toca "Añadir a paleta" en Crear
- **THEN** se crea "Paleta sin título", pasa a ser la activa y contiene el color actual

#### Scenario: Usar un color guardado
- **WHEN** el usuario toca la muestra `#E24347` de la paleta activa
- **THEN** el color actual pasa a ser `#E24347` como cambio confirmado

### Requirement: Reordenar por arrastre táctil
En la paleta activa, mantener pulsada una muestra y arrastrarla SHALL reordenarla: la muestra levantada SHALL seguir al dedo con elevación, las demás SHALL desplazarse para mostrar el hueco de destino y soltar SHALL fijar la nueva posición; soltar después de la última muestra SHALL moverla al final. Para no competir con el menú, el menú SHALL abrirse si se mantiene pulsado y se suelta sin arrastrar. El orden SHALL persistir y actualizar la fecha de modificación.

#### Scenario: Reordenar
- **WHEN** el usuario arrastra el tercer color a la primera posición
- **THEN** el orden persiste tras reiniciar la app

#### Scenario: Mantener sin arrastrar abre el menú
- **WHEN** el usuario mantiene pulsada una muestra y la suelta sin moverla
- **THEN** se abre el menú contextual de esa muestra

### Requirement: Biblioteca
Debajo de la paleta activa (o mediante "Biblioteca") la pestaña Paletas SHALL listar todas las paletas con nombre, cantidad de colores, fecha de modificación y una vista previa con todos sus colores en filas que envuelven (hasta 64). Tocar una paleta SHALL marcarla como activa. SHALL ofrecer: Nueva, Duplicar ("<nombre> (copia)"), Eliminar (con "Deshacer" mientras el aviso esté visible), Recargar en la rueda, Exportar `.mpalette`, Importar `.mpalette`, Exportar imagen y Copiar como código. Con la biblioteca vacía SHALL verse un estado vacío explicativo con "Nueva" e "Importar".

#### Scenario: Eliminar con deshacer
- **WHEN** el usuario elimina la paleta "PuchiApp" y toca "Deshacer" en el aviso
- **THEN** "PuchiApp" vuelve a la lista con sus colores y fechas intactos

#### Scenario: Biblioteca vacía
- **WHEN** no hay paletas y el usuario abre la pestaña Paletas
- **THEN** se ve un mensaje explicativo con los botones "Nueva" e "Importar"

### Requirement: Recargar la paleta en la rueda
"Recargar en la rueda" SHALL pedir confirmación ("Se cargará la paleta en la rueda cromática y se perderán las selecciones actuales.") y, al confirmar, el primer color SHALL pasar a ser el color actual (cambio confirmado) y principal, los restantes SHALL cargarse como secundarios con brillo propio que reproducen exactamente sus colores, el conjunto previo SHALL reemplazarse, el modo SHALL pasar a Personalizado y SHALL mostrarse la pestaña Crear. SHALL estar deshabilitado si la paleta no tiene colores. No SHALL modificar la paleta.

#### Scenario: Carga completa en Personalizado
- **WHEN** el usuario confirma "Recargar" sobre "PuchiApp" con `#5246BC`, `#E24347`, `#F7F9FB`
- **THEN** el color actual es `#5246BC`, Personalizado tiene los puntos 1 (`#E24347`) y 2 (`#F7F9FB`) y se muestra Crear

### Requirement: Máximo de colores por paleta
Añadir colores a una paleta SHALL respetar un máximo de 64: si la paleta ya tiene 64, o si un lote ("Añadir todo") lo excedería, SHALL bloquearse la operación completa sin añadir nada y avisar "Máximo 64 colores por paleta". Las paletas existentes con más de 64 colores (importadas) SHALL conservarse completas, visibles y exportables.

#### Scenario: Lote que no cabe
- **WHEN** la paleta activa tiene 60 colores y el usuario toca "Añadir todo" sobre 6 colores
- **THEN** no se añade ninguno, la paleta queda con 60 y aparece el aviso

### Requirement: Persistencia local automática
Las paletas, la paleta activa, el historial y los ajustes SHALL guardarse automáticamente tras cada cambio (sin acción "Guardar", con escritura diferida ≤ 300 ms) en archivos JSON en el almacenamiento privado de la app, con el mismo esquema y `schemaVersion` que desktop (`palettes.json`, `history.json`; `settings.json` con las claves propias de móvil). La escritura SHALL ser atómica y SHALL completarse también cuando la app pasa a segundo plano. Un archivo corrupto SHALL renombrarse a `<nombre>.corrupt-<fecha>.json`, la app SHALL iniciar con datos vacíos para ese archivo y avisar sin cerrarse. Los datos SHALL incluirse en la copia de seguridad automática del sistema.

#### Scenario: Persistencia entre sesiones
- **WHEN** el usuario crea una paleta con 3 colores y cierra la app desde el selector de apps recientes
- **THEN** al abrirla de nuevo la paleta aparece con los mismos nombres, colores, orden y fechas

#### Scenario: Archivo corrupto
- **WHEN** `palettes.json` no es JSON válido al iniciar
- **THEN** se renombra a `palettes.corrupt-<fecha>.json`, la biblioteca inicia vacía y un aviso informa la situación
