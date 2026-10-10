---
tags: [desarrollo]
---
# Compilar y ejecutar
Requisitos: Flutter 3.47+, JDK 17 y Android SDK 36. En esta máquina están en `%LOCALAPPDATA%\Android\jdk` y `%LOCALAPPDATA%\Android\Sdk`, configurados con `flutter config`. Emulador: AVD `matiz_pixel` (Pixel 7, API 36).
```bash
flutter pub get
flutter run                          # dispositivo o emulador
flutter build apk --release          # build/app/outputs/flutter-apk/app-release.apk
```
Para instalar en un teléfono: activar *Depuración USB* y usar `flutter install`, o copiar el APK. Ver [[Tests]] y [[Publicación]].
