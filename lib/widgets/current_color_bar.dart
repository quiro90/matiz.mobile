import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../state/app_controller.dart';
import '../ui/color_detail_sheet.dart';
import '../ui/theme.dart';
import 'color_utils.dart';

/// Barra compacta Anterior | Actual con Copiar y Añadir a paleta.
/// Tocar Anterior lo restaura; tocar Actual abre la hoja de detalle.
class CurrentColorBar extends StatelessWidget {
  const CurrentColorBar({super.key, this.height = 56});

  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final t = AppLocalizations.of(context);
    final cur = c.currentArgb;
    final prev = c.previous.argb;
    final hex = c.defaultFormatter.id == 'hex' ? c.defaultFormatter.format(cur, c.formatOptions) : cur.toHex();
    return SizedBox(
      height: height,
      child: Row(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Row(children: [
              SizedBox(
                width: 64,
                child: Semantics(
                  button: true,
                  label: '${t.previous} ${prev.toHex()}',
                  child: Material(
                    color: prev.toColor,
                    child: InkWell(
                      onTap: c.restorePrevious,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(t.previous,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: TextStyle(fontSize: 10, color: prev.onColor)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: '${t.current} ${cur.toHex()}',
                  child: Material(
                    color: cur.toColor,
                    child: InkWell(
                      onTap: () => showColorDetailSheet(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.current, style: TextStyle(fontSize: 10, color: cur.onColor)),
                                Text(hex,
                                    maxLines: 1,
                                    style: MatizTheme.mono.copyWith(
                                        fontSize: 18, fontWeight: FontWeight.w700, color: cur.onColor)),
                              ],
                            ),
                          ),
                          Icon(Icons.tune, size: 18, color: cur.onColor),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: t.copyColorA11y(c.defaultFormatter.format(cur, c.formatOptions)),
          icon: const Icon(Icons.copy_rounded),
          onPressed: () => c.copyDefault(cur),
        ),
        IconButton(
          tooltip: t.addToPalette,
          icon: const Icon(Icons.playlist_add_rounded),
          onPressed: () => c.addToActive(cur),
        ),
      ]),
    );
  }
}

/// Fila desplazable de colores recientes. Tocar = usar; mantener = copiar / añadir.
class RecentsRow extends StatelessWidget {
  const RecentsRow({super.key, this.height = 40});

  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final t = AppLocalizations.of(context);
    final items = c.history.items;
    if (items.isEmpty) {
      return SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(t.noRecents,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final color = items[i];
          return Semantics(
            button: true,
            label: color.toHex(),
            child: GestureDetector(
              onTap: () => c.usePaletteColor(color),
              onLongPress: () => _menu(context, c, color),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: (height - 32) / 2),
                child: SizedBox(width: 32, height: 32, child: ColorSwatchBox(color: color, radius: 8)),
              ),
            ),
          );
        },
      ),
    );
  }

  void _menu(BuildContext context, AppController c, color) {
    final t = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: SizedBox(width: 28, height: 28, child: ColorSwatchBox(color: color, radius: 6)),
            title: Text(color.toHex(), style: MatizTheme.mono),
          ),
          ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: Text(t.copy),
            onTap: () {
              Navigator.pop(ctx);
              c.copyDefault(color);
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded),
            title: Text(t.addToPalette),
            onTap: () {
              Navigator.pop(ctx);
              c.addToActive(color);
            },
          ),
        ]),
      ),
    );
  }
}
