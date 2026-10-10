import '../colors/argb.dart';
import '../colors/color_math.dart';
import '../util/num_util.dart';

/// Interpreta texto como color. Formatos aceptados (sin distinguir mayúsculas, tolerante a espacios):
/// HEX de 3/6/8 dígitos con o sin '#' (8 dígitos = #AARRGGBB), 0xAARRGGBB / 0xRRGGBB,
/// rgb()/rgba(), hsl()/hsla(), hsv()/hsb(), y tres enteros 0–255 separados por comas/espacios.
abstract final class ColorParser {
  static final _function = RegExp(r'^([a-z]+)\s*\(([^)]*)\)$');
  static final _hexOnly = RegExp(r'^[0-9a-f]+$');
  static final _int = RegExp(r'^\d+$');
  static final _separator = RegExp(r'[\s,;/]+');
  static final _number = RegExp(r'^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$');

  static Argb? parse(String? input) {
    if (input == null || input.trim().isEmpty) return null;

    var s = input.trim();
    while (s.endsWith(';')) {
      s = s.substring(0, s.length - 1);
    }
    s = s.trim().toLowerCase();

    if (s.startsWith('0x')) return _hexDigits(s.substring(2));

    final fn = _function.firstMatch(s);
    if (fn != null) return _function2(fn.group(1)!, fn.group(2)!);

    if (s.startsWith('#')) return _hexDigits(s.substring(1).trim());

    if (_hexOnly.hasMatch(s)) return _hexDigits(s);

    final parts = _split(s);
    if (parts.length == 3 && parts.every(_int.hasMatch)) return _rgbChannels(parts, null);

    return null;
  }

  static bool tryParse(String? input) => parse(input) != null;

  static Argb? _hexDigits(String hex) {
    if (!_hexOnly.hasMatch(hex)) return null;
    switch (hex.length) {
      case 3:
        int dup(String ch) => int.parse(ch, radix: 16) * 17;
        return Argb.fromRgb(dup(hex[0]), dup(hex[1]), dup(hex[2]));
      case 6:
        return Argb.fromUInt32(0xFF000000 | int.parse(hex, radix: 16));
      case 8:
        return Argb.fromUInt32(int.parse(hex, radix: 16));
      default:
        return null;
    }
  }

  static Argb? _function2(String name, String args) {
    final parts = _split(args);
    switch (name) {
      case 'rgb':
      case 'rgba':
        if (parts.length != 3 && parts.length != 4) return null;
        return _rgbChannels(parts.sublist(0, 3), parts.length == 4 ? parts[3] : null);
      case 'hsl':
      case 'hsla':
      case 'hsv':
      case 'hsb':
        if (parts.length != 3 && parts.length != 4) return null;
        final h = _hue(parts[0]);
        final p1 = _percent(parts[1]);
        final p2 = _percent(parts[2]);
        if (h == null || p1 == null || p2 == null) return null;
        var a = 255;
        if (parts.length == 4) {
          final pa = _alpha(parts[3]);
          if (pa == null) return null;
          a = pa;
        }
        return name.startsWith('hsl') ? ColorMath.fromHsl(h, p1, p2, a) : ColorMath.fromHsv(h, p1, p2, a);
      default:
        return null;
    }
  }

  static Argb? _rgbChannels(List<String> parts, String? alpha) {
    final ch = List<int>.filled(3, 0);
    for (var i = 0; i < 3; i++) {
      final p = parts[i];
      if (p.endsWith('%')) {
        final pct = _num(p.substring(0, p.length - 1));
        if (pct == null || pct < 0 || pct > 100) return null;
        ch[i] = Argb.toByte(pct / 100);
      } else {
        final v = _num(p);
        if (v == null || v < 0 || v > 255) return null;
        ch[i] = roundAway(v).toInt();
      }
    }
    var a = 255;
    if (alpha != null) {
      final pa = _alpha(alpha);
      if (pa == null) return null;
      a = pa;
    }
    return Argb(a, ch[0], ch[1], ch[2]);
  }

  static double? _hue(String s) {
    s = s.replaceAll('deg', '').replaceAll('°', '');
    final h = _num(s);
    if (h == null || h < 0 || h > 360) return null;
    return ColorMath.normalizeHue(h);
  }

  static double? _percent(String s) {
    while (s.endsWith('%')) {
      s = s.substring(0, s.length - 1);
    }
    final v = _num(s);
    if (v == null || v < 0 || v > 100) return null;
    return v / 100;
  }

  static int? _alpha(String s) {
    if (s.endsWith('%')) {
      final pct = _num(s.substring(0, s.length - 1));
      if (pct == null || pct < 0 || pct > 100) return null;
      return Argb.toByte(pct / 100);
    }
    final v = _num(s);
    if (v == null || v < 0 || v > 1) return null;
    return Argb.toByte(v);
  }

  static double? _num(String s) {
    if (!_number.hasMatch(s)) return null;
    final v = double.tryParse(s);
    return v != null && v.isFinite ? v : null;
  }

  static List<String> _split(String s) => s.trim().split(_separator).where((p) => p.isNotEmpty).toList();
}
