import '../colors/argb.dart';
import '../colors/color_math.dart';
import '../colors/color_spaces.dart';
import '../colors/color_state.dart';
import '../localization/texts.dart';
import '../util/num_util.dart';
import 'design_scale.dart';
import 'generated_color.dart';
import 'harmony_kind.dart';

/// Desfase relativo de un punto libre respecto del principal.
class PointOffset {
  final double hueDelta;
  final double satDelta;

  /// Δbrillo propio (null = se ajusta con "Equilibrar" como las armonías).
  final double? valueDelta;

  const PointOffset(this.hueDelta, this.satDelta, [this.valueDelta]);

  PointOffset copyWith({double? hueDelta, double? satDelta}) =>
      PointOffset(hueDelta ?? this.hueDelta, satDelta ?? this.satDelta, valueDelta);
}

abstract final class PaletteGenerator {
  static String harmonyName(HarmonyKind kind) => Texts.current.harmonyName(kind);

  static List<int> harmonyOffsets(HarmonyKind kind) => switch (kind) {
        HarmonyKind.complementary => const [0, 180],
        HarmonyKind.analogous => const [-60, -30, 0, 30, 60],
        HarmonyKind.splitComplementary => const [0, 150, 210],
        HarmonyKind.triadic => const [0, 120, 240],
        HarmonyKind.tetradic => const [0, 90, 180, 270],
        HarmonyKind.monochromatic => const [0],
      };

  /// Armonía a partir de un color canónico (se convierte a coordenadas del selector).
  static List<GeneratedColor> harmonyFromArgb(Argb baseColor, HarmonyKind kind,
          {ScaleAnchorMode anchor = ScaleAnchorMode.fixed500, bool balanceLightness = true}) =>
      harmony(ColorState.fromArgb(baseColor), kind, anchor: anchor, balanceLightness: balanceLightness);

  /// Armonías geométricas: giran el hue de la rueda (HSV) el ángulo exacto y conservan la saturación;
  /// con [balanceLightness] se ajusta solo el brillo de cada color para igualar la L OKLab del base.
  /// Monocromática toma 5 pasos de la Design Scale.
  static List<GeneratedColor> harmony(ColorState baseState, HarmonyKind kind,
      {ScaleAnchorMode anchor = ScaleAnchorMode.fixed500, bool balanceLightness = true}) {
    final baseColor = baseState.argb;
    if (kind == HarmonyKind.monochromatic) return monochromatic(baseColor, anchor);

    final targetL = lightnessOf(baseState.hue, baseState.saturation, baseState.value);
    return harmonyOffsets(kind).map((d) {
      if (d == 0) {
        return GeneratedColor(Texts.current.base, baseColor,
            isBase: true, wheelHue: baseState.hue, wheelSaturation: baseState.saturation);
      }
      final s = clampD(baseState.saturation, 0, 1);
      final h = ColorMath.normalizeHue(baseState.hue + d);
      final v = balanceLightness ? valueForLightness(h, s, targetL) : baseState.value;
      final c = ColorMath.fromHsv(h, s, v, baseState.alpha);
      return GeneratedColor(d > 0 ? '+$d°' : '$d°', c, wheelHue: h, wheelSaturation: s);
    }).toList();
  }

  /// Modo Personalizado: base + un color por cada desfase relativo respecto del principal.
  static List<GeneratedColor> freePoints(ColorState baseState, List<PointOffset> offsets,
      {bool balanceLightness = true}) {
    final baseColor = baseState.argb;
    final targetL = lightnessOf(baseState.hue, baseState.saturation, baseState.value);
    final list = <GeneratedColor>[
      GeneratedColor(Texts.current.base, baseColor,
          isBase: true, wheelHue: baseState.hue, wheelSaturation: baseState.saturation),
    ];
    for (final o in offsets) {
      final s = clampD(baseState.saturation + o.satDelta, 0, 1);
      final h = ColorMath.normalizeHue(baseState.hue + o.hueDelta);
      final dv = o.valueDelta;
      final v = dv != null
          ? clampD(baseState.value + dv, 0, 1)
          : balanceLightness
              ? valueForLightness(h, s, targetL)
              : baseState.value;
      final c = ColorMath.fromHsv(h, s, v, baseState.alpha);
      list.add(GeneratedColor(list.length.toString(), c, wheelHue: h, wheelSaturation: s));
    }
    return list;
  }

  /// OKLab L de un color HSV continuo (sin redondear a 8 bits).
  static double lightnessOf(double h, double s, double v) {
    final rgb = ColorMath.hsvToRgb(h, s, v);
    return ColorMath.linearToOklab(LinearRgb(
      ColorMath.srgbToLinear(rgb.r),
      ColorMath.srgbToLinear(rgb.g),
      ColorMath.srgbToLinear(rgb.b),
    )).l;
  }

  /// Brillo (HSV V) con el que (h, s) alcanza la luminosidad [targetL] (búsqueda binaria; si no es alcanzable, 0 o 1).
  static double valueForLightness(double h, double s, double targetL) {
    if (lightnessOf(h, s, 1) <= targetL) return 1;
    var lo = 0.0, hi = 1.0;
    for (var i = 0; i < 40; i++) {
      final mid = (lo + hi) / 2;
      if (lightnessOf(h, s, mid) < targetL) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }

  static List<GeneratedColor> monochromatic(Argb baseColor, [ScaleAnchorMode anchor = ScaleAnchorMode.fixed500]) {
    final scale = DesignScale.generate(baseColor, anchor);
    final anchorIndex = scale.indexWhere((s) => s.isBase);
    const picks = [1, 3, 5, 7, 9];
    final nearest = stableSorted<int>(picks, (a, b) => (a - anchorIndex).abs().compareTo((b - anchorIndex).abs())).first;
    final idx = picks.map((i) => i == nearest ? anchorIndex : i).toSet().toList()..sort();
    return [for (final i in idx) scale[i]];
  }

  /// Tint N% = mezcla sRGB con blanco al N% (definición Sass/Bootstrap).
  static Argb tint(Argb c, double amount) =>
      Argb(c.a, _mix(c.r, 255, amount), _mix(c.g, 255, amount), _mix(c.b, 255, amount));

  /// Shade N% = mezcla sRGB con negro al N%.
  static Argb shade(Argb c, double amount) =>
      Argb(c.a, _mix(c.r, 0, amount), _mix(c.g, 0, amount), _mix(c.b, 0, amount));

  /// Tints 50…10%, base, Shades 10…50%.
  static List<GeneratedColor> tintsAndShades(Argb c) {
    final t = Texts.current;
    final list = <GeneratedColor>[];
    for (var p = 50; p >= 10; p -= 10) {
      list.add(GeneratedColor(t.tint(p), tint(c, p / 100.0)));
    }
    list.add(GeneratedColor(t.base, c, isBase: true));
    for (var p = 10; p <= 50; p += 10) {
      list.add(GeneratedColor(t.shade(p), shade(c, p / 100.0)));
    }
    return list;
  }

  /// Neutros: mismas luminosidades que la Design Scale, hue del base y croma muy baja (≤ 0.015).
  static List<GeneratedColor> neutrals(Argb baseColor) {
    final lch = ColorMath.toOklch(baseColor);
    const lightness = DesignScale.referenceL;
    final chroma = lch.c < 0.002 ? 0.0 : (lch.c * 0.12 < 0.015 ? lch.c * 0.12 : 0.015);
    return [
      for (var i = 0; i < DesignScale.steps.length; i++)
        GeneratedColor(
          DesignScale.steps[i].toString(),
          chroma == 0 ? _gray(lightness[i]) : ColorMath.fromOklchGamutMapped(Oklch(lightness[i], chroma, lch.h)),
        ),
    ];
  }

  static Argb _gray(double l) {
    final v = Argb.toByte(ColorMath.linearToSrgb(clampD(l * l * l, 0, 1)));
    return Argb.fromRgb(v, v, v);
  }

  static int _mix(int from, int to, double amount) => clampD(roundAway(from + (to - from) * amount), 0, 255).toInt();
}
