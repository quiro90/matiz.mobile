import '../util/num_util.dart';
import 'argb.dart';
import 'color_math.dart';

/// Estado del selector: coordenadas HSV continuas + alpha. Es la representación del
/// "Color Actual"; el valor canónico [Argb] se deriva de él.
/// Conserva hue/saturación aunque el color sea acromático (gris o negro).
class ColorState {
  final double hue;
  final double saturation;
  final double value;
  final int alpha;
  final Argb argb;

  ColorState._(this.hue, this.saturation, this.value, this.alpha, this.argb);

  factory ColorState(double hue, double saturation, double value, [int alpha = 255]) {
    final h = ColorMath.normalizeHue(hue);
    final s = clampD(saturation, 0, 1);
    final v = clampD(value, 0, 1);
    return ColorState._(h, s, v, alpha, ColorMath.fromHsv(h, s, v, alpha));
  }

  ColorState withHue(double h) => ColorState(h, saturation, value, alpha);
  ColorState withSaturation(double s) => ColorState(hue, s, value, alpha);
  ColorState withValue(double v) => ColorState(hue, saturation, v, alpha);
  ColorState withHueSaturation(double h, double s) => ColorState(h, s, value, alpha);

  /// Crea el estado para un color canónico. Si el color es acromático conserva el hue
  /// del estado previo; si es negro conserva también la saturación previa.
  /// El [argb] resultante es siempre exactamente [color].
  static ColorState fromArgb(Argb color, [ColorState? previous]) {
    final hsv = ColorMath.toHsv(color);
    var hue = hsv.h;
    var sat = hsv.s;
    if (previous != null) {
      if (hsv.s <= 0 || hsv.v <= 0) hue = previous.hue;
      if (hsv.v <= 0) sat = previous.saturation;
    }
    final state = ColorState(hue, sat, hsv.v, color.a);
    // Garantía de ida y vuelta exacta (protege ante cualquier borde numérico).
    return state.argb == color ? state : ColorState(hsv.h, hsv.s, hsv.v, color.a);
  }

  @override
  bool operator ==(Object other) =>
      other is ColorState &&
      other.hue == hue &&
      other.saturation == saturation &&
      other.value == value &&
      other.alpha == alpha;

  @override
  int get hashCode => Object.hash(hue, saturation, value, alpha);
}
