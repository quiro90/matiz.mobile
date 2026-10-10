import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_controller.dart';
import '../state/image_doc.dart';
import '../ui/theme.dart';
import 'color_utils.dart';

/// Visor de imagen táctil:
/// - Un dedo: lupa desplazada sobre el dedo; al soltar, el píxel exacto pasa a ser el color actual.
/// - Mantener quieto (≥ 500 ms): añade ese píxel como secundario (Personalizado).
/// - Dos dedos: zoom (pinza) y desplazamiento. Doble toque: ajustar ↔ 4×.
class ImageCanvas extends StatefulWidget {
  const ImageCanvas({super.key, required this.doc});

  final ImageDoc doc;

  @override
  State<ImageCanvas> createState() => _ImageCanvasState();
}

class _ImageCanvasState extends State<ImageCanvas> {
  static const _slop = 8.0;
  static const _maxScale = 32.0;

  final Map<int, Offset> _pointers = {};
  Offset? _finger;
  Offset _downPos = Offset.zero;
  bool _pending = false;
  bool _picking = false;
  bool _longPressed = false;
  bool _ignoreUntilAllUp = false;
  Timer? _timer;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);
  Offset _lastTapPos = Offset.zero;

  // Transformación con dos dedos.
  double _startScale = 1;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;
  double _startDist = 1;

  Size _viewport = Size.zero;

  ImageDoc get doc => widget.doc;
  AppController get _c => context.read<AppController>();

  double _fitScale(Size s) => math.min(s.width / doc.width, s.height / doc.height);

  void _ensureView(Size s) {
    if (s.isEmpty) return;
    if (doc.scale <= 0) _fit(s);
    _viewport = s;
  }

  void _fit(Size s) {
    doc.scale = _fitScale(s);
    doc.offset = Offset((s.width - doc.width * doc.scale) / 2, (s.height - doc.height * doc.scale) / 2);
  }

  (int, int) _pixel(Offset local) {
    final x = ((local.dx - doc.offset.dx) / doc.scale).floor();
    final y = ((local.dy - doc.offset.dy) / doc.scale).floor();
    return (x.clamp(0, doc.width - 1), y.clamp(0, doc.height - 1));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 1) {
      if (_ignoreUntilAllUp) return;
      _downPos = e.localPosition;
      _finger = e.localPosition;
      _pending = true;
      _picking = true;
      _longPressed = false;
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 500), () {
        if (!_pending || _pointers.length != 1) return;
        _longPressed = true;
        final (x, y) = _pixel(_downPos);
        _c.addSecondaryFromImage(x, y);
        setState(() {});
      });
      setState(() {});
    } else if (_pointers.length == 2) {
      // Pasa a zoom/pan: cancela la selección en curso.
      _timer?.cancel();
      _picking = false;
      _pending = false;
      _finger = null;
      _ignoreUntilAllUp = true;
      final pts = _pointers.values.toList();
      _startFocal = (pts[0] + pts[1]) / 2;
      _startDist = math.max(1, (pts[0] - pts[1]).distance);
      _startScale = doc.scale;
      _startOffset = doc.offset;
      setState(() {});
    }
  }

  void _onMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length >= 2) {
      final pts = _pointers.values.take(2).toList();
      final focal = (pts[0] + pts[1]) / 2;
      final dist = math.max(1.0, (pts[0] - pts[1]).distance);
      final minScale = math.min(_fitScale(_viewport), 1.0);
      final s = (_startScale * dist / _startDist).clamp(minScale, math.max(_maxScale, _fitScale(_viewport))).toDouble();
      final imagePoint = (_startFocal - _startOffset) / _startScale;
      setState(() {
        doc.scale = s;
        doc.offset = focal - imagePoint * s;
      });
      return;
    }
    if (!_picking) return;
    if (_pending && (e.localPosition - _downPos).distance > _slop) {
      _pending = false;
      _timer?.cancel();
    }
    if (_longPressed) return;
    setState(() => _finger = e.localPosition);
  }

  void _onUp(PointerEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers.remove(e.pointer);
    _timer?.cancel();
    if (_pointers.isEmpty) {
      final wasPicking = _picking && !_ignoreUntilAllUp && !_longPressed && e is PointerUpEvent;
      if (wasPicking) {
        final now = DateTime.now();
        final isDoubleTap = _pending &&
            now.difference(_lastTap) < const Duration(milliseconds: 300) &&
            (e.localPosition - _lastTapPos).distance < 40;
        if (isDoubleTap) {
          _toggleZoom(e.localPosition);
          _lastTap = DateTime.fromMillisecondsSinceEpoch(0);
        } else {
          final (x, y) = _pixel(_finger ?? e.localPosition);
          _c.pickFromImage(x, y);
          if (_pending) {
            _lastTap = now;
            _lastTapPos = e.localPosition;
          }
        }
      }
      _ignoreUntilAllUp = false;
      setState(() {
        _picking = false;
        _pending = false;
        _finger = null;
      });
    }
  }

  void _toggleZoom(Offset at) {
    final fit = _fitScale(_viewport);
    setState(() {
      if (doc.scale > fit * 1.5) {
        _fit(_viewport);
      } else {
        final target = math.max(4.0, fit * 4);
        final imagePoint = (at - doc.offset) / doc.scale;
        doc.scale = target;
        doc.offset = at - imagePoint * target;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      _ensureView(size);
      final finger = _finger;
      final showLoupe = finger != null && _picking && !_longPressed;
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: _onUp,
        child: ClipRect(
          child: Stack(children: [
            Positioned.fill(
              child: CustomPaint(painter: _ImagePainter(doc.image, doc.scale, doc.offset, scheme.surfaceContainerLow)),
            ),
            if (showLoupe) ..._loupe(size, finger, scheme),
          ]),
        ),
      );
    });
  }

  List<Widget> _loupe(Size size, Offset finger, ColorScheme scheme) {
    const cells = 11;
    const cell = 11.0;
    const side = cells * cell;
    const labelH = 26.0;
    final (px, py) = _pixel(finger);
    final color = doc.pixelAt(px, py);
    // Por encima del dedo; si no entra, debajo; y siempre dentro del ancho.
    var top = finger.dy - side - labelH - 56;
    if (top < 4) top = finger.dy + 56;
    final left = (finger.dx - side / 2).clamp(4.0, math.max(4.0, size.width - side - 4)).toDouble();
    return [
      Positioned(
        left: finger.dx - 14,
        top: finger.dy - 14,
        child: IgnorePointer(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 2)],
            ),
          ),
        ),
      ),
      Positioned(
        left: left,
        top: top,
        child: IgnorePointer(
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: side,
              height: side + labelH,
              child: Column(children: [
                SizedBox(
                  width: side,
                  height: side,
                  child: CustomPaint(painter: _LoupePainter(doc, px, py, cells, cell)),
                ),
                Container(
                  height: labelH,
                  width: side,
                  color: color.toColor,
                  alignment: Alignment.center,
                  child: Text(color.toHex(),
                      style: MatizTheme.mono.copyWith(color: color.onColor, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ),
        ),
      ),
    ];
  }
}

class _ImagePainter extends CustomPainter {
  _ImagePainter(this.image, this.scale, this.offset, this.bg);

  final ui.Image image;
  final double scale;
  final Offset offset;
  final Color bg;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    final paint = Paint()..filterQuality = scale >= 2 ? FilterQuality.none : FilterQuality.medium;
    canvas.drawImage(image, Offset.zero, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ImagePainter old) =>
      old.image != image || old.scale != scale || old.offset != offset || old.bg != bg;
}

/// Cuadrícula de píxeles ampliados (sin suavizado) del búfer original, con el píxel central marcado.
class _LoupePainter extends CustomPainter {
  _LoupePainter(this.doc, this.cx, this.cy, this.cells, this.cell);

  final ImageDoc doc;
  final int cx, cy, cells;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final half = cells ~/ 2;
    final paint = Paint();
    for (var j = 0; j < cells; j++) {
      for (var i = 0; i < cells; i++) {
        final x = cx + i - half, y = cy + j - half;
        final inside = x >= 0 && y >= 0 && x < doc.width && y < doc.height;
        paint.color = inside ? doc.pixelAt(x, y).toColor : const Color(0xFF808080);
        canvas.drawRect(Rect.fromLTWH(i * cell, j * cell, cell, cell), paint);
      }
    }
    final grid = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 0.5;
    for (var k = 1; k < cells; k++) {
      canvas.drawLine(Offset(k * cell, 0), Offset(k * cell, size.height), grid);
      canvas.drawLine(Offset(0, k * cell), Offset(size.width, k * cell), grid);
    }
    final center = Rect.fromLTWH(half * cell, half * cell, cell, cell);
    canvas.drawRect(center.inflate(1), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black);
    canvas.drawRect(center, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white);
  }

  @override
  bool shouldRepaint(_LoupePainter old) => old.cx != cx || old.cy != cy || old.doc != doc;
}
