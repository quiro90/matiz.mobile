## Purpose

Lleva paletas y escalas a código y a imagen desde el teléfono: formatos de texto listos para pegar y una imagen PNG limpia (paleta clásica o superpuestos) para guardar o compartir.

## ADDED Requirements

### Requirement: Formatos de código para paletas
El sistema SHALL copiar (o compartir como texto) una paleta guardada o una paleta/escala generada como: CSS variables, JSON, Dart/Flutter, C#, Tailwind v4 y lista HEX, con nombres convertidos a identificadores válidos (CSS kebab-case, JSON nombre original, Dart camelCase, C# PascalCase, sin tildes), colores sin nombre como `color1`, `color2`… y colisiones con sufijo numérico. La salida SHALL ser idéntica a la de desktop. Los formatos SHALL ser extensibles por registro.

#### Scenario: CSS variables
- **WHEN** la paleta contiene "Primary" `#5246BC` y "Secondary" `#FF8A00` y el usuario copia como CSS
- **THEN** el portapapeles contiene:
  ```
  :root {
    --primary: #5246BC;
    --secondary: #FF8A00;
  }
  ```

#### Scenario: Dart/Flutter
- **WHEN** la misma paleta se copia como Dart
- **THEN** el resultado contiene `static const Color primary = Color(0xFF5246BC);` dentro de una clase con el nombre de la paleta en PascalCase

#### Scenario: Escala con pasos
- **WHEN** el usuario copia la Design Scale con prefijo "Primary" como CSS
- **THEN** el resultado contiene `--primary-50` … `--primary-950`

#### Scenario: Compartir como texto
- **WHEN** el usuario elige "Compartir como → JSON" sobre "PuchiApp"
- **THEN** se abre la hoja de compartir del sistema con el texto JSON de la paleta

### Requirement: Exportar paleta como imagen PNG
"Exportar imagen → Paleta" SHALL abrir una pantalla de vista previa con: título, bloques de color y debajo de cada uno nombre, HEX y RGB (HSL y CMYK opcionales); orientación horizontal (hasta 6 por fila) o vertical; escala 1×/2×/3×; fondo claro, oscuro o transparente (alfa 0, texto con estilo claro). Las acciones SHALL ser "Guardar en…" (diálogo del sistema), "Guardar en Galería" (álbum "Matiz", sin solicitar permisos en Android 10+) y "Compartir". El centro de cada bloque SHALL tener exactamente el color de la paleta. Con la paleta vacía la acción SHALL estar deshabilitada.

#### Scenario: Exportación básica
- **WHEN** el usuario exporta "PuchiApp" (3 colores) en horizontal a 2×
- **THEN** la imagen tiene el título "PuchiApp", 3 bloques con nombre, HEX y RGB y el doble de dimensiones que a 1×

#### Scenario: Píxeles exactos
- **WHEN** se inspecciona el centro de un bloque del PNG exportado
- **THEN** su RGB coincide exactamente con el color de la paleta

#### Scenario: Compartir la imagen
- **WHEN** el usuario toca "Compartir" en la vista previa
- **THEN** se abre la hoja de compartir del sistema con el PNG

### Requirement: Exportar como superpuestos
"Exportar imagen → Superpuestos" (también desde la dupla Anterior/Actual de la hoja de detalle) SHALL dibujar los colores como capas opacas apiladas de tamaño decreciente con forma cuadrado, círculo o triángulo, orden primero→último o último→primero, escala 1×/2×/3× y fondo claro, oscuro o transparente, de modo que con 64 colores todos los anillos sigan visibles, y SHALL listar nombre, HEX y RGB de cada color. Con un color SHALL verse una única capa. Las acciones de guardado y compartido SHALL ser las mismas que en la exportación de paleta.

#### Scenario: Superposición incremental
- **WHEN** el usuario exporta 8 colores en cuadrado, orden primero→último
- **THEN** la imagen muestra 8 capas apiladas desde la mayor (primer color) hasta la menor, cada una con anillo visible

#### Scenario: Dupla Anterior/Actual
- **WHEN** "Anterior" es `#5246BC`, "Actual" es `#675BCE` y el usuario toca "Exportar superpuestos" en la hoja de detalle
- **THEN** la vista previa muestra la dupla [`#5246BC`, `#675BCE`] con la doble capa y sus valores
