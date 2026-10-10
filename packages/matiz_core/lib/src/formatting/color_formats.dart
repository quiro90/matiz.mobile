import '../colors/argb.dart';
import '../colors/color_math.dart';
import '../colors/color_spaces.dart';
import '../util/num_util.dart';

/// Opciones de presentación del HEX.
class FormatOptions {
  final bool hexUppercase;
  final bool hexHash;

  const FormatOptions({this.hexUppercase = true, this.hexHash = true});

  static const FormatOptions defaults = FormatOptions();

  FormatOptions copyWith({bool? hexUppercase, bool? hexHash}) =>
      FormatOptions(hexUppercase: hexUppercase ?? this.hexUppercase, hexHash: hexHash ?? this.hexHash);
}

/// Representaciones de texto de un color con los redondeos definidos en la spec color-model.
abstract final class ColorFormats {
  static int pct(double unit) => roundAway(unit * 100).toInt();

  static int deg(double hue) => roundAway(hue).toInt() % 360;

  static String hex(Argb c, [FormatOptions o = FormatOptions.defaults]) {
    var h = '${hex2(c.r)}${hex2(c.g)}${hex2(c.b)}';
    if (!o.hexUppercase) h = h.toLowerCase();
    return o.hexHash ? '#$h' : h;
  }

  static String argbHex(Argb c, [FormatOptions o = FormatOptions.defaults]) {
    var h = '${hex2(c.a)}${hex2(c.r)}${hex2(c.g)}${hex2(c.b)}';
    if (!o.hexUppercase) h = h.toLowerCase();
    return o.hexHash ? '#$h' : h;
  }

  static String rgb(Argb c) => '${c.r}, ${c.g}, ${c.b}';

  static String hsl(Argb c) {
    final h = ColorMath.toHsl(c);
    return '${deg(h.h)}°, ${pct(h.s)}%, ${pct(h.l)}%';
  }

  static String hsv(Argb c) {
    final h = ColorMath.toHsv(c);
    return '${deg(h.h)}°, ${pct(h.s)}%, ${pct(h.v)}%';
  }

  static String cmyk(Argb c) {
    final k = ColorMath.toCmyk(c);
    return '${pct(k.c)}%, ${pct(k.m)}%, ${pct(k.y)}%, ${pct(k.k)}%';
  }

  static String oklch(Argb c) {
    final o = ColorMath.toOklch(c);
    return '${formatFixed(o.l, 3)} ${formatFixed(o.c, 3)} ${formatFixed(_oklchHue(o), 1)}';
  }

  static String cssRgb(Argb c) => c.isOpaque
      ? 'rgb(${c.r}, ${c.g}, ${c.b})'
      : 'rgba(${c.r}, ${c.g}, ${c.b}, ${formatUpTo2(c.a / 255.0)})';

  static String cssHsl(Argb c) {
    final h = ColorMath.toHsl(c);
    return c.isOpaque
        ? 'hsl(${deg(h.h)}, ${pct(h.s)}%, ${pct(h.l)}%)'
        : 'hsla(${deg(h.h)}, ${pct(h.s)}%, ${pct(h.l)}%, ${formatUpTo2(c.a / 255.0)})';
  }

  static String cssOklch(Argb c) {
    final o = ColorMath.toOklch(c);
    final body = '${formatFixed(o.l, 3)} ${formatFixed(o.c, 3)} ${formatFixed(_oklchHue(o), 1)}';
    return c.isOpaque ? 'oklch($body)' : 'oklch($body / ${formatUpTo2(c.a / 255.0)})';
  }

  static String cSharpWpf(Argb c) => c.isOpaque ? 'Color.FromRgb(${c.r}, ${c.g}, ${c.b})' : cSharpArgb(c);

  static String cSharpArgb(Argb c) => 'Color.FromArgb(${c.a}, ${c.r}, ${c.g}, ${c.b})';

  static String xaml(Argb c) => '#${hex2(c.a)}${hex2(c.r)}${hex2(c.g)}${hex2(c.b)}';

  static String dart(Argb c) => 'Color(0x${hex2(c.a)}${hex2(c.r)}${hex2(c.g)}${hex2(c.b)})';

  static String argbInt(Argb c) => '0x${hex2(c.a)}${hex2(c.r)}${hex2(c.g)}${hex2(c.b)}';

  static String copyAll(Argb c, [FormatOptions o = FormatOptions.defaults]) {
    final lines = <String>[
      'HEX: ${hex(c, o)}',
      'RGB: ${rgb(c)}',
      'HSL: ${hsl(c)}',
      'HSV: ${hsv(c)}',
      'CMYK: ${cmyk(c)}',
    ];
    if (!c.isOpaque) lines.insert(1, 'ARGB: ${argbHex(c, o)}');
    return lines.join('\n');
  }

  static double _oklchHue(Oklch o) {
    final h = roundAwayDigits(o.h, 1);
    return h >= 360 ? 0 : h;
  }
}
