import 'dart:math' as math;
import 'dart:typed_data';

import 'package:matiz_core/matiz_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  const violet = Argb.fromRgb(82, 70, 188);
  const scaleInputs = [
    '#5246BC', '#FACC15', '#22C55E', '#000000', '#FFFFFF', '#FF0000', '#0000FF', '#808080',
    '#F0F0FF', '#101018', '#00FFFF', '#FF00FF', '#8B4513', '#FFF8E1',
  ];
  const rotations = [
    HarmonyKind.complementary, HarmonyKind.analogous, HarmonyKind.splitComplementary,
    HarmonyKind.triadic, HarmonyKind.tetradic,
  ];

  test('Tint and shade 50', () {
    expect(PaletteGenerator.tint(violet, 0.5).toHex(), '#A9A3DE');
    expect(PaletteGenerator.shade(violet, 0.5).toHex(), '#29235E');
  });

  test('Tints and shades have base in the middle', () {
    final list = PaletteGenerator.tintsAndShades(violet);
    expect(list.length, 11);
    expect(list[5].isBase, isTrue);
    expect(list[5].color, violet);
  });

  for (final (kind, count) in const [
    (HarmonyKind.complementary, 2), (HarmonyKind.analogous, 5), (HarmonyKind.splitComplementary, 3),
    (HarmonyKind.triadic, 3), (HarmonyKind.tetradic, 4), (HarmonyKind.monochromatic, 5),
  ]) {
    test('Harmony $kind size $count with base', () {
      final list = PaletteGenerator.harmonyFromArgb(violet, kind);
      expect(list.length, count);
      expect(list.any((g) => g.isBase && g.color == violet), isTrue);
    });
  }

  for (final hex in scaleInputs) {
    test('Balanced harmonies match lightness when reachable $hex', () {
      final c = ColorParser.parse(hex)!;
      final baseL = ColorMath.toOklab(c).l;
      for (final kind in rotations) {
        for (final g in PaletteGenerator.harmonyFromArgb(c, kind).where((g) => !g.isBase)) {
          final reachable = PaletteGenerator.lightnessOf(g.wheelHue!, g.wheelSaturation!, 1) >= baseL;
          if (reachable) {
            expectInRange((ColorMath.toOklab(g.color).l - baseL).abs(), 0, 0.01);
          } else {
            expectPrecision(ColorMath.toHsv(g.color).v, 1, 2);
          }
        }
      }
    });
  }

  test('Triadic is exact geometry on the wheel', () {
    final list = PaletteGenerator.harmony(ColorState(246.1, 0.63, 0.74), HarmonyKind.triadic);
    expectPrecision(list[1].wheelHue!, 6.1, 6);
    expectPrecision(list[2].wheelHue!, 126.1, 6);
    for (final g in list) {
      expectPrecision(g.wheelSaturation!, 0.63, 9);
    }
  });

  test('Lowering brightness keeps hue and saturation', () {
    for (final kind in rotations) {
      final bright = PaletteGenerator.harmony(ColorState(246.1, 0.63, 0.74), kind);
      final dark = PaletteGenerator.harmony(ColorState(246.1, 0.63, 0.15), kind);
      for (var i = 0; i < bright.length; i++) {
        expectPrecision(dark[i].wheelHue!, bright[i].wheelHue!, 9);
        expectPrecision(dark[i].wheelSaturation!, bright[i].wheelSaturation!, 9);
      }
    }
  });

  test('Unbalanced harmonies keep base brightness', () {
    for (final g in PaletteGenerator.harmony(ColorState(30, 0.9, 0.5), HarmonyKind.tetradic, balanceLightness: false)) {
      expectInRange((ColorMath.toHsv(g.color).v - 0.5).abs(), 0, 0.003);
    }
  });

  for (final hex in scaleInputs) {
    test('Design scale strictly decreasing and anchored $hex', () {
      final c = ColorParser.parse(hex)!;
      for (final mode in ScaleAnchorMode.values) {
        final scale = DesignScale.generate(c, mode);
        expect(scale.length, 11);
        expect(scale.where((s) => s.isBase).length, 1);
        expect(scale.firstWhere((s) => s.isBase).color, c);
        final l = scale.map((s) => ColorMath.toOklab(s.color).l).toList();
        for (var i = 1; i < l.length; i++) {
          expect(l[i] < l[i - 1], isTrue, reason: '$hex $mode: L[$i]=${l[i]} >= L[${i - 1}]=${l[i - 1]}');
        }
      }
    });
  }

  test('Design scale base at 500', () {
    final scale = DesignScale.generate(violet, ScaleAnchorMode.fixed500);
    expect(scale[5].label, '500');
    expect(scale[5].color, violet);
  });

  test('Automatic anchor places light color on light step with distinct steps', () {
    final scale = DesignScale.generate(ColorParser.parse('#FACC15')!, ScaleAnchorMode.automatic);
    final anchor = scale.indexWhere((s) => s.isBase);
    expect(anchor <= 3, isTrue, reason: 'anchor ${scale[anchor].label}');
    final l = scale.map((s) => ColorMath.toOklab(s.color).l).toList();
    for (var i = 1; i < l.length; i++) {
      expect(l[i - 1] - l[i] >= 0.019, isTrue);
    }
  });

  test('Neutrals have low chroma and gray input gives pure grays', () {
    for (final g in PaletteGenerator.neutrals(violet)) {
      expect(ColorMath.toOklch(g.color).c <= 0.02, isTrue);
    }
    for (final g in PaletteGenerator.neutrals(const Argb.fromRgb(128, 128, 128))) {
      expect(g.color.r, g.color.g);
      expect(g.color.g, g.color.b);
    }
  });

  Uint8List threeBlocks(int w, int h) {
    final px = Uint8List(w * h * 4);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final o = (y * w + x) * 4;
        final (r, g, b) = x < 150 ? (82, 70, 188) : y < 100 ? (255, 138, 0) : (34, 197, 94);
        px[o] = b;
        px[o + 1] = g;
        px[o + 2] = r;
        px[o + 3] = 255;
      }
    }
    return px;
  }

  test('Dominant colors are deterministic and find main colors', () {
    final px = threeBlocks(300, 200);
    final a = DominantColors.extract(px, 300, 200, 1200, 3, layout: PixelLayout.bgra);
    final b = DominantColors.extract(px, 300, 200, 1200, 3, layout: PixelLayout.bgra);
    expect(a, b);
    expect(a[0], violet);
    expect(a, contains(const Argb.fromRgb(255, 138, 0)));
    expect(a, contains(const Argb.fromRgb(34, 197, 94)));
  });

  test('Dominant colors large image is fast', () {
    const w = 6000, h = 4000;
    final px = Uint8List(w * h * 4);
    final r = math.Random(1);
    for (var i = 0; i < px.length; i++) {
      px[i] = r.nextInt(256);
    }
    final sw = Stopwatch()..start();
    final result = DominantColors.extract(px, w, h, w * 4, 6);
    sw.stop();
    expect(result, isNotEmpty);
    expect(sw.elapsedMilliseconds < 2000, isTrue, reason: '${sw.elapsedMilliseconds} ms');
  });

  test('Dominant colors clamps count to 1 and 64', () {
    final px = threeBlocks(300, 200);
    expect(DominantColors.extract(px, 300, 200, 1200, 0, layout: PixelLayout.bgra).length, 1);

    const sw = 256, sh = 128;
    final stripes = Uint8List(sw * sh * 4);
    for (var y = 0; y < sh; y++) {
      for (var x = 0; x < sw; x++) {
        final o = (y * sw + x) * 4;
        final v = x * 64 ~/ sw;
        stripes[o] = v;
        stripes[o + 1] = v;
        stripes[o + 2] = v;
        stripes[o + 3] = 255;
      }
    }
    expect(DominantColors.extract(stripes, sw, sh, sw * 4, 64).toSet().length, 64);
    expectInRange(DominantColors.extract(px, 300, 200, 1200, 70).length, 1, DominantColors.maxCount);
  });
}
