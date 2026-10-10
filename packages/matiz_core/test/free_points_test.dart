import 'package:matiz_core/matiz_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final violetState = ColorState(246.1, 0.63, 0.74);
  double v(Argb c) => ColorMath.toHsv(c).v;

  test('Empty offsets give base only', () {
    final list = PaletteGenerator.freePoints(violetState, []);
    expect(list.length, 1);
    expect(list[0].isBase, isTrue);
    expect(list[0].color, violetState.argb);
  });

  test('Points are relative to the base', () {
    final list = PaletteGenerator.freePoints(violetState, [const PointOffset(120, 0)], balanceLightness: false);
    expect(list.length, 2);
    expectPrecision(list[1].wheelHue!, 6.1, 6);
    expectPrecision(list[1].wheelSaturation!, 0.63, 9);
    for (final g in list) {
      expectPrecision(v(g.color), v(violetState.argb), 6);
    }
    expect(list[1].label, '1');
  });

  test('Labels are consecutive numbers', () {
    final list = PaletteGenerator.freePoints(violetState, [const PointOffset(90, 0), const PointOffset(180, 0)]);
    expect(list.map((g) => g.label), ['Base', '1', '2']);
  });

  test('Negative saturation delta clamps to gamut', () {
    final list = PaletteGenerator.freePoints(violetState, [const PointOffset(0, -2), const PointOffset(10, 0.5)],
        balanceLightness: false);
    expectPrecision(list[1].wheelSaturation!, 0, 9);
    expectPrecision(list[2].wheelSaturation!, 1, 9);
  });

  for (final (hd, sd) in const [(0.0, 0.0), (120.0, 0.0), (180.0, -0.3), (-45.0, 0.2)]) {
    test('Balanced points match base lightness ($hd, $sd)', () {
      final baseL = PaletteGenerator.lightnessOf(violetState.hue, violetState.saturation, violetState.value);
      final g = PaletteGenerator.freePoints(violetState, [PointOffset(hd, sd)])[1];
      final reachable = g.wheelSaturation! > 0 && PaletteGenerator.lightnessOf(g.wheelHue!, g.wheelSaturation!, 1) >= baseL;
      if (reachable) {
        expectInRange((ColorMath.toOklab(g.color).l - baseL).abs(), 0, 0.01);
      } else {
        expectPrecision(v(g.color), 1, 2);
      }
    });
  }

  test('Points follow base rotation rigidly', () {
    final a = PaletteGenerator.freePoints(violetState, [const PointOffset(120, 0)], balanceLightness: false);
    final b = PaletteGenerator.freePoints(ColorState(251.1, 0.63, 0.74), [const PointOffset(120, 0)],
        balanceLightness: false);
    expectPrecision(b[1].wheelHue!, 11.1, 6);
    expectPrecision(a[1].wheelHue!, 6.1, 6);
  });

  test('Explicit value delta reproduces exact value and is immune to balance', () {
    final list = PaletteGenerator.freePoints(violetState, [const PointOffset(120, 0, -0.04)], balanceLightness: false);
    expectPrecision(v(list[1].color), violetState.value - 0.04, 2);
    final w = PaletteGenerator.freePoints(violetState, [const PointOffset(120, 0, 0.25)], balanceLightness: true);
    final wo = PaletteGenerator.freePoints(violetState, [const PointOffset(120, 0, 0.25)], balanceLightness: false);
    expect(w[1].color, wo[1].color);
  });

  test('Explicit value delta clamps to gamut', () {
    final list = PaletteGenerator.freePoints(violetState, [const PointOffset(0, 0, -1), const PointOffset(0, 0, 2)]);
    expectPrecision(v(list[1].color), 0, 9);
    expectPrecision(v(list[2].color), 1, 9);
  });

  group('FreePointSet (lógica del modo Personalizado)', () {
    test('"+" opuesto y luego al lado del último sin solaparse', () {
      final set = FreePointSet();
      set.add(set.nextAddPosition());
      expect(set.offsets.single.hueDelta, 180);
      set.add(set.nextAddPosition());
      set.add(set.nextAddPosition());
      expect(set.offsets.map((o) => o.hueDelta), [180, 210, 240]);
    });

    test('"+" en Triádica convierte la armonía y añade +270°', () {
      final set = FreePointSet()..fromHarmony(HarmonyKind.triadic);
      set.add(set.nextAddPosition());
      expect(set.offsets.map((o) => o.hueDelta), [120, 240, 270]);
    });

    test('Monocromática no aporta puntos', () {
      expect(FreePointSet.harmonyPoints(HarmonyKind.monochromatic), isEmpty);
    });

    test('Límite de 64', () {
      final set = FreePointSet();
      for (var i = 0; i < 64; i++) {
        expect(set.add(PointOffset(i.toDouble(), 0)), isTrue);
      }
      expect(set.add(const PointOffset(1, 0)), isFalse);
      expect(set.length, 64);
    });

    test('Color con brillo propio se reproduce exacto', () {
      final principal = ColorState.fromArgb(const Argb.fromRgb(82, 70, 188));
      final set = FreePointSet()..add(FreePointSet.offsetForColor(principal, const Argb.fromRgb(0xE3, 0x4A, 0x63)));
      final list = PaletteGenerator.freePoints(principal, set.offsets);
      expect(list[1].color.toHex(), '#E34A63');
    });

    test('Quitar el principal promueve al siguiente con posiciones absolutas', () {
      final principal = ColorState(0, 1, 1);
      final set = FreePointSet()
        ..add(const PointOffset(30, 0))
        ..add(const PointOffset(90, 0));
      final generated = PaletteGenerator.freePoints(principal, set.offsets, balanceLightness: false).map((g) => g.color).toList();
      final promoted = set.promoteFirst(generated)!;
      expect(promoted, generated[1]);
      final newState = ColorState.fromArgb(promoted, principal);
      final after = PaletteGenerator.freePoints(newState, set.offsets, balanceLightness: false);
      expectInRange((after[1].wheelHue! - 90).abs(), 0, 0.5);
    });
  });
}
