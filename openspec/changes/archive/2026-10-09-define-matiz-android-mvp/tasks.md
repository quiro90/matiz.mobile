## 1. Fase 0 — Esqueleto del proyecto (entregable: app vacía que compila y corre)

- [x] 1.1 Crear el proyecto Flutter en la raíz (`flutter create --org com.juanquiroga --project-name matiz --platforms android,ios .`) y verificar que `flutter run` abre la app de ejemplo en un emulador o dispositivo
- [x] 1.2 Crear `packages/matiz_core` (paquete Dart puro con `package:test`), referenciarlo por `path` desde la app y verificar que `dart test` corre en el paquete y `flutter analyze` no da errores
- [x] 1.3 Configurar `analysis_options.yaml` (lints estrictos), `.gitignore` (incluye `key.properties`, `*.jks`) y `README.md` mínimo; verificar con `flutter analyze` sin advertencias
- [x] 1.4 Configurar Android: `minSdk 29`, `targetSdk/compileSdk 36`, `applicationId com.juanquiroga.matiz`, `MainActivity` `singleTask`, borde a borde y `enableOnBackInvokedCallback`; verificar con `flutter build apk --debug` y que la app abre con las barras del sistema transparentes
- [x] 1.5 Configurar gen-l10n (`l10n.yaml`, `app_es.arb`, `app_en.arb`) con unas claves de prueba y `localeConfig`; verificar que cambiando el idioma del emulador el texto cambia

## 2. Fase 1 — `matiz_core`: port 1:1 con paridad (entregable: núcleo verificado con `dart test`)

- [x] 2.1 Portar `Colors/` (Argb, ColorMath con `roundAway` y `cbrt` exacto, ColorSpaces, ColorState, WheelMapping) y los tests de `ColorModelTests`; verificar que `dart test test/color_model_test.dart` pasa con los mismos valores esperados (`#5246BC` → HSL `246°, 47%, 51%`, etc.)
- [x] 2.2 Portar `Parsing/ColorParser` y `Formatting/` (ColorFormats, ColorFormatters) con `ParsingAndFormattingTests`; verificar que pasan (`#5AC` → `#55AACC`, `rgb(300,0,0)` inválido, `Color(0xFF5246BC)`)
- [x] 2.3 Implementar `DotNetRandom` (generador sustractivo de .NET con semilla) y verificar con un test que sus primeras 10 salidas para la semilla 1234 coinciden con los valores obtenidos en .NET
- [x] 2.4 Portar `Generation/` (DesignScale, PaletteGenerator, DominantColors) y `GenerationTests`; verificar que pasan (escala de `#5246BC` con 500 exacto, Tint 50% `#A9A3DE`, Shade 50% `#29235E`, triádica 6.1°/126.1°)
- [x] 2.5 Portar la lógica de puntos libres (desfases, seguimiento rígido, promoción del principal, "+" al lado del último, conversión desde armonía) y `FreePointsTests`; verificar que pasan
- [x] 2.6 Portar `Palettes/` (Palette, PaletteService con límite de 64, PaletteFile `.mpalette`) y `PaletteFileTests`; verificar que pasan, incluido el rechazo de `schemaVersion` futura y el sufijo " 2"
- [x] 2.7 Portar `Export/PaletteFormatters`, `History/ColorHistory` y `Session/ColorSession` (deshacer 50) con `SessionPaletteExportTests`; verificar que pasan (CSS `--primary: #5246BC;`, identificadores sin tildes, colisiones `primary-2`)
- [x] 2.8 Portar `Persistence/` (JsonStore atómico con `.bak`, diferido 300 ms, `flush()`, recuperación `*.corrupt-<fecha>.json`, migración v0→v1) y `Settings/` (esquema móvil) con `PersistenceTests`; verificar que pasan en un directorio temporal
- [x] 2.9 Crear el test de "tabla dorada": generar en .NET (script en `tool/golden/` que use `../matiz` solo para leer, sin modificarlo) un JSON con unos 2.000 colores y sus conversiones, escala, armonías y extracción de 2 PNG de muestra; verificar que `dart test test/golden_parity_test.dart` coincide al 100%
- [x] 2.10 Verificar que un `.mpalette` exportado por desktop (fixture copiado) se importa idéntico y que uno exportado por `matiz_core` se valida contra el esquema de desktop (test de ida y vuelta)

## 3. Fase 2 — Crear: rueda y color actual (entregable: elegir, ajustar y copiar un color)

- [x] 3.1 Implementar el tema neutro claro/oscuro (`ColorScheme` a mano) y el shell: `NavigationBar` con Crear/Generar/Paletas en un `IndexedStack`, barra superior (deshacer, rehacer, tema, ajustes) y `PopScope` con la prioridad de Atrás; verificar a mano los escenarios de `app-shell` "Estado conservado" y "Atrás desde Paletas"
- [x] 3.2 Implementar `SessionController`, `SettingsController` y `HistoryController` sobre `matiz_core` con autoguardado y `flush` al pasar a segundo plano; verificar con tests unitarios de los controladores (deshacer de un arrastre = 1 paso; los arrastres no ensucian el historial)
- [x] 3.3 Implementar `ColorWheel`: bitmap en caché por tamaño, DPR y γ, capa de marcador/puntos, y máquina de gestos tap/arrastre/mantener (8 dp/500 ms) con muestra visible sobre el dedo; verificar con widget tests (tap en el borde a 120° → `#00FF00`; mantener 600 ms no cambia el color) y con el perfil de Flutter (sin regenerar el bitmap durante el arrastre)
- [x] 3.4 Implementar `BrightnessBar` vertical (≥ 48 dp) con el degradado del color actual; verificar que `#5246BC` → brillo 37% da `#29235E`
- [x] 3.5 Implementar la barra compacta Anterior | Actual con "Copiar" y "Añadir a paleta" y la fila de Recientes; verificar los escenarios "Comparar tras arrastre" y "Volver al anterior"
- [x] 3.6 Implementar la hoja de detalle del color: campo de texto con el parser y "Pegar", R/G/B, H/S/B con −/+ que repiten, enfoque, "Gris equivalente", formatos con copiar, "Más formatos", "Copiar todo", Recientes y vaciar historial; verificar los escenarios de `current-color`, `color-clipboard` y `visual-picker` (`256` inválido, "Copiar todo" exacto)
- [x] 3.7 Restaurar el último color y la posición del selector al iniciar; verificar cerrando la app desde Recientes y reabriéndola con `#5246BC`

## 4. Fase 3 — Generar y Personalizado (entregable: armar paletas desde la rueda)

- [x] 4.1 Implementar `GenerationController` y la pestaña Generar: chips de modos y de armonías, grilla de tarjetas (3 columnas en 360 dp) con Copiar/Añadir siempre visibles, tocar = usar como principal, menú al mantener pulsado; verificar "Usar un color generado" y "Menú contextual"
- [x] 4.2 Implementar la rueda compacta en Armonías/Personalizado y la barra Anterior | Actual en el resto de los modos; verificar "Rueda compacta en Armonías" (Triádica con 2 puntos y líneas)
- [x] 4.3 Implementar puntos de armonía en la rueda: tocar = seleccionar y "Copiar" en el aviso, arrastrar = pasar a Personalizado, doble toque = pasar a Personalizado sin el punto, prioridad del marcador principal; verificar con widget tests los escenarios de `palette-generation`
- [x] 4.4 Implementar `FreePointsController` y Personalizado: mantener pulsado en la rueda añade un punto (háptica y aviso "Ver"), "+", "Borrar" con confirmación, "−" siempre visible, promoción del principal, límite 64 y "Equilibrar"; verificar los escenarios de `free-points`
- [x] 4.5 Implementar el prefijo, "Añadir todo" (límite de 64 en lote) y "Copiar como" (CSS/JSON/Dart/C#/Tailwind/HEX); verificar que "Añadir todo" con "Primary" crea `Primary 50`…`Primary 950`
- [x] 4.6 Implementar la tira de vista previa del modo en Crear con salto a Generar; verificar "Ver lo que se está armando"
- [x] 4.7 Persistir modo, armonía, prefijo y equilibrar entre sesiones; verificar reabriendo la app

## 5. Fase 4 — Paletas y `.mpalette` (entregable: guardar, organizar e intercambiar con desktop)

- [x] 5.1 Implementar `PalettesController` con autoguardado y la pestaña Paletas: paleta activa (nombre y descripción editables, grilla, tocar = usar, menú) y biblioteca con vista previa que envuelve; verificar "Primera vez" y "Biblioteca vacía"
- [x] 5.2 Implementar reordenar por arrastre táctil (levantar, hueco, soltar al final; mantener sin mover = menú); verificar que el orden persiste tras reiniciar
- [x] 5.3 Implementar Nueva, Duplicar, Eliminar con "Deshacer", Renombrar, Reemplazar con actual y Mover; verificar "Eliminar con deshacer"
- [x] 5.4 Implementar "Recargar en la rueda" con confirmación; verificar "Carga completa en Personalizado" con `#5246BC`, `#E24347`, `#F7F9FB`
- [ ] 5.5 Implementar Exportar `.mpalette` (Guardar en… con `file_picker` y Compartir con `share_plus`) e Importar (selector de archivos); verificar la ida y vuelta real con Matiz desktop (exportar en el teléfono, importar en Windows y viceversa)
- [x] 5.6 Implementar "Copiar como" y "Compartir como texto" de la paleta; verificar que el CSS de "Primary/Secondary" es exacto

## 6. Fase 5 — Imagen, pegar y compartir (entregable: captura → Compartir → colores)

- [x] 6.1 Implementar `ImageController`: cargar con `image_picker` (selector de fotos, sin permisos), decodificar, conservar el búfer RGBA original y aplicar el límite de 24 MP; verificar que la app no solicita permisos de medios (`adb shell dumpsys package com.juanquiroga.matiz`)
- [x] 6.2 Implementar `ImageCanvas` con la matriz zoom/pan, pinza con dos dedos, doble toque 1×↔4× y lupa táctil desplazada (11×11, `FilterQuality.none`); verificar "Píxel exacto" con una imagen de prueba de colores conocidos y "Pinza no cambia el color"
- [x] 6.3 Implementar el conmutador Rueda | Imagen, "Cerrar imagen" y Atrás desde Imagen → Rueda conservando zoom, extraídos y Personalizado; verificar "Ida y vuelta sin pérdida"
- [x] 6.4 Implementar la extracción en `Isolate` con la cantidad 1–64 (−/+), "Extraer de nuevo", modo "De la imagen" y "Personalizar" con confirmación; verificar el determinismo y que una imagen de 4000×3000 no bloquea la UI
- [x] 6.5 Implementar el canal Kotlin `matiz/platform` con intents entrantes (`SEND` `image/*`, `SEND`/`VIEW` de `.mpalette` validados por contenido, arranque en frío y en caliente, sin reprocesar al rotar); verificar "Compartir una captura con la app cerrada", "Compartir con la app abierta" y "Abrir un adjunto"
- [ ] 6.6 Implementar "Pegar imagen" (`ClipboardManager` → URI → bytes) y "Pegar" inteligente en Crear (imagen → modo Imagen; texto parseable → color); verificar copiando una imagen desde el navegador y pegándola
- [x] 6.7 Implementar "Copiar al tomar color" (ajuste, desactivado por defecto) aplicado a imagen, cámara y burbuja; verificar con el ajuste activo que el portapapeles recibe el formato principal

## 7. Fase 6 — Exportación de imágenes (entregable: PNG para guardar o compartir)

- [x] 7.1 Portar el renderizado de paleta PNG (horizontal/vertical, 1×/2×/3×, fondo claro/oscuro/transparente, HSL/CMYK opcionales) con `PictureRecorder`; verificar con un test de píxeles que el centro de cada bloque es exacto y que 2× duplica las dimensiones
- [x] 7.2 Portar el renderizado de superpuestos (cuadrado/círculo/triángulo, orden, anillos visibles con 64 colores); verificar con tests de 1, 8 y 64 colores
- [x] 7.3 Implementar la pantalla de vista previa con "Guardar en…", "Guardar en Galería" (`MediaStore`, álbum Matiz, sin permisos) y "Compartir", también desde la dupla Anterior/Actual; verificar que el PNG aparece en la galería y se comparte por mensajería

## 8. Fase 7 — Cámara en vivo (entregable: tomar colores del mundo real)

- [x] 8.1 Implementar la vista de cámara con permiso en contexto (explicación previa, denegado → "Abrir ajustes"), retícula movible por toque y muestra en vivo (5×5 YUV→RGB, ~15/s); verificar "Primer uso" y "Permiso denegado"
- [x] 8.2 Implementar "Usar", "+ Secundario" (la cámara sigue abierta) y "Congelar" (abre el fotograma en modo Imagen), con aviso de luz y balance de blancos; verificar "Tomar varios secundarios" y "Congelar fotograma"
- [x] 8.3 Liberar y reanudar la cámara según el ciclo de vida; verificar que el indicador de cámara del sistema se apaga al cambiar de app

## 9. Fase 8 — Ajustes, idioma y pulido (entregable: app completa en es/en, claro/oscuro)

- [x] 9.1 Completar la pantalla Ajustes (idioma, tema, formato principal, opciones de HEX, copiar al tomar, ancla de la escala, créditos con Instagram, Cafecito/PayPal con la bandera `DONATIONS`, privacidad y licencias); verificar que cada ajuste persiste y que `--dart-define=DONATIONS=false` oculta la sección
- [x] 9.2 Traducir todos los textos (es/en) partiendo de `Strings.resx`/`Strings.es.resx` de desktop e integrar `setApplicationLocales`; verificar con un test que ambas ARB tienen las mismas claves y revisando a mano cada pantalla en los dos idiomas
- [ ] 9.3 Pasar la accesibilidad: descripciones de TalkBack en los botones con ícono, áreas ≥ 48 dp, texto al 130% en 360×640 dp; verificar con el Accessibility Scanner y los escenarios "Pantalla pequeña" y "TalkBack"
- [ ] 9.4 Implementar el layout de dos columnas para anchos ≥ 600 dp; verificar en un emulador de tablet y en horizontal
- [ ] 9.5 Medir el rendimiento en un dispositivo de gama media (arranque < 2 s, arrastre sin saltos); verificar con `flutter run --profile` y DevTools

## 10. Fase 9 — Burbuja flotante (entregable: capturar colores de otras apps)

- [x] 10.1 Implementar `BubbleService` (servicio en primer plano `specialUse`, notificación con "Detener", overlay arrastrable con acople y zona "✕", posición recordada) y el ajuste con permisos en orden (superposición y notificaciones); verificar "Activar la burbuja", "Permiso de superposición denegado" y "Descartar arrastrando"
- [x] 10.2 Implementar `CaptureActivity` y la captura de un solo fotograma (consentimiento, cambio a `MEDIA_PROJECTION`, ocultar la burbuja, `ImageReader`, `stop()`, PNG en caché, abrir Matiz en modo Imagen); verificar "Capturar un color de otra app" (la burbuja no aparece en la instantánea) y "Cancelar el consentimiento"
- [x] 10.3 Implementar la ayuda "¿Cómo funciona?" con las limitaciones y ocultar la burbuja en plataformas sin el servicio; verificar "Consultar la ayuda"

## 11. Fase 10 — Empaquetado y Google Play (entregable: AAB firmado y material de la ficha)

> Diferida por decisión del autor (2026-10-09): la prioridad es que la app compile y sea usable; la publicación en Play se retoma más adelante.

- [x] 11.1 Generar los íconos adaptativos (con capa monocromática) y la pantalla de inicio a partir de `../matiz/src/Matiz.App/Assets/matiz.png` (copiado); verificar el ícono temático en Android 13+
- [ ] 11.2 Configurar la firma (`key.properties` local, fallo claro si falta), R8 y reglas de los plugins, y los scripts `tool/build_release.ps1` y `tool/build_apk.ps1`; verificar que se genera `app-release.aab` y que el APK de release funciona completo (sin clases eliminadas por R8)
- [x] 11.3 Verificar el manifiesto combinado: solo los permisos de `app-packaging`, la cámara opcional y los tipos de servicio en primer plano declarados (`aapt2 dump badging` y `bundletool`)
- [ ] 11.4 Redactar `docs/play-store/` (descripciones es/en, notas de versión, capturas guía, formulario de seguridad de datos, justificación y guion del video de los servicios en primer plano, clasificación de contenido, política de privacidad, riesgo y plan B de donaciones); verificar cada respuesta contra el manifiesto real
- [ ] 11.5 Subir a la pista de pruebas internas y revisar el informe previo al lanzamiento; verificar que no hay errores de API, de 16 KB ni de permisos

## 12. Documentación (entregable: vault y README del proyecto móvil)

- [x] 12.1 Crear `docs/vault/` con la misma estructura que el de desktop (Inicio, Producto, Funcionalidades, Flujos, Arquitectura, Modelo de color, Decisiones/ADR, Referencias, Desarrollo), adaptado a móvil: gestos, pestañas, compartir, cámara, burbuja, canal de plataforma y paridad; verificar que todos los enlaces `[[...]]` resuelven a una nota existente
- [x] 12.2 Escribir `README.md` (en) y `README.es.md` (compilar, ejecutar, tests, release, estructura) y `docs/vault/08 Desarrollo/OpenSpec.md`; verificar siguiendo el README desde cero en una terminal limpia
- [ ] 12.3 Validar y archivar el cambio: `openspec validate --specs --strict` sin errores y `/opsx:archive` para sincronizar las specs vigentes
