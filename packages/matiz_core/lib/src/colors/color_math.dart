import 'dart:math' as math;

import '../util/num_util.dart';
import 'argb.dart';
import 'color_spaces.dart';

/// Conversiones entre espacios de color. Fórmulas estándar:
/// HSV/HSL hexcónicos, CMYK ingenuo sin perfil, Oklab/OKLCH según Björn Ottosson
/// con la función de transferencia sRGB IEC 61966-2-1.
abstract final class ColorMath {
  // ---------- HSV ----------

  static Hsv toHsv(Argb c) => toHsvUnit(c.rUnit, c.gUnit, c.bUnit);

  static Hsv toHsvUnit(double r, double g, double b) {
    final max = math.max(r, math.max(g, b));
    final min = math.min(r, math.min(g, b));
    final d = max - min;
    final s = max <= 0 ? 0.0 : d / max;
    return Hsv(_hue(r, g, b, max, d), s, max);
  }

  static Rgb3 hsvToRgb(double h, double s, double v) {
    h = normalizeHue(h);
    s = clampD(s, 0, 1);
    v = clampD(v, 0, 1);
    final c = v * s;
    final hp = h / 60.0;
    final x = c * (1 - (csMod(hp, 2) - 1).abs());
    final sec = _sector(hp, c, x);
    final m = v - c;
    return (r: sec.r + m, g: sec.g + m, b: sec.b + m);
  }

  static Argb fromHsv(double h, double s, double v, [int alpha = 255]) {
    final rgb = hsvToRgb(h, s, v);
    return Argb.fromUnit(rgb.r, rgb.g, rgb.b, alpha);
  }

  // ---------- HSL ----------

  static Hsl toHsl(Argb c) {
    final r = c.rUnit, g = c.gUnit, b = c.bUnit;
    final max = math.max(r, math.max(g, b));
    final min = math.min(r, math.min(g, b));
    final d = max - min;
    final l = (max + min) / 2;
    final denom = 1 - (2 * l - 1).abs();
    final s = d <= 0 || denom <= 0 ? 0.0 : d / denom;
    return Hsl(_hue(r, g, b, max, d), clampD(s, 0, 1), l);
  }

  static Rgb3 hslToRgb(double h, double s, double l) {
    h = normalizeHue(h);
    s = clampD(s, 0, 1);
    l = clampD(l, 0, 1);
    final c = (1 - (2 * l - 1).abs()) * s;
    final hp = h / 60.0;
    final x = c * (1 - (csMod(hp, 2) - 1).abs());
    final sec = _sector(hp, c, x);
    final m = l - c / 2;
    return (r: sec.r + m, g: sec.g + m, b: sec.b + m);
  }

  static Argb fromHsl(double h, double s, double l, [int alpha = 255]) {
    final rgb = hslToRgb(h, s, l);
    return Argb.fromUnit(rgb.r, rgb.g, rgb.b, alpha);
  }

  // ---------- CMYK (aproximado, sin perfil ICC) ----------

  static Cmyk toCmyk(Argb c) {
    final r = c.rUnit, g = c.gUnit, b = c.bUnit;
    final double k = 1 - math.max(r, math.max(g, b));
    if (k >= 1) return const Cmyk(0, 0, 0, 1);
    return Cmyk((1 - r - k) / (1 - k), (1 - g - k) / (1 - k), (1 - b - k) / (1 - k), k);
  }

  // ---------- sRGB lineal ----------

  static double srgbToLinear(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  static double linearToSrgb(double c) =>
      c <= 0.0031308 ? 12.92 * c : 1.055 * math.pow(c, 1 / 2.4).toDouble() - 0.055;

  static LinearRgb toLinear(Argb c) =>
      LinearRgb(srgbToLinear(c.rUnit), srgbToLinear(c.gUnit), srgbToLinear(c.bUnit));

  static Argb fromLinear(LinearRgb c, [int alpha = 255]) => Argb.fromUnit(
        linearToSrgb(clampD(c.r, 0, 1)),
        linearToSrgb(clampD(c.g, 0, 1)),
        linearToSrgb(clampD(c.b, 0, 1)),
        alpha,
      );

  // ---------- Oklab / OKLCH ----------

  static Oklab toOklab(Argb c) => linearToOklab(toLinear(c));

  static Oklab linearToOklab(LinearRgb c) {
    final l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
    final m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
    final s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;
    final l_ = cbrt(l);
    final m_ = cbrt(m);
    final s_ = cbrt(s);
    return Oklab(
      0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
      1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
      0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
    );
  }

  static LinearRgb oklabToLinear(Oklab c) {
    final l_ = c.l + 0.3963377774 * c.a + 0.2158037573 * c.b;
    final m_ = c.l - 0.1055613458 * c.a - 0.0638541728 * c.b;
    final s_ = c.l - 0.0894841775 * c.a - 1.2914855480 * c.b;
    final l = l_ * l_ * l_;
    final m = m_ * m_ * m_;
    final s = s_ * s_ * s_;
    return LinearRgb(
      4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
      -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
      -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    );
  }

  static Oklch toOklch(Argb c) => oklabToOklch(toOklab(c));

  static Oklch oklabToOklch(Oklab c) {
    final chroma = math.sqrt(c.a * c.a + c.b * c.b);
    final h = chroma < 1e-9 ? 0.0 : normalizeHue(math.atan2(c.b, c.a) * 180 / math.pi);
    return Oklch(c.l, chroma, h);
  }

  static Oklab oklchToOklab(Oklch c) {
    final rad = c.h * math.pi / 180;
    return Oklab(c.l, c.c * math.cos(rad), c.c * math.sin(rad));
  }

  static bool isInGamut(LinearRgb c, [double eps = 1e-6]) =>
      c.r >= -eps && c.r <= 1 + eps && c.g >= -eps && c.g <= 1 + eps && c.b >= -eps && c.b <= 1 + eps;

  /// Convierte OKLCH a sRGB de 8 bits. Si queda fuera de gama reduce solo la croma
  /// (búsqueda binaria) conservando L y h.
  static Argb fromOklchGamutMapped(Oklch c, [int alpha = 255]) {
    final l = clampD(c.l, 0, 1);
    final target = Oklch(l, math.max(0, c.c), c.h);
    final lin = oklabToLinear(oklchToOklab(target));
    if (isInGamut(lin)) return fromLinear(lin, alpha);

    var lo = 0.0, hi = target.c;
    for (var i = 0; i < 30; i++) {
      final mid = (lo + hi) / 2;
      if (isInGamut(oklabToLinear(oklchToOklab(target.withC(mid))))) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return fromLinear(oklabToLinear(oklchToOklab(target.withC(lo))), alpha);
  }

  /// Gris neutro con la misma luminosidad perceptual (Oklab L) que el color dado.
  static Argb grayEquivalent(Argb c) {
    final l = toOklab(c).l;
    final lin = clampD(l * l * l, 0, 1);
    final v = Argb.toByte(linearToSrgb(lin));
    return Argb(c.a, v, v, v);
  }

  /// Mezcla por canal del color hacia su gris equivalente perceptual (0 = original, 1 = gris).
  /// Solo presentación: conserva el alfa del original y no muta colores almacenados.
  static Argb mixToGray(Argb c, double amount) {
    if (amount.isNaN) return c;
    amount = clampD(amount, 0, 1);
    if (amount <= 0) return c;
    final g = grayEquivalent(c);
    if (amount >= 1) return g;
    return Argb(c.a, _lerpByte(c.r, g.r, amount), _lerpByte(c.g, g.g, amount), _lerpByte(c.b, g.b, amount));
  }

  /// `Math.Round(a + (b - a) * t, MidpointRounding.AwayFromZero)` acotado a byte.
  static int _lerpByte(int a, int b, double t) => clampI(roundAway(a + (b - a) * t).toInt(), 0, 255);

  // ---------- utilidades ----------

  static double normalizeHue(double h) {
    if (h.isNaN || h.isInfinite) return 0;
    h = csMod(h, 360);
    if (h < 0) h += 360;
    return h >= 360 ? 0 : h;
  }

  static double _hue(double r, double g, double b, double max, double d) {
    if (d <= 0) return 0;
    double h;
    if (max == r) {
      h = csMod((g - b) / d, 6);
    } else if (max == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    return normalizeHue(h * 60);
  }

  static Rgb3 _sector(double hp, double c, double x) {
    if (hp < 1) return (r: c, g: x, b: 0.0);
    if (hp < 2) return (r: x, g: c, b: 0.0);
    if (hp < 3) return (r: 0.0, g: c, b: x);
    if (hp < 4) return (r: 0.0, g: x, b: c);
    if (hp < 5) return (r: x, g: 0.0, b: c);
    return (r: c, g: 0.0, b: x);
  }
}
