import 'package:test/test.dart';

/// Equivalente a `Assert.Equal(expected, actual, precision)` de xUnit: compara redondeando a [digits] decimales.
void expectPrecision(double actual, double expected, int digits) {
  double r(double v) {
    var p = 1.0;
    for (var i = 0; i < digits; i++) {
      p *= 10;
    }
    return (v * p).roundToDouble() / p;
  }

  expect(r(actual), r(expected), reason: 'actual=$actual expected=$expected (precision $digits)');
}

void expectInRange(num value, num lo, num hi, [String? reason]) {
  expect(value >= lo && value <= hi, isTrue, reason: reason ?? '$value fuera de [$lo, $hi]');
}
