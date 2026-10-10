import 'package:flutter/material.dart';
import 'package:matiz_core/matiz_core.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../state/app_controller.dart';
import '../widgets/color_utils.dart';
import '../widgets/color_wheel.dart';
import '../widgets/current_color_bar.dart';
import '../widgets/swatch_card.dart';
import 'labels.dart';
import 'theme.dart';

/// Pestaña Generar: modos (chips), rueda compacta en Armonías/Personalizado, tarjetas y acciones.
class GeneratePage extends StatelessWidget {
  const GeneratePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final t = AppLocalizations.of(context);
    final modes = [
      GenerationMode.scale,
      GenerationMode.tintsShades,
      GenerationMode.neutrals,
      GenerationMode.harmony,
      GenerationMode.custom,
      if (c.hasExtracted) GenerationMode.extracted,
    ];
    return Column(children: [
      _ChipsRow(children: [
        for (final m in modes)
          ChoiceChip(label: Text(modeLabel(t, m)), selected: c.mode == m, onSelected: (_) => c.setMode(m)),
      ]),
      if (c.mode == GenerationMode.harmony)
        _ChipsRow(children: [
          for (final k in HarmonyKind.values)
            ChoiceChip(
              label: Text(harmonyLabel(t, k)),
              selected: c.harmony == k,
              onSelected: (_) => c.setHarmony(k),
              visualDensity: VisualDensity.compact,
            ),
        ]),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: c.markersVisible
            ? SizedBox(
                height: 190,
                child: Row(children: const [
                  Expanded(child: ColorWheel(compact: true)),
                  BrightnessBar(width: 32),
                ]),
              )
            : const CurrentColorBar(),
      ),
      const _ActionsRow(),
      const Expanded(child: _Cards()),
      const _BottomBar(),
    ]);
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) => Center(child: children[i]),
      ),
    );
  }
}

/// Fila de Equilibrar, "+", Borrar, Personalizar y cantidad de colores extraídos.
class _ActionsRow extends StatelessWidget {
  const _ActionsRow();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final t = AppLocalizations.of(context);
    final custom = c.mode == GenerationMode.custom;
    final extracted = c.mode == GenerationMode.extracted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: SizedBox(
        height: 48,
        child: Row(children: [
          if (c.markersVisible) ...[
            Switch(value: c.settings.harmonyBalanceLightness, onChanged: c.setBalance),
            Flexible(
              child: Text(t.balanceLightness,
                  style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ] else if (extracted) ...[
            IconButton(
              tooltip: '−',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: c.settings.extractCount > 1 ? () => c.setExtractCount(c.settings.extractCount - 1) : null,
            ),
            Text('${c.settings.extractCount}', style: MatizTheme.mono.copyWith(fontSize: 16)),
            IconButton(
              tooltip: '+',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: c.settings.extractCount < 64 ? () => c.setExtractCount(c.settings.extractCount + 1) : null,
            ),
            IconButton(
              tooltip: t.extractAgain,
              icon: c.image?.extracting ?? false
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded),
              onPressed: c.extract,
            ),
          ],
          const Spacer(),
          if (extracted)
            TextButton.icon(
              onPressed: c.customizeFromImage,
              icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
              label: Text(t.customize),
            ),
          if (custom && !c.freePoints.isEmpty)
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    content: Text(t.clearPointsConfirm),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t.cancel)),
                      FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t.clearPoints)),
                    ],
                  ),
                );
                if (ok == true) c.clearPoints();
              },
              child: Text(t.clearPoints),
            ),
          IconButton.filledTonal(
            tooltip: t.addPoint,
            icon: const Icon(Icons.add),
            onPressed: c.canAddPoint ? c.addPointButton : null,
          ),
        ]),
      ),
    );
  }
}

class _Cards extends StatelessWidget {
  const _Cards();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final t = AppLocalizations.of(context);
    final g = c.generated;
    final custom = c.mode == GenerationMode.custom;
    final selected = c.selectedGeneratedIndex;
    return LayoutBuilder(builder: (context, box) {
      final cols = (box.maxWidth / 118).floor().clamp(3, 8);
      return CustomScrollView(slivers: [
        if (custom && c.freePoints.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(t.customHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.92,
            ),
            itemCount: g.length,
            itemBuilder: (context, i) {
              final x = g[i];
              final hex = ColorFormats.hex(x.color, c.formatOptions);
              final label = x.isBase && x.label == 'Base' ? t.base : x.label;
              return SwatchCard(
                color: x.color,
                label: label,
                hex: hex,
                isBase: x.isBase,
                selected: i == selected,
                onUse: () => c.useGenerated(i),
                onCopy: () => c.copyDefault(x.color),
                onAdd: () => c.addGeneratedToPalette(i),
                onRemove: custom && g.length > 1 ? () => c.removeCustomCard(i) : null,
                onMenu: () => _menu(context, c, i),
              );
            },
          ),
        ),
      ]);
    });
  }

  void _menu(BuildContext context, AppController c, int i) {
    final t = AppLocalizations.of(context);
    final x = c.generated[i];
    final custom = c.mode == GenerationMode.custom;
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
              leading: SizedBox(width: 28, height: 28, child: ColorSwatchBox(color: x.color, radius: 6)),
              title: Text('${c.generatedName(i)} · ${x.color.toHex()}', style: MatizTheme.mono),
            ),
            ListTile(leading: const Icon(Icons.radio_button_checked), title: Text(t.useAsMain), onTap: () => run(() => c.useGenerated(i))),
            ListTile(leading: const Icon(Icons.copy_rounded), title: Text(t.copy), onTap: () => run(() => c.copyDefault(x.color))),
            ListTile(leading: const Icon(Icons.tag), title: Text(t.copyHex), onTap: () => run(() => c.copyHex(x.color))),
            ListTile(
              leading: const Icon(Icons.format_list_numbered),
              title: Text(t.copyRgb),
              onTap: () => run(() => c.copyText(ColorFormats.rgb(x.color), color: x.color)),
            ),
            ListTile(leading: const Icon(Icons.playlist_add_rounded), title: Text(t.addToPalette), onTap: () => run(() => c.addGeneratedToPalette(i))),
            if (custom && c.generated.length > 1)
              ListTile(leading: const Icon(Icons.remove_circle_outline), title: Text(t.remove), onTap: () => run(() => c.removeCustomCard(i))),
          ]),
        );
      },
    );
  }
}

class _BottomBar extends StatefulWidget {
  const _BottomBar();

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  late final TextEditingController _prefix =
      TextEditingController(text: context.read<AppController>().settings.scalePrefix);

  @override
  void dispose() {
    _prefix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.read<AppController>();
    final t = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(children: [
          SizedBox(
            width: 120,
            child: TextField(
              controller: _prefix,
              decoration: InputDecoration(labelText: t.prefix),
              onChanged: c.setPrefix,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: c.addAllGenerated,
              icon: const Icon(Icons.playlist_add_rounded, size: 18),
              label: Text(t.addAll, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: t.copyAs,
            icon: const Icon(Icons.code_rounded),
            onSelected: c.copyGeneratedAs,
            itemBuilder: (_) => [
              for (final f in PaletteFormatters.all) PopupMenuItem(value: f.id, child: Text('${t.copyAs} ${f.displayName}')),
            ],
          ),
        ]),
      ),
    );
  }
}
