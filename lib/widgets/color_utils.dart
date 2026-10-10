import 'package:flutter/material.dart';
import 'package:matiz_core/matiz_core.dart';

extension ArgbFlutter on Argb {
  Color get toColor => Color.fromARGB(a, r, g, b);

  /// Texto legible sobre este color (según la luminosidad perceptual OKLab).
  Color get onColor => ColorMath.toOklab(opaque).l > 0.62 ? const Color(0xDD000000) : const Color(0xF2FFFFFF);
}

/// Patrón de tablero para mostrar colores con transparencia.
class CheckerPainter extends CustomPainter {
  const CheckerPainter({this.cell = 6});
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFFFFFFF);
    final dark = Paint()..color = const Color(0xFFD9D9D9);
    canvas.drawRect(Offset.zero & size, light);
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        if (((x / cell).floor() + (y / cell).floor()).isOdd) {
          canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), dark);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CheckerPainter oldDelegate) => oldDelegate.cell != cell;
}

/// Muestra de color con soporte de alpha (tablero de fondo).
class ColorSwatchBox extends StatelessWidget {
  const ColorSwatchBox({super.key, required this.color, this.radius = 10, this.child, this.border = true});

  final Argb color;
  final double radius;
  final Widget? child;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: color.toColor,
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: scheme.onSurface.withValues(alpha: 0.10)) : null,
      ),
      child: child ?? const SizedBox.expand(),
    );
    if (color.isOpaque) return box;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(painter: const CheckerPainter(), child: box),
    );
  }
}
