import 'dart:convert';

import '../colors/argb.dart';
import '../formatting/color_formats.dart';
import '../localization/texts.dart';
import '../palettes/palette.dart';

/// Modelo común de exportación: sirve para paletas guardadas, generadas y escalas.
class PaletteExportModel {
  final String name;
  final List<PaletteExportColor> colors;

  const PaletteExportModel(this.name, this.colors);

  static PaletteExportModel from(Palette p) =>
      PaletteExportModel(p.name, [for (final c in p.colors) PaletteExportColor(c.name, c.color)]);
}

class PaletteExportColor {
  final String? name;
  final Argb color;
  const PaletteExportColor(this.name, this.color);
}

class PaletteFormatter {
  final String id;
  final String displayName;
  final String Function(PaletteExportModel palette, FormatOptions options) _format;

  const PaletteFormatter(this.id, this.displayName, this._format);

  String format(PaletteExportModel palette, [FormatOptions options = FormatOptions.defaults]) =>
      _format(palette, options);
}

/// Registro de formatos de exportación de paletas. Añadir uno nuevo = registrarlo aquí.
abstract final class PaletteFormatters {
  static const String _nl = '\n';

  static final List<PaletteFormatter> all = [
    PaletteFormatter('css', 'CSS variables', css),
    PaletteFormatter('json', 'JSON', json),
    PaletteFormatter('dart', 'Dart / Flutter', (p, _) => dart(p)),
    PaletteFormatter('csharp', 'C# (WPF)', (p, _) => cSharp(p)),
    PaletteFormatter('tailwind', 'Tailwind v4 (@theme)', tailwind),
    PaletteFormatter('hex-list', 'HEX', (p, o) => p.colors.map((c) => _hex(c.color, o)).join(_nl)),
  ];

  static PaletteFormatter get(String id) {
    final key = id.toLowerCase();
    return all.firstWhere((f) => f.id == key, orElse: () => all[0]);
  }

  static String css(PaletteExportModel p, FormatOptions o) {
    final names = IdentifierNaming.unique(p.colors, IdentifierNaming.kebab, '-');
    final sb = StringBuffer(':root {$_nl');
    for (var i = 0; i < p.colors.length; i++) {
      sb.write('  --${names[i]}: ${_cssValue(p.colors[i].color, o)};$_nl');
    }
    sb.write('}');
    return sb.toString();
  }

  static String tailwind(PaletteExportModel p, FormatOptions o) {
    final names = IdentifierNaming.unique(p.colors, IdentifierNaming.kebab, '-');
    final sb = StringBuffer('@theme {$_nl');
    for (var i = 0; i < p.colors.length; i++) {
      sb.write('  --color-${names[i]}: ${_cssValue(p.colors[i].color, o)};$_nl');
    }
    sb.write('}');
    return sb.toString();
  }

  static String json(PaletteExportModel p, FormatOptions o) {
    final names = IdentifierNaming.unique(p.colors, (n) => n, ' ');
    final map = <String, String>{};
    for (var i = 0; i < p.colors.length; i++) {
      final c = p.colors[i].color;
      map[names[i]] = c.isOpaque ? _hex(c, o) : ColorFormats.argbHex(c, o);
    }
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static String dart(PaletteExportModel p) {
    final cls = IdentifierNaming.pascal(p.name, 'Palette');
    final names = IdentifierNaming.unique(p.colors, (n) => IdentifierNaming.camel(n), '');
    final sb = StringBuffer("import 'package:flutter/material.dart';$_nl$_nl");
    sb.write('class $cls {$_nl');
    sb.write('  $cls._();$_nl$_nl');
    for (var i = 0; i < p.colors.length; i++) {
      sb.write('  static const Color ${names[i]} = ${ColorFormats.dart(p.colors[i].color)};$_nl');
    }
    sb.write('}');
    return sb.toString();
  }

  static String cSharp(PaletteExportModel p) {
    final cls = IdentifierNaming.pascal(p.name, 'Palette');
    final names = IdentifierNaming.unique(p.colors, (n) => IdentifierNaming.pascal(n), '');
    final sb = StringBuffer('using System.Windows.Media;$_nl$_nl');
    sb.write('public static class $cls$_nl{$_nl');
    for (var i = 0; i < p.colors.length; i++) {
      sb.write('    public static readonly Color ${names[i]} = ${ColorFormats.cSharpArgb(p.colors[i].color)};$_nl');
    }
    sb.write('}');
    return sb.toString();
  }

  static String _hex(Argb c, FormatOptions o) => ColorFormats.hex(c, o.copyWith(hexHash: true));

  static String _cssValue(Argb c, FormatOptions o) => c.isOpaque ? _hex(c, o) : ColorFormats.cssRgb(c);
}

/// Conversión de nombres libres a identificadores válidos de cada lenguaje.
abstract final class IdentifierNaming {
  /// Nombra cada color (los sin nombre como "Color N" según su posición) aplicando [transform]
  /// y resuelve colisiones añadiendo sufijo numérico.
  static List<String> unique(
      List<PaletteExportColor> colors, String Function(String) transform, String suffixSeparator) {
    final fallback = Texts.current;
    final used = <String>{};
    final result = <String>[];
    for (var i = 0; i < colors.length; i++) {
      final n = colors[i].name;
      final raw = n == null || n.trim().isEmpty ? fallback.colorNumberFallback(i + 1) : n.trim();
      var name = transform(raw);
      if (name.isEmpty) name = transform(fallback.colorNumberFallback(i + 1));
      var candidate = name;
      for (var k = 2; !used.add(candidate.toLowerCase()); k++) {
        candidate = '$name$suffixSeparator$k';
      }
      result.add(candidate);
    }
    return result;
  }

  static bool _isAsciiLetterOrDigit(int c) =>
      (c >= 0x30 && c <= 0x39) || (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);
  static bool _isUpper(int c) => c >= 0x41 && c <= 0x5A;
  static bool _isLower(int c) => c >= 0x61 && c <= 0x7A;

  static List<String> words(String text) {
    final normalized = removeDiacritics(text);
    final out = <String>[];
    final sb = StringBuffer();
    var last = -1;
    void flush() {
      if (sb.isNotEmpty) out.add(sb.toString());
      sb.clear();
      last = -1;
    }

    for (final ch in normalized.runes) {
      if (!_isAsciiLetterOrDigit(ch)) {
        flush();
        continue;
      }
      // Separa camelCase: "primaryDark" → primary, Dark
      if (_isUpper(ch) && sb.isNotEmpty && _isLower(last)) flush();
      sb.writeCharCode(ch);
      last = ch;
    }
    flush();
    return out;
  }

  static String kebab(String text) => words(text).map((w) => w.toLowerCase()).join('-');

  static String camel(String text, [String fallback = 'color']) {
    final p = pascal(text, fallback);
    var first = 0;
    while (first < p.length && _isUpper(p.codeUnitAt(first))) {
      first++;
    }
    // "Primary" → "primary"; "UIColor" → "uiColor"
    final lower = first <= 1 ? 1 : (first == p.length ? first : first - 1);
    return p.substring(0, lower).toLowerCase() + p.substring(lower);
  }

  static String pascal(String text, [String fallback = 'Color']) {
    var s = words(text).map((w) => w[0].toUpperCase() + w.substring(1)).join();
    if (s.isEmpty) s = fallback;
    final c0 = s.codeUnitAt(0);
    if (c0 >= 0x30 && c0 <= 0x39) s = fallback + s;
    return s;
  }

  static const _from = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖòóôõöÙÚÛÜùúûüÝýÿÑñÇçŠšŽžČčĆćĐđŘřŤťŇňĽľĹĺŔŕŚśŹźŻżŁłĄąĘęŃńŐőŰűĞğŞşİıĂăȘșȚțĀāĒēĪīŌōŪū';
  static const _to = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuYyyNnCcSsZzCcCcDdRrTtNnLlLlRrSsZzZzLlAaEeNnOoUuGgSsIiAaSsTtAaEeIiOoUu';

  /// Quita tildes y diacríticos de letras latinas (equivalente a la normalización FormD de .NET para los casos comunes).
  static String removeDiacritics(String text) {
    final sb = StringBuffer();
    for (final ch in text.runes) {
      final s = String.fromCharCode(ch);
      final i = _from.indexOf(s);
      sb.write(i >= 0 ? _to[i] : s);
    }
    return sb.toString();
  }
}
