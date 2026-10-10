import 'dart:math' as math;
import 'dart:typed_data';

import '../colors/argb.dart';
import '../colors/color_math.dart';
import '../colors/color_spaces.dart';
import '../util/num_util.dart';
import 'dotnet_random.dart';

/// Orden de los canales del búfer de píxeles.
enum PixelLayout { bgra, rgba }

/// Extracción de colores predominantes: muestreo a ≤128 px del lado mayor, k-means++ en Oklab
/// con semilla fija (resultado determinista), ordenado por población.
abstract final class DominantColors {
  static const int maxSide = 128;

  /// Límite de colores por paleta (regla global).
  static const int maxCount = 64;
  static const int _seed = 1234;
  static const int _iterations = 12;

  /// [pixels]: píxeles de 32 bits fila a fila, en el orden [layout] (desktop usa BGRA; Flutter entrega RGBA).
  static List<Argb> extract(Uint8List pixels, int width, int height, int stride, int count,
      {PixelLayout layout = PixelLayout.rgba}) {
    count = clampI(count, 1, maxCount);
    final samples = _sample(pixels, width, height, stride, layout);
    if (samples.isEmpty) return [];

    final k = math.min(count, samples.length);
    final centers = _initPlusPlus(samples, k);
    final assign = List<int>.filled(samples.length, 0);

    for (var it = 0; it < _iterations; it++) {
      var changed = false;
      for (var i = 0; i < samples.length; i++) {
        final best = _nearest(samples[i], centers);
        if (best != assign[i] || it == 0) {
          changed |= best != assign[i];
          assign[i] = best;
        }
      }

      final sl = List<double>.filled(k, 0), sa = List<double>.filled(k, 0), sb = List<double>.filled(k, 0);
      final sn = List<int>.filled(k, 0);
      for (var i = 0; i < samples.length; i++) {
        final c = assign[i];
        sl[c] += samples[i].l;
        sa[c] += samples[i].a;
        sb[c] += samples[i].b;
        sn[c]++;
      }
      for (var c = 0; c < k; c++) {
        if (sn[c] > 0) centers[c] = Oklab(sl[c] / sn[c], sa[c] / sn[c], sb[c] / sn[c]);
      }

      if (!changed && it > 0) break;
    }

    final population = List<int>.filled(k, 0);
    for (final a in assign) {
      population[a]++;
    }

    final order = stableSorted<int>(
      List.generate(k, (c) => c).where((c) => population[c] > 0),
      (a, b) {
        final p = population[b].compareTo(population[a]);
        return p != 0 ? p : centers[a].l.compareTo(centers[b].l);
      },
    );
    final result = <Argb>[];
    for (final c in order) {
      final color = ColorMath.fromLinear(ColorMath.oklabToLinear(centers[c]));
      if (!result.contains(color)) result.add(color);
    }
    return result;
  }

  static List<Oklab> _sample(Uint8List px, int width, int height, int stride, PixelLayout layout) {
    final step = math.max(1, (math.max(width, height) / maxSide).ceil());
    final list = <Oklab>[];
    final rgba = layout == PixelLayout.rgba;
    for (var y = 0; y < height; y += step) {
      final row = y * stride;
      for (var x = 0; x < width; x += step) {
        final o = row + x * 4;
        if (px[o + 3] < 128) continue; // ignora píxeles transparentes
        final r = rgba ? px[o] : px[o + 2];
        final b = rgba ? px[o + 2] : px[o];
        list.add(ColorMath.toOklab(Argb.fromRgb(r, px[o + 1], b)));
      }
    }
    return list;
  }

  static List<Oklab> _initPlusPlus(List<Oklab> samples, int k) {
    final rnd = DotNetRandom(_seed);
    final centers = List<Oklab>.filled(k, samples[0]);
    centers[0] = samples[rnd.next(samples.length)];
    final dist = List<double>.filled(samples.length, 0);
    for (var c = 1; c < k; c++) {
      var sum = 0.0;
      for (var i = 0; i < samples.length; i++) {
        var d = double.maxFinite;
        for (var j = 0; j < c; j++) {
          d = math.min(d, _dist2(samples[i], centers[j]));
        }
        dist[i] = d;
        sum += d;
      }
      if (sum <= 0) {
        centers[c] = centers[0];
        continue;
      }
      final target = rnd.nextDouble() * sum;
      var idx = 0;
      for (var acc = 0.0; idx < samples.length - 1; idx++) {
        acc += dist[idx];
        if (acc >= target) break;
      }
      centers[c] = samples[idx];
    }
    return centers;
  }

  static int _nearest(Oklab p, List<Oklab> centers) {
    var best = 0;
    var bestD = double.maxFinite;
    for (var c = 0; c < centers.length; c++) {
      final d = _dist2(p, centers[c]);
      if (d < bestD) {
        bestD = d;
        best = c;
      }
    }
    return best;
  }

  static double _dist2(Oklab a, Oklab b) {
    final dl = a.l - b.l, da = a.a - b.a, db = a.b - b.b;
    return dl * dl + da * da + db * db;
  }
}
