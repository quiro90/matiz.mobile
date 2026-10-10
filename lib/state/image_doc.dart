import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:matiz_core/matiz_core.dart';

/// Imagen abierta en el modo Imagen: el `ui.Image` para dibujar y el búfer RGBA original
/// (sin interpolación) del que se leen los píxeles exactos. Conserva zoom/posición entre
/// cambios Rueda ↔ Imagen.
class ImageDoc {
  final ui.Image image;
  final Uint8List rgba;
  final int width;
  final int height;

  /// Colores extraídos (k-means), en orden de población.
  List<Argb> extracted = const [];
  bool extracting = false;

  /// Vista: escala (px de pantalla por px de imagen) y desplazamiento del origen de la imagen.
  double scale = 0;
  Offset offset = Offset.zero;

  ImageDoc(this.image, this.rgba, this.width, this.height);

  Argb pixelAt(int x, int y) {
    x = x.clamp(0, width - 1);
    y = y.clamp(0, height - 1);
    final o = (y * width + x) * 4;
    return Argb.fromRgb(rgba[o], rgba[o + 1], rgba[o + 2]);
  }

  void dispose() => image.dispose();

  /// Decodifica bytes de imagen (PNG, JPEG, WebP, GIF, BMP, HEIC si el sistema lo soporta).
  /// Las imágenes mayores a [maxPixels] se reducen. Devuelve null si no es decodificable.
  static Future<ImageDoc?> decode(Uint8List bytes, {int maxPixels = 24000000}) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      int? targetW, targetH;
      final px = descriptor.width * descriptor.height;
      if (px > maxPixels) {
        final f = (maxPixels / px);
        final k = math.sqrt(f);
        targetW = (descriptor.width * k).floor();
        targetH = (descriptor.height * k).floor();
      }
      final codec = await descriptor.instantiateCodec(targetWidth: targetW, targetHeight: targetH);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
      if (data == null) {
        image.dispose();
        return null;
      }
      return ImageDoc(image, data.buffer.asUint8List(), image.width, image.height);
    } catch (_) {
      return null;
    }
  }

}
