---
tags: [adr]
---
# ADR-M04 Captura de un fotograma
**Decisión**: la [[Burbuja flotante]] toma **una** instantánea por consentimiento y la abre en el modo [[Imagen]]. No hay captura continua ni lupa sobre otras apps.

**Por qué**:
- privacidad;
- no queda un indicador permanente de "compartiendo pantalla";
- la revisión de Play es más simple;
- reutiliza toda la lógica de imagen (como la "captura congelada" de desktop).
