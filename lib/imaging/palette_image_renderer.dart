import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:matiz_core/matiz_core.dart';

enum OverlayShape { square, circle, triangle }

enum ImageBackground { light, dark, transparent }

class PaletteImageOptions {
  final bool horizontal;
  final int scale;
  final ImageBackground background;
  final bool showHsl;
  final bool showCmyk;

  const PaletteImageOptions({
    this.horizontal = true,
    this.scale = 2,
    this.background = ImageBackground.light,
    this.showHsl = false,
    this.showCmyk = false,
  });

  PaletteImageOptions copyWith({bool? horizontal, int? scale, ImageBackground? background, bool? showHsl, bool? showCmyk}) =>
      PaletteImageOptions(
        horizontal: horizontal ?? this.horizontal,
        scale: scale ?? this.scale,
        background: background ?? this.background,
        showHsl: showHsl ?? this.showHsl,
        showCmyk: showCmyk ?? this.showCmyk,
      );
}

class OverlayImageOptions {
  final int scale;
  final ImageBackground background;
  final OverlayShape shape;
  final bool reverse;
  final bool showHsl;
  final bool showCmyk;

  const OverlayImageOptions({
    this.scale = 2,
    this.background = ImageBackground.light,
    this.shape = OverlayShape.square,
    this.reverse = false,
    this.showHsl = false,
    this.showCmyk = false,
  });

  OverlayImageOptions copyWith(
          {int? scale, ImageBackground? background, OverlayShape? shape, bool? reverse, bool? showHsl, bool? showCmyk}) =>
      OverlayImageOptions(
        scale: scale ?? this.scale,
        background: background ?? this.background,
        shape: shape ?? this.shape,
        reverse: reverse ?? this.reverse,
        showHsl: showHsl ?? this.showHsl,
        showCmyk: showCmyk ?? this.showCmyk,
      );
}

/// Paleta de estilos del PNG (mismos colores que desktop).
class _Style {
  final Color? bg;
  final Color fg;
  final Color muted;
  final Color border;

  _Style(ImageBackground b)
      : bg = switch (b) {
          ImageBackground.light => const Color(0xFFFFFFFF),
          ImageBackground.dark => const Color(0xFF18181B),
          ImageBackground.transparent => null,
        },
        fg = b == ImageBackground.dark ? const Color(0xFFF0F0F0) : const Color(0xFF18181B),
        muted = b == ImageBackground.dark ? const Color(0xFFA0A0A6) : const Color(0xFF64646C),
        border = b == ImageBackground.dark ? const Color(0x28FFFFFF) : const Color(0x1E000000);
}

/// Port de PaletteImageRenderer / OverlayImageRenderer de desktop (misma geometría en DIP).
/// Los bloques se dibujan sin antialiasing: el centro de cada bloque tiene exactamente el color de la paleta.
abstract final class PaletteImageRenderer {
  static const double _pad = 40, _titleH = 58, _gap = 16, _lineH = 19;
  static const double _hBlockW = 176, _hBlockH = 132;
  static const double _vBlockW = 132, _vBlockH = 76, _vTextW = 260;
  static const int _maxPerRow = 6;

  static int _lines(bool hsl, bool cmyk) => 3 + (hsl ? 1 : 0) + (cmyk ? 1 : 0);

  static Size layoutSize(int count, PaletteImageOptions o) {
    final lines = _lines(o.showHsl, o.showCmyk);
    count = math.max(1, count);
    if (o.horizontal) {
      final cols = math.min(count, _maxPerRow);
      final rows = (count / cols).ceil();
      final cellH = _hBlockH + 12 + lines * _lineH;
      return Size(_pad * 2 + cols * _hBlockW + (cols - 1) * _gap, _pad + _titleH + rows * cellH + (rows - 1) * _gap * 1.5 + _pad);
    }
    final rowH = math.max(_vBlockH, lines * _lineH);
    return Size(_pad * 2 + _vBlockW + 18 + _vTextW, _pad + _titleH + count * rowH + (count - 1) * _gap + _pad);
  }

  static Future<Uint8List> renderPalette(PaletteExportModel palette, PaletteImageOptions o) async {
    final size = layoutSize(palette.colors.length, o);
    final scale = o.scale.clamp(1, 4).toDouble();
    final s = _Style(o.background);
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.scale(scale);
    if (s.bg != null) canvas.drawRect(Offset.zero & size, Paint()..color = s.bg!);
    _text(canvas, palette.name, const Offset(_pad, _pad - 4), 28, s.fg, bold: true);

    final lines = _lines(o.showHsl, o.showCmyk);
    for (var i = 0; i < palette.colors.length; i++) {
      final c = palette.colors[i];
      Rect block;
      Offset text;
      if (o.horizontal) {
        final cols = math.min(palette.colors.length, _maxPerRow);
        final col = i % cols, row = i ~/ cols;
        final cellH = _hBlockH + 12 + lines * _lineH;
        final x = _pad + col * (_hBlockW + _gap);
        final y = _pad + _titleH + row * (cellH + _gap * 1.5);
        block = Rect.fromLTWH(x, y, _hBlockW, _hBlockH);
        text = Offset(x, y + _hBlockH + 10);
      } else {
        final rowH = math.max(_vBlockH, lines * _lineH);
        final y = _pad + _titleH + i * (rowH + _gap);
        block = Rect.fromLTWH(_pad, y, _vBlockW, _vBlockH);
        text = Offset(_pad + _vBlockW + 18, y + math.max(0, (_vBlockH - lines * _lineH) / 2));
      }
      canvas.drawRect(block, Paint()
        ..color = Color.fromARGB(c.color.a, c.color.r, c.color.g, c.color.b)
        ..isAntiAlias = false);
      canvas.drawRect(block, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = s.border
        ..isAntiAlias = false);
      _values(canvas, c, i, text, s, o.showHsl, o.showCmyk);
    }
    return _encode(rec, size, scale);
  }

  // ---------- Superpuestos ----------

  static const double _textGap = 18, _textW = 260, _entryGap = 14;
  static const double _baseDip = 480, _minRing = 4, _minLayer = 10;

  static double _stackBase(int count) {
    var b = _baseDip;
    if (b / (2.0 * (count + 1)) < _minRing) b = 2 * (count + 1) * _minRing;
    return b;
  }

  static double _textHeight(int count, int lines) => count * lines * _lineH + math.max(0, count - 1) * _entryGap;

  static Size overlaySize(int count, OverlayImageOptions o) {
    count = math.max(1, count);
    final textH = _textHeight(count, _lines(o.showHsl, o.showCmyk));
    final contentH = math.max(_stackBase(count), textH);
    return Size(_pad * 2 + _stackBase(count) + _textGap + _textW, _pad + _titleH + contentH + _pad);
  }

  static Future<Uint8List> renderOverlay(PaletteExportModel palette, OverlayImageOptions o) async {
    final size = overlaySize(palette.colors.length, o);
    final scale = o.scale.clamp(1, 4).toDouble();
    final s = _Style(o.background);
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.scale(scale);
    if (s.bg != null) canvas.drawRect(Offset.zero & size, Paint()..color = s.bg!);
    _text(canvas, palette.name, const Offset(_pad, _pad - 4), 28, s.fg, bold: true);

    final colors = o.reverse ? palette.colors.reversed.toList() : palette.colors;
    final count = math.max(1, colors.length);
    final b = _stackBase(count);
    final step = b / (count + 1);
    final lines = _lines(o.showHsl, o.showCmyk);
    const top = _pad + _titleH;
    final contentH = math.max(b, _textHeight(count, lines));
    final cx = _pad + b / 2;
    final cy = top + contentH / 2;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = s.border;

    for (var k = 0; k < colors.length; k++) {
      final c = colors[k].color;
      final side = math.max(b - k * step, _minLayer);
      final r = Rect.fromCenter(center: Offset(cx, cy), width: side, height: side);
      final fill = Paint()
        ..color = Color.fromARGB(c.a, c.r, c.g, c.b)
        ..isAntiAlias = o.shape != OverlayShape.square;
      switch (o.shape) {
        case OverlayShape.circle:
          canvas.drawOval(r, fill);
          canvas.drawOval(r, border);
        case OverlayShape.triangle:
          final path = Path()
            ..moveTo(r.center.dx, r.top)
            ..lineTo(r.right, r.bottom)
            ..lineTo(r.left, r.bottom)
            ..close();
          canvas.drawPath(path, fill);
          canvas.drawPath(path, border);
        case OverlayShape.square:
          canvas.drawRect(r, fill);
          canvas.drawRect(r, border..isAntiAlias = false);
      }
    }

    final x = _pad + b + _textGap;
    var y = top;
    for (var i = 0; i < colors.length; i++) {
      _values(canvas, colors[i], i, Offset(x, y), s, o.showHsl, o.showCmyk);
      y += lines * _lineH + _entryGap;
    }
    return _encode(rec, size, scale);
  }

  // ---------- comunes ----------

  static void _values(Canvas canvas, PaletteExportColor c, int i, Offset t, _Style s, bool hsl, bool cmyk) {
    final name = (c.name == null || c.name!.trim().isEmpty) ? 'Color ${i + 1}' : c.name!;
    _text(canvas, name.toUpperCase(), t, 13, s.fg, bold: true);
    t = t.translate(0, _lineH);
    _text(canvas, ColorFormats.hex(c.color), t, 13, s.fg, mono: true);
    t = t.translate(0, _lineH);
    _text(canvas, 'RGB(${c.color.r},${c.color.g},${c.color.b})', t, 12, s.muted, mono: true);
    if (hsl) {
      t = t.translate(0, _lineH);
      _text(canvas, 'HSL(${ColorFormats.hsl(c.color)})', t, 12, s.muted, mono: true);
    }
    if (cmyk) {
      t = t.translate(0, _lineH);
      _text(canvas, 'CMYK(${ColorFormats.cmyk(c.color)})', t, 12, s.muted, mono: true);
    }
  }

  static void _text(Canvas canvas, String text, Offset at, double size, Color color, {bool bold = false, bool mono = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          fontFamily: mono ? 'monospace' : null,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, at);
  }

  static Future<Uint8List> _encode(ui.PictureRecorder rec, Size size, double scale) async {
    final picture = rec.endRecording();
    final img = await picture.toImage((size.width * scale).ceil(), (size.height * scale).ceil());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    img.dispose();
    return data!.buffer.asUint8List();
  }
}
