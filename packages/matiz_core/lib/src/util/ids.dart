import 'dart:math' as math;

final _rnd = math.Random.secure();

/// GUID v4 en el formato de .NET (`xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`, minúsculas).
String newGuid() {
  final b = List<int>.generate(16, (_) => _rnd.nextInt(256));
  b[6] = (b[6] & 0x0F) | 0x40;
  b[8] = (b[8] & 0x3F) | 0x80;
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  final s = List.generate(16, h).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
}

/// Fecha en formato ISO 8601 con desfase, como `DateTimeOffset` de .NET (UTC → "+00:00").
String formatDate(DateTime d) {
  final u = d.toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  final frac = u.microsecond == 0 && u.millisecond == 0
      ? ''
      : '.${(u.millisecond * 1000 + u.microsecond).toString().padLeft(6, '0')}'.replaceFirst(RegExp(r'0+$'), '');
  return '${u.year.toString().padLeft(4, '0')}-${two(u.month)}-${two(u.day)}T${two(u.hour)}:${two(u.minute)}:${two(u.second)}$frac+00:00';
}

/// Lee una fecha ISO 8601 (con desfase o "Z"). Devuelve null si falta o es inválida.
DateTime? parseDate(Object? v) {
  if (v is! String || v.isEmpty) return null;
  // Dart no acepta más de 6 decimales: .NET escribe hasta 7 (ticks).
  final fixed = v.replaceFirstMapped(RegExp(r'\.(\d{6})\d+'), (m) => '.${m[1]}');
  return DateTime.tryParse(fixed)?.toUtc();
}
