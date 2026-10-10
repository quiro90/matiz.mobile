import 'dart:math' as math;

import 'package:matiz_core/matiz_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  const violet = Argb.fromRgb(82, 70, 188);

  test('Rounding is away from zero at midpoint', () {
    expect(Argb.toByte(127.5 / 255), 128);
    expect(Argb.toByte(-0.1), 0);
    expect(Argb.toByte(1.2), 255);
  });

  test('Reference conversions of #5246BC', () {
    expect(ColorFormats.hex(violet), '#5246BC');
    expect(ColorFormats.rgb(violet), '82, 70, 188');
    expect(ColorFormats.hsl(violet), '246°, 47%, 51%');
    expect(ColorFormats.hsv(violet), '246°, 63%, 74%');
    expect(ColorFormats.cmyk(violet), '56%, 63%, 0%, 26%');
  });

  for (final row in const [
    ['#FF0000', '0°, 100%, 50%', '0°, 100%, 100%', '0%, 100%, 100%, 0%'],
    ['#00FF00', '120°, 100%, 50%', '120°, 100%, 100%', '100%, 0%, 100%, 0%'],
    ['#0000FF', '240°, 100%, 50%', '240°, 100%, 100%', '100%, 100%, 0%, 0%'],
    ['#FFFFFF', '0°, 0%, 100%', '0°, 0%, 100%', '0%, 0%, 0%, 0%'],
    ['#000000', '0°, 0%, 0%', '0°, 0%, 0%', '0%, 0%, 0%, 100%'],
    ['#808080', '0°, 0%, 50%', '0°, 0%, 50%', '0%, 0%, 0%, 50%'],
  ]) {
    test('Primaries and neutrals ${row[0]}', () {
      final c = ColorParser.parse(row[0])!;
      expect(ColorFormats.hsl(c), row[1]);
      expect(ColorFormats.hsv(c), row[2]);
      expect(ColorFormats.cmyk(c), row[3]);
    });
  }

  test('Exhaustive round trip HSV and HSL (16.7 M colores)', () {
    for (var r = 0; r < 256; r++) {
      for (var g = 0; g < 256; g++) {
        for (var b = 0; b < 256; b++) {
          final c = Argb.fromRgb(r, g, b);
          final hsv = ColorMath.toHsv(c);
          final back = ColorMath.fromHsv(hsv.h, hsv.s, hsv.v);
          if (back != c) fail('HSV $c → $back');
          final hsl = ColorMath.toHsl(c);
          final back2 = ColorMath.fromHsl(hsl.h, hsl.s, hsl.l);
          if (back2 != c) fail('HSL $c → $back2');
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('Oklab round trip sampled', () {
    final rnd = math.Random(7);
    for (var i = 0; i < 200000; i++) {
      final c = Argb.fromUInt32(0xFF000000 | rnd.nextInt(1 << 24));
      final back = ColorMath.fromLinear(ColorMath.oklabToLinear(ColorMath.oklchToOklab(ColorMath.toOklch(c))));
      expect(back, c);
    }
  });

  test('OKLCH of white and black', () {
    final white = ColorMath.toOklch(const Argb.fromRgb(255, 255, 255));
    expectPrecision(white.l, 1.0, 3);
    expect(white.c < 1e-4, isTrue);
    expectPrecision(ColorMath.toOklch(const Argb.fromRgb(0, 0, 0)).l, 0.0, 6);
  });

  test('Gamut mapping keeps lightness and hue', () {
    final mapped = ColorMath.fromOklchGamutMapped(const Oklch(0.7, 0.4, 150));
    final lch = ColorMath.toOklch(mapped);
    expectPrecision(lch.l, 0.7, 2);
    expectInRange((lch.h - 150).abs(), 0, 2);
    expect(lch.c < 0.4, isTrue);
  });

  test('Gray equivalent preserves perceptual lightness', () {
    final gray = ColorMath.grayEquivalent(violet);
    expect(gray.r, gray.g);
    expect(gray.g, gray.b);
    expectInRange((ColorMath.toOklab(gray).l - ColorMath.toOklab(violet).l).abs(), 0, 0.005);
  });

  test('Achromatic state preserves previous hue', () {
    final v = ColorState.fromArgb(violet);
    final gray = ColorState.fromArgb(const Argb.fromRgb(128, 128, 128), v);
    expectPrecision(gray.hue, v.hue, 9);
    expect(gray.saturation, 0);
    expect(gray.argb, const Argb.fromRgb(128, 128, 128));

    final black = ColorState.fromArgb(const Argb.fromRgb(0, 0, 0), v);
    expectPrecision(black.hue, v.hue, 9);
    expectPrecision(black.saturation, v.saturation, 9);
  });

  test('Darken to black and back recovers color', () {
    final s = ColorState.fromArgb(violet);
    final dark = s.withValue(0);
    expect(dark.argb, const Argb.fromRgb(0, 0, 0));
    expect(dark.withValue(s.value).argb, violet);
  });

  test('Brightness 37% gives #29235E', () {
    expect(ColorState.fromArgb(violet).withValue(0.37).argb.toHex(), '#29235E');
  });

  test('Wheel edge at 120 is pure green and center is white', () {
    final p = WheelMapping.fromPoint(math.sin(120 * math.pi / 180) * 100, -math.cos(120 * math.pi / 180) * 100, 100, 1);
    expect(ColorState(p.hue, p.saturation, 1).argb.toHex(), '#00FF00');
    final c = WheelMapping.fromPoint(0, 0, 100, 1);
    expect(ColorState(0, c.saturation, 1).argb.toHex(), '#FFFFFF');
  });

  for (final focus in const [-1.0, 0.0, 0.6, 1.0]) {
    test('Wheel mapping round trip focus=$focus', () {
      final gamma = WheelMapping.gammaFromFocus(focus);
      for (var hue = 0.0; hue < 360; hue += 13.7) {
        for (var sat = 0.05; sat <= 1; sat += 0.05) {
          final pt = WheelMapping.toPoint(hue, sat, gamma);
          final back = WheelMapping.fromPoint(pt.x * 200, pt.y * 200, 200, gamma);
          expectPrecision(back.saturation, sat, 9);
          expectInRange((((back.hue - hue + 540) % 360) - 180).abs(), 0, 1e-6);
        }
      }
    });
  }

  test('Pastel focus gives more than half radius to low saturation', () {
    final pt = WheelMapping.toPoint(0, 0.30, WheelMapping.gammaFromFocus(1));
    expect(math.sqrt(pt.x * pt.x + pt.y * pt.y) > 0.5, isTrue);
  });

  test('Wheel clamps outside to full saturation', () {
    expect(WheelMapping.fromPoint(300, 0, 100, 1).saturation, 1);
  });
}
