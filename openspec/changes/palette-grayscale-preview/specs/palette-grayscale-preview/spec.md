## Purpose

Modo de vista temporal ("en caliente", solo presentación) de la paleta activa en la pestaña Paletas: una escala continua 0–100 % que muestra cada color mezclado hacia su gris equivalente perceptual para previsualizar y entregar la paleta en escala de grises, sin alterar los colores guardados, con el porcentaje recordado por paleta y portable con desktop.

## ADDED Requirements

### Requirement: Modo de vista en escala de grises
La pestaña Paletas SHALL ofrecer, para la paleta activa, un modo de vista continuo de 0 a 100 % ("Escala de grises"). A 0 % las muestras SHALL verse exactamente igual que con el modo desactivado. A 100 %, cada muestra SHALL mostrar individualmente su gris equivalente perceptual con la misma luminosidad percibida que su color original. Los valores intermedios SHALL mezclar proporcionalmente cada color con su gris equivalente (0 % = color original, 100 % = gris equivalente). El modo SHALL afectar solo a la presentación: los colores almacenados SHALL permanecer sin alterar, ninguna acción del modo SHALL modificarlos ni las fechas de la paleta, y al volver a 0 % la paleta SHALL verse exactamente como su estado original. El porcentaje vigente SHALL recordarse por paleta y SHALL restaurarse automáticamente (ver "Persistencia del porcentaje por paleta").

#### Scenario: Vista a 100 %
- **WHEN** la paleta activa contiene `#5246BC` y `#FF8A00` y el usuario arrastra la escala de grises a 100
- **THEN** cada muestra muestra su gris equivalente (misma luminosidad perceptual que su color original), el HEX visible corresponde al gris mostrado y los colores guardados de la paleta no cambian

#### Scenario: Valor intermedio
- **WHEN** la escala se deja en 60
- **THEN** cada muestra muestra la mezcla proporcional 60 % entre su color original y su gris equivalente y su HEX visible corresponde a esa mezcla

#### Scenario: Vuelta al estado previo
- **WHEN** el usuario deja la escala en 100 y luego la devuelve a 0
- **THEN** las muestras y los HEX visibles vuelven a ser idénticos a los originales y no se registró ningún cambio de color ni de fecha de modificación

#### Scenario: Porcentaje visible y restablecer
- **WHEN** se mueve la escala
- **THEN** el porcentaje vigente SHALL estar visible junto al slider (por ejemplo `57 %`) con una acción de restablecer a 0 %, y al tocarla el valor queda en 0 y las muestras vuelven a sus colores originales

#### Scenario: Acciones por color intactas
- **WHEN** con la escala en 100 el usuario toca una muestra (o usa su menú: copiar, usar como color actual, reemplazar)
- **THEN** la acción opera sobre el color original almacenado de esa muestra, no sobre la vista en gris

### Requirement: Acceso directo y permanente en la pestaña Paletas
El modo SHALL tener acceso inmediato desde la pestaña Paletas, sin hojas ni menús intermedios: la escala SHALL estar siempre visible dentro del encabezado de la paleta activa, con objetivo táctil ≥ 48 dp, y las muestras (relleno con su gris y su HEX visible) SHALL refrescarse en vivo durante el arrastre. Si la paleta activa no tiene colores, el control SHALL verse deshabilitado.

#### Scenario: Arrastre en vivo
- **WHEN** la paleta activa tiene colores y el usuario arrastra la escala hacia 100
- **THEN** todas las muestras se van mezclando en vivo durante el arrastre, con su HEX visible acompañando al color mostrado, sin abrir ninguna hoja ni menú

#### Scenario: Paleta sin colores
- **WHEN** la paleta activa no tiene colores
- **THEN** la escala aparece deshabilitada y no tiene efecto

### Requirement: Coherencia en caliente
Mientras el modo esté en un valor > 0, cualquier cambio de la paleta activa (agregar color, reemplazar, mover, cambiar de paleta marcada o importar) SHALL presentar también los colores nuevos o existentes conforme al valor vigente del modo, sin intervención del usuario; el % mostrado SHALL corresponder siempre a la paleta marcada en ese momento.

#### Scenario: Agregar color con el modo activo
- **WHEN** con la escala en 100 el usuario agrega un color nuevo a la paleta activa
- **THEN** la nueva muestra aparece ya con su gris equivalente y su HEX de gris, y al devolver la escala a 0 ese color agregado se muestra en el original

#### Scenario: Cambiar de paleta marcada actualiza el % mostrado
- **WHEN** la paleta A tiene 60 %, el usuario marca la paleta B (0 %) en la biblioteca
- **THEN** el slider y las muestras pasan a reflejar B: 0 % y colores originales

### Requirement: Persistencia del porcentaje por paleta
Cada paleta SHALL recordar su porcentaje como campo opcional (`grayPercent`, null = 0 %) en `palettes.json` y en el `.mpalette` exportado, sin cambio de `schemaVersion`: los archivos sin el campo SHALL tratarse como 0 % y el campo SHALL ignorarse sin error por apps anteriores. Guardar el porcentaje (arrastre o restablecer) SHALL no modificar colores ni fechas. Al reabrir la app, cambiar la paleta marcada o importar un `.mpalette` SHALL restaurarse el porcentaje de esa paleta (slider y muestras, sin intervención del usuario). Crear una paleta nueva y duplicar SHALL dejar el porcentaje en 0 %.

#### Scenario: Restauración al reabrir la app
- **WHEN** la paleta quedó con 80 % guardado, el usuario cierra la app y la vuelve a abrir
- **THEN** el slider arranca en 80 % y las muestras se muestran con esa mezcla, con los colores guardados intactos

#### Scenario: Volver a cambiar de paleta
- **WHEN** la paleta A está con 60 % recordado, el usuario marca la paleta B y luego vuelve a marcar A
- **THEN** al marcar B el slider muestra 0 % con colores originales y al volver a A el slider muestra 60 % con las muestras de esa mezcla

#### Scenario: Crear y duplicar arrancan en 0 %
- **WHEN** el usuario crea una paleta nueva o duplica una paleta con 57 %
- **THEN** la paleta resultante queda con 0 %

#### Scenario: El porcentaje no altera datos
- **WHEN** el usuario mueve la escala de 0 a 57 y la deja ahí
- **THEN** los colores y `modifiedAt` de la paleta no cambian y el valor 57 queda guardado en `palettes.json`