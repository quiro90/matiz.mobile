---
tags: [arquitectura]
---
# Arquitectura general
```
packages/matiz_core  (Dart puro, sin Flutter)  ← tests + paridad con desktop
lib/state            AppController (ChangeNotifier) + ImageDoc
lib/ui · lib/widgets · lib/imaging             UI Material 3 neutra
lib/platform         PlatformBridge (Dart)  ⇄  android/.../kotlin (MainActivity, BubbleService, CaptureActivity)
```
- Estado: `provider` con `context.watch/select` sobre el [[AppController]].
- Idiomas: `gen-l10n` (`lib/l10n/app_es.arb`, `app_en.arb`). Los textos que genera el core (`Base`, `Paleta sin título`) usan `Texts.current`.
- Plataforma: [[Canal de plataforma]]. Decisión: [[ADR-M01 Flutter y port del core]].
