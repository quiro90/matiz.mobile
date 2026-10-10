import 'dart:math' as math;

import '../util/num_util.dart';
import 'color_math.dart';

/// Mapeo entre la posición en la rueda y (hue, saturación HSV).
/// Ángulo: 0° (rojo) arriba, creciente en sentido horario. Radio normalizado r ∈ [0,1].
/// Distribución radial: S = r^γ. γ = 1 lineal; γ > 1 dedica más radio a saturaciones bajas (pastel);
/// γ < 1 a saturaciones altas (vivo).
abstract final class WheelMapping {
  static const double maxFocusExponent = 1.25;

  /// Convierte el control "Enfoque" k ∈ [-1, 1] (−1 vivo, 0 lineal, +1 pastel) en γ.
  static double gammaFromFocus(double focus) =>
      math.pow(2, maxFocusExponent * clampD(focus, -1, 1)).toDouble();

  /// Posición relativa al centro (dx a la derecha, dy hacia abajo) → hue y saturación.
  /// Fuera de la rueda la saturación se limita a 1. En el centro exacto el hue es NaN.
  static ({double hue, double saturation}) fromPoint(double dx, double dy, double radius, double gamma) {
    if (radius <= 0) return (hue: 0, saturation: 0);
    final dist = math.sqrt(dx * dx + dy * dy);
    final r = math.min(dist / radius, 1.0);
    final hue = dist < 1e-9 ? double.nan : ColorMath.normalizeHue(math.atan2(dx, -dy) * 180 / math.pi);
    return (hue: hue, saturation: math.pow(r, gamma).toDouble());
  }

  /// Hue y saturación → desplazamiento normalizado (radio 1) desde el centro.
  static ({double x, double y}) toPoint(double hue, double saturation, double gamma) {
    final r = math.pow(clampD(saturation, 0, 1), 1 / gamma).toDouble();
    final rad = hue * math.pi / 180;
    return (x: r * math.sin(rad), y: -r * math.cos(rad));
  }
}
