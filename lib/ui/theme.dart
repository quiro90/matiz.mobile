import 'package:flutter/material.dart';

/// Tema neutro: superficies en grises sin croma para no interferir con la percepción de los colores
/// analizados (equivalente al ADR-007 de desktop). No usa color dinámico del sistema.
abstract final class MatizTheme {
  static ThemeData light() => _build(const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF18181B),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFE4E4E7),
        onPrimaryContainer: Color(0xFF18181B),
        secondary: Color(0xFF3F3F46),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFE4E4E7),
        onSecondaryContainer: Color(0xFF18181B),
        tertiary: Color(0xFF52525B),
        onTertiary: Color(0xFFFFFFFF),
        error: Color(0xFFB91C1C),
        onError: Color(0xFFFFFFFF),
        surface: Color(0xFFFAFAFA),
        onSurface: Color(0xFF18181B),
        onSurfaceVariant: Color(0xFF52525B),
        surfaceContainerLowest: Color(0xFFFFFFFF),
        surfaceContainerLow: Color(0xFFF4F4F5),
        surfaceContainer: Color(0xFFEFEFF0),
        surfaceContainerHigh: Color(0xFFE9E9EB),
        surfaceContainerHighest: Color(0xFFE4E4E7),
        outline: Color(0xFFA1A1AA),
        outlineVariant: Color(0xFFD4D4D8),
        inverseSurface: Color(0xFF27272A),
        onInverseSurface: Color(0xFFF4F4F5),
        inversePrimary: Color(0xFFE4E4E7),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        surfaceTint: Color(0x00000000),
      ));

  static ThemeData dark() => _build(const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFF4F4F5),
        onPrimary: Color(0xFF18181B),
        primaryContainer: Color(0xFF3F3F46),
        onPrimaryContainer: Color(0xFFF4F4F5),
        secondary: Color(0xFFD4D4D8),
        onSecondary: Color(0xFF18181B),
        secondaryContainer: Color(0xFF3F3F46),
        onSecondaryContainer: Color(0xFFF4F4F5),
        tertiary: Color(0xFFA1A1AA),
        onTertiary: Color(0xFF18181B),
        error: Color(0xFFF87171),
        onError: Color(0xFF18181B),
        surface: Color(0xFF121214),
        onSurface: Color(0xFFF4F4F5),
        onSurfaceVariant: Color(0xFFA1A1AA),
        surfaceContainerLowest: Color(0xFF0C0C0D),
        surfaceContainerLow: Color(0xFF18181B),
        surfaceContainer: Color(0xFF1C1C1F),
        surfaceContainerHigh: Color(0xFF242427),
        surfaceContainerHighest: Color(0xFF2E2E32),
        outline: Color(0xFF71717A),
        outlineVariant: Color(0xFF3F3F46),
        inverseSurface: Color(0xFFF4F4F5),
        onInverseSurface: Color(0xFF18181B),
        inversePrimary: Color(0xFF3F3F46),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        surfaceTint: Color(0x00000000),
      ));

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true, visualDensity: VisualDensity.standard);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.surfaceContainerHighest,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        actionTextColor: scheme.onInverseSurface,
        insetPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: scheme.outlineVariant),
        showCheckmark: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        showDragHandle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }

  /// Fuente monoespaciada para valores de color.
  static const mono = TextStyle(fontFamily: 'monospace', fontFeatures: [FontFeature.tabularFigures()]);
}
