import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matiz/app.dart';
import 'package:matiz/l10n/generated/app_localizations.dart';
import 'package:matiz/platform/platform_bridge.dart';
import 'package:matiz/state/app_controller.dart';
import 'package:matiz_core/matiz_core.dart';

AppController newController() {
  final dir = Directory.systemTemp.createTempSync('matiz-ui-');
  return AppController(dataDir: dir.path, platform: PlatformBridge())..load();
}

/// Deja correr los timers pendientes (guardado diferido, avisos) antes de cerrar el test.
Future<void> settle(WidgetTester tester, AppController c) async {
  c.flush();
  await tester.pump(const Duration(seconds: 10));
}

void main() {
  testWidgets('Arranca en Crear con el último color y tres pestañas', (tester) async {
    final c = newController();
    await tester.pumpWidget(MatizApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.text('#5246BC'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Palettes'), findsOneWidget);
  });

  testWidgets('Cambiar a español traduce la navegación al instante', (tester) async {
    final c = newController();
    await tester.pumpWidget(MatizApp(controller: c));
    await tester.pumpAndSettle();
    c.setLanguage(AppLanguage.spanish);
    await tester.pumpAndSettle();
    expect(find.text('Crear'), findsOneWidget);
    expect(find.text('Generar'), findsOneWidget);
    expect(find.text('Paletas'), findsOneWidget);
    await settle(tester, c);
  });

  testWidgets('Añadir a paleta sin paletas crea "Untitled palette" con el color actual', (tester) async {
    final c = newController();
    await tester.pumpWidget(MatizApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to palette').first);
    await tester.pump();
    expect(c.activePalette?.colors.single.color, const Argb.fromRgb(82, 70, 188));
    await settle(tester, c);
  });

  test('ARB es/en tienen las mismas claves', () {
    final en = File('lib/l10n/app_en.arb').readAsStringSync();
    final es = File('lib/l10n/app_es.arb').readAsStringSync();
    Set<String> keys(String s) =>
        RegExp(r'^\s*"([A-Za-z][A-Za-z0-9_]*)"\s*:', multiLine: true).allMatches(s).map((m) => m[1]!).toSet();
    expect(keys(es), keys(en));
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode), containsAll(['en', 'es']));
  });
}
