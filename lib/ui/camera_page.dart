import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:matiz_core/matiz_core.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../state/app_controller.dart';
import '../widgets/color_utils.dart';
import 'theme.dart';

/// Cámara en vivo: retícula (movible al tocar) con el color promediado 5×5 bajo ella.
/// Usar → principal; + Secundario → Personalizado (sigue abierta); Congelar → fotograma en modo Imagen.
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _cam;
  CameraDescription? _desc;
  String? _error;
  bool _denied = false;
  Argb _color = const Argb.fromRgb(128, 128, 128);
  Offset _reticle = const Offset(0.5, 0.5); // fracción del área de vista previa
  DateTime _lastSample = DateTime.fromMillisecondsSinceEpoch(0);
  bool _busy = false;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cam?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _cam;
    // Mientras se inicializa (p. ej. con el diálogo de permiso abierto) no se toca la cámara.
    if (_initializing) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _cam = null;
      cam?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && cam == null && !_denied && _error == null) {
      _init();
    }
  }

  Future<void> _start() async {
    final c = context.read<AppController>();
    final t = AppLocalizations.of(context);
    if (!c.settings.cameraIntroShown) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          icon: const Icon(Icons.photo_camera_outlined),
          title: Text(t.cameraPermissionTitle),
          content: Text(t.cameraPermissionBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t.cancel)),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t.ok)),
          ],
        ),
      );
      if (ok != true) {
        if (mounted) Navigator.pop(context);
        return;
      }
      c.markCameraIntroShown();
    }
    await _init();
  }

  Future<void> _init() async {
    if (_initializing) return;
    _initializing = true;
    try {
      if (_desc == null) {
        final cams = await availableCameras();
        if (cams.isEmpty) {
          setState(() => _error = 'none');
          return;
        }
        _desc = cams.firstWhere((d) => d.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
      }
      final cam = CameraController(_desc!, ResolutionPreset.medium,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
      await cam.initialize();
      if (!mounted) {
        await cam.dispose();
        return;
      }
      _cam = cam;
      await cam.startImageStream(_onFrame);
      setState(() {});
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _denied = e.code.contains('Denied') || e.code.contains('denied');
        _error = e.code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'none');
    } finally {
      _initializing = false;
    }
  }

  void _onFrame(CameraImage img) {
    final now = DateTime.now();
    if (now.difference(_lastSample) < const Duration(milliseconds: 66) || img.planes.length < 3) return;
    _lastSample = now;
    final (ix, iy) = _toImage(_reticle, img.width, img.height);
    final c = _sample(img, ix, iy);
    if (mounted && c != _color) setState(() => _color = c);
  }

  /// Fracción de la vista previa (vertical) → píxel de la imagen del sensor según su orientación.
  (int, int) _toImage(Offset f, int w, int h) {
    final o = _desc?.sensorOrientation ?? 90;
    // La cámara frontal se muestra espejada horizontalmente.
    if (_desc?.lensDirection == CameraLensDirection.front) f = Offset(1 - f.dx, f.dy);
    double x, y;
    switch (o) {
      case 90:
        x = f.dy * w;
        y = (1 - f.dx) * h;
      case 270:
        x = (1 - f.dy) * w;
        y = f.dx * h;
      case 180:
        x = (1 - f.dx) * w;
        y = (1 - f.dy) * h;
      default:
        x = f.dx * w;
        y = f.dy * h;
    }
    return (x.round().clamp(2, w - 3), y.round().clamp(2, h - 3));
  }

  /// Promedio 5×5 en YUV420 → RGB (BT.601, rango completo).
  Argb _sample(CameraImage img, int cx, int cy) {
    final yP = img.planes[0], uP = img.planes[1], vP = img.planes[2];
    final uvStride = uP.bytesPerPixel ?? 1;
    var r = 0.0, g = 0.0, b = 0.0;
    var n = 0;
    for (var dy = -2; dy <= 2; dy++) {
      for (var dx = -2; dx <= 2; dx++) {
        final x = cx + dx, y = cy + dy;
        final yv = yP.bytes[y * yP.bytesPerRow + x].toDouble();
        final uvIndex = (y >> 1) * uP.bytesPerRow + (x >> 1) * uvStride;
        if (uvIndex >= uP.bytes.length || uvIndex >= vP.bytes.length) continue;
        final u = uP.bytes[uvIndex] - 128.0;
        final v = vP.bytes[uvIndex] - 128.0;
        r += yv + 1.402 * v;
        g += yv - 0.344136 * u - 0.714136 * v;
        b += yv + 1.772 * u;
        n++;
      }
    }
    if (n == 0) return _color;
    int ch(double s) => (s / n).round().clamp(0, 255);
    return Argb.fromRgb(ch(r), ch(g), ch(b));
  }

  Future<void> _freeze() async {
    final cam = _cam;
    if (cam == null || _busy) return;
    _busy = true;
    final c = context.read<AppController>();
    final nav = Navigator.of(context);
    try {
      await cam.stopImageStream();
      final file = await cam.takePicture();
      final bytes = await file.readAsBytes();
      nav.pop();
      await c.loadImageBytes(bytes);
    } catch (_) {
      _busy = false;
      if (cam.value.isInitialized && !cam.value.isStreamingImages) await cam.startImageStream(_onFrame);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.read<AppController>();
    final cam = _cam;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(t.camera),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error == 'none' ? t.cameraUnavailable : t.cameraDenied,
                      style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  if (_denied) ...[
                    const SizedBox(height: 12),
                    FilledButton(onPressed: c.platform.openAppSettings, child: Text(t.openSettings)),
                  ],
                ]),
              ),
            )
          : cam == null || !cam.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1 / cam.value.aspectRatio,
                        child: LayoutBuilder(builder: (context, box) {
                          return GestureDetector(
                            onTapDown: (d) => setState(() => _reticle = Offset(
                                (d.localPosition.dx / box.maxWidth).clamp(0.02, 0.98),
                                (d.localPosition.dy / box.maxHeight).clamp(0.02, 0.98))),
                            child: Stack(children: [
                              Positioned.fill(child: CameraPreview(cam)),
                              Positioned(
                                left: _reticle.dx * box.maxWidth - 22,
                                top: _reticle.dy * box.maxHeight - 22,
                                child: IgnorePointer(
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    // Doble anillo sin relleno: no tiñe el área que se está midiendo.
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black54, width: 1),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: Center(
                                        child: Container(width: 4, height: 4, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                          );
                        }),
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: SafeArea(
                      top: false,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _color.toColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_color.toHex(),
                                style: MatizTheme.mono.copyWith(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                          ),
                        ]),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(t.cameraHint, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        ),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                              onPressed: () => c.addPointFromColor(_color),
                              child: FittedBox(child: Text(t.cameraAddSecondary, maxLines: 1)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                              onPressed: _freeze,
                              icon: const Icon(Icons.pause_circle_outline),
                              label: FittedBox(child: Text(t.cameraFreeze, maxLines: 1)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                              onPressed: () {
                                c.commitArgb(_color, ColorChangeSource.camera);
                                Navigator.pop(context);
                              },
                              child: FittedBox(child: Text(t.cameraUse, maxLines: 1)),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                ]),
    );
  }
}
