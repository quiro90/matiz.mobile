---
tags: [referencia]
---
# Mapa del código
| Ruta | Contenido |
|---|---|
| `packages/matiz_core/` | [[matiz_core]] + tests y `fixtures/golden.json` |
| `lib/main.dart`, `lib/app.dart` | Arranque, tema, idioma |
| `lib/state/` | [[AppController]], `ImageDoc` |
| `lib/ui/shell.dart` | Barra superior, pestañas, Atrás, avisos, contenido entrante |
| `lib/ui/create_page.dart`, `generate_page.dart`, `palettes_page.dart` | Pestañas |
| `lib/ui/color_detail_sheet.dart`, `camera_page.dart`, `export_image_page.dart`, `settings_page.dart` | Pantallas y hojas |
| `lib/widgets/` | `ColorWheel`, `BrightnessBar`, `ImageCanvas`, `SwatchCard`, `CurrentColorBar` |
| `lib/imaging/palette_image_renderer.dart` | PNG |
| `lib/platform/platform_bridge.dart` | [[Canal de plataforma]] |
| `android/app/src/main/kotlin/com/juanquiroga/matiz/` | `MainActivity`, `BubbleService`, `CaptureActivity` |
| `tool/golden/` | Generador de la tabla dorada |
| `assets/branding/` | Ícono (derivado del de desktop) |
