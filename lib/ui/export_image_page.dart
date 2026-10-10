import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:matiz_core/matiz_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../imaging/palette_image_renderer.dart';
import '../l10n/generated/app_localizations.dart';
import '../state/app_controller.dart';
import '../widgets/color_utils.dart';

/// Vista previa de la exportación PNG (paleta clásica o superpuestos) con Guardar en…, Galería y Compartir.
class ExportImagePage extends StatefulWidget {
  const ExportImagePage({super.key, required this.model, this.overlay = false});

  final PaletteExportModel model;
  final bool overlay;

  @override
  State<ExportImagePage> createState() => _ExportImagePageState();
}

class _ExportImagePageState extends State<ExportImagePage> {
  PaletteImageOptions _palette = const PaletteImageOptions();
  OverlayImageOptions _overlay = const OverlayImageOptions();
  Uint8List? _png;
  int _renderId = 0;

  @override
  void initState() {
    super.initState();
    _render();
  }

  Future<void> _render() async {
    final id = ++_renderId;
    final bytes = widget.overlay
        ? await PaletteImageRenderer.renderOverlay(widget.model, _overlay)
        : await PaletteImageRenderer.renderPalette(widget.model, _palette);
    if (!mounted || id != _renderId) return;
    setState(() => _png = bytes);
  }

  String get _fileName {
    final base = widget.model.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return '${base.isEmpty ? 'palette' : base}${widget.overlay ? '-overlay' : ''}.png';
  }

  Future<void> _saveTo() async {
    final c = context.read<AppController>();
    final t = AppLocalizations.of(context);
    final png = _png;
    if (png == null) return;
    try {
      final uri = await FilePicker.saveFile(fileName: _fileName, bytes: png, mimeType: 'image/png');
      if (uri != null) c.showToast(t.toastSavedImage);
    } catch (_) {
      c.showToast(t.toastSaveFailed);
    }
  }

  Future<void> _saveGallery() async {
    final c = context.read<AppController>();
    final t = AppLocalizations.of(context);
    final png = _png;
    if (png == null) return;
    final ok = await c.platform.saveImageToGallery(png, _fileName);
    c.showToast(ok ? t.toastSavedImage : t.toastSaveFailed);
  }

  Future<void> _share() async {
    final png = _png;
    if (png == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$_fileName');
    await file.writeAsBytes(png, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'image/png')]));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final empty = widget.model.colors.isEmpty;
    Widget seg<T>(String label, List<(T, String)> options, T selected, ValueChanged<T> onChanged) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<T>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [for (final (v, l) in options) ButtonSegment(value: v, label: Text(l))],
                selected: {selected},
                onSelectionChanged: (s) {
                  onChanged(s.first);
                  _render();
                },
              ),
            ),
          ]),
        );
    final bgOptions = [
      (ImageBackground.light, t.bgLight),
      (ImageBackground.dark, t.bgDark),
      (ImageBackground.transparent, t.bgTransparent),
    ];
    final sizes = [(1, '1×'), (2, '2×'), (3, '3×')];
    return Scaffold(
      appBar: AppBar(title: Text(widget.overlay ? '${t.exportTitle} · ${t.exportOverlayImage}' : t.exportTitle)),
      body: empty
          ? Center(child: Text(t.toastNothingToExport))
          : ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomPaint(
                  painter: const CheckerPainter(cell: 10),
                  child: _png == null
                      ? const Center(child: CircularProgressIndicator())
                      : InteractiveViewer(maxScale: 8, child: Center(child: Image.memory(_png!, gaplessPlayback: true))),
                ),
              ),
              const SizedBox(height: 16),
              if (!widget.overlay) ...[
                seg(t.exportOrientation, [(true, t.horizontal), (false, t.vertical)], _palette.horizontal,
                    (v) => _palette = _palette.copyWith(horizontal: v)),
                seg(t.exportSize, sizes, _palette.scale, (v) => _palette = _palette.copyWith(scale: v)),
                seg(t.exportBackground, bgOptions, _palette.background, (v) => _palette = _palette.copyWith(background: v)),
              ] else ...[
                seg(t.exportShape, [(OverlayShape.square, t.shapeSquare), (OverlayShape.circle, t.shapeCircle), (OverlayShape.triangle, t.shapeTriangle)],
                    _overlay.shape, (v) => _overlay = _overlay.copyWith(shape: v)),
                seg(t.exportOrder, [(false, t.orderFirstLast), (true, t.orderLastFirst)], _overlay.reverse,
                    (v) => _overlay = _overlay.copyWith(reverse: v)),
                seg(t.exportSize, sizes, _overlay.scale, (v) => _overlay = _overlay.copyWith(scale: v)),
                seg(t.exportBackground, bgOptions, _overlay.background, (v) => _overlay = _overlay.copyWith(background: v)),
              ],
              Text(t.exportValues, style: Theme.of(context).textTheme.labelMedium),
              Wrap(spacing: 8, children: [
                FilterChip(
                  label: const Text('HSL'),
                  selected: widget.overlay ? _overlay.showHsl : _palette.showHsl,
                  onSelected: (v) {
                    widget.overlay ? _overlay = _overlay.copyWith(showHsl: v) : _palette = _palette.copyWith(showHsl: v);
                    _render();
                  },
                ),
                FilterChip(
                  label: const Text('CMYK'),
                  selected: widget.overlay ? _overlay.showCmyk : _palette.showCmyk,
                  onSelected: (v) {
                    widget.overlay ? _overlay = _overlay.copyWith(showCmyk: v) : _palette = _palette.copyWith(showCmyk: v);
                    _render();
                  },
                ),
              ]),
            ]),
      bottomNavigationBar: empty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(children: [
                  Expanded(child: _ActionButton(icon: Icons.save_alt_rounded, label: t.saveTo, onPressed: _saveTo)),
                  if (context.read<AppController>().platform.isAndroid)
                    Expanded(child: _ActionButton(icon: Icons.photo_outlined, label: t.saveToGallery, onPressed: _saveGallery)),
                  Expanded(child: _ActionButton(icon: Icons.share_rounded, label: t.share, onPressed: _share, primary: true)),
                ]),
              ),
            ),
    );
  }
}

/// Botón de acción compacto (ícono arriba, texto abajo) para que las etiquetas no se partan.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onPressed, this.primary = false});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = primary ? scheme.onPrimary : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: primary ? scheme.primary : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: fg),
              const SizedBox(height: 4),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }
}
