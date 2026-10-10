## Purpose

Mantiene a mano los colores usados recientemente para volver a ellos con un toque, especialmente al tomar varios colores seguidos de una imagen, la cámara o la burbuja.

## ADDED Requirements

### Requirement: Política de inserción
El sistema SHALL añadir un color al historial cuando: se confirma un color desde una imagen, la cámara o la burbuja, se confirma una entrada manual (texto/RGB/pegar) o se copia un color. Los movimientos de la rueda o del brillo no SHALL añadir entradas por sí solos.

#### Scenario: Arrastres no ensucian el historial
- **WHEN** el usuario arrastra la rueda varias veces sin copiar
- **THEN** el historial no cambia

#### Scenario: Copiar registra el color
- **WHEN** el usuario copia el HEX del color actual
- **THEN** ese color aparece primero en el historial

### Requirement: Orden, duplicados y límite
El historial SHALL ordenarse del más reciente al más antiguo, con máximo 30 colores, moviendo al principio un color ya presente en lugar de duplicarlo.

#### Scenario: Duplicado
- **WHEN** el historial contiene `#5246BC` en la posición 5 y se vuelve a tomar `#5246BC`
- **THEN** `#5246BC` pasa a la posición 1 y aparece una sola vez

#### Scenario: Límite
- **WHEN** el historial tiene 30 colores y se añade uno nuevo
- **THEN** se descarta el más antiguo

### Requirement: Presentación, uso y persistencia
Los Recientes SHALL mostrarse como una fila desplazable horizontal de muestras pequeñas (mínimo 32 dp de lado, área táctil de 48 dp) en la pestaña Crear y en la hoja de detalle del color. Tocar una muestra SHALL convertirla en el color actual (cambio confirmado); mantenerla pulsada SHALL ofrecer copiar o añadir a la paleta activa. El historial SHALL persistir entre sesiones (`history.json`, mismo esquema que desktop) y SHALL poder vaciarse desde la hoja de detalle con confirmación.

#### Scenario: Persistencia
- **WHEN** el usuario cierra y vuelve a abrir la app
- **THEN** los Recientes muestran los mismos colores en el mismo orden

#### Scenario: Usar un reciente
- **WHEN** el usuario toca `#E24347` en Recientes
- **THEN** el color actual pasa a ser `#E24347` y "Anterior" muestra el color previo
