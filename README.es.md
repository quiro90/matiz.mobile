# Matiz para Android

Versión móvil de [Matiz](../matiz): una herramienta de color pequeña y rápida para **tomar un color → entenderlo → armar una paleta → copiar / guardar → exportar**, rediseñada para pantallas táctiles.

- **Crear**: rueda HSV con barra de brillo, o una imagen como foco (pellizcar para zoom, un dedo con lupa para elegir, mantener pulsado para añadir). Barra Anterior | Actual y recientes.
- **Generar**: Design Scale 50–950, tints/shades, neutros, armonías y **Personalizado** (principal + hasta 64 puntos secundarios, que se añaden manteniendo pulsada la rueda, la imagen, la cámara o la burbuja).
- **Paletas**: paleta activa (arrastrar para reordenar), biblioteca, importar/exportar `.mpalette` (compatible con Matiz desktop), exportar PNG (paleta y superpuestos).
- **Entradas**: rueda, galería (selector de fotos del sistema, sin permisos), pegar, **Compartir → Matiz** (capturas), cámara en vivo, burbuja flotante opcional (una captura consentida).
- Español / inglés, tema claro / oscuro.

El motor de color (`packages/matiz_core`) es un port 1:1 en Dart de `Matiz.Core` y se verifica byte a byte contra la app de escritorio (ver *Paridad*).

## Requisitos

- Flutter 3.47+ (Dart 3.13+)
- Android SDK (plataforma 36, build-tools 36) y JDK 17
- Android 10 (API 29) o superior en el dispositivo

## Ejecutar

```bash
flutter pub get
flutter run                 # en un dispositivo conectado o emulador
```

## Tests

```bash
cd packages/matiz_core && dart test     # motor de color (107 tests, incluye paridad con desktop)
flutter test                            # tests de widgets de la app
flutter analyze
```

### Paridad con desktop

`tool/golden` es una app de consola .NET que compila `Matiz.Core` de desktop **leyendo** sus fuentes desde `../matiz` (no escribe nada allí) y vuelca resultados de referencia en `packages/matiz_core/test/fixtures/golden.json`: 2.000 colores (conversiones, escalas, armonías, tints, neutros), extracción k-means y exportación de código. `golden_parity_test.dart` debe coincidir exactamente.

```bash
cd tool/golden && dotnet run
```

## Compilar

```bash
flutter build apk --release        # pruebas locales (firma de depuración si no hay key.properties)
flutter build appbundle --release  # Google Play (requiere android/key.properties)
# Sin enlaces de donación (plan B ante la política de pagos de Play):
flutter build appbundle --release --dart-define=DONATIONS=false
```

## Estructura

```
packages/matiz_core/   Motor de color en Dart (sin Flutter) + tests
lib/state/             AppController (fuente única de verdad), ImageDoc
lib/ui/                Páginas Crear / Generar / Paletas / Ajustes / Cámara / Exportar
lib/widgets/           ColorWheel, BrightnessBar, ImageCanvas (lupa), tarjetas
lib/imaging/           Renderizadores PNG (paleta, superpuestos)
lib/platform/          Lado Dart del canal `matiz/platform`
android/.../kotlin/    MainActivity (compartir/abrir/portapapeles/galería/idioma), BubbleService, CaptureActivity
openspec/              Cambio y specs (spec-driven)
docs/vault/            Documentación de producto y técnica (vault de Obsidian)
```
