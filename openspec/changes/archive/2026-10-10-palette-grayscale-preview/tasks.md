## 1. Core: mezcla hacia gris (matiz_core)

- [x] 1.1 Implementar `ColorMath.mixToGray(Argb c, double amount)` en `packages/matiz_core/lib/src/colors/color_math.dart`: clamp 0–1, identidad si ≤ 0, `grayEquivalent` si ≥ 1, lerp por canal RGB con redondeo away-from-zero (paridad con `ColorMath.MixToGray` de desktop) conservando el alfa. Verificar con `cd packages/matiz_core && dart test test/color_model_test.dart`.
- [x] 1.2 Tests de mezcla en `packages/matiz_core/test/`: a 0 % identidad exacta, a 100 % bit a bit con `grayEquivalent`, a 50 % vector calculado a mano (p. ej. `#5246BC` con gris conocido), alfa no opaco conservado, NaN/amount fuera de rango seguros. Verificar con `dart test`. → Cobertura real: propiedades semánticas (`palette_gray_test.dart`) + paridad byte a byte contra desktop C# vía vectores `grayMix25/50/57/100` en el dorado de 2000 colores (`tool/golden`, `golden_parity_test.dart`).

## 2. Core: persistencia del porcentaje

- [x] 2.1 `Palette.grayPercent` (int?, null = 0) en `packages/matiz_core/lib/src/palettes/palette.dart`: `toJson` omite la clave si es null; `fromJson` lee tolerante con clamp 0–100 (inválido → null). Tests de ida y vuelta: paleta sin campo → 0 %; con `grayPercent: 57` → 57; campo inválido → 0 %.
- [x] 2.2 `PaletteFile`: mapear `grayPercent` en `from`/`toPalette`/`toJson`/`decode` (omitido si null; clamp al leer; `schemaVersion` sin cambios). Tests: encode con 57 produce `"grayPercent": 57` y hex originales sin mezclar; decode de archivo sin campo → 0 %; ida y vuelta desktop↔móvil con el ejemplo real de `.mpalette`. Verificar con `dart test`.
- [x] 2.3 `PaletteService.setGrayPercent(String id, int value)`: acota 0–100, normaliza 0 → null, no-op sin `_changed()` si no cambia; NO llama `_touch` (`modifiedAt` intacto). `create`/`duplicate` no copian el campo; `import` y `restore` lo conservan. Tests: 150 → 100; 0 → null y fecha sin alterar; duplicar paleta con 57 % → copia en 0 %; importar conserva 57 %. Verificar con `dart test`.

## 3. Core: WYSIWYG en exportación

- [x] 3.1 Agregar `PaletteExportModel.fromGrayed(Palette p)` en `packages/matiz_core/lib/src/export/palette_formatters.dart`: colores con `mixToGray(c.color, (p.grayPercent ?? 0)/100)`, nombres sin transformar; `from` queda intacto para generadas. Tests: paleta con 57 % exportada como CSS/JSON contiene los HEX mezclados; a 0 % salida idéntica a `from`; generadas sin % no cambian. Verificar con `dart test`.

## 4. Estado de app (AppController)

- [x] 4.1 Exponer `setGrayPercent(String paletteId, int value)` (delega al servicio y notifica) y usar la paleta activa como única fuente del % en la UI. Verificar: mover el % persiste en `palettes.json` (escribiéndose por `scheduleSave`) reconstruyendo AppController en un test de estado.
- [x] 4.2 WYSIWYG en los caminos de la paleta guardada: `copyPaletteAs`, `paletteAsText` y la construcción del `PaletteExportModel` para `ExportImagePage` (imagen/overlay) pasan a usar `fromGrayed`; `exportPaletteFile` queda entregando originales + `grayPercent`. Verificar con test de estado: copiar como CSS con 100 % entrega el gris equivalente, y `exportPaletteFile` conserva hex originales + `grayPercent`.
- [x] 4.3 `reloadInWheel` mezcla cada color con el % vigente de la paleta antes de commit/free points (a 0 % identidad) sin alterar la paleta. Verificar con test de estado: primer color commiteado con 80 % es el gris-equivalente mezclado.

## 5. UI pestaña Paletas

- [x] 5.1 Fila del modo en `_ActiveHeader` (`lib/ui/palettes_page.dart`): etiqueta "Escala de grises", `Slider` 0–100 (divisions 100, objetivo táctil ≥ 48 dp) deshabilitado si la paleta no tiene colores, % visible (p. ej. `57 %`) y acción de restablecer a 0. Strings nuevos en `app_es.arb`/`app_en.arb` + `flutter gen-l10n`. Verificar con `flutter analyze` y arrastre manual: muestras y HEX se mezclan en vivo y a 0 % vuelven al original. → `flutter analyze` limpio + test de interfaz que arrastra el slider (`test/palette_gray_state_test.dart`).
- [x] 5.2 Muestras mezcladas en `_ActiveColors`: swatch y texto HEX calculados con el % de la paleta activa; tap/menú/copiado operan sobre `pc.color` original. Verificar: con 100 % el HEX visible es el gris, pero "copiar" entrega el HEX original.
- [x] 5.3 Restauraciones automáticas: cambio de paleta marcada, importar `.mpalette` (con y sin `grayPercent`), crear/duplicar y reabrir la app muestran el % correcto (slider + muestras). Verificar en dispositivo/emulador: paleta con 60 % → marcar otra → volver → 60 % visible; reiniciar la app con 80 % arranca en 80 %. → Validado en motorola edge 50 ultra (Android 16) el 2026-10-10, build release 1.1.1+11.

## 6. Versión y cierre

- [x] 6.1 Bump de versión en `pubspec.yaml` → `version: 1.1.1+11`. Verificar con `flutter analyze` limpio.
- [x] 6.2 Suite completa: `cd packages/matiz_core && dart test` y `flutter test` en la raíz; build de verificación `flutter build apk --debug` para validar integración. Comparar resultados con main como línea base. → matiz_core 189/189, raíz 14/14, APK debug OK.
- [x] 6.3 `openspec validate palette-grayscale-preview --strict` sin errores (specs, scenarios con valores concretos coherentes).