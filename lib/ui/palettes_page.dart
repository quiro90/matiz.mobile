import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matiz_core/matiz_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../state/app_controller.dart';
import '../widgets/color_utils.dart';
import 'export_image_page.dart';
import 'theme.dart';

/// Pestaña Paletas: paleta activa (reordenable) y biblioteca.
class PalettesPage extends StatelessWidget {
  const PalettesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final t = AppLocalizations.of(context);
    final active = c.activePalette;
    final all = c.palettes.palettes;
    return CustomScrollView(slivers: [
      if (active == null)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.palette_outlined, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(t.emptyLibrary, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Wrap(spacing: 8, children: [
                FilledButton.icon(onPressed: c.createPalette, icon: const Icon(Icons.add), label: Text(t.newPalette)),
                OutlinedButton.icon(
                    onPressed: () => importPaletteFile(context), icon: const Icon(Icons.file_open_outlined), label: Text(t.importFile)),
              ]),
            ]),
          ),
        )
      else ...[
        SliverToBoxAdapter(child: _ActiveHeader(palette: active)),
        if (active.colors.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(t.emptyPalette, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          )
        else
          _ActiveColors(palette: active),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
            child: Row(children: [
              Expanded(child: Text(t.library, style: Theme.of(context).textTheme.titleMedium)),
              TextButton.icon(onPressed: () => importPaletteFile(context), icon: const Icon(Icons.file_open_outlined, size: 18), label: Text(t.importFile)),
              TextButton.icon(onPressed: c.createPalette, icon: const Icon(Icons.add, size: 18), label: Text(t.newPalette)),
            ]),
          ),
        ),
        SliverList.builder(
          itemCount: all.length,
          itemBuilder: (context, i) => _LibraryItem(palette: all[i], active: identical(all[i], active)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    ]);
  }
}

/// Importa un `.mpalette` con el selector de archivos del sistema.
Future<void> importPaletteFile(BuildContext context) async {
  final c = context.read<AppController>();
  final files = await FilePicker.pickFiles(type: FileType.any);
  if (files.isEmpty) return;
  final bytes = await files.first.readAsBytes();
  try {
    c.importPaletteText(utf8.decode(bytes));
  } on FormatException {
    c.showToast(c.t.toastImportFailed);
  }
}

class _ActiveHeader extends StatelessWidget {
  const _ActiveHeader({required this.palette});

  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final c = context.read<AppController>();
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasColors = palette.colors.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.activePalette.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.8)),
        Row(children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _editNameAndDescription(context, palette),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(palette.name, style: theme.textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    Icon(Icons.edit_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  ]),
                  Text(
                    [t.colorsCount(palette.colors.length), if (palette.description != null) palette.description!].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ]),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: t.more,
            onSelected: (v) => _onAction(context, v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'duplicate', child: ListTile(leading: const Icon(Icons.copy_all_outlined), title: Text(t.duplicate))),
              PopupMenuItem(value: 'delete', child: ListTile(leading: const Icon(Icons.delete_outline), title: Text(t.delete))),
            ],
          ),
        ]),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            FilledButton.tonalIcon(
              onPressed: hasColors ? () => c.reloadInWheel(palette.id) : null,
              icon: const Icon(Icons.donut_large, size: 18),
              label: Text(t.reloadInWheel),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: hasColors ? () => _exportSheet(context) : null,
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: Text(t.export),
            ),
          ]),
        ),
        _GrayscaleRow(
          value: palette.grayPercent ?? 0,
          hasColors: hasColors,
          onChanged: (v) => c.setGrayPercent(palette.id, v),
        ),
        if (hasColors)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(t.reorderHint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
      ]),
    );
  }

  /// Todas las salidas de la paleta en un solo lugar: imagen, archivo y código.
  Future<void> _exportSheet(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        Widget item(String value, IconData icon, String title) =>
            ListTile(leading: Icon(icon), title: Text(title), onTap: () => Navigator.pop(ctx, value));
        Widget header(String text) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(text.toUpperCase(), style: Theme.of(ctx).textTheme.labelSmall),
            );
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              header(t.exportImage),
              item('image', Icons.image_outlined, t.exportPaletteImage),
              item('overlay', Icons.layers_outlined, t.exportOverlayImage),
              header(t.exportFile),
              item('file-save', Icons.save_alt_rounded, t.saveTo),
              item('file-share', Icons.share_rounded, t.share),
              header(t.exportCode),
              item('code', Icons.code_rounded, t.copyAs),
              item('share-text', Icons.text_snippet_outlined, t.shareAs),
            ]),
          ),
        );
      },
    );
    if (action != null && context.mounted) await _onAction(context, action);
  }

  Future<void> _onAction(BuildContext context, String action) async {
    final c = context.read<AppController>();
    final t = AppLocalizations.of(context);
    switch (action) {
      case 'image':
      case 'overlay':
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                ExportImagePage(model: PaletteExportModel.fromGrayed(palette), overlay: action == 'overlay')));
      case 'file-save':
        try {
          final uri = await FilePicker.saveFile(
              fileName: c.paletteFileName(palette), bytes: c.exportPaletteFile(palette), mimeType: 'application/json');
          if (uri != null) c.notifyExported(palette);
        } catch (_) {
          c.showToast(t.toastSaveFailed);
        }
      case 'file-share':
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}${Platform.pathSeparator}${c.paletteFileName(palette)}');
        await file.writeAsBytes(c.exportPaletteFile(palette), flush: true);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'application/json')]));
      case 'code':
      case 'share-text':
        if (!context.mounted) return;
        final id = await showModalBottomSheet<String>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final f in PaletteFormatters.all)
                ListTile(leading: const Icon(Icons.code_rounded), title: Text(f.displayName), onTap: () => Navigator.pop(ctx, f.id)),
            ]),
          ),
        );
        if (id == null) return;
        if (action == 'code') {
          c.copyPaletteAs(palette, id);
        } else {
          await SharePlus.instance.share(ShareParams(text: c.paletteAsText(palette, id), subject: palette.name));
        }
      case 'duplicate':
        c.duplicatePalette(palette.id);
      case 'delete':
        c.deletePalette(palette.id);
    }
  }

  Future<void> _editNameAndDescription(BuildContext context, Palette p) async {
    final c = context.read<AppController>();
    final t = AppLocalizations.of(context);
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _NameDescDialog(
        paletteName: p.name,
        paletteDescription: p.description,
        t: t,
      ),
    );
    if (result != null) {
      c.renamePalette(p.id, result.$1);
      c.setPaletteDescription(p.id, result.$2);
    }
  }
}

/// Fila siempre visible del modo de vista en escala de grises. 0 % = colores originales;
/// mover aplica en caliente sin tocar modifiedAt. Deshabilitada sin colores.
class _GrayscaleRow extends StatelessWidget {
  const _GrayscaleRow({required this.value, required this.hasColors, required this.onChanged});

  final int value;
  final bool hasColors;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(children: [
      const SizedBox(width: 8),
      Text(t.grayscaleTitle, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      Expanded(
        child: Slider(
          value: value.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          label: '$value %',
          onChanged: hasColors ? (v) => onChanged(v.round()) : null,
        ),
      ),
      SizedBox(
        width: 44,
        child: Text('$value %', textAlign: TextAlign.center, style: MatizTheme.mono.copyWith(fontSize: 12)),
      ),
      IconButton(
        tooltip: t.grayscaleReset,
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.restart_alt, size: 20),
        onPressed: hasColors && value > 0 ? () => onChanged(0) : null,
      ),
    ]);
  }
}

/// Colores de la paleta activa: tocar = usar; mantener y arrastrar = reordenar; mantener sin mover = menú.
class _ActiveColors extends StatelessWidget {
  const _ActiveColors({required this.palette});

  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final c = context.read<AppController>();
    final colors = palette.colors;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverReorderableList(
        itemCount: colors.length,
        onReorderItem: (oldIndex, newIndex) {
          // Mantener pulsado y soltar sin mover: abre el menú del color.
          if (newIndex == oldIndex) {
            _menu(context, c, palette, colors[oldIndex]);
            return;
          }
          c.movePaletteColor(palette.id, colors[oldIndex].id, newIndex);
        },
        proxyDecorator: (child, index, animation) => Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
        itemBuilder: (context, i) {
          final pc = colors[i];
          final original = pc.color;
          // Vista mezclada hacia gris; las acciones (usar, copiar, menú) operan sobre el color original.
          final display = ColorMath.mixToGray(original, (palette.grayPercent ?? 0) / 100.0);
          return ReorderableDelayedDragStartListener(
            key: ValueKey(pc.id),
            index: i,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => c.usePaletteColor(original),
                  child: SizedBox(
                    height: 56,
                    child: Row(children: [
                      SizedBox(width: 72, child: ColorSwatchBox(color: display, radius: 0, border: false)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(pc.name ?? 'Color ${i + 1}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                          Text(display.toString(), style: MatizTheme.mono.copyWith(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ]),
                      ),
                      IconButton(
                        tooltip: AppLocalizations.of(context).copy,
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        onPressed: () => c.copyDefault(original),
                      ),
                      IconButton(
                        tooltip: AppLocalizations.of(context).delete,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => c.removePaletteColor(palette.id, pc.id),
                      ),
                      IconButton(
                        tooltip: AppLocalizations.of(context).more,
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _menu(context, c, palette, pc),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static void _menu(BuildContext context, AppController c, Palette p, PaletteColor pc) {
    final t = AppLocalizations.of(context);
    final index = p.colors.indexOf(pc);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        void run(VoidCallback f) {
          Navigator.pop(ctx);
          f();
        }

        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: SizedBox(width: 28, height: 28, child: ColorSwatchBox(color: pc.color, radius: 6)),
              title: Text('${pc.name ?? 'Color ${index + 1}'} · ${pc.color}', style: MatizTheme.mono),
            ),
            ListTile(leading: const Icon(Icons.copy_rounded), title: Text(t.copy), onTap: () => run(() => c.copyDefault(pc.color))),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: Text(t.rename),
              onTap: () async {
                Navigator.pop(ctx);
                final newName = await showDialog<String>(
                  context: context,
                  builder: (_) => _TextPromptDialog(
                    label: t.renameColor,
                    initial: pc.name ?? '',
                    labelCancel: t.cancel,
                    labelSave: t.save,
                  ),
                );
                if (newName != null) c.renamePaletteColor(p.id, pc.id, newName);
              },
            ),
            ListTile(leading: const Icon(Icons.find_replace), title: Text(t.replaceWithCurrent), onTap: () => run(() => c.replacePaletteColor(p.id, pc.id))),
            if (index > 0)
              ListTile(leading: const Icon(Icons.vertical_align_top), title: Text(t.moveFirst), onTap: () => run(() => c.movePaletteColor(p.id, pc.id, 0))),
            if (index < p.colors.length - 1)
              ListTile(
                  leading: const Icon(Icons.vertical_align_bottom),
                  title: Text(t.moveLast),
                  onTap: () => run(() => c.movePaletteColor(p.id, pc.id, p.colors.length - 1))),
          ]),
        );
      },
    );
  }
}

class _LibraryItem extends StatelessWidget {
  const _LibraryItem({required this.palette, required this.active});

  final Palette palette;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.read<AppController>();
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = DateFormat.yMMMd(t.localeName).add_Hm().format(palette.modifiedAt.toLocal());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: active ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => c.setActivePalette(palette.id),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(palette.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (active)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(10)),
                    child: Text(t.activeBadge, style: TextStyle(fontSize: 11, color: theme.colorScheme.onPrimary)),
                  ),
              ]),
              Text('${t.colorsCount(palette.colors.length)} · $date',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              if (palette.colors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 3, runSpacing: 3, children: [
                  for (final pc in palette.colors.take(64)) SizedBox(width: 18, height: 18, child: ColorSwatchBox(color: pc.color, radius: 4)),
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Diálogo de nombre + descripción. Los controllers viven en el State y se liberan al desmontarse:
/// disposearlos en el caller rompe el TextField mientras el diálogo anima su salida.
class _NameDescDialog extends StatefulWidget {
  const _NameDescDialog({required this.paletteName, required this.paletteDescription, required this.t});

  final String? paletteName;
  final String? paletteDescription;
  final AppLocalizations t;

  @override
  State<_NameDescDialog> createState() => _NameDescDialogState();
}

class _NameDescDialogState extends State<_NameDescDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.paletteName);
  late final TextEditingController _desc = TextEditingController(text: widget.paletteDescription);

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return AlertDialog(
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _name, autofocus: true, decoration: InputDecoration(labelText: t.paletteName)),
        const SizedBox(height: 12),
        TextField(controller: _desc, maxLines: 3, minLines: 1, decoration: InputDecoration(labelText: t.paletteDescription, hintText: t.descriptionHint)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: Text(t.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, (_name.text, _desc.text)), child: Text(t.save)),
      ],
    );
  }
}

/// Diálogo de un solo campo de texto (devuelve el texto o null si se cancela).
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({required this.label, required this.initial, required this.labelCancel, required this.labelSave});

  final String label;
  final String initial;
  final String labelCancel;
  final String labelSave;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _ctl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: TextField(controller: _ctl, autofocus: true, decoration: InputDecoration(labelText: widget.label)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: Text(widget.labelCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _ctl.text), child: Text(widget.labelSave)),
      ],
    );
  }
}
