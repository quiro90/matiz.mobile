import '../colors/argb.dart';
import '../parsing/color_parser.dart';

/// Colores recientes: más reciente primero, sin duplicados, máximo [capacity].
class ColorHistory {
  static const int capacity = 30;

  final List<Argb> _items = [];
  void Function()? onChanged;

  ColorHistory([Iterable<Argb>? items]) {
    if (items == null) return;
    for (final c in items.toList().reversed) {
      _add(c, raise: false);
    }
  }

  List<Argb> get items => List.unmodifiable(_items);

  void add(Argb color) => _add(color, raise: true);

  void clear() {
    _items.clear();
    onChanged?.call();
  }

  void _add(Argb color, {required bool raise}) {
    final existing = _items.indexOf(color);
    if (existing == 0) return;
    if (existing > 0) _items.removeAt(existing);
    _items.insert(0, color);
    if (_items.length > capacity) _items.removeRange(capacity, _items.length);
    if (raise) onChanged?.call();
  }

  /// Contenido de history.json.
  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'colors': [for (final c in _items) c.toString()],
      };

  static ColorHistory fromJson(Map<String, Object?> j) => ColorHistory([
        for (final s in (j['colors'] as List? ?? const []))
          ?ColorParser.parse(s is String ? s : null),
      ]);
}
