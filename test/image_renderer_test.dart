import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:matiz/imaging/palette_image_renderer.dart';
import 'package:matiz_core/matiz_core.dart';

Future<(int, int, ByteData)> decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final img = (await codec.getNextFrame()).image;
  final data = (await img.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!;
  return (img.width, img.height, data);
}

Argb at(ByteData d, int w, int x, int y) {
  final o = (y * w + x) * 4;
  return Argb(d.getUint8(o + 3), d.getUint8(o), d.getUint8(o + 1), d.getUint8(o + 2));
}

void main() {
  const puchi = PaletteExportModel('PuchiApp', [
    PaletteExportColor('Primary', Argb.fromRgb(82, 70, 188)),
    PaletteExportColor('Secondary', Argb.fromRgb(226, 67, 71)),
    PaletteExportColor(null, Argb.fromRgb(247, 249, 251)),
  ]);

  testWidgets('Paleta: centro de cada bloque con el color exacto y 2× = doble de 1×', (tester) async {
    await tester.runAsync(() async {
      final (w1, h1, _) = await decode(await PaletteImageRenderer.renderPalette(puchi, const PaletteImageOptions(scale: 1)));
      final (w2, h2, d2) = await decode(await PaletteImageRenderer.renderPalette(puchi, const PaletteImageOptions(scale: 2)));
      expect((w2, h2), (w1 * 2, h1 * 2));
      // Bloques horizontales: x = 40 + i·(176+16), y = 40 + 58, tamaño 176×132 (DIP) → centro × escala.
      for (var i = 0; i < 3; i++) {
        final cx = ((40 + i * 192 + 88) * 2).round();
        final cy = ((98 + 66) * 2).round();
        expect(at(d2, w2, cx, cy), puchi.colors[i].color, reason: 'bloque $i');
      }
    });
  });

  testWidgets('Fondo transparente: zonas de fondo con alfa 0', (tester) async {
    await tester.runAsync(() async {
      final (w, _, d) = await decode(await PaletteImageRenderer.renderPalette(
          puchi, const PaletteImageOptions(scale: 1, background: ImageBackground.transparent)));
      expect(at(d, w, 2, 2).a, 0);
    });
  });

  for (final n in [1, 8, 64]) {
    testWidgets('Superpuestos con $n colores: cada capa visible con su color', (tester) async {
      await tester.runAsync(() async {
        final model = PaletteExportModel('Stack', [
          for (var i = 0; i < n; i++) PaletteExportColor('C$i', Argb.fromRgb((i * 37) % 256, (i * 91) % 256, (i * 53 + 20) % 256)),
        ]);
        final (w, _, d) = await decode(await PaletteImageRenderer.renderOverlay(model, const OverlayImageOptions(scale: 1)));
        // Base de la pila: 480 DIP (crece si hace falta); paso = base/(n+1); el anillo visible de la capa k
        // queda en el borde izquierdo de la capa k, a step/4 hacia adentro.
        var base = 480.0;
        if (base / (2.0 * (n + 1)) < 4) base = 2 * (n + 1) * 4.0;
        final step = base / (n + 1);
        const top = 40 + 58.0;
        final contentH = base > n * 3 * 19 + (n - 1) * 14 ? base : n * 3 * 19 + (n - 1) * 14.0;
        final cy = (top + contentH / 2).round();
        final cx = 40 + base / 2;
        for (var k = 0; k < n; k++) {
          final side = (base - k * step) < 10 ? 10 : base - k * step;
          final x = (cx - side / 2 + step / 4).round();
          expect(at(d, w, x, cy), model.colors[k].color, reason: 'capa $k de $n');
        }
      });
    });
  }
}
