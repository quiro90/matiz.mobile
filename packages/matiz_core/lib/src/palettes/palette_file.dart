import 'dart:convert';
import 'dart:io';

import '../util/ids.dart';
import 'palette.dart';

/// Error de formato o versión al leer un `.mpalette`.
class PaletteFileException implements Exception {
  final String message;
  final bool unsupportedVersion;
  const PaletteFileException(this.message, {this.unsupportedVersion = false});
  @override
  String toString() => 'PaletteFileException: $message';
}

/// Formato de archivo de paleta (.mpalette): JSON versionado standalone con la paleta completa
/// (nombre, descripción, fechas y colores con nombre individual, en orden). Compatible con Matiz desktop.
class PaletteFile {
  static const int currentSchemaVersion = 1;

  int schemaVersion;
  String name;
  String? description;
  DateTime? createdAt;
  DateTime? modifiedAt;

  /// Vista en escala de grises guardada con la paleta (0–100, null = 0 %). Los `hex`
  /// del archivo son SIEMPRE los colores originales (sin gris horneado).
  int? grayPercent;
  List<PaletteColor> colors;

  PaletteFile({
    this.schemaVersion = currentSchemaVersion,
    this.name = '',
    this.description,
    this.createdAt,
    this.modifiedAt,
    this.grayPercent,
    List<PaletteColor>? colors,
  }) : colors = colors ?? [];

  static PaletteFile from(Palette palette) => PaletteFile(
        name: palette.name,
        description: palette.description,
        createdAt: palette.createdAt,
        modifiedAt: palette.modifiedAt,
        grayPercent: palette.grayPercent,
        colors: [...palette.colors],
      );

  /// Paleta nueva con datos del archivo e ids nuevos (paleta y colores).
  Palette toPalette() => Palette(
        name: name,
        description: description,
        createdAt: createdAt,
        modifiedAt: modifiedAt,
        grayPercent: grayPercent,
        colors: [for (final c in colors) PaletteColor(name: c.name, hex: c.hex, alpha: c.alpha)],
      );

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'name': name,
        if (description != null) 'description': description,
        'createdAt': formatDate(createdAt ?? DateTime.utc(1)),
        'modifiedAt': formatDate(modifiedAt ?? DateTime.utc(1)),
        if (grayPercent != null) 'grayPercent': grayPercent,
        'colors': [for (final c in colors) c.toJson()],
      };

  /// JSON indentado (mismo estilo que System.Text.Json con WriteIndented).
  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Escritura atómica (archivo temporal + reemplazo).
  void write(String path) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    final tmp = File('$path.tmp')..writeAsStringSync(encode(), flush: true);
    if (file.existsSync()) file.deleteSync();
    tmp.renameSync(path);
  }

  static PaletteFile read(String path) => decode(File(path).readAsStringSync());

  /// Lee y valida un `.mpalette`. Lanza [PaletteFileException] si no es una paleta válida o la versión es futura.
  static PaletteFile decode(String text) {
    Object? node;
    try {
      node = jsonDecode(text);
    } on FormatException catch (e) {
      throw PaletteFileException('JSON inválido: ${e.message}');
    }
    if (node is! Map) throw const PaletteFileException('Documento vacío o no es un objeto');
    final j = node.cast<String, Object?>();
    final version = (j['schemaVersion'] as num?)?.toInt() ?? 0;
    if (version > currentSchemaVersion) {
      throw PaletteFileException('.mpalette versión $version no soportada', unsupportedVersion: true);
    }
    final colors = j['colors'];
    if (j['name'] is! String && colors is! List) {
      throw const PaletteFileException('El archivo no contiene una paleta');
    }
    try {
      return PaletteFile(
        schemaVersion: version,
        name: (j['name'] as String?) ?? '',
        description: j['description'] as String?,
        createdAt: parseDate(j['createdAt']),
        modifiedAt: parseDate(j['modifiedAt']),
        grayPercent: Palette.readGrayPercent(j['grayPercent']),
        colors: [
          for (final c in (colors as List? ?? const []))
            if (c is Map) PaletteColor.fromJson(c.cast<String, Object?>()),
        ],
      );
    } on TypeError {
      throw const PaletteFileException('Estructura de paleta inválida');
    }
  }
}
