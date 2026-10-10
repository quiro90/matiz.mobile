import '../generation/harmony_kind.dart';

/// Textos generados por el modelo (etiquetas de paletas, nombres por defecto…).
/// La app lo inicializa con su catálogo localizable; por defecto, inglés.
abstract class MatizTexts {
  String harmonyName(HarmonyKind kind);
  String tint(int percent);
  String shade(int percent);
  String get base;
  String colorNumberFallback(int index);
  String get untitledPalette;
  String get copySuffix;
}

abstract final class Texts {
  static MatizTexts current = EnglishTexts();
}

/// Catálogo por defecto (inglés), usado cuando la app no inicializa ninguno (tests, uso directo del core).
class EnglishTexts implements MatizTexts {
  @override
  String harmonyName(HarmonyKind kind) => switch (kind) {
        HarmonyKind.complementary => 'Complementary',
        HarmonyKind.analogous => 'Analogous',
        HarmonyKind.splitComplementary => 'Split-complementary',
        HarmonyKind.triadic => 'Triadic',
        HarmonyKind.tetradic => 'Tetradic',
        HarmonyKind.monochromatic => 'Monochromatic',
      };

  @override
  String tint(int percent) => 'Tint $percent%';
  @override
  String shade(int percent) => 'Shade $percent%';
  @override
  String get base => 'Base';
  @override
  String colorNumberFallback(int index) => 'Color $index';
  @override
  String get untitledPalette => 'Untitled palette';
  @override
  String get copySuffix => '(copy)';
}

/// Catálogo en español (mismos textos que Matiz desktop).
class SpanishTexts implements MatizTexts {
  @override
  String harmonyName(HarmonyKind kind) => switch (kind) {
        HarmonyKind.complementary => 'Complementaria',
        HarmonyKind.analogous => 'Análoga',
        HarmonyKind.splitComplementary => 'Complementaria dividida',
        HarmonyKind.triadic => 'Triádica',
        HarmonyKind.tetradic => 'Tetrádica',
        HarmonyKind.monochromatic => 'Monocromática',
      };

  @override
  String tint(int percent) => 'Tint $percent%';
  @override
  String shade(int percent) => 'Shade $percent%';
  @override
  String get base => 'Base';
  @override
  String colorNumberFallback(int index) => 'Color $index';
  @override
  String get untitledPalette => 'Paleta sin título';
  @override
  String get copySuffix => '(copia)';
}
