## Why

Matiz desktop (Windows/WPF) resuelve el flujo "veo un color → lo capturo → lo analizo → genero una paleta → copio / guardo → exporto", pero ese flujo también ocurre en el teléfono: capturas de pantalla, fotos, referencias de Instagram o Pinterest. Hoy no existe una versión móvil y la UI de escritorio (clic derecho, hover, atajos, paneles anchos) no se traslada a una pantalla táctil chica. Se necesita una app Android **independiente** (proyecto aparte, sin tocar `../matiz`), con el mismo motor de color y los mismos formatos de archivo, pero con flujos repensados para el uso táctil y lista para publicarse en Google Play.

## What Changes

- Nueva app **Flutter** (Android primero, código preparado para iOS) en este directorio, con un paquete Dart puro `packages/matiz_core` que porta 1:1 la lógica de `Matiz.Core`: modelo de color, conversiones, OKLCH, parser, formatos, Design Scale, armonías, puntos libres, extracción k-means, paletas, `.mpalette` y persistencia. También se portan sus tests, para que ambas apps produzcan exactamente los mismos colores.
- **Navegación por pestañas inferiores**: **Crear** (rueda o imagen + color actual), **Generar** (paletas generadas: Escala, Tints/Shades, Neutros, Armonías, Personalizado, De la imagen) y **Paletas** (paleta activa + biblioteca). La barra superior tiene deshacer/rehacer, tema y ajustes.
- **Gestos táctiles en lugar de ratón**:
  - Mantener pulsado reemplaza al clic derecho (añade un color secundario).
  - Doble toque sobre un punto lo quita.
  - En la imagen: pinza para zoom y desplazamiento, y un dedo con una lupa desplazada (para que el dedo no tape el píxel) para elegir el color.
  - Se elimina todo lo que dependía del hover.
- **Entrada de imágenes**:
  - Abrir desde la galería con el selector de fotos del sistema, sin permisos.
  - Pegar una imagen del portapapeles.
  - **Recibir imágenes por "Compartir"** desde cualquier app (por ejemplo, una captura de pantalla): la app abre en Crear → Imagen y extrae los colores automáticamente.
  - El modo Imagen convive con la rueda (se puede volver a la rueda sin perder la imagen ni los colores).
- **Cámara en vivo**: apuntar con la cámara y tomar el color del centro como principal o como secundario.
- **Burbuja flotante** (reemplazo móvil de la captura de pantalla con Alt+C): una burbuja sobre otras apps que, previo consentimiento de captura de pantalla del sistema, toma una instantánea y permite elegir píxeles con lupa.
- **Archivos `.mpalette`** compatibles con desktop: exportar (guardar o compartir), importar (selector de archivos, "Abrir con" y "Compartir" hacia Matiz).
- **Exportación PNG** de la paleta y de los superpuestos (guardar en la galería o compartir).
- **Idioma** español/inglés (por defecto el del sistema) y **tema** Sistema/Claro/Oscuro en grises neutros, aplicados en vivo y persistentes.
- **Empaquetado para Google Play**: AAB firmado, `targetSdk` vigente, permisos mínimos y justificados, íconos adaptativos, ficha de la tienda y declaraciones de seguridad de datos.
- **Se quita respecto de desktop**: atajos de teclado, atajo global, "Siempre visible", botones de ventana e instancia única. Los enlaces de donación (Cafecito/PayPal) se **mantienen** en Ajustes por decisión del autor; el riesgo ante la política de pagos de Play queda documentado.

## Capabilities

### New Capabilities
- `color-model`: valor canónico sRGB de 8 bits con alfa, conversiones (HEX/RGB/HSL/HSV/CMYK/OKLCH), redondeo y parser de entradas, idénticos a los de desktop.
- `visual-picker`: rueda hue/saturación táctil, brillo, enfoque Vivo↔Pastel, ajuste fino con campos HSB y grises.
- `current-color`: fuente única de verdad, Anterior/Actual compactos, deshacer/rehacer y entrada manual validada.
- `color-clipboard`: copiar en el formato principal y como código, "Copiar todo", opciones de HEX y aviso de copia.
- `color-history`: recientes (30, sin duplicados, persistentes).
- `palette-generation`: Escala 50–950, Tints/Shades, Neutros y Armonías con sus puntos en la rueda; tarjetas compactas táctiles.
- `free-points`: modo Personalizado con principal + hasta 64 secundarios, que se añaden manteniendo pulsado, con "+" o con "Personalizar".
- `image-picker`: abrir o pegar una imagen, conmutador Rueda/Imagen, lupa táctil, zoom/pan con pinza y extracción automática.
- `share-intake`: recibir imágenes y archivos `.mpalette` por Compartir o "Abrir con", en frío y en caliente.
- `camera-picker`: tomar colores de la cámara en vivo (principal o secundario).
- `floating-bubble`: burbuja flotante con captura de pantalla consentida y lupa sobre la instantánea.
- `saved-palettes`: biblioteca, paleta activa, límite de 64, reordenar por arrastre táctil, recargar en la rueda y autoguardado.
- `palette-file`: formato `.mpalette` compatible con desktop; exportar e importar siempre como paleta nueva.
- `palette-export`: código (CSS, JSON, Dart, C#, Tailwind, lista HEX) e imagen PNG (paleta y superpuestos).
- `app-shell`: navegación por pestañas inferiores, barra superior, temas, idioma, ajustes y créditos/donaciones, sin pantallas intermedias.
- `app-packaging`: build AAB firmado para Google Play, permisos, íconos, versión y cumplimiento de políticas.

### Modified Capabilities
<!-- Proyecto nuevo: no hay specs previas en este repositorio. -->

## Impact

- **Código nuevo**: app Flutter (`lib/`, `android/`, `ios/` como esqueleto) y `packages/matiz_core` (Dart puro con tests).
- **Dependencias** (pub.dev, mantenidas): `provider`, `flutter_localizations`/`intl`, `path_provider`, `share_plus`, `file_picker`, `image_picker` (selector de fotos), `image` (decodificación de píxeles), `camera`, `receive_sharing_intent` o `share_handler`, `url_launcher`, `super_clipboard` o un canal propio para pegar imágenes. La burbuja necesita código nativo Kotlin (servicio en primer plano + MediaProjection + ventana superpuesta).
- **Permisos Android**: `CAMERA` (cámara en vivo, en tiempo de ejecución), `SYSTEM_ALERT_WINDOW` + `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MEDIA_PROJECTION` + `POST_NOTIFICATIONS` (solo burbuja), `INTERNET` no requerido (los enlaces se abren en el navegador). Sin permisos de almacenamiento ni de medios.
- **Google Play**: declaración de tipo de servicio en primer plano (media projection) con video, formulario de seguridad de datos ("no se recopilan datos"), política de privacidad publicada y riesgo de revisión por los enlaces de donación externos.
- **Proyecto `../matiz`**: sin cambios. Solo se lee como referencia y se copian los assets (ícono) que se necesiten.
- **Documentación**: `README.md`/`README.es.md` y el vault `docs/vault` del proyecto móvil.
