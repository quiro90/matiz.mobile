enum HarmonyKind {
  complementary,
  analogous,
  splitComplementary,
  triadic,
  tetradic,
  monochromatic,
}

enum ScaleAnchorMode {
  /// El color base ocupa siempre el paso 500 (si es geométricamente posible).
  fixed500,

  /// El color base ocupa el paso cuya luminosidad de referencia es más cercana.
  automatic,
}
