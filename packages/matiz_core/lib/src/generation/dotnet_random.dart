/// Port del generador sustractivo de Knuth que usa `new System.Random(seed)` en .NET
/// (implementación compatible con semilla). Garantiza que la extracción de colores
/// (k-means++ con semilla fija) produzca exactamente los mismos resultados que Matiz desktop.
class DotNetRandom {
  static const int _mBig = 2147483647; // int.MaxValue
  static const int _mSeed = 161803398;

  final List<int> _seedArray = List<int>.filled(56, 0);
  int _inext = 0;
  int _inextp = 21;

  DotNetRandom(int seed) {
    final subtraction = seed == -2147483648 ? _mBig : seed.abs();
    var mj = _mSeed - subtraction;
    _seedArray[55] = mj;
    var mk = 1;
    for (var i = 1; i < 55; i++) {
      final ii = (21 * i) % 55;
      _seedArray[ii] = mk;
      mk = mj - mk;
      if (mk < 0) mk += _mBig;
      mj = _seedArray[ii];
    }
    for (var k = 1; k < 5; k++) {
      for (var i = 1; i < 56; i++) {
        var n = i + 30;
        if (n >= 55) n -= 55;
        _seedArray[i] -= _seedArray[1 + n];
        if (_seedArray[i] < 0) _seedArray[i] += _mBig;
      }
    }
  }

  int _internalSample() {
    var locINext = _inext + 1;
    if (locINext >= 56) locINext = 1;
    var locINextp = _inextp + 1;
    if (locINextp >= 56) locINextp = 1;
    var retVal = _seedArray[locINext] - _seedArray[locINextp];
    if (retVal == _mBig) retVal--;
    if (retVal < 0) retVal += _mBig;
    _seedArray[locINext] = retVal;
    _inext = locINext;
    _inextp = locINextp;
    return retVal;
  }

  double _sample() => _internalSample() * (1.0 / _mBig);

  /// `Next(maxValue)`: entero en [0, maxValue).
  int next(int maxValue) => (_sample() * maxValue).toInt();

  /// `NextDouble()`: double en [0, 1).
  double nextDouble() => _sample();
}
