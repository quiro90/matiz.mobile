## Purpose

Hace que copiar valores de color sea inmediato en el teléfono: un toque copia en el formato principal del usuario, existen fragmentos de código listos para pegar y cada copia se confirma de forma no intrusiva.

## ADDED Requirements

### Requirement: Formatos del color actual
La hoja de detalle del color SHALL mostrar HEX, RGB, HSL, HSV y CMYK (aproximado), cada uno con una acción de copiar de al menos 48 dp, y una sección desplegable "Más formatos" con OKLCH y, si alpha ≠ 255, ARGB.

#### Scenario: Copiar RGB
- **WHEN** el color actual es `#5246BC` y el usuario toca copiar junto a RGB
- **THEN** el portapapeles contiene `82, 70, 188` y se muestra una confirmación breve

### Requirement: Copiar como código
El sistema SHALL permitir copiar el color actual como: HEX `#5246BC`; CSS rgb `rgb(82, 70, 188)`; CSS hsl `hsl(246, 47%, 51%)`; CSS oklch; C# WPF `Color.FromRgb(82, 70, 188)`; C# ARGB `Color.FromArgb(255, 82, 70, 188)`; XAML `#FF5246BC`; Dart/Flutter `Color(0xFF5246BC)`; entero ARGB `0xFF5246BC`. Añadir un formato no SHALL requerir cambios de UI más allá de registrarlo.

#### Scenario: Copiar para Flutter
- **WHEN** el usuario elige "Copiar como → Dart/Flutter" con `#5246BC`
- **THEN** el portapapeles contiene `Color(0xFF5246BC)`

### Requirement: Copiar todo
El sistema SHALL ofrecer "Copiar todo", que copie una línea por formato principal.

#### Scenario: Bloque completo
- **WHEN** el usuario ejecuta "Copiar todo" con `#5246BC`
- **THEN** el portapapeles contiene exactamente:
  ```
  HEX: #5246BC
  RGB: 82, 70, 188
  HSL: 246°, 47%, 51%
  HSV: 246°, 63%, 74%
  CMYK: 56%, 63%, 0%, 26%
  ```

### Requirement: Formato principal y opciones de HEX
El sistema SHALL permitir configurar en Ajustes el formato principal (usado por el botón "Copiar" de la barra Anterior/Actual, por las tarjetas y por "Copiar al tomar color"), HEX en mayúsculas/minúsculas y con/sin `#`. Por defecto: HEX en mayúsculas con `#`.

#### Scenario: Formato principal configurado
- **WHEN** el formato principal es "CSS rgb" y el usuario toca "Copiar" en la barra del color actual con `#5246BC`
- **THEN** el portapapeles contiene `rgb(82, 70, 188)`

### Requirement: Confirmación de copia sin duplicados
Cada copia SHALL confirmarse con un aviso breve dentro de la app que incluya el valor copiado. En las versiones de Android que ya muestran su propia confirmación del sistema al copiar (Android 13+), el aviso de la app SHALL igualmente mostrarse dentro de la app pero no SHALL usarse ninguna notificación adicional. Si la copia falla, SHALL mostrarse "No se pudo copiar" sin cerrar la app.

#### Scenario: Copia confirmada
- **WHEN** el usuario copia el HEX `#5246BC` desde una tarjeta
- **THEN** aparece el aviso "Copiado #5246BC"
