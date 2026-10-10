import '../util/num_util.dart';

/// Valor canónico de un color: sRGB de 8 bits por canal más alpha de 8 bits.
/// Todo lo que se muestra, copia o guarda se deriva de este valor.
class Argb {
  final int a;
  final int r;
  final int g;
  final int b;

  const Argb(this.a, this.r, this.g, this.b);

  const Argb.fromRgb(this.r, this.g, this.b) : a = 255;

  /// Convierte un canal en [0,1] al byte canónico: round(x × 255), punto medio away-from-zero.
  static int toByte(double unit) {
    if (unit.isNaN) return 0;
    final v = roundAway(unit * 255.0);
    return clampD(v, 0, 255).toInt();
  }

  static Argb fromUnit(double r, double g, double b, [int a = 255]) =>
      Argb(a, toByte(r), toByte(g), toByte(b));

  static Argb fromUInt32(int argb) =>
      Argb((argb >> 24) & 0xFF, (argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF);

  int toUInt32() => (a << 24) | (r << 16) | (g << 8) | b;

  bool get isOpaque => a == 255;

  double get rUnit => r / 255.0;
  double get gUnit => g / 255.0;
  double get bUnit => b / 255.0;

  Argb withAlpha(int alpha) => Argb(alpha, r, g, b);

  Argb get opaque => Argb(255, r, g, b);

  /// #RRGGBB en mayúsculas (sin alpha).
  String toHex() => '#${hex2(r)}${hex2(g)}${hex2(b)}';

  /// #AARRGGBB en mayúsculas.
  String toArgbHex() => '#${hex2(a)}${hex2(r)}${hex2(g)}${hex2(b)}';

  @override
  String toString() => isOpaque ? toHex() : toArgbHex();

  @override
  bool operator ==(Object other) =>
      other is Argb && other.a == a && other.r == r && other.g == g && other.b == b;

  @override
  int get hashCode => toUInt32();
}
