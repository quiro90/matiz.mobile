import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matiz/app.dart';
import 'package:matiz/platform/platform_bridge.dart';
import 'package:matiz/state/app_controller.dart';
import 'package:matiz_core/matiz_core.dart';

AppController newController() {
  final dir = Directory.systemTemp.createTempSync('matiz-gray-ui-');
  return AppController(dataDir: dir.path, platform: PlatformBridge())..load();
}

/// Deja correr los timers pendientes (guardado diferido, avisos) antes de cerrar el test.
Future<void> settle(WidgetTester tester, AppController c) async {
  c.flush();
  await tester.pump(const Duration(seconds: 10));
}

void main() {
  testWidgets('setGrayPercent actualiza la paleta activa y persiste el % en palettes.json', (tester) async {
    final c = newController();
    await tester.pumpWidget(MatizApp(controller: c));
    await tester.pumpAndSettle();
    c.addToActive(const Argb.fromRgb(82, 70, 188));
    final p = c.activePalette!;
    expect(p.grayPercent, isNull);

    c.setGrayPercent(p.id, 57);
    expect(c.activePalette!.grayPercent, 57);

    await settle(tester, c);
    final json = File('${c.dataDir}${Platform.pathSeparator}palettes.json').readAsStringSync();
    expect(json, contains('"grayPercent": 57'));

    // Reabrir la app conserva el modo (crear/duplicar/importar cubiertos en matiz_core).
    final reopened = AppController(dataDir: c.dataDir, platform: PlatformBridge())..load();
    expect(reopened.activePalette!.grayPercent, 57);
    await settle(tester, reopened);
  });

  testWidgets('setGrayPercent con 0 restaura el modo (null) y persiste sin la clave', (tester) async {
    final c = newController();
    await tester.pumpWidget(MatizApp(controller: c));
    await tester.pumpAndSettle();
    c.addToActive(const Argb.fromRgb(82, 70, 188));
    final p = c.activePalette!;
    c.setGrayPercent(p.id, 42);
    c.setGrayPercent(p.id, 0);
    expect(c.activePalette!.grayPercent, isNull);
    await settle(tester, c);
    final json = File('${c.dataDir}${Platform.pathSeparator}palettes.json').readAsStringSync();
    expect(json, isNot(contains('grayPercent')));
  });

  testWidgets('Copiar como código y exportar imagen son WYSIWYG; el .mpalette conserva originales + %', (tester) async {
    final c = newController();
    await tester.pumpWidget(MatizApp(controller: c));
    await tester.pumpAndSettle();
    c.addToActive(const Argb.fromRgb(82, 70, 188));
    final p = c.activePalette!;

    // 0 %: salida idéntica al original.
    expect(c.paletteAsText(p, 'hex-list'), contains('#5246BC'));

    // 100 %: el HEX exportado es el gris equivalente; la paleta no se muta.
    c.setGrayPercent(p.id, 100);
    final text = c.paletteAsText(p, 'hex-list');
    final gray = ColorMath.mixToGray(const Argb.fromRgb(82, 70, 188), 1.0);
    expect(text, contains(gray.toHex()));
    expect(text, isNot(contains('#5246BC')));
    expect(p.colors.single.color, const Argb.fromRgb(82, 70, 188));

    // El archivo .mpalette entrega SIEMPRE originales + el % recordado.
    final fileText = utf8.decode(c.exportPaletteFile(p));
    expect(fileText, contains('"hex": "#5246BC"'));
    expect(fileText, contains('"grayPercent": 100'));

    // Importar ese archivo restaura el modo.
    expect(c.importPaletteText(fileText), isTrue);
    expect(c.activePalette!.grayPercent, 100);
    expect(c.activePalette!.colors.single.color, const Argb.fromRgb(82, 70, 188));
    await settle(tester, c);
  });

  testWidgets('reloadInWheel carga lo que se ve: primer color mezclado con el % vigente', (tester) async {
    final c = newController();
    await tester.pumpWidget(MatizApp(controller: c));
    await tester.pumpAndSettle();
    c.addToActive(const Argb.fromRgb(82, 70, 188));
    final p = c.activePalette!;

    // 0 %: identidad exacta.
    c.reloadInWheel(p.id, confirmed: true);
    expect(c.currentArgb, const Argb.fromRgb(82, 70, 188));

    // 80 %: el color commiteado es la mezcla; la paleta sigue con el original.
    c.setGrayPercent(p.id, 80);
    c.reloadInWheel(p.id, confirmed: true);
    expect(c.currentArgb, ColorMath.mixToGray(const Argb.fromRgb(82, 70, 188), 0.8));
    expect(p.colors.single.color, const Argb.fromRgb(82, 70, 188));
    expect(p.grayPercent, 80);
    await settle(tester, c);
  });

  testWidgets('Pestaña Paletas muestra la fila de escala de grises y el slider mueve el modo', (tester) async {
    final c = newController();
    await tester.pumpWidget(MatizApp(controller: c));
    await tester.pumpAndSettle();
    c.addToActive(const Argb.fromRgb(82, 70, 188));

    await tester.tap(find.text('Palettes'));
    await tester.pumpAndSettle();

    expect(find.text('Grayscale'), findsOneWidget);
    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);

    // Sin paleta no debería romper: crear paleta vacía conserva la fila deshabilitada.
    await tester.drag(slider, const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(c.activePalette!.grayPercent, greaterThan(0));
    expect(c.activePalette!.grayPercent, lessThanOrEqualTo(100));

    await settle(tester, c);
  });
}