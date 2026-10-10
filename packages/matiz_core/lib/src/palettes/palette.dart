import '../colors/argb.dart';
import '../parsing/color_parser.dart';
import '../util/ids.dart';

/// Color dentro de una paleta. Se persiste como "#RRGGBB" + alpha opcional (omitido si 255).
class PaletteColor {
  String id;
  String? name;
  String hex;
  int? alpha;

  PaletteColor({String? id, this.name, this.hex = '#000000', this.alpha}) : id = id ?? newGuid();

  Argb get color {
    final c = ColorParser.parse(hex);
    return c == null ? const Argb.fromRgb(0, 0, 0) : c.withAlpha(alpha ?? 255);
  }

  set color(Argb value) {
    hex = value.toHex();
    alpha = value.isOpaque ? null : value.a;
  }

  static PaletteColor create(Argb color, [String? name]) => PaletteColor(name: name)..color = color;

  PaletteColor clone() => PaletteColor(name: name, hex: hex, alpha: alpha);

  Map<String, Object?> toJson() => {
        'id': id,
        if (name != null) 'name': name,
        'hex': hex,
        if (alpha != null) 'alpha': alpha,
      };

  static PaletteColor fromJson(Map<String, Object?> j) => PaletteColor(
        id: j['id'] is String ? j['id'] as String : null,
        name: j['name'] as String?,
        hex: (j['hex'] as String?) ?? '#000000',
        alpha: (j['alpha'] as num?)?.toInt(),
      );
}

class Palette {
  String id;
  String name;
  String? description;
  DateTime createdAt;
  DateTime modifiedAt;

  /// Porcentaje de vista en escala de grises recordado por la paleta
  /// (estado de presentación, no de datos; null = 0 %). Paridad con desktop.
  int? grayPercent;
  List<PaletteColor> colors;

  Palette({
    String? id,
    this.name = '',
    this.description,
    DateTime? createdAt,
    DateTime? modifiedAt,
    this.grayPercent,
    List<PaletteColor>? colors,
  })  : id = id ?? newGuid(),
        createdAt = createdAt ?? DateTime.utc(1),
        modifiedAt = modifiedAt ?? DateTime.utc(1),
        colors = colors ?? [];

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'createdAt': formatDate(createdAt),
        'modifiedAt': formatDate(modifiedAt),
        if (grayPercent != null) 'grayPercent': grayPercent,
        'colors': [for (final c in colors) c.toJson()],
      };

  static Palette fromJson(Map<String, Object?> j) => Palette(
        id: j['id'] is String ? j['id'] as String : null,
        name: (j['name'] as String?) ?? '',
        description: j['description'] as String?,
        createdAt: parseDate(j['createdAt']),
        modifiedAt: parseDate(j['modifiedAt']),
        grayPercent: readGrayPercent(j['grayPercent']),
        colors: [
          for (final c in (j['colors'] as List? ?? const []))
            if (c is Map) PaletteColor.fromJson(c.cast<String, Object?>()),
        ],
      );

  /// Lee `grayPercent` tolerante: null = 0 %; entero válido 1–100 se conserva;
  /// 0, no numéricos y fuera de rango se normalizan a null.
  static int? readGrayPercent(Object? v) {
    final n = v is int ? v : null;
    return n == null || n <= 0 || n > 100 ? null : n;
  }
}

/// Contenido de palettes.json.
class PaletteLibrary {
  static const int currentSchemaVersion = 1;

  int schemaVersion;
  String? activePaletteId;
  List<Palette> palettes;

  PaletteLibrary({this.schemaVersion = currentSchemaVersion, this.activePaletteId, List<Palette>? palettes})
      : palettes = palettes ?? [];

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        if (activePaletteId != null) 'activePaletteId': activePaletteId,
        'palettes': [for (final p in palettes) p.toJson()],
      };

  static PaletteLibrary fromJson(Map<String, Object?> j) => PaletteLibrary(
        schemaVersion: (j['schemaVersion'] as num?)?.toInt() ?? currentSchemaVersion,
        activePaletteId: j['activePaletteId'] as String?,
        palettes: [
          for (final p in (j['palettes'] as List? ?? const []))
            if (p is Map) Palette.fromJson(p.cast<String, Object?>()),
        ],
      );
}
