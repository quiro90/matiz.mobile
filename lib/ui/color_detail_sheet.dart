import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matiz_core/matiz_core.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../state/app_controller.dart';
import '../widgets/current_color_bar.dart';
import 'export_image_page.dart';
import 'theme.dart';

Future<void> showColorDetailSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => _DetailBody(scroll: scroll),
      ),
    );

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final t = AppLocalizations.of(context);
    final st = c.current;
    final argb = st.argb;
    final o = c.formatOptions;
    final theme = Theme.of(context);

    Widget formatRow(String name, String value, {String? info}) => ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Row(children: [
            SizedBox(
              width: 64,
              child: Text(name, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            Expanded(child: SelectableText(value, style: MatizTheme.mono.copyWith(fontSize: 14))),
            if (info != null)
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                tooltip: info,
                onPressed: () => c.showToast(info),
              ),
          ]),
          trailing: IconButton(
            tooltip: t.copy,
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: () => c.copyText(value, color: argb),
          ),
        );

    final extra = ColorFormatters.all.where((f) => !const {'hex', 'rgb', 'hsl', 'hsv', 'cmyk', 'all'}.contains(f.id));

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(t.detailTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        const CurrentColorBar(height: 56),
        const SizedBox(height: 12),
        _ColorInput(key: ValueKey(argb), initial: ColorFormats.hex(argb, o)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _NumField(label: 'R', value: argb.r.toDouble(), min: 0, max: 255, onCommit: (v) => c.commitArgb(Argb(argb.a, v.round(), argb.g, argb.b), ColorChangeSource.manualInput))),
          const SizedBox(width: 8),
          Expanded(child: _NumField(label: 'G', value: argb.g.toDouble(), min: 0, max: 255, onCommit: (v) => c.commitArgb(Argb(argb.a, argb.r, v.round(), argb.b), ColorChangeSource.manualInput))),
          const SizedBox(width: 8),
          Expanded(child: _NumField(label: 'B', value: argb.b.toDouble(), min: 0, max: 255, onCommit: (v) => c.commitArgb(Argb(argb.a, argb.r, argb.g, v.round()), ColorChangeSource.manualInput))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _NumField(label: 'H', value: st.hue, min: 0, max: 360, decimals: 1, onCommit: (v) => c.commit(st.withHue(v), ColorChangeSource.manualInput))),
          const SizedBox(width: 8),
          Expanded(child: _NumField(label: 'S', value: st.saturation * 100, min: 0, max: 100, onCommit: (v) => c.commit(st.withSaturation(v / 100), ColorChangeSource.manualInput))),
          const SizedBox(width: 8),
          Expanded(child: _NumField(label: 'B', value: st.value * 100, min: 0, max: 100, onCommit: (v) => c.commit(st.withValue(v / 100), ColorChangeSource.manualInput))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Text(t.focus, style: theme.textTheme.labelMedium),
          const SizedBox(width: 8),
          Text(t.focusVivid, style: theme.textTheme.bodySmall),
          Expanded(
            child: Slider(
              value: c.settings.wheelFocus,
              min: -1,
              max: 1,
              onChanged: c.setFocus,
            ),
          ),
          Text(t.focusPastel, style: theme.textTheme.bodySmall),
          IconButton(tooltip: t.resetFocus, icon: const Icon(Icons.restart_alt, size: 20), onPressed: () => c.setFocus(0)),
        ]),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(onPressed: c.grayEquivalent, icon: const Icon(Icons.contrast, size: 18), label: Text(t.grayEquivalent)),
          OutlinedButton.icon(
            onPressed: () => c.copyText(ColorFormats.copyAll(argb, o), color: argb, what: t.toastCopiedAs(t.copyAll)),
            icon: const Icon(Icons.copy_all_rounded, size: 18),
            label: Text(t.copyAll),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ExportImagePage(
                      model: PaletteExportModel(t.previousCurrentTitle, [
                        PaletteExportColor(t.previous, c.previous.argb),
                        PaletteExportColor(t.current, argb),
                      ]),
                      overlay: true,
                    ))),
            icon: const Icon(Icons.layers_outlined, size: 18),
            label: Text(t.exportOverlay),
          ),
        ]),
        const SizedBox(height: 8),
        const Divider(),
        formatRow('HEX', ColorFormats.hex(argb, o)),
        if (!argb.isOpaque) formatRow('ARGB', ColorFormats.argbHex(argb, o)),
        formatRow('RGB', ColorFormats.rgb(argb)),
        formatRow('HSL', ColorFormats.hsl(argb)),
        formatRow('HSV', ColorFormats.hsv(argb)),
        formatRow('CMYK*', ColorFormats.cmyk(argb), info: t.cmykApprox),
        ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(t.moreFormats, style: theme.textTheme.labelLarge),
          children: [
            formatRow('OKLCH', ColorFormats.oklch(argb)),
            for (final f in extra) formatRow(f.displayName, f.format(argb, o)),
          ],
        ),
        const Divider(),
        Row(children: [
          Expanded(child: Text(t.recents, style: theme.textTheme.labelLarge)),
          if (c.history.items.isNotEmpty)
            IconButton(
              tooltip: t.clearRecents,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    content: Text(t.clearRecentsConfirm),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t.cancel)),
                      FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t.delete)),
                    ],
                  ),
                );
                if (ok == true) c.clearHistory();
              },
            ),
        ]),
        const RecentsRow(height: 44),
      ],
    );
  }
}

/// Campo de texto que acepta cualquier formato de color (Enter confirma; rojo si es inválido).
class _ColorInput extends StatefulWidget {
  const _ColorInput({super.key, required this.initial});

  final String initial;

  @override
  State<_ColorInput> createState() => _ColorInputState();
}

class _ColorInputState extends State<_ColorInput> {
  late final TextEditingController _ctl = TextEditingController(text: widget.initial);
  bool _invalid = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _submit(String text) {
    final ok = context.read<AppController>().commitText(text);
    setState(() => _invalid = !ok);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return TextField(
      controller: _ctl,
      style: MatizTheme.mono.copyWith(fontSize: 16),
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: t.colorInputHint,
        errorText: _invalid ? t.invalidColor : null,
        suffixIcon: IconButton(
          tooltip: t.paste,
          icon: const Icon(Icons.content_paste_rounded),
          onPressed: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            final text = data?.text?.trim();
            if (text == null || text.isEmpty) return;
            _ctl.text = text;
            _submit(text);
          },
        ),
      ),
      onChanged: (_) {
        if (_invalid) setState(() => _invalid = false);
      },
      onSubmitted: _submit,
    );
  }
}

/// Campo numérico con −/+ (repite al mantener) y validación de rango.
class _NumField extends StatefulWidget {
  const _NumField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onCommit,
    this.decimals = 0,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int decimals;
  final ValueChanged<double> onCommit;

  @override
  State<_NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<_NumField> {
  late final TextEditingController _ctl = TextEditingController(text: _fmt(widget.value));
  final FocusNode _focus = FocusNode();
  bool _invalid = false;
  Timer? _repeat;

  String _fmt(double v) => widget.decimals == 0 ? v.round().toString() : v.toStringAsFixed(widget.decimals);

  @override
  void didUpdateWidget(_NumField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && old.value != widget.value) {
      _ctl.text = _fmt(widget.value);
      _invalid = false;
    }
  }

  @override
  void dispose() {
    _repeat?.cancel();
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String s) {
    final v = double.tryParse(s.replaceAll(',', '.'));
    if (v == null || v < widget.min || v > widget.max) {
      setState(() => _invalid = true);
      return;
    }
    setState(() => _invalid = false);
    widget.onCommit(v);
  }

  void _step(double d) {
    final current = double.tryParse(_ctl.text.replaceAll(',', '.')) ?? widget.value;
    final v = (current + d).clamp(widget.min, widget.max).toDouble();
    _ctl.text = _fmt(v);
    widget.onCommit(v);
  }

  Widget _btn(IconData icon, double d) => GestureDetector(
        onLongPressStart: (_) => _repeat = Timer.periodic(const Duration(milliseconds: 70), (_) => _step(d)),
        onLongPressEnd: (_) => _repeat?.cancel(),
        child: IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 26, minHeight: 40),
          icon: Icon(icon, size: 16),
          onPressed: () => _step(d),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _btn(Icons.remove, -1),
      Expanded(
        child: TextField(
          controller: _ctl,
          focusNode: _focus,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: MatizTheme.mono.copyWith(fontSize: 13, letterSpacing: -0.5),
          decoration: InputDecoration(
            labelText: widget.label,
            errorText: _invalid ? '' : null,
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
          ),
          onSubmitted: _submit,
          onTapOutside: (_) {
            if (_focus.hasFocus) {
              _submit(_ctl.text);
              _focus.unfocus();
            }
          },
        ),
      ),
      _btn(Icons.add, 1),
    ]);
  }
}
