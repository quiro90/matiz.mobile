## Context

Ver proposal.md (Why). Estado relevante de móvil:

- El gris equivalente ya existe en core (`packages/matiz_core/lib/src/colors/color_math.dart`, `ColorMath.grayEquivalent`, Oklab L) y tiene paridad probada con desktop vía `tool/golden` (`golden_parity_test.dart` verifica la clave `gray` contra valores generados por el C# de desktop).
- La biblioteca vive en `PaletteService` (matiz_core): toda mutación pasa por métodos que llaman `_touch(p)` (actualiza `modifiedAt`) y `_changed()` (notifica a AppController → autoguardado con `JsonStore.scheduleSave` debounceado ≤ 300 ms). El modelo `Palette`/`PaletteFile` ya es idéntico al esquema v1 de desktop con escritura atómica.
- La pestaña Paletas (`lib/ui/palettes_page.dart`) muestra la paleta activa (`_ActiveHeader` con botones "Recargar en la rueda", "Exportar" y fila "Biblioteca") y sus muestras (`_ActiveColors`, swatch + nombre + HEX, con tap/menú/reorder). Todo el render consulta `Palette.colors` directamente.
- Las exportaciones de la paleta activa construyen `PaletteExportModel.from(palette)` (único punto de verdad para formatters de código) en 4 sitios: `ExportImagePage` (imagen/overlay) desde `_onAction`, y `AppController.copyPaletteAs` / `paletteAsText`. `exportPaletteFile` serializa `PaletteFile.from(p)`.
- `reloadInWheel` carga `p.colors` crudos en la sesión (color principal + free points con brillo propio).
- El usuario ya decidió: slider siempre visible (no popup), WYSIWYG en exportaciones, versión 1.1.1 (build +11). Desktop es su referencia de comportamiento (cambio `palette-grayscale-preview` en ../matiz, ya completado).

## Goals / Non-Goals

**Goals:**
- Port 1:1 del gris perceptual de desktop: mezcla por canal sRGB hacia `GrayEquivalent` con el mismo redondeo, para que móvil y desktop produzcan los mismos bits ante el mismo color y %.
- Un solo punto de verdad para el % (`Palette.grayPercent`) y un solo transformador de exportación (WYSIWYG), como en desktop.
- Reutilizar los caminos existentes (servicio, store, formatters) sin duplicar lógica ni tocar desktop.

**Non-Goals:**
- No persistir el % global ni en ajustes: el único lugar del valor es la paleta.
- No aplicar el modo a paletas generadas (Generar), escalas ni a la dupla Anterior/Actual del detalle de color.
- No mezclar en acciones por color (tap usar / copiar / reemplazar operan sobre el original).
- No tocar el proyecto desktop ni cambiar `schemaVersion` de `palettes.json`/`.mpalette`.

## Decisions

1. **Port exacto de `MixToGray` en matiz_core** (`ColorMath.mixToGray(Argb c, double amount)`): clamp 0–1, identidad si ≤ 0, `grayEquivalent` si ≥ 1, y lerp por canal RGB con redondeo away-from-zero como desktop (`LerpByte`), conservando el alfa del original. Alternativas descartadas: interpolar en Oklab (más caro, diferencias imperceptibles, rompería la paridad bit a bit con desktop) o mezclar solo estados discretos (veto del usuario).

2. **El % vive solo en la paleta: `Palette.grayPercent` (int?, null = 0)**. `toJson` lo omite si es null (equivalente a `JsonIgnore(Condition.WhenWritingNull)` de desktop) y `fromJson` lo lee tolerante (clamp a 0–100; valores inválidos/fuera de rango → null = 0 %). `PaletteFile` mapea el mismo campo en `from`/`toPalette`/`encode`/`decode` sin tocar `schemaVersion`. Compatibilidad: archivos viejos sin campo → 0 %; archivos nuevos leídos por apps viejas ignoran la clave desconocida (el decoder usa claves explícitas). Alternativas descartadas: persistir en `settings.json` global (no viaja con la paleta ni al `.mpalette`) o versionar el esquema (innecesario, campo aditivo).

3. **`PaletteService.setGrayPercent(id, v)`**: acota 0–100, normaliza 0 → null, no-op (sin `_changed()`) si el valor no cambia; a diferencia del resto de mutaciones **no llama `_touch`** (el % es estado de vista, no toca `modifiedAt`) pero sí `_changed()` para notificar y autoguardar (la persistencia ya viene debounceada por `scheduleSave`, así que el arrastre escribe el valor asentado). `create` y `duplicate` no copian el campo (paletas nuevas en 0 %); `import` (`.mpalette`) y `restore` (deshacer) lo conservan tal cual viene de la paleta. Alternativa descartada: manejarlo fuera del servicio en AppController (el campo es de la paleta y el servicio es dueño de sus invariantes).

4. **Presentación mezclada calculada en la UI, sin mutar datos.** El encabezado de `_ActiveHeader` agrega una fila compacta siempre visible: etiqueta "Escala de grises" + `Slider` 0–100 (M3, divisions 100, ≥ 48 dp de objetivo táctil) + texto de % + acción de restablecer (0). `_ActiveColors` muestra swatch y HEX mezclados calculados al vuelo (`ColorMath.mixToGray(pc.color, pct/100)`) mientras que tap/menú/copy/exportar-por-color siguen usando `pc.color`. Alternativas descartadas: mezclar al vuelo dentro de `PaletteService` (contaminaría el modelo de datos con estado de vista), o materializar la vista en el estado (duplicaría la lista y haría difícil el drag/menú sobre ítems reales). Flutter ya reconstruye por `notifyListeners` en cada cambio del %: refrescar ≤ 64 muestras por tick es despreciable.

5. **WYSIWYG transformando el modelo de exportación una sola vez.** A `PaletteExportModel` se le agrega un constructor estático `fromGrayed(Palette p)` que aplica `mixToGray` con el % de la paleta a los colores del modelo (los nombres jamás se transforman); los 4 sitios de exportación de la paleta guardada (imagen, overlay, copiar como, compartir como) lo usan; las paletas generadas siguen usando `from`. `exportPaletteFile` queda tal cual (`.mpalette` entrega originales + `grayPercent` vía `PaletteFile`). Los formatters y renderers no cambian. Alternativas descartadas: pasar el % dentro de `FormatOptions` (mezcla sería responsabilidad del formatter, que es genérico y compartido con generadas) o transformar en cada call site (lógica duplicada).

6. **`reloadInWheel` carga la vista vigente**: al confirmar, mezcla cada color con el % actual de la paleta (`mixToGray`) antes de commit principal y offsets de free points (misma fórmula que desktop `LoadPaletteToFree`), sin modificar la paleta ni su %. A 0 % es identidad exacta. Alternativa descartada: cargar crudos (rompería la expectativa "carga lo que veo").

7. **Textos** en `app_es.arb` / `app_en.arb` + regeneración gen-l10n: título ("Escala de grises" / "Grayscale"), restablecer ("Restablecer" / "Reset"), quizá tooltip/ayuda de qué hace el modo. Sin accesibilidad nueva (el slider Material ya es accesible).

8. **Versión**: `pubspec.yaml` → `version: 1.1.1+11`.

## Risks / Trade-offs

- [Paridad bit a bit con desktop] → port exacto de `LerpByte` (redondeo away-from-zero); los valores intermedios no están en el golden de desktop, así que se suman vectores de pruebas con mezcla 50 % calculada a mano y, si aplica al harness actual, claves `gray-25/50/75` en `tool/golden`.
- [Confusión: HEX visible ≠ HEX guardado con el modo activo] → WYSIWYG consistente en muestras, exportaciones y recarga; acciones por color copian el original (igual que desktop); el texto del modo lo aclara.
- [Mezclas intermedias no son "accesibles"] → son estética de preview; solo 0 % y 100 % garantizan coincidencia con el gris perceptual exacto (aclarado en tooltip).
- [Escrituras de `palettes.json` en cada tick del slider] → `scheduleSave` debouncea (≤ 300 ms): persiste el valor asentado, escritura atómica como siempre.
- [El % queda "pegado" a la paleta y confunde al importar paletas viejas] → archivos sin `grayPercent` abren en 0 % y el slider es siempre visible: nada silencioso sobre los colores.
- [Cambio de paleta activa con sliders desincronizados] → el % se lee de `palettes.active` en cada build: un solo origen, sin estado duplicado en el Controller.

## Migration Plan

Sin migración: campo aditivo opcional con `schemaVersion` v1 intacta, compatible en ambos sentidos (archivos viejos sin campo muestran 0 %; apps viejas ignoran la clave desconocida). Rollback: revertir UI y transformación; los datos persistidos no se pierden ni corrompen. Desktop no cambia (ya tiene el campo).

## Open Questions

Ninguna: ubicación (siempre visible, decisión de usuario), alcance de exportación (WYSIWYG) y persistencia (por paleta, en `palettes.json`/`.mpalette` con `schemaVersion` v1) quedaron resueltos con el usuario; el resto replica el comportamiento ya implementado y validado en desktop.