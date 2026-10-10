import '../colors/argb.dart';
import 'color_formats.dart';

/// Formato de texto de un color individual. Se registra en [ColorFormatters].
class ColorFormatter {
  final String id;
  final String displayName;
  final String Function(Argb color, FormatOptions options) _format;

  const ColorFormatter(this.id, this.displayName, this._format);

  String format(Argb color, [FormatOptions options = FormatOptions.defaults]) => _format(color, options);
}

/// Registro de formatos de color. La UI construye sus menús iterando [all];
/// añadir un formato nuevo solo requiere registrarlo aquí.
abstract final class ColorFormatters {
  static const String hexId = 'hex';

  static final List<ColorFormatter> all = [
    ColorFormatter(hexId, 'HEX', (c, o) => ColorFormats.hex(c, o)),
    ColorFormatter('rgb', 'RGB', (c, _) => ColorFormats.rgb(c)),
    ColorFormatter('hsl', 'HSL', (c, _) => ColorFormats.hsl(c)),
    ColorFormatter('hsv', 'HSV', (c, _) => ColorFormats.hsv(c)),
    ColorFormatter('cmyk', 'CMYK*', (c, _) => ColorFormats.cmyk(c)),
    ColorFormatter('css-rgb', 'CSS rgb()', (c, _) => ColorFormats.cssRgb(c)),
    ColorFormatter('css-hsl', 'CSS hsl()', (c, _) => ColorFormats.cssHsl(c)),
    ColorFormatter('css-oklch', 'CSS oklch()', (c, _) => ColorFormats.cssOklch(c)),
    ColorFormatter('csharp-wpf', 'C# Color.FromRgb', (c, _) => ColorFormats.cSharpWpf(c)),
    ColorFormatter('csharp-argb', 'C# Color.FromArgb', (c, _) => ColorFormats.cSharpArgb(c)),
    ColorFormatter('xaml', 'XAML #AARRGGBB', (c, _) => ColorFormats.xaml(c)),
    ColorFormatter('dart', 'Dart / Flutter', (c, _) => ColorFormats.dart(c)),
    ColorFormatter('argb-int', '0xAARRGGBB', (c, _) => ColorFormats.argbInt(c)),
    ColorFormatter('all', 'HEX, RGB, HSL, HSV, CMYK', (c, o) => ColorFormats.copyAll(c, o)),
  ];

  static ColorFormatter get(String? id) {
    final key = id?.toLowerCase();
    return all.firstWhere((f) => f.id == key, orElse: () => all[0]);
  }
}
