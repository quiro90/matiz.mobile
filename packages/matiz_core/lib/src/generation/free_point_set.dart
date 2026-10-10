import '../colors/argb.dart';
import '../colors/color_math.dart';
import '../colors/color_state.dart';
import '../util/num_util.dart';
import 'harmony_kind.dart';
import 'palette_generator.dart';

/// Conjunto del modo Personalizado: desfases de los puntos secundarios relativos al principal
/// (el color actual). Port de la lógica de `MainViewModel.GeneratedPalettes` de desktop.
class FreePointSet {
  /// Límite de puntos secundarios (regla global de 64 colores por paleta).
  static const int maxPoints = 64;

  final List<PointOffset> _offsets = [];

  List<PointOffset> get offsets => List.unmodifiable(_offsets);
  int get length => _offsets.length;
  bool get isEmpty => _offsets.isEmpty;
  bool get isFull => _offsets.length >= maxPoints;

  void clear() => _offsets.clear();

  void replaceAll(Iterable<PointOffset> items) {
    _offsets
      ..clear()
      ..addAll(items);
  }

  /// Desfases canónicos de una armonía (sin el base; Monocromática no aporta puntos).
  static List<PointOffset> harmonyPoints(HarmonyKind kind) => kind == HarmonyKind.monochromatic
      ? []
      : [for (final a in PaletteGenerator.harmonyOffsets(kind).where((a) => a != 0)) PointOffset(a.toDouble(), 0)];

  /// Conversión Armonías → Personalizado: reemplaza el conjunto por la figura canónica.
  void fromHarmony(HarmonyKind kind) => replaceAll(harmonyPoints(kind));

  /// Desfase de una posición absoluta de la rueda respecto del principal.
  static PointOffset offsetAt(ColorState principal, double hue, double saturation) =>
      PointOffset(ColorMath.normalizeHue(hue - principal.hue), clampD(saturation, 0, 1) - principal.saturation);

  /// Desfase con brillo propio que reproduce exactamente [c] (captura, imagen, cámara, paleta).
  static PointOffset offsetForColor(ColorState principal, Argb c) {
    final hsv = ColorMath.toHsv(c);
    return PointOffset(
      ColorMath.normalizeHue(hsv.h - principal.hue),
      clampD(hsv.s - principal.saturation, -1, 1),
      clampD(hsv.v - principal.value, -1, 1),
    );
  }

  /// Añade un punto; devuelve false si se alcanzó el límite.
  bool add(PointOffset o) {
    if (isFull) return false;
    _offsets.add(o);
    return true;
  }

  /// Mueve un punto conservando su Δbrillo propio.
  void move(int index, ColorState principal, double hue, double saturation) {
    if (index < 0 || index >= _offsets.length || hue.isNaN) return;
    final o = offsetAt(principal, hue, saturation);
    _offsets[index] = PointOffset(o.hueDelta, o.satDelta, _offsets[index].valueDelta);
  }

  void removeAt(int index) {
    if (index >= 0 && index < _offsets.length) _offsets.removeAt(index);
  }

  /// Posición del punto que añade el botón "+": opuesto al principal si no hay secundarios; si los hay,
  /// al lado del último (hue +30° por paso, conservando su saturación) hasta no solaparse.
  PointOffset nextAddPosition() {
    if (_offsets.isEmpty) return const PointOffset(180.0, 0.0);
    var hue = _offsets.last.hueDelta;
    final sat = _offsets.last.satDelta;
    for (var i = 0; i < 12; i++) {
      hue = ColorMath.normalizeHue(hue + 30.0);
      if (_isFreePosition(hue)) return PointOffset(hue, sat);
    }
    return PointOffset(ColorMath.normalizeHue(hue + 30.0), sat);
  }

  bool _isFreePosition(double hueDelta) {
    if (angularDistance(hueDelta, 0) < 10.0) return false;
    for (final o in _offsets) {
      if (angularDistance(o.hueDelta, hueDelta) < 10.0) return false;
    }
    return true;
  }

  static double angularDistance(double a, double b) {
    final d = ColorMath.normalizeHue(a - b).abs();
    return d > 180 ? 360 - d : d;
  }

  /// Quita el principal: promueve al primer secundario. [generated] son los colores actuales del conjunto
  /// (índice 0 = principal). Devuelve el color que pasa a ser el actual, o null si no hay secundarios.
  /// Los demás puntos conservan sus posiciones absolutas.
  Argb? promoteFirst(List<Argb> generated) {
    if (_offsets.isEmpty || generated.length < 2) return null;
    final k = _offsets[0];
    final promoted = generated[1];
    final promotedV = ColorMath.toHsv(promoted).v;
    for (var i = 1; i < _offsets.length; i++) {
      final o = _offsets[i];
      _offsets[i] = PointOffset(
        ColorMath.normalizeHue(o.hueDelta - k.hueDelta),
        o.satDelta - k.satDelta,
        o.valueDelta != null ? clampD(ColorMath.toHsv(generated[i + 1]).v - promotedV, -1, 1) : null,
      );
    }
    _offsets.removeAt(0);
    return promoted;
  }
}
