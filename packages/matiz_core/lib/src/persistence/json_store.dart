import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../history/color_history.dart';
import '../palettes/palette.dart';
import '../settings/app_settings.dart';

/// Resultado de una carga: datos y, si hubo que recuperarse de un archivo corrupto, su nueva ruta.
class LoadResult<T> {
  final T value;
  final String? recoveredCorruptFile;
  const LoadResult(this.value, this.recoveredCorruptFile);
}

/// Almacén JSON de un único documento: escritura atómica (tmp + reemplazo con .bak), guardado diferido
/// (debounce), recuperación de archivos corruptos y migraciones por "schemaVersion".
class JsonStore<T> {
  final String path;
  final Map<String, Object?> Function(T value) _toJson;
  final T Function(Map<String, Object?> json) _fromJson;
  final T Function() _factory;
  final Object? Function(Object? node)? _migrate;
  final Duration debounce;

  Timer? _timer;
  String? _pendingJson;

  JsonStore(
    this.path, {
    required Map<String, Object?> Function(T value) toJson,
    required T Function(Map<String, Object?> json) fromJson,
    required T Function() factory,
    Object? Function(Object? node)? migrate,
    this.debounce = const Duration(milliseconds: 300),
  })  : _toJson = toJson, // ignore: prefer_initializing_formals
        _fromJson = fromJson, // ignore: prefer_initializing_formals
        _factory = factory, // ignore: prefer_initializing_formals
        _migrate = migrate; // ignore: prefer_initializing_formals

  static const _encoder = JsonEncoder.withIndent('  ');

  LoadResult<T> load() {
    final file = File(path);
    if (!file.existsSync()) return LoadResult(_factory(), null);
    try {
      Object? node = jsonDecode(file.readAsStringSync());
      if (_migrate != null) node = _migrate(node);
      if (node is! Map) throw const FormatException('Documento vacío o no es un objeto');
      return LoadResult(_fromJson(node.cast<String, Object?>()), null);
    } catch (e) {
      if (e is! FormatException && e is! TypeError && e is! UnsupportedError) rethrow;
      final dir = file.parent.path;
      final name = file.uri.pathSegments.last.replaceFirst(RegExp(r'\.json$'), '');
      final now = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final stamp = '${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}${two(now.second)}';
      final corrupt = '$dir${Platform.pathSeparator}$name.corrupt-$stamp.json';
      final target = File(corrupt);
      if (target.existsSync()) target.deleteSync();
      file.renameSync(corrupt);
      return LoadResult(_factory(), corrupt);
    }
  }

  /// Serializa ya y programa la escritura diferida.
  void scheduleSave(T value) {
    _pendingJson = _encoder.convert(_toJson(value));
    _timer?.cancel();
    _timer = Timer(debounce, flush);
  }

  /// Guarda de inmediato (síncrono).
  void save(T value) {
    _timer?.cancel();
    _pendingJson = null;
    _writeAtomic(_encoder.convert(_toJson(value)));
  }

  /// Escribe cualquier guardado pendiente (llamar al pasar la app a segundo plano).
  void flush() {
    _timer?.cancel();
    final json = _pendingJson;
    if (json == null) return;
    _pendingJson = null;
    _writeAtomic(json);
  }

  bool get hasPending => _pendingJson != null;

  void _writeAtomic(String json) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    final tmp = File('$path.tmp');
    tmp.writeAsStringSync(json, flush: true);
    if (file.existsSync()) {
      final bak = File('$path.bak');
      if (bak.existsSync()) bak.deleteSync();
      file.renameSync(bak.path);
    }
    tmp.renameSync(path);
  }

  void dispose() => flush();
}

/// Rutas de los archivos de datos del usuario.
class DataPaths {
  final String directory;
  const DataPaths(this.directory);

  String get palettes => '$directory${Platform.pathSeparator}palettes.json';
  String get history => '$directory${Platform.pathSeparator}history.json';
  String get settings => '$directory${Platform.pathSeparator}settings.json';
}

abstract final class Repositories {
  static JsonStore<PaletteLibrary> palettes(DataPaths p, {Duration? debounce}) => JsonStore(
        p.palettes,
        toJson: (v) => v.toJson(),
        fromJson: PaletteLibrary.fromJson,
        factory: PaletteLibrary.new,
        migrate: migratePalettes,
        debounce: debounce ?? const Duration(milliseconds: 300),
      );

  /// Migraciones: v0 = array JSON de paletas sin envoltorio → v1. Versiones futuras se rechazan.
  static Object? migratePalettes(Object? node) {
    if (node is List) {
      node = <String, Object?>{'schemaVersion': PaletteLibrary.currentSchemaVersion, 'palettes': node};
    }
    if (node is Map) {
      final version = (node['schemaVersion'] as num?)?.toInt() ?? 0;
      if (version > PaletteLibrary.currentSchemaVersion) {
        throw UnsupportedError('palettes.json versión $version no soportada');
      }
      node['schemaVersion'] = PaletteLibrary.currentSchemaVersion;
    }
    return node;
  }

  static JsonStore<ColorHistory> history(DataPaths p, {Duration? debounce}) => JsonStore(
        p.history,
        toJson: (v) => v.toJson(),
        fromJson: ColorHistory.fromJson,
        factory: ColorHistory.new,
        debounce: debounce ?? const Duration(milliseconds: 300),
      );

  static JsonStore<AppSettings> settings(DataPaths p, {Duration? debounce}) => JsonStore(
        p.settings,
        toJson: (v) => v.toJson(),
        fromJson: AppSettings.fromJson,
        factory: AppSettings.new,
        debounce: debounce ?? const Duration(milliseconds: 300),
      );
}
