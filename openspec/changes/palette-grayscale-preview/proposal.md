## Why

La versión 1.1.0 de Matiz Android no permite ver ni entregar la paleta en escala de grises: para preparar versiones para impresión, accesibilidad o una entrega "sin color" habría que recalcular cada color a mano. El cambio llega con la app ya publicada en Play y su contraparte de desktop (../matiz) ya implementada, así que móvil debe quedarse en paridad (mismo gris perceptual `Oklab L`, mismo campo `grayPercent` en `palettes.json`/`.mpalette`, mismo comportamiento de exportación).

## What Changes

- Nuevo modo de vista "en caliente" **"Escala de grises"** en la pestaña Paletas, controlado por una barra deslizante continua de **0 a 100 %** visible de forma permanente en el encabezado de la paleta activa (con su % y acceso rápido de restablecer a 0): al arrastrar, cada muestra se muestra mezclada hacia su gris equivalente perceptual (el mismo de `ColorMath.grayEquivalent`, paridad con desktop `MixToGray`). A 0 % la paleta se ve exactamente igual que hoy.
- Los colores almacenados **no** se modifican: el % es estado de vista; al volver a 0 % la paleta vuelve exactamente a su estado previo y el HEX visible vuelve al original.
- **WYSIWYG en exportaciones** (decisión de usuario): con % > 0 salen mezclados los formatos de código (Copiar como / Compartir como: CSS/JSON/Dart/C#/Tailwind/HEX) y las imágenes (Paleta PNG y Superpuestos). El `.mpalette` exportado conserva los colores **originales** y añade el campo opcional `grayPercent` (como ya lo hace desktop).
- **Persistencia por paleta**: `grayPercent` (opcional, null = 0 %) vive en `palettes.json` y en `.mpalette` sin cambio de `schemaVersion` (compatible en ambos sentidos con archivos antiguos y con desktop). Guardarlo no altera colores ni `modifiedAt`. Reabrir la app, cambiar de paleta o importar restaura el % con la mezcla aplicada sin intervención.
- **"Recargar en la rueda"** carga los colores tal como se ven (mezclados al % vigente) y deja la paleta intacta (conserva su %).
- **Crear y duplicar** paletas arrancan en 0 %. Las acciones por color (usar como color actual, copiar HEX, menú contextual) operan sobre el color original almacenado.
- Versión de la app: **1.1.1** (`pubspec.yaml` `version: 1.1.1+11`).

## Capabilities

### New Capabilities
- `palette-grayscale-preview`: modo de vista temporal 0–100 % que muestra la paleta activa con cada color mezclado hacia su gris equivalente perceptual sin alterar datos, con slider visible en el encabezado de la paleta activa, coherencia en caliente ante cambios de la paleta, y porcentaje recordado por paleta (persistencia aditiva y restauración automática).

### Modified Capabilities
- `palette-export`: las exportaciones de la paleta activa (imagen PNG, superpuestos y formatos de código) SHALL reflejar el estado actual del modo en escala de grises (WYSIWYG).
- `saved-palettes`: el modelo de paleta recuerda `grayPercent`; el cambio de paleta activa y la reapertura restauran el % con su mezcla; "Recargar en la rueda" carga los colores como se ven; crear/duplicar arrancan en 0 % y las acciones por color usan el color original.
- `palette-file`: el `.mpalette` incorpora el campo opcional `grayPercent` (idempotente con desktop, `schemaVersion` sin cambios): se guarda al exportar y se restaura al importar; archivos sin el campo se tratan como 0 %.

## Impact

- `packages/matiz_core/lib/src/colors/color_math.dart` — `ColorMath.mixToGray(Argb, double)` (lerp por canal sRGB hacia `grayEquivalent`, alfa del original) + prueba de paridad con desktop.
- `packages/matiz_core/lib/src/palettes/palette.dart` — `Palette.grayPercent` (int?, null = 0) en JSON omitido si null.
- `packages/matiz_core/lib/src/palettes/palette_file.dart` — campo opcional `grayPercent` en `encode`/`decode` y mapeo `from`/`toPalette`.
- `packages/matiz_core/lib/src/palettes/palette_service.dart` — `setGrayPercent(id, v)`: acota 0–100, normaliza 0 → null, no toca `modifiedAt`, no-op sin cambio, notifica `onChanged`.
- `packages/matiz_core/lib/src/export/palette_formatters.dart` — construcción del `PaletteExportModel` con mezcla aplicada según el % (único punto de verdad para WYSIWYG).
- `lib/state/app_controller.dart` — `setGrayPercent` de la activa, mezcla en `reloadInWheel`, y mezcla aplicada en los caminos de exportación (código e imágenes).
- `lib/ui/palettes_page.dart` — slider visible en `_ActiveHeader` (+% + restablecer), muestras y HEX mezclados según el %.
- `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb` (+ regeneración gen-l10n) — textos "Escala de grises", restablecer, tooltip/aviso.
- `pubspec.yaml` — versión 1.1.1+11.
- Tests: `packages/matiz_core/test/` (mezcla, persistencia, servicio, exportación).