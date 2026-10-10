import 'package:flutter/material.dart';
import 'package:matiz_core/matiz_core.dart';

import '../l10n/generated/app_localizations.dart';
import '../ui/theme.dart';
import 'color_utils.dart';

/// Tarjeta compacta de un color generado: tocar = usar como principal; Copiar y Añadir siempre visibles;
/// "−" opcional (Personalizado); mantener = menú.
class SwatchCard extends StatelessWidget {
  const SwatchCard({
    super.key,
    required this.color,
    required this.label,
    required this.hex,
    this.isBase = false,
    this.selected = false,
    required this.onUse,
    required this.onCopy,
    required this.onAdd,
    this.onRemove,
    required this.onMenu,
  });

  final Argb color;
  final String label;
  final String hex;
  final bool isBase;
  final bool selected;
  final VoidCallback onUse;
  final VoidCallback onCopy;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final on = color.onColor;
    Widget action(IconData icon, String tip, VoidCallback onTap) => Semantics(
          button: true,
          label: tip,
          child: InkResponse(
            onTap: onTap,
            radius: 20,
            child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 18, color: on)),
          ),
        );
    return Semantics(
      label: '$label $hex',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? scheme.onSurface : Colors.transparent, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(children: [
                  Positioned.fill(child: ColorSwatchBox(color: color, radius: 10)),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(onTap: onUse, onLongPress: onMenu),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 6,
                    child: Text(label,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: on),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (isBase)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(width: 7, height: 7, decoration: BoxDecoration(color: on, shape: BoxShape.circle)),
                    ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Row(children: [
                      action(Icons.copy_rounded, t.copy, onCopy),
                      action(Icons.add_rounded, t.addToPalette, onAdd),
                    ]),
                  ),
                  if (onRemove != null)
                    Positioned(right: 0, bottom: 0, child: action(Icons.remove_rounded, t.remove, onRemove!)),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Text(hex,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: MatizTheme.mono.copyWith(fontSize: 12, color: scheme.onSurface)),
            ),
          ]),
        ),
      ),
    );
  }
}
