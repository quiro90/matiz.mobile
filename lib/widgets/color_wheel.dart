import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matiz_core/matiz_core.dart';
import 'package:provider/provider.dart';

import '../state/app_controller.dart';
import 'color_utils.dart';

enum _Gesture { none, pending, dragMain, dragMarker, longPressed }

/// Rueda hue/saturación táctil.
/// - Tocar y soltar: fija el color (cambio confirmado). Arrastrar: lo mueve en vivo y confirma al soltar.
/// - Mantener pulsado (≥ 500 ms sin moverse): añade un punto secundario (Personalizado), sin mover el principal.
/// - Con Armonías/Personalizado: tocar un punto lo selecciona, arrastrarlo lo mueve, doble toque lo quita.
/// La rueda se dibuja con gradientes en GPU (HSV con V=1 es lineal en sRGB), sin regenerar bitmaps.
class ColorWheel extends StatefulWidget {
  const ColorWheel({super.key, this.compact = false});

  final bool compact;

  @override
  State<ColorWheel> createState() => _ColorWheelState();
}

class _ColorWheelState extends State<ColorWheel> {
  static const _slop = 8.0;
  static const _longPress = Duration(milliseconds: 500);
  static const _doubleTap = Duration(milliseconds: 350);

  int? _pointer;
  Offset _downPos = Offset.zero;
  Offset? _finger;
  _Gesture _gesture = _Gesture.none;
  bool _onMain = false;
  int _markerIndex = -1;
  Timer? _timer;
  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _lastTapMarker = -1;

  late Offset _center;
  late double _radius;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  AppController get _c => context.read<AppController>();

  ({double hue, double saturation}) _hs(Offset p) =>
      WheelMapping.fromPoint(p.dx - _center.dx, p.dy - _center.dy, _radius, _c.wheelGamma);

  Offset _pos(double hue, double sat) {
    final pt = WheelMapping.toPoint(hue, sat, _c.wheelGamma);
    return _center + Offset(pt.x, pt.y) * _radius;
  }

  ColorState _stateAt(Offset p) {
    final hs = _hs(p);
    final cur = _c.current;
    return cur.withHueSaturation(hs.hue.isNaN ? cur.hue : hs.hue, hs.saturation);
  }

  void _onDown(PointerDownEvent e) {
    if (_pointer != null) return; // un solo dedo
    _pointer = e.pointer;
    _downPos = e.localPosition;
    _finger = e.localPosition;
    _gesture = _Gesture.pending;
    _markerIndex = -1;
    final hit = widget.compact ? 26.0 : 24.0;
    _onMain = (_pos(_c.current.hue, _c.current.saturation) - e.localPosition).distance <= hit;
    if (!_onMain) {
      final markers = _c.markers;
      var best = hit;
      for (var i = 0; i < markers.length; i++) {
        final d = (_pos(markers[i].hue, markers[i].saturation) - e.localPosition).distance;
        if (d <= best) {
          best = d;
          _markerIndex = i;
        }
      }
    }
    _timer?.cancel();
    _timer = Timer(_longPress, _onLongPress);
  }

  void _onLongPress() {
    if (_gesture != _Gesture.pending) return;
    _gesture = _Gesture.longPressed;
    final hs = _hs(_downPos);
    _c.addPointAt(hs.hue, hs.saturation);
  }

  void _onMove(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    _finger = e.localPosition;
    if (_gesture == _Gesture.pending && (e.localPosition - _downPos).distance > _slop) {
      _timer?.cancel();
      if (_markerIndex >= 0) {
        _gesture = _Gesture.dragMarker;
        _c.beginMarkerDrag();
      } else {
        _gesture = _Gesture.dragMain;
      }
    }
    switch (_gesture) {
      case _Gesture.dragMain:
        _c.preview(_stateAt(e.localPosition));
        setState(() {});
      case _Gesture.dragMarker:
        final hs = _hs(e.localPosition);
        if (!hs.hue.isNaN) _c.moveMarker(_markerIndex, hs.hue, hs.saturation);
      default:
        break;
    }
  }

  void _onUp(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    _timer?.cancel();
    switch (_gesture) {
      case _Gesture.dragMain:
        _c.commit(_c.current);
      case _Gesture.pending:
        if (_markerIndex >= 0) {
          final now = DateTime.now();
          if (_lastTapMarker == _markerIndex && now.difference(_lastTapTime) < _doubleTap) {
            HapticFeedback.lightImpact();
            _c.removeMarker(_markerIndex);
            _lastTapMarker = -1;
          } else {
            _c.selectMarker(_markerIndex);
            _lastTapMarker = _markerIndex;
            _lastTapTime = now;
          }
        } else {
          _c.commit(_stateAt(e.localPosition));
        }
      default:
        break;
    }
    _reset();
  }

  void _onCancel(PointerCancelEvent e) {
    if (e.pointer != _pointer) return;
    _timer?.cancel();
    if (_gesture == _Gesture.dragMain) _c.commit(_c.current);
    _reset();
  }

  void _reset() {
    setState(() {
      _pointer = null;
      _gesture = _Gesture.none;
      _finger = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, box) {
      final size = math.min(box.maxWidth, box.maxHeight);
      final pad = widget.compact ? 10.0 : 16.0;
      _radius = math.max(10, size / 2 - pad);
      _center = Offset(box.maxWidth / 2, box.maxHeight / 2);
      final gamma = c.wheelGamma;
      final mainPos = _pos(c.current.hue, c.current.saturation);
      final showLoupe = _gesture == _Gesture.dragMain && _finger != null;
      return Semantics(
        label: 'Color wheel',
        value: c.currentArgb.toHex(),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onDown,
          onPointerMove: _onMove,
          onPointerUp: _onUp,
          onPointerCancel: _onCancel,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _WheelPainter(_center, _radius, gamma, scheme.outlineVariant)),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _MarkersPainter(
                  center: _center,
                  main: mainPos,
                  mainColor: c.currentArgb,
                  markers: [for (final m in c.markers) (_pos(m.hue, m.saturation), m.color, m.selected)],
                  lineColor: scheme.onSurface.withValues(alpha: 0.35),
                  compact: widget.compact,
                ),
              ),
            ),
            if (showLoupe)
              Positioned(
                left: (_finger!.dx - 28).clamp(-20.0, box.maxWidth - 36),
                top: _finger!.dy - (widget.compact ? 64 : 84),
                child: IgnorePointer(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: c.currentArgb.toColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 8)],
                    ),
                  ),
                ),
              ),
          ]),
        ),
      );
    });
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.center, this.radius, this.gamma, this.rim);

  final Offset center;
  final double radius;
  final double gamma;
  final Color rim;

  static const _hues = [
    Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00), Color(0xFF00FFFF),
    Color(0xFF0000FF), Color(0xFFFF00FF), Color(0xFFFF0000),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    // 0° (rojo) arriba, sentido horario: HSV con V=1 es interpolación lineal entre los 6 primarios.
    final sweep = const SweepGradient(colors: _hues, transform: GradientRotation(-math.pi / 2)).createShader(rect);
    canvas.drawCircle(center, radius, Paint()..shader = sweep);
    // Saturación S = r^γ: blanco con alpha 1 − r^γ (mezcla lineal con blanco, exacta para HSV).
    const n = 32;
    final stops = [for (var i = 0; i <= n; i++) i / n];
    final colors = [for (final t in stops) Colors.white.withValues(alpha: 1 - math.pow(t, gamma).toDouble())];
    final radial = RadialGradient(colors: colors, stops: stops).createShader(rect);
    canvas.drawCircle(center, radius, Paint()..shader = radial);
    canvas.drawCircle(center, radius, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = rim);
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.center != center || old.radius != radius || old.gamma != gamma || old.rim != rim;
}

class _MarkersPainter extends CustomPainter {
  _MarkersPainter({
    required this.center,
    required this.main,
    required this.mainColor,
    required this.markers,
    required this.lineColor,
    required this.compact,
  });

  final Offset center;
  final Offset main;
  final Argb mainColor;
  final List<(Offset, Argb, bool)> markers;
  final Color lineColor;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    if (markers.isNotEmpty) canvas.drawLine(center, main, line);
    for (final (p, _, _) in markers) {
      canvas.drawLine(center, p, line);
    }
    for (final (p, color, selected) in markers) {
      final r = selected ? (compact ? 8.0 : 10.0) : (compact ? 6.0 : 7.5);
      canvas.drawCircle(p, r + 1.5, Paint()..color = const Color(0x99000000));
      canvas.drawCircle(p, r, Paint()..color = Colors.white);
      canvas.drawCircle(p, r - 2, Paint()..color = color.opaque.toColor);
    }
    final r = compact ? 10.0 : 13.0;
    canvas.drawCircle(main, r + 1.5, Paint()..color = const Color(0xAA000000));
    canvas.drawCircle(main, r, Paint()..color = Colors.white);
    canvas.drawCircle(main, r - 3, Paint()..color = mainColor.opaque.toColor);
  }

  @override
  bool shouldRepaint(_MarkersPainter old) => true;
}

/// Control de brillo (HSV V) vertical: degradado del color actual con brillo 100% hasta negro.
class BrightnessBar extends StatelessWidget {
  const BrightnessBar({super.key, this.width = 40});

  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final st = c.current;
    final top = ColorMath.fromHsv(st.hue, st.saturation, 1).toColor;
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, box) {
      const pad = 14.0;
      final h = math.max(1.0, box.maxHeight - pad * 2);
      double valueAt(double y) => clampD(1 - (y - pad) / h, 0, 1);
      void setV(double y) => c.preview(st.withValue(valueAt(y)));
      final y = pad + (1 - st.value) * h;
      return Semantics(
        label: 'Brightness',
        value: '${(st.value * 100).round()}%',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (d) => setV(d.localPosition.dy),
          onVerticalDragUpdate: (d) => c.preview(c.current.withValue(valueAt(d.localPosition.dy))),
          onVerticalDragEnd: (_) => c.commit(c.current),
          onTapUp: (d) => c.commit(st.withValue(valueAt(d.localPosition.dy))),
          child: SizedBox(
            width: math.max(width, 48),
            child: Stack(children: [
              Positioned(
                left: (math.max(width, 48) - width / 2) / 2,
                width: width / 2,
                top: pad,
                bottom: pad,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width / 4),
                    border: Border.all(color: scheme.outlineVariant),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [top, Colors.black],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (math.max(width, 48) - width * 0.9) / 2,
                top: y - 7,
                child: Container(
                  width: width * 0.9,
                  height: 14,
                  decoration: BoxDecoration(
                    color: st.argb.toColor,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3)],
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }
}
