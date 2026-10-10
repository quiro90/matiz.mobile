## Context

- El motor de Matiz desktop vive en `../matiz/src/Matiz.Core` (C#, ~2.000 líneas sin dependencias de WPF) y tiene ~1.250 líneas de tests xUnit. Flutter no puede ejecutar C#, así que **no se reutiliza el binario: se porta el código**. El proyecto desktop no se modifica; solo se lee y se copian assets (ícono).
- Herramientas disponibles: Flutter 3.47.2 / Dart 3.13.2 (stable), OpenSpec 1.11. No hay git por ahora.
- El objetivo es Google Play. iOS queda "preparado", sin empaquetar (ver proposal.md).
- Restricciones de Android que dan forma al diseño: no se pueden leer píxeles de otras apps sin MediaProjection; el selector de fotos evita permisos de medios; Android 14+ exige tipo para cada servicio en primer plano y consentimiento por sesión de MediaProjection; `targetSdk` 35+ impone borde a borde y 36 el atrás predictivo.

## Goals / Non-Goals

**Goals:**
- Paridad numérica exacta con desktop en todo `matiz_core`, verificada con los tests portados.
- Un flujo táctil de una sola mano en vertical: tomar color → generar → guardar → exportar en tres pestañas.
- Lógica y estado testeables sin Flutter; servicios de plataforma aislados detrás de interfaces.
- Pocas dependencias de terceros, todas mantenidas, sin toolchains extra (Rust, NDK propio).

**Non-Goals:**
- Sincronización en la nube o cuentas; formatos `.ase`/`.gpl`; checker WCAG; slider de alpha; OKHSV; widgets de pantalla de inicio; builds de iOS publicados.
- Captura continua o "en vivo" de pantalla con la burbuja (es instantánea única, como la captura congelada de desktop, ADR-003).
- Tests de UI exhaustivos: solo widget tests de los gestos críticos y golden test de la exportación PNG.

## Decisions

### D1. Estructura: app + paquete Dart puro
```
matiz.android/
  packages/matiz_core/        # Dart puro (sin Flutter): port 1:1 de Matiz.Core + tests
    lib/src/{colors,formatting,parsing,generation,palettes,export,history,session,settings,persistence}/
    test/                     # port de Matiz.Core.Tests (mismos valores esperados)
  lib/
    main.dart, app.dart
    state/                    # ChangeNotifiers (ver D3)
    ui/{create,generate,palettes,settings,export,camera,common}/
    widgets/                  # ColorWheel, BrightnessBar, ImageCanvas, Loupe, SwatchCard…
    platform/                 # interfaces + implementación Android (MethodChannel)
    l10n/                     # app_es.arb, app_en.arb (gen-l10n)
  android/app/src/main/kotlin/…/  # MainActivity, IntentBridge, ClipboardBridge, BubbleService, CaptureActivity
  docs/vault/ · docs/play-store/ · openspec/
```
*Por qué:* separar el núcleo mantiene la paridad testeable con `dart test` (rápido, sin emulador) y deja la lógica lista para iOS. *Alternativa descartada:* compilar el C# con .NET MAUI o con NativeAOT y FFI. Exigiría otro stack de UI o un puente FFI frágil, y suma tamaño.

### D2. Port fiel del Core, con dos trampas conocidas
- **Redondeo:** el `Math.Round(x, MidpointRounding.AwayFromZero)` de C# equivale al `double.round()` de Dart (que redondea alejándose del cero). Se centraliza en un helper `roundAway`.
- **Raíz cúbica:** Dart no tiene `cbrt`. Se implementa como `sign(x)·pow(|x|, 1/3)` más una iteración de Newton, para igualar a `Math.Cbrt` hasta el último bit relevante. La ida y vuelta del HEX la verifican los tests portados.
- **Aleatoriedad del k-means++:** `new Random(1234)` de .NET usa el generador sustractivo de Knuth (`Net5CompatSeedImpl`). Para que la extracción sea idéntica se porta ese algoritmo en Dart (`DotNetRandom`, ~40 líneas) con un test de las primeras salidas para la semilla 1234. Los valores de referencia se obtienen una sola vez ejecutando .NET en la máquina del autor.
- La persistencia del Core (`JsonStore`) se porta con `dart:io` (archivo temporal + `rename` atómico + `.bak`), con guardado diferido de 300 ms y un `flush()` explícito que se llama al pasar a `AppLifecycleState.paused`.

### D3. Estado: `provider` + `ChangeNotifier`, uno por área
`SessionController` (color actual, anterior, deshacer/rehacer; envuelve `ColorSession`), `GenerationController` (modo, armonía, prefijo, equilibrar), `FreePointsController`, `ImageController` (imagen decodificada, zoom/pan, extracción en un `Isolate`), `PalettesController` (`PaletteService` + autoguardado), `HistoryController` y `SettingsController` (tema, idioma, formatos y burbuja). Se reparte igual que las clases parciales de `MainViewModel` en desktop, lo que facilita portar el comportamiento. Para el rendimiento, los widgets escuchan con `Selector`/`context.select`, de modo que un arrastre redibuje solo la rueda, la barra y las tarjetas visibles.
*Alternativas:* Riverpod o Bloc. Son más potentes, pero agregan ceremonia y no aportan para una app de un usuario sin red. Si algún día hiciera falta, la migración no toca `matiz_core`.

### D4. Rueda y brillo con `CustomPainter` y bitmap en caché
La rueda se rasteriza una vez a un `ui.Image` con `decodeImageFromPixels`, por píxel físico, según el tamaño, el `devicePixelRatio` y el γ del enfoque. Se cachea y se pinta con `drawImage`. El marcador, los puntos y las líneas se dibujan en un `CustomPainter` aparte, encima. El brillo es un `LinearGradient`, sin bitmap.

**Gestos:** se usa un `Listener` propio con una máquina de estados `idle → pending → dragging | longPressed` (umbral de 8 dp y 500 ms), en lugar de `GestureDetector`. Así se controla exactamente que tocar y soltar confirme el color, que arrastrar lo mueva en vivo y lo confirme al soltar, que mantener pulsado añada un secundario (con háptica) sin mover el principal y que el doble toque sobre un punto lo quite. Un `GestureDetector` estándar tiene ambigüedades de arena entre tap, doble tap y long press: retrasa el tap unos 300 ms para esperar el doble tap. Aquí el doble toque solo se evalúa cuando el toque cae sobre un punto secundario, así que el tap normal no se retrasa.

### D5. Imagen: decodificación con píxeles exactos y lupa táctil
- **Decodificación:** el códec de la plataforma (`instantiateImageCodec`) para mostrar, y `toByteData(rawRgba)` para tener el búfer RGBA original del que se leen los píxeles exactos. Por encima de 24 MP se pide el codec con `targetWidth` y se documenta.
- **Vista:** el visor es un `CustomPainter` con una matriz de zoom/pan propia (no `InteractiveViewer`, porque hay que repartir los gestos de un dedo y de dos).
  - **Un puntero:** máquina de estados de la lupa, igual que en la rueda.
  - **Dos punteros:** zoom/pan, y se cancela la lupa.
  - **Doble toque:** alterna entre ajustar a la pantalla y 4×.
- **Lupa:** un `CustomPainter` con `FilterQuality.none` que muestra 11×11 píxeles del búfer original. Se coloca 96 dp por encima del dedo, o al costado o debajo cerca de los bordes.
- **Extracción:** se hace en `Isolate.run` pasando el búfer como `TransferableTypedData`.

### D6. Servicios de plataforma propios con un solo `MethodChannel`
Se usa un canal `matiz/platform` en Kotlin para:
- (a) los intents entrantes `ACTION_SEND` y `ACTION_VIEW`, con arranque en frío (intent inicial) y en caliente (`onNewIntent` → `EventChannel`);
- (b) leer imágenes del portapapeles (`ClipboardManager` → URI → bytes);
- (c) guardar en la galería con `MediaStore` (álbum `Pictures/Matiz`, sin permisos en API 29+);
- (d) la burbuja.

*Por qué no usar paquetes:* `receive_sharing_intent` y `share_handler` no resuelven bien `.mpalette` con MIME `application/octet-stream` ni los `content://` de "Abrir con"; `super_clipboard` exige Rust (cargokit); y la burbuja no tiene un paquete confiable. Como igual se necesita Kotlin para la burbuja, centralizar todo en un canal reduce dependencias.

Paquetes que sí se usan, por ser estándar y mantenidos:
- `image_picker` (selector de fotos del sistema);
- `file_picker` (abrir y guardar archivos `.mpalette`/PNG con SAF);
- `share_plus` (compartir archivos y texto);
- `camera`;
- `url_launcher`;
- `path_provider`;
- `provider`;
- `flutter_localizations` e `intl`.

En Dart cada servicio es una interfaz (`IncomingContentService`, `ClipboardImageService`, `GallerySaver`, `BubbleService`) con su implementación Android. En otras plataformas se usa una implementación "no disponible" que oculta la función.

**Intent filters:** `SEND` con `image/*`; `SEND` y `VIEW` con `application/octet-stream`, `application/json` y `*/*`. En los dos últimos, la ruta se filtra por `.mpalette` cuando el esquema es `file`/`content` con `pathPattern`. Como muchos orígenes no la informan, el contenido se valida en Dart (spec `share-intake`). `MainActivity` es `singleTask` para no duplicar instancias.

### D7. Cámara: flujo de la librería `camera` y muestreo YUV
Se usa `startImageStream` a resolución media, limitado a unas 15 lecturas por segundo. Se convierten de YUV420 a RGB (BT.601 full-range) solo los 5×5 píxeles alrededor de la retícula. "Congelar" usa `takePicture()` y carga ese JPEG en `ImageController`. Se respeta el ciclo de vida: `dispose` en `inactive` y reinicialización en `resumed`.
*Alternativa:* procesar la vista previa en la GPU. Es innecesario para leer 25 píxeles.

### D8. Burbuja: servicio nativo y captura de un solo fotograma
- `BubbleService`, en Kotlin, es un servicio en primer plano de tipo `specialUse` con la propiedad `PROPERTY_SPECIAL_USE_FGS_SUBTYPE="floating color picker bubble"`, una notificación persistente con "Detener" y una vista `TYPE_APPLICATION_OVERLAY` arrastrable y acoplable al borde.
- **Al tocar la burbuja** se lanza `CaptureActivity`, una actividad transparente con `excludeFromRecents` que pide `MediaProjectionManager.createScreenCaptureIntent()`.
- **Con el consentimiento:**
  1. el servicio pasa a `startForeground(…, MEDIA_PROJECTION | SPECIAL_USE)`;
  2. se oculta la burbuja;
  3. se crea un `VirtualDisplay` con un `ImageReader` (RGBA_8888, a la resolución real) y se toma el primer `Image`;
  4. se hace `projection.stop()` y el servicio vuelve al tipo `specialUse`;
  5. se escribe un PNG en la caché y se abre `MainActivity` con un extra (`matiz.capture=<ruta>`), que el canal entrega como imagen entrante.

*Por qué un solo fotograma:* respeta la privacidad, evita el indicador permanente de "compartiendo pantalla" y simplifica la revisión en Play (sigue la idea de la captura congelada de desktop, ADR-003). *Alternativa descartada:* elegir el color sobre el overlay sin abrir la app. Duplicaría en Kotlin toda la lupa y el modo Imagen.

### D9. Navegación y layout
`NavigationBar` de Material 3 con 3 destinos dentro de un `IndexedStack`, para conservar el estado de cada pestaña. `PopScope` implementa la prioridad del gesto Atrás de `app-shell`. Por encima de 600 dp, `Crear` usa un `Row` con el selector y el panel lado a lado.

El tema es `ColorScheme` construido a mano en grises neutros. No se usa `dynamic_color`: el color es el protagonista, como establece el ADR-007 de desktop.

Prioridades del espacio vertical de **Crear** en 360×640 dp:

| Zona | Altura |
|---|---|
| Barra superior | 56 |
| Acciones de entrada y conmutador | 48 |
| Rueda + brillo | lo que sobre, mínimo 220 |
| Anterior/Actual | 56 |
| Recientes | 44 |
| Vista previa del modo | 56 |
| Barra de navegación | 64–80 |

### D10. Idioma y ajustes
Se usa `gen-l10n` con ARB y claves equivalentes a las de desktop (`Strings.resx`). Las traducciones se copian y adaptan donde aplica. Se declara `android:localeConfig` (es, en) y se sincroniza con `AppCompatDelegate.setApplicationLocales` a través del canal, para que la elección de la app y la del sistema coincidan.

`settings.json` móvil: `theme`, `language` (`system|es|en`), `defaultFormatId`, `hexUppercase`, `hexHash`, `copyOnPick`, `wheelFocus`, `scaleAnchor`, `scalePrefix`, `harmonyBalanceLightness`, `generationMode`, `harmonyType`, `extractCount`, `bubbleEnabled`, `bubblePosition`, `lastColor`, `lastHue`, `activePaletteId`. Las claves exclusivas de desktop no se escriben.

### D11. Exportación PNG
Las imágenes se generan con `PictureRecorder` y `Canvas`, con la misma geometría que `PaletteImageRenderer` y `OverlayImageRenderer` de desktop. Los bloques se dibujan con `isAntiAlias=false` para que el centro tenga el color exacto (golden test de píxeles). Se codifican con `toByteData(png)`.

### D12. Empaquetado
- `applicationId`: `com.juanquiroga.matiz` (confirmable antes del primer envío, porque después es inmutable).
- `minSdk` 29 y `targetSdk`/`compileSdk` 36, con R8 y reglas `proguard` para los plugins.
- Firma: `android/key.properties` (local, sin versionar) y `upload-keystore.jks` fuera del proyecto. Se usa Play App Signing.
- Íconos: `flutter_launcher_icons` (solo en desarrollo) a partir de `matiz.png` de desktop, con capa monocromática.
- Scripts `tool/build_release.ps1` (AAB) y `tool/build_apk.ps1`.
- La bandera `--dart-define=DONATIONS=false` oculta las donaciones como plan B.

## Risks / Trade-offs

- **[Rechazo en Play por enlaces de donación externos]:** la política de pagos permite enlaces a donaciones solo en casos acotados. → Se mantienen por decisión del autor; la bandera `DONATIONS=false` permite reenviar sin ellos en minutos. Queda documentado en `docs/play-store/`.
- **[Revisión del servicio `specialUse` y de MediaProjection]:** Play exige justificación y video, y puede pedir cambios. → La burbuja va en la última fase y es opcional (desactivada por defecto). Si la rechazan, se publica sin ella desactivando el módulo, sin afectar al resto.
- **[Paridad numérica en casos límite (`cbrt`, `pow`)]:** → Se portan los tests de desktop más un test de "tabla dorada" con unos 2.000 colores aleatorios cuyos resultados se generan una sola vez en .NET y se guardan como fixture JSON.
- **[Colores de la cámara poco fiables]:** el balance de blancos y la exposición alteran el color. → Se avisa en la UI y se ofrece "Congelar" para elegir con lupa. No se promete exactitud.
- **[Fabricantes que matan servicios]** (MIUI, ColorOS, etc.). → Notificación persistente y guía en la ayuda de la burbuja. La burbuja no es crítica para el flujo principal (compartir una captura cubre el caso).
- **[`.mpalette` sin MIME]:** algunos gestores no ofrecen Matiz en "Abrir con". → Se usan filtros amplios y validación por contenido, y "Importar" dentro de la app siempre funciona.
- **[Rendimiento de la rueda en gama baja]:** → Bitmap en caché, repintado solo de la capa de marcadores y `RepaintBoundary` por zona. Se mide con el perfil de Flutter en un dispositivo real (tarea de verificación).

## Migration Plan

Proyecto nuevo, sin migración de datos del teléfono. La compatibilidad con desktop es por archivo (`.mpalette`). La publicación sigue este orden:
1. pruebas internas;
2. pruebas cerradas con 12 testers durante 14 días, requisito vigente para cuentas personales nuevas de Play;
3. producción.

Si una versión falla, se sube otra con `versionCode` mayor (Play no permite volver atrás un bundle).

## Open Questions

- `applicationId` definitivo (propuesto `com.juanquiroga.matiz`): se confirma antes del primer envío, no cambia el diseño.
- URL de alojamiento de la política de privacidad (GitHub Pages o la web del autor).
- Si la cuenta de Play del autor es personal u organización: define si se aplica el requisito de 12 testers durante 14 días.

## Implementation Notes (2026-10-09)

Ajustes respecto del diseño original, decididos durante la implementación (no cambian las specs):

- **D3 → un solo `AppController`** (ChangeNotifier) con secciones por área (color, generadas, Personalizado, paletas, imagen, ajustes) en lugar de varios controladores: las áreas dependen mucho entre sí (Personalizado ↔ color actual ↔ imagen) y así se refleja 1:1 el `MainViewModel` de desktop. La lógica testeable vive en `matiz_core` (`FreePointSet`, `PaletteService`, `ColorSession`).
- **D4 → la rueda no usa bitmap**: con V = 1, HSV es interpolación lineal en sRGB, así que se dibuja exacta con un `SweepGradient` (primarios) + `RadialGradient` blanco con α = 1 − r^γ en GPU. Cambiar el enfoque no regenera nada y no hay coste de rasterizado.
- **D6**: `file_picker` 13 usa API estática (`FilePicker.pickFiles` / `FilePicker.saveFile`, devuelve `Uri`).
- **D8**: en Android 14+ el consentimiento se pide con `MediaProjectionConfig.createConfigForDefaultDisplay()` (pantalla completa por defecto). La burbuja se oculta mientras Matiz está en primer plano.
- **Paridad verificada**: `tool/golden` (.NET) compila `Matiz.Core` leyendo `../matiz` sin escribir allí; `golden_parity_test.dart` compara 2.000 colores, extracción k-means (con `DotNetRandom`) y exportación de código: coincidencia exacta.
- **Toolchain**: la plantilla de Flutter 3.47 con AGP 9 (`builtInKotlin=false`) omitía el plugin de Kotlin en `app/`; se agregó `org.jetbrains.kotlin.android`.
