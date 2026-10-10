import 'dart:math' as math;

import '../colors/argb.dart';
import '../colors/color_math.dart';
import '../colors/color_spaces.dart';
import '../util/num_util.dart';
import 'generated_color.dart';
import 'harmony_kind.dart';

/// Design Scale 50–950 en OKLCH: L estrictamente decreciente según una curva de referencia remapeada
/// para que el color base caiga exactamente en el paso ancla; croma derivada del base reducida hacia
/// los extremos; hue constante; ajuste a gama reduciendo croma.
abstract final class DesignScale {
  static const List<int> steps = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950];

  /// Luminosidades OKLCH de referencia (inspiradas en Tailwind v4).
  static const List<double> referenceL = [0.975, 0.945, 0.89, 0.82, 0.72, 0.63, 0.55, 0.47, 0.39, 0.32, 0.24];

  /// Diferencia mínima de L entre pasos consecutivos.
  static const double minStep = 0.02;

  /// Reducción máxima de croma en los extremos (0.6 → los extremos conservan el 40%).
  static const double chromaFalloff = 0.6;

  static const int _fixedAnchorIndex = 5;

  static List<GeneratedColor> generate(Argb baseColor, [ScaleAnchorMode mode = ScaleAnchorMode.fixed500]) {
    final lch = ColorMath.toOklch(baseColor);
    final res = lightness(lch.l, mode);
    final l = res.values;
    final anchor = res.anchor;

    final lightSpan = math.max(l[0] - lch.l, 1e-6);
    final darkSpan = math.max(lch.l - l[l.length - 1], 1e-6);

    final result = <GeneratedColor>[];
    for (var i = 0; i < steps.length; i++) {
      if (i == anchor) {
        result.add(GeneratedColor(steps[i].toString(), baseColor, isBase: true));
        continue;
      }
      final t = i < anchor ? (l[i] - lch.l) / lightSpan : (lch.l - l[i]) / darkSpan;
      final chroma = lch.c * (1 - chromaFalloff * t * t);
      final color = lch.c < 1e-4
          ? _grayForL(l[i], baseColor.a)
          : ColorMath.fromOklchGamutMapped(Oklch(l[i], chroma, lch.h), baseColor.a);
      result.add(GeneratedColor(steps[i].toString(), color));
    }
    return result;
  }

  /// Calcula las 11 luminosidades para un base de luminosidad [baseL].
  static ({List<double> values, int anchor}) lightness(double baseL, ScaleAnchorMode mode) {
    baseL = clampD(baseL, 0, 1);
    final anchor = _chooseAnchor(baseL, mode);
    final n = steps.length;
    final l = List<double>.filled(n, 0);
    l[anchor] = baseL;

    // Extremos: al menos los de referencia, y con espacio suficiente para minStep por paso.
    var top = math.min(1.0, math.max(referenceL[0], baseL + minStep * anchor));
    var bottom = math.max(0.0, math.min(referenceL[n - 1], baseL - minStep * (n - 1 - anchor)));
    if (anchor == 0) top = baseL;
    if (anchor == n - 1) bottom = baseL;

    _distribute(l, anchor, 0, top); // pasos más claros
    _distribute(l, anchor, n - 1, bottom); // pasos más oscuros
    return (values: l, anchor: anchor);
  }

  /// Reparte la distancia entre el ancla y un extremo garantizando minStep por hueco y
  /// repartiendo el sobrante proporcionalmente a los huecos de la curva de referencia.
  static void _distribute(List<double> l, int anchor, int end, double endValue) {
    final count = (end - anchor).abs();
    if (count == 0) return;
    final dir = (end - anchor).sign;
    final total = (endValue - l[anchor]).abs();
    final refGaps = List<double>.filled(count, 0);
    var refSum = 0.0;
    for (var k = 0; k < count; k++) {
      final a = anchor + k * dir;
      refGaps[k] = (referenceL[a + dir] - referenceL[a]).abs();
      refSum += refGaps[k];
    }
    final spare = math.max(0.0, total - minStep * count);
    final sign = dir < 0 ? 1 : -1; // hacia los claros L sube; hacia los oscuros baja
    var acc = l[anchor];
    for (var k = 0; k < count; k++) {
      final gap = minStep + spare * refGaps[k] / refSum;
      acc += sign * gap;
      l[anchor + (k + 1) * dir] = clampD(acc, 0, 1);
    }
  }

  static bool _feasible(double baseL, int anchor) =>
      baseL + minStep * anchor <= 1 + 1e-9 && baseL - minStep * (steps.length - 1 - anchor) >= -1e-9;

  static int _chooseAnchor(double baseL, ScaleAnchorMode mode) {
    if (mode == ScaleAnchorMode.fixed500 && _feasible(baseL, _fixedAnchorIndex)) return _fixedAnchorIndex;
    // Automático (o 500 imposible): el paso de referencia más cercano que sea factible.
    final order = stableSorted<int>(
      List.generate(steps.length, (i) => i),
      (a, b) => (referenceL[a] - baseL).abs().compareTo((referenceL[b] - baseL).abs()),
    );
    return order.firstWhere((i) => _feasible(baseL, i));
  }

  static Argb _grayForL(double l, int alpha) {
    final v = Argb.toByte(ColorMath.linearToSrgb(clampD(l * l * l, 0, 1)));
    return Argb(alpha, v, v, v);
  }
}
