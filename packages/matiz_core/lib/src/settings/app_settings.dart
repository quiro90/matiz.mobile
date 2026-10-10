import '../formatting/color_formats.dart';
import '../formatting/color_formatters.dart';
import '../generation/harmony_kind.dart';

enum ThemePreference { system, light, dark }

/// Idioma de la interfaz: el del sistema por defecto.
enum AppLanguage { system, spanish, english }

/// Modo de las paletas generadas (pestaña Generar).
enum GenerationMode { scale, tintsShades, neutrals, harmony, custom, extracted }

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is! String) return fallback;
  final key = name.toLowerCase();
  for (final v in values) {
    if (v.name.toLowerCase() == key) return v;
  }
  return fallback;
}

/// Contenido de settings.json (esquema móvil; claves compartidas con desktop donde aplica).
class AppSettings {
  int schemaVersion = 1;
  ThemePreference theme = ThemePreference.system;
  AppLanguage language = AppLanguage.system;

  /// Formato principal: botón Copiar, tarjetas y "Copiar al tomar color".
  String defaultFormatId = ColorFormatters.hexId;
  bool hexUppercase = true;
  bool hexHash = true;
  bool copyOnPick = false;

  /// Enfoque de la rueda: −1 vivo, 0 lineal, +1 pastel.
  double wheelFocus = 0;
  ScaleAnchorMode scaleAnchor = ScaleAnchorMode.fixed500;
  String scalePrefix = 'Primary';
  bool harmonyBalanceLightness = true;
  GenerationMode generationMode = GenerationMode.scale;
  HarmonyKind harmonyKind = HarmonyKind.complementary;
  int extractCount = 6;

  bool bubbleEnabled = false;
  bool cameraIntroShown = false;
  double? bubbleX;
  double? bubbleY;

  String lastColor = '#5246BC';
  double? lastHue;
  double? lastSaturation;

  FormatOptions toFormatOptions() => FormatOptions(hexUppercase: hexUppercase, hexHash: hexHash);

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'theme': _pascal(theme.name),
        'language': _pascal(language.name),
        'defaultFormatId': defaultFormatId,
        'hexUppercase': hexUppercase,
        'hexHash': hexHash,
        'copyOnPick': copyOnPick,
        'wheelFocus': wheelFocus,
        'scaleAnchor': scaleAnchor == ScaleAnchorMode.fixed500 ? 'Fixed500' : 'Automatic',
        'scalePrefix': scalePrefix,
        'harmonyBalanceLightness': harmonyBalanceLightness,
        'generationMode': _pascal(generationMode.name),
        'harmonyKind': _pascal(harmonyKind.name),
        'extractCount': extractCount,
        'bubbleEnabled': bubbleEnabled,
        'cameraIntroShown': cameraIntroShown,
        if (bubbleX != null) 'bubbleX': bubbleX,
        if (bubbleY != null) 'bubbleY': bubbleY,
        'lastColor': lastColor,
        if (lastHue != null) 'lastHue': lastHue,
        if (lastSaturation != null) 'lastSaturation': lastSaturation,
      };

  static AppSettings fromJson(Map<String, Object?> j) {
    final s = AppSettings();
    s.schemaVersion = (j['schemaVersion'] as num?)?.toInt() ?? 1;
    s.theme = _enumByName(ThemePreference.values, j['theme'], ThemePreference.system);
    s.language = _enumByName(AppLanguage.values, j['language'], AppLanguage.system);
    s.defaultFormatId = (j['defaultFormatId'] as String?) ?? ColorFormatters.hexId;
    s.hexUppercase = (j['hexUppercase'] as bool?) ?? true;
    s.hexHash = (j['hexHash'] as bool?) ?? true;
    s.copyOnPick = (j['copyOnPick'] as bool?) ?? false;
    s.wheelFocus = (j['wheelFocus'] as num?)?.toDouble() ?? 0;
    s.scaleAnchor = _enumByName(ScaleAnchorMode.values, j['scaleAnchor'], ScaleAnchorMode.fixed500);
    s.scalePrefix = (j['scalePrefix'] as String?) ?? 'Primary';
    s.harmonyBalanceLightness = (j['harmonyBalanceLightness'] as bool?) ?? true;
    s.generationMode = _enumByName(GenerationMode.values, j['generationMode'], GenerationMode.scale);
    if (s.generationMode == GenerationMode.extracted) s.generationMode = GenerationMode.scale;
    s.harmonyKind = _enumByName(HarmonyKind.values, j['harmonyKind'], HarmonyKind.complementary);
    s.extractCount = ((j['extractCount'] as num?)?.toInt() ?? 6).clamp(1, 64);
    s.bubbleEnabled = (j['bubbleEnabled'] as bool?) ?? false;
    s.cameraIntroShown = (j['cameraIntroShown'] as bool?) ?? false;
    s.bubbleX = (j['bubbleX'] as num?)?.toDouble();
    s.bubbleY = (j['bubbleY'] as num?)?.toDouble();
    s.lastColor = (j['lastColor'] as String?) ?? '#5246BC';
    s.lastHue = (j['lastHue'] as num?)?.toDouble();
    s.lastSaturation = (j['lastSaturation'] as num?)?.toDouble();
    return s;
  }

  static String _pascal(String n) => n[0].toUpperCase() + n.substring(1);
}
