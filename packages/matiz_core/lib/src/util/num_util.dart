import 'dart:math' as math;

/// Utilidades numéricas que replican la semántica de .NET para garantizar paridad con Matiz desktop.

/// `Math.Round(x, MidpointRounding.AwayFromZero)`: Dart `round()` ya redondea el punto medio alejándose de cero.
double roundAway(double x) => x.isFinite ? x.roundToDouble() : x;

/// `Math.Round(x, digits, MidpointRounding.AwayFromZero)`.
double roundAwayDigits(double x, int digits) {
  final p = math.pow(10, digits).toDouble();
  return roundAway(x * p) / p;
}

double clampD(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

int clampI(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

/// Operador `%` de C# para doubles (el signo sigue al dividendo).
double csMod(double a, double b) => a.remainder(b);

/// `Math.Cbrt`: raíz cúbica real con un paso de Newton para aproximarse al valor correctamente redondeado.
double cbrt(double x) {
  if (x == 0 || x.isNaN || x.isInfinite) return x;
  final a = x.abs();
  var y = math.pow(a, 1 / 3).toDouble();
  y = y - (y * y * y - a) / (3 * y * y);
  return x < 0 ? -y : y;
}

/// Ordenamiento estable (equivalente a LINQ OrderBy/ThenBy): `List.sort` de Dart no garantiza estabilidad.
List<T> stableSorted<T>(Iterable<T> items, int Function(T a, T b) compare) {
  final indexed = items.toList().asMap().entries.toList();
  indexed.sort((a, b) {
    final c = compare(a.value, b.value);
    return c != 0 ? c : a.key.compareTo(b.key);
  });
  return [for (final e in indexed) e.value];
}

/// Formato .NET "0.##" (cultura invariante): hasta 2 decimales sin ceros sobrantes.
String formatUpTo2(double v) {
  var s = roundAwayDigits(v, 2).toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s;
}

/// Formato .NET con decimales fijos ("0.000"), redondeo away-from-zero.
String formatFixed(double v, int digits) {
  final r = roundAwayDigits(v, digits);
  final s = r.toStringAsFixed(digits);
  return s == '-${0.toStringAsFixed(digits)}' ? 0.toStringAsFixed(digits) : s;
}

String hex2(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
