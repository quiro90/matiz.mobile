## ADDED Requirements

### Requirement: Exportación fiel al modo en escala de grises
Con la paleta activa en un porcentaje > 0, toda exportación de esa paleta SHALL reflejar el valor vigente del modo (WYSIWYG): los formatos de código ("Copiar como" / "Compartir como") SHALL entregar los colores mezclados con sus valores visibles (HEX/RGB) correspondientes, y las imágenes exportadas (Paleta PNG y Superpuestos) SHALL reproducir exactamente el color mezclado mostrado por cada muestra, con los valores HEX/RGB listados calculados sobre esa mezcla. El archivo `.mpalette` no forma parte del WYSIWYG: SHALL conservar los colores originales y el porcentaje (ver `palette-file`). A 0 % toda exportación SHALL quedar idéntica a como es hoy. Las paletas generadas y las escalas no SHALL verse afectadas (no tienen modo de escala de grises).

#### Scenario: Copiar como código con escala 100
- **WHEN** la paleta activa tiene escala 100 y contiene `#5246BC`
- **THEN** cualquier formato de código (por ejemplo CSS variables) entrega el gris equivalente de `#5246BC` con el HEX/valor correspondiente al gris mostrado

#### Scenario: Imagen con mezcla intermedia
- **WHEN** la paleta activa tiene escala 60 y se exporta como imagen Paleta (o Superpuestos) a 1×
- **THEN** el RGB del centro de cada bloque coincide exactamente con la mezcla 60 % mostrada y los valores HEX/RGB listados corresponden a esa mezcla

#### Scenario: Exportación a 0 % idéntica
- **WHEN** la escala está en 0
- **THEN** todas las exportaciones (código, imagen Paleta, Superpuestos y `.mpalette`) quedan bit a bit idénticas a como son hoy

#### Scenario: Escalas y paletas generadas intactas
- **WHEN** con la paleta activa en 80 % el usuario exporta una Tints & Shades o "Añade todo" de una página Generar
- **THEN** los colores generados salen en su color original, sin mezcla