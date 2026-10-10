# Matiz for Android

**English** · [Español](README.es.md)

Mobile version of [Matiz](../matiz) — a small, fast color tool to **pick a color → understand it → build a palette → copy / save → export**, redesigned for touch screens.

![Matiz](docs/capture.png)
![Matiz](docs/capture2.png)
![Matiz](docs/capture3.png)

## Features

- **Visual picker**: hue/saturation wheel (white center) with a brightness bar showing the color itself, previous | current bar and recent colors; or an image as the focus — pinch to zoom, one finger + loupe to pick, long-press to add.
- **Pick from anywhere**: gallery (system photo picker — no permissions), paste any format, screenshots via **Share → Matiz**, live camera, and an optional floating bubble (a single consented screenshot).
- **Every format**: HEX, RGB, HSL, HSV, CMYK (approx.), OKLCH, plus code snippets (CSS, C#/WPF, XAML, Flutter/Dart, ARGB); type a format to set a color.
- **Design scale 50–950** generated in OKLCH, ready for design systems.
- **Harmonies** (complementary, analogous, split, triadic, tetradic, monochromatic) drawn on the wheel with balanced lightness, plus tints/shades and neutrals.
- **Custom set**: main color + up to 64 secondary points, added by long-pressing the wheel, the image, the camera or the bubble; **Customize** (from image/camera) loads the extracted colors as Custom points at once.
- **Palettes**: active palette with drag reordering, library with autosave, import/export self-contained **`.mpalette`** files (compatible with Matiz desktop), PNG exports (palette and overlay), copy/share as **CSS variables, JSON, Dart, C#, Tailwind** or HEX.
- **Grayscale** (1.1.1): slider 0–100 % on the active palette that live-blends every color toward its perceptual gray (Oklab) without touching stored colors; the % is remembered per palette, travels inside the `.mpalette`, and exports come out exactly as seen.
- Undo/redo, Spanish / English UI, light / dark theme.

> The color engine (`packages/matiz_core`) is a 1:1 Dart port of the desktop `Matiz.Core`, verified byte-for-byte against it (see *Parity*).

## Requirements

- Flutter 3.47+ (Dart 3.13+)
- Android SDK (platform 36, build-tools 36) and JDK 17
- Android 10 (API 29) or later on the device

## Run

```bash
flutter pub get
flutter run                 # on a connected device or emulator
```

## Tests

```bash
cd packages/matiz_core && dart test     # color engine (includes desktop parity)
flutter test                            # app widget tests
flutter analyze
```

### Parity with desktop

`tool/golden` is a .NET console app that compiles the desktop `Matiz.Core` **reading** its sources from `../matiz` (nothing is written there) and dumps reference results to `packages/matiz_core/test/fixtures/golden.json` (2,000 colors: conversions, scales, harmonies, tints, neutrals; k-means extraction; code export). `golden_parity_test.dart` must match it exactly.

```bash
cd tool/golden && dotnet run
```

## Build

```bash
flutter build apk --release        # local testing (debug-signed if no key.properties)
flutter build appbundle --release  # Google Play (requires android/key.properties)
# Without donation links (Play payments policy plan B):
flutter build appbundle --release --dart-define=DONATIONS=false
```

## Project layout

```
packages/matiz_core/   Dart color engine (no Flutter) + tests
lib/state/             AppController (single source of truth), ImageDoc
lib/ui/                Create / Generate / Palettes / Settings / Camera / Export pages
lib/widgets/           ColorWheel, BrightnessBar, ImageCanvas (loupe), cards
lib/imaging/           PNG renderers (palette, overlay)
lib/platform/          Dart side of the `matiz/platform` channel
android/.../kotlin/    MainActivity (share/open/clipboard/gallery/locale), BubbleService, CaptureActivity
openspec/              Spec-driven change and specs
docs/vault/            Product & technical documentation (Obsidian vault)
```

## License

Apache 2.0 with the [Commons Clause](https://commonsclause.com/): free to copy, modify, build and distribute; selling the software itself is reserved to the author. See [LICENSE](LICENSE).

## Support the project

Consider donating if you find it useful:

<a href="https://cafecito.app/juanquiroga"><img src="https://cdn.cafecito.app/imgs/buttons/button_2.png" alt="Invitame un café en cafecito.app"></a> <a href="https://www.paypal.com/ncp/payment/PJXDUSBHSE8DE"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="Donate with PayPal"></a>