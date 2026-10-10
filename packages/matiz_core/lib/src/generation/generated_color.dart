import '../colors/argb.dart';

/// Color generado: etiqueta visible (p. ej. "500", "+120°", "Tint 20%"), si es el color base y, para armonías,
/// sus coordenadas exactas en la rueda (hue y saturación HSV antes de redondear a 8 bits).
class GeneratedColor {
  final String label;
  final Argb color;
  final bool isBase;
  final double? wheelHue;
  final double? wheelSaturation;

  const GeneratedColor(this.label, this.color, {this.isBase = false, this.wheelHue, this.wheelSaturation});
}
