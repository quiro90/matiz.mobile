import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matiz_core/matiz_core.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../state/app_controller.dart';
import '../widgets/color_utils.dart';
import '../widgets/color_wheel.dart';
import '../widgets/current_color_bar.dart';
import '../widgets/image_canvas.dart';
import 'camera_page.dart';
import 'labels.dart';

/// Pestaña Crear: rueda o imagen (foco), barra Anterior | Actual, Recientes y vista previa del modo generado.
class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 600;
      const source = _SourceArea();
      const panel = Column(mainAxisSize: MainAxisSize.min, children: [
        CurrentColorBar(),
        SizedBox(height: 6),
        RecentsRow(),
        SizedBox(height: 6),
        _GeneratedPreview(),
      ]);
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: wide
            ? Row(children: [
                const Expanded(child: Column(children: [_SourceToolbar(), Expanded(child: source)])),
                const SizedBox(width: 16),
                SizedBox(width: 360, child: Center(child: SingleChildScrollView(child: panel))),
              ])
            : const Column(children: [
                _SourceToolbar(),
                Expanded(child: source),
                SizedBox(height: 6),
                panel,
              ]),
      );
    });
  }
}

class _SourceToolbar extends StatelessWidget {
  const _SourceToolbar();

  Future<void> _openImage(BuildContext context) async {
    final c = context.read<AppController>();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, requestFullMetadata: false);
    if (file == null) return;
    await c.loadImageBytes(await file.readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final t = AppLocalizations.of(context);
    final hasImage = c.image != null;
    return SizedBox(
      height: 52,
      child: Row(children: [
        if (hasImage)
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SegmentedButton<bool>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              ButtonSegment(value: false, icon: const Icon(Icons.palette_outlined, size: 18), label: Text(t.sourceWheel)),
              ButtonSegment(value: true, icon: const Icon(Icons.image_outlined, size: 18), label: Text(t.sourceImage)),
            ],
            selected: {c.showImage},
            onSelectionChanged: (s) => c.setShowImage(s.first),
              ),
            ),
          ),
        if (!hasImage) const Spacer(),
        if (c.loadingImage) const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
        IconButton(visualDensity: VisualDensity.compact, tooltip: t.openImage, icon: const Icon(Icons.photo_library_outlined), onPressed: () => _openImage(context)),
        IconButton(visualDensity: VisualDensity.compact, tooltip: t.pasteAction, icon: const Icon(Icons.content_paste_rounded), onPressed: c.pasteSmart),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: t.camera,
          icon: const Icon(Icons.photo_camera_outlined),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CameraPage())),
        ),
        if (hasImage && c.showImage)
          IconButton(visualDensity: VisualDensity.compact, tooltip: t.closeImage, icon: const Icon(Icons.close_rounded), onPressed: c.closeImage),
      ]),
    );
  }
}

class _SourceArea extends StatelessWidget {
  const _SourceArea();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final t = AppLocalizations.of(context);
    final doc = c.image;
    if (c.showImage && doc != null) {
      return Column(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ImageCanvas(key: ObjectKey(doc), doc: doc),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(t.loupeHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ]);
    }
    return const Row(children: [
      Expanded(child: ColorWheel()),
      BrightnessBar(),
    ]);
  }
}

/// Tira con los colores del modo generado activo; tocar lleva a Generar.
class _GeneratedPreview extends StatelessWidget {
  const _GeneratedPreview();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final t = AppLocalizations.of(context);
    final g = c.generated;
    final title = modeLabel(t, c.mode) + (c.mode == GenerationMode.harmony ? ' · ${harmonyLabel(t, c.harmony)}' : '');
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => c.setTab(Tabs.generate),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 6, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.chevron_right, size: 18),
            ]),
            const SizedBox(height: 4),
            SizedBox(
              height: 24,
              child: Row(children: [
                for (final x in g.take(16))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: ColorSwatchBox(color: x.color, radius: 4, border: false),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
