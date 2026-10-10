import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:matiz_core/matiz_core.dart';
import 'package:test/test.dart';

/// Paridad exacta con Matiz desktop: compara contra `fixtures/golden.json`, generado con
/// Matiz.Core (C#) por `tool/golden`. Cualquier diferencia de un solo byte falla.
void main() {
  final golden = jsonDecode(File('test/fixtures/golden.json').readAsStringSync()) as Map<String, dynamic>;
  List<String> hexes(List<GeneratedColor> g) => [for (final x in g) x.color.toHex()];

  test('DotNetRandom(1234) reproduce System.Random', () {
    final ref = golden['random1234'] as Map<String, dynamic>;
    final r = DotNetRandom(1234);
    expect([for (var i = 0; i < 10; i++) r.next(1000)], ref['next1000']);
    expect([for (var i = 0; i < 10; i++) r.nextDouble()], ref['nextDouble']);
  });

  test('2000 colores: conversiones, escala, armonías, tints, neutros', () {
    final failures = <String>[];
    for (final c in golden['colors'] as List) {
      final m = c as Map<String, dynamic>;
      final argb = ColorParser.parse(m['hex'] as String)!;
      void check(String what, Object actual, Object? expected) {
        if (jsonEncode(actual) != jsonEncode(expected)) failures.add('${m['hex']} $what: $actual ≠ $expected');
      }

      check('hsl', ColorFormats.hsl(argb), m['hsl']);
      check('hsv', ColorFormats.hsv(argb), m['hsv']);
      check('cmyk', ColorFormats.cmyk(argb), m['cmyk']);
      check('oklch', ColorFormats.oklch(argb), m['oklch']);
      check('gray', ColorMath.grayEquivalent(argb).toHex(), m['gray']);
      check('grayMix25', ColorMath.mixToGray(argb, 0.25).toHex(), m['grayMix25']);
      check('grayMix50', ColorMath.mixToGray(argb, 0.50).toHex(), m['grayMix50']);
      check('grayMix57', ColorMath.mixToGray(argb, 0.57).toHex(), m['grayMix57']);
      check('grayMix100', ColorMath.mixToGray(argb, 1.0).toHex(), m['grayMix100']);
      check('scale500', hexes(DesignScale.generate(argb, ScaleAnchorMode.fixed500)), m['scale500']);
      check('scaleAuto', hexes(DesignScale.generate(argb, ScaleAnchorMode.automatic)), m['scaleAuto']);
      check('tintsShades', hexes(PaletteGenerator.tintsAndShades(argb)), m['tintsShades']);
      check('neutrals', hexes(PaletteGenerator.neutrals(argb)), m['neutrals']);
      final harm = m['harmony'] as Map<String, dynamic>;
      for (final k in HarmonyKind.values) {
        final name = k.name[0].toUpperCase() + k.name.substring(1);
        check('harmony $name', hexes(PaletteGenerator.harmonyFromArgb(argb, k)), harm[name]);
        check('harmony ${name}Raw', hexes(PaletteGenerator.harmonyFromArgb(argb, k, balanceLightness: false)),
            harm['${name}Raw']);
      }
      if (failures.length > 20) break;
    }
    expect(failures, isEmpty, reason: failures.take(20).join('\n'));
  });

  test('Puntos libres', () {
    final list = PaletteGenerator.freePoints(ColorState(246.1, 0.63, 0.74), const [
      PointOffset(120, 0),
      PointOffset(180, -0.3),
      PointOffset(-45, 0.2),
      PointOffset(30, 0.1, -0.2),
      PointOffset(200, 0.5, 0.3),
    ]);
    expect(hexes(list), golden['freePoints']);
  });

  test('Extracción de colores idéntica (BGRA sintético)', () {
    for (final img in golden['extraction'] as List) {
      final m = img as Map<String, dynamic>;
      final w = m['w'] as int, h = m['h'] as int;
      final px = Uint8List.fromList(base64Decode(m['bgra'] as String));
      final result = m['result'] as Map<String, dynamic>;
      for (final e in result.entries) {
        final got = DominantColors.extract(px, w, h, w * 4, int.parse(e.key), layout: PixelLayout.bgra);
        expect(got.map((c) => c.toHex()).toList(), e.value, reason: '${w}x$h count=${e.key}');
      }
    }
  });

  test('Exportación de código idéntica', () {
    const model = PaletteExportModel('Mi Paleta Bonita', [
      PaletteExportColor('Primary', Argb.fromRgb(82, 70, 188)),
      PaletteExportColor('Secondary', Argb.fromRgb(255, 138, 0)),
      PaletteExportColor('Árbol Ñandú', Argb.fromRgb(1, 2, 3)),
      PaletteExportColor(null, Argb.fromRgb(4, 5, 6)),
      PaletteExportColor('primary', Argb.fromRgb(7, 8, 9)),
      PaletteExportColor('UIColor', Argb(128, 10, 20, 30)),
      PaletteExportColor('3d shadow', Argb.fromRgb(11, 12, 13)),
      PaletteExportColor('primaryDark', Argb.fromRgb(14, 15, 16)),
    ]);
    final export = golden['export'] as Map<String, dynamic>;
    for (final f in PaletteFormatters.all) {
      expect(f.format(model), export[f.id], reason: f.id);
    }
  });
}
