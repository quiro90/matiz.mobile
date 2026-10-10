import '../colors/argb.dart';
import '../localization/texts.dart';
import 'palette.dart';
import 'palette_file.dart';

/// Operaciones sobre la biblioteca de paletas. Toda modificación actualiza modifiedAt y notifica
/// [onChanged] (la capa de persistencia se suscribe para autoguardar).
class PaletteService {
  /// Límite de colores por paleta (regla global).
  static const int maxColors = 64;

  static String get defaultName => Texts.current.untitledPalette;

  final PaletteLibrary library;
  final DateTime Function() _clock;
  void Function()? onChanged;

  PaletteService(this.library, {DateTime Function()? clock, this.onChanged})
      : _clock = clock ?? (() => DateTime.now().toUtc()) {
    if (library.activePaletteId != null && find(library.activePaletteId!) == null) library.activePaletteId = null;
    library.activePaletteId ??= library.palettes.isEmpty ? null : library.palettes.first.id;
  }

  List<Palette> get palettes => library.palettes;

  Palette? get active => library.activePaletteId == null ? null : find(library.activePaletteId!);

  void _changed() => onChanged?.call();

  Palette? find(String id) {
    for (final p in library.palettes) {
      if (p.id == id) return p;
    }
    return null;
  }

  void setActive(String? id) {
    if (id != null && find(id) == null) return;
    library.activePaletteId = id;
    _changed();
  }

  Palette create({String? name, bool activate = true}) {
    final now = _clock();
    final p = Palette(
      name: _uniqueName(name == null || name.trim().isEmpty ? defaultName : name.trim()),
      createdAt: now,
      modifiedAt: now,
    );
    library.palettes.add(p);
    if (activate) library.activePaletteId = p.id;
    _changed();
    return p;
  }

  /// Paleta activa, creando una nueva si no hay ninguna.
  Palette ensureActive() => active ?? create();

  void rename(String id, String name) {
    final p = find(id);
    if (p == null || name.trim().isEmpty) return;
    p.name = name.trim();
    _touch(p);
  }

  void setDescription(String id, String? description) {
    final p = find(id);
    if (p == null) return;
    p.description = description == null || description.trim().isEmpty ? null : description;
    _touch(p);
  }

  /// Cambia el porcentaje de la vista en escala de grises de la paleta.
  /// Es estado de presentación: NO toca modifiedAt y guardar colores no se ve afectado.
  void setGrayPercent(String id, int value) {
    final p = find(id);
    if (p == null) return;
    final v = value <= 0 ? null : (value >= 100 ? 100 : value);
    if (p.grayPercent == v) return;
    p.grayPercent = v;
    _changed();
  }

  Palette? duplicate(String id) {
    final src = find(id);
    if (src == null) return null;
    final now = _clock();
    final copy = Palette(
      name: _uniqueName('${src.name} ${Texts.current.copySuffix}'),
      description: src.description,
      createdAt: now,
      modifiedAt: now,
      colors: [for (final c in src.colors) c.clone()],
    );
    library.palettes.insert(library.palettes.indexOf(src) + 1, copy);
    library.activePaletteId = copy.id;
    _changed();
    return copy;
  }

  /// Elimina y devuelve la paleta y su índice (para deshacer con [restore]).
  ({Palette palette, int index})? delete(String id) {
    final p = find(id);
    if (p == null) return null;
    final index = library.palettes.indexOf(p);
    library.palettes.removeAt(index);
    if (library.activePaletteId == id) {
      library.activePaletteId = library.palettes.isEmpty
          ? null
          : library.palettes[index < library.palettes.length ? index : library.palettes.length - 1].id;
    }
    _changed();
    return (palette: p, index: index);
  }

  void restore(Palette palette, int index) {
    if (find(palette.id) != null) return;
    library.palettes.insert(index.clamp(0, library.palettes.length), palette);
    library.activePaletteId = palette.id;
    _changed();
  }

  /// Importación desde `.mpalette`: SIEMPRE crea una paleta nueva (sufijo automático en colisiones de nombre),
  /// conserva nombre, descripción, fechas y colores completos (sin límite), con ids nuevos; queda activa.
  Palette import(PaletteFile file) {
    final now = _clock();
    final createdAt = _isDefault(file.createdAt) ? now : file.createdAt!;
    final modifiedAt =
        _isDefault(file.modifiedAt) || file.modifiedAt!.isBefore(createdAt) ? createdAt : file.modifiedAt!;
    final p = file.toPalette();
    p.name = _uniqueName(file.name.trim().isEmpty ? defaultName : file.name.trim());
    p.description = _normalize(file.description);
    p.createdAt = createdAt;
    p.modifiedAt = modifiedAt;
    for (final c in p.colors) {
      c.name = _normalize(c.name);
    }
    library.palettes.add(p);
    library.activePaletteId = p.id;
    _changed();
    return p;
  }

  PaletteColor? addColor(String paletteId, Argb color, [String? name]) {
    final p = find(paletteId);
    if (p == null || p.colors.length >= maxColors) return null;
    final pc = PaletteColor.create(color, _normalize(name));
    p.colors.add(pc);
    _touch(p);
    return pc;
  }

  /// Añade un lote en bloque: si el total superaría [maxColors] no añade ninguno (todo-o-nada) y devuelve 0.
  int addColors(String paletteId, List<({Argb color, String? name})> colors) {
    final p = find(paletteId);
    if (p == null || colors.isEmpty || p.colors.length + colors.length > maxColors) return 0;
    for (final c in colors) {
      p.colors.add(PaletteColor.create(c.color, _normalize(c.name)));
    }
    _touch(p);
    return colors.length;
  }

  void renameColor(String paletteId, String colorId, String? name) {
    final f = _findColor(paletteId, colorId);
    if (f == null) return;
    f.color.name = _normalize(name);
    _touch(f.palette);
  }

  void replaceColor(String paletteId, String colorId, Argb color) {
    final f = _findColor(paletteId, colorId);
    if (f == null) return;
    f.color.color = color;
    _touch(f.palette);
  }

  void removeColor(String paletteId, String colorId) {
    final f = _findColor(paletteId, colorId);
    if (f == null) return;
    f.palette.colors.remove(f.color);
    _touch(f.palette);
  }

  /// Reinserta un color quitado (deshacer). No aplica el límite: restaura el estado previo exacto.
  void insertColor(String paletteId, PaletteColor color, int index) {
    final p = find(paletteId);
    if (p == null || p.colors.any((c) => c.id == color.id)) return;
    p.colors.insert(index.clamp(0, p.colors.length), color);
    _touch(p);
  }

  void moveColor(String paletteId, String colorId, int newIndex) {
    final f = _findColor(paletteId, colorId);
    if (f == null) return;
    final colors = f.palette.colors;
    final old = colors.indexOf(f.color);
    newIndex = newIndex.clamp(0, colors.length - 1);
    if (old == newIndex) return;
    colors.removeAt(old);
    colors.insert(newIndex, f.color);
    _touch(f.palette);
  }

  ({Palette palette, PaletteColor color})? _findColor(String paletteId, String colorId) {
    final p = find(paletteId);
    if (p == null) return null;
    for (final c in p.colors) {
      if (c.id == colorId) return (palette: p, color: c);
    }
    return null;
  }

  void _touch(Palette p) {
    final now = _clock();
    p.modifiedAt = now.isAfter(p.modifiedAt) ? now : p.modifiedAt.add(const Duration(microseconds: 1));
    _changed();
  }

  String _uniqueName(String name) {
    bool free(String n) => library.palettes.every((p) => p.name.toLowerCase() != n.toLowerCase());
    if (free(name)) return name;
    for (var i = 2;; i++) {
      final candidate = '$name $i';
      if (free(candidate)) return candidate;
    }
  }

  static bool _isDefault(DateTime? d) => d == null || d.year <= 1;

  static String? _normalize(String? name) => name == null || name.trim().isEmpty ? null : name.trim();
}
