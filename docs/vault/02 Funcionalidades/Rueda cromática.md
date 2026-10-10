---
tags: [funcionalidad, selector]
---
# Rueda cromática
- Ángulo = hue (0° rojo arriba, horario), radio = saturación (centro blanco), brillo 100%. Enfoque Vivo↔Pastel (`S = r^γ`) desde la hoja de detalle.
- **Gestos** ([[Gestos]]): tocar y soltar = fija el color; arrastrar = en vivo y confirma al soltar (con un círculo del color por encima del dedo); mantener pulsado 500 ms = añade un punto a [[Personalizado]] con vibración.
- Con Armonías/Personalizado: tocar un punto = seleccionarlo y ofrecer Copiar; arrastrarlo = moverlo (desde Armonías convierte a Personalizado); doble toque = quitarlo. El marcador principal tiene prioridad.
- Barra de brillo vertical con el degradado del color actual.
- Render: [[ADR-M05 Rueda por gradientes]]. Código: `lib/widgets/color_wheel.dart`.
