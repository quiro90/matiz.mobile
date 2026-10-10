import 'dart:io';

import 'package:matiz_core/matiz_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('matiz-tests-'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  String pathOf(String name) => '${dir.path}${Platform.pathSeparator}$name';
  DataPaths paths() => DataPaths(dir.path);

  Palette samplePalette() {
    final svc = PaletteService(PaletteLibrary());
    final p = svc.create(name: 'PuchiApp', activate: false);
    svc.setDescription(p.id, 'Colores de la app');
    svc.addColors(p.id, [
      (color: const Argb.fromRgb(82, 70, 188), name: 'Primary'),
      (color: const Argb(128, 255, 138, 0), name: 'Secondary'),
      (color: const Argb.fromRgb(34, 197, 94), name: null),
    ]);
    return p;
  }

  group('PaletteFile', () {
    test('Round trip preserves name, description, colors, order, dates and alpha', () {
      final p = samplePalette();
      final path = pathOf('PuchiApp.mpalette');
      PaletteFile.from(p).write(path);

      final file = PaletteFile.read(path);
      expect(file.schemaVersion, PaletteFile.currentSchemaVersion);
      expect(file.name, 'PuchiApp');
      expect(file.description, 'Colores de la app');
      expect(file.createdAt, p.createdAt);
      expect(file.modifiedAt, p.modifiedAt);
      expect(file.colors.map((c) => (c.name, c.color)), p.colors.map((c) => (c.name, c.color)));
      expect(file.colors[1].color, const Argb(128, 255, 138, 0));

      final json = File(path).readAsStringSync();
      expect(json, contains('"schemaVersion": 1'));
      expect(json, contains('"name": "PuchiApp"'));
      expect(json, contains('"hex": "#5246BC"'));
      expect(json, contains('"alpha": 128'));
    });

    test('Invalid JSON fails', () {
      File(pathOf('roto.mpalette')).writeAsStringSync('{ esto no es json');
      expect(() => PaletteFile.read(pathOf('roto.mpalette')), throwsA(isA<PaletteFileException>()));
    });

    test('Future schema version is rejected', () {
      File(pathOf('futura.mpalette')).writeAsStringSync('{"schemaVersion": 99, "name": "Futura"}');
      expect(
        () => PaletteFile.read(pathOf('futura.mpalette')),
        throwsA(isA<PaletteFileException>()
            .having((e) => e.unsupportedVersion, 'unsupportedVersion', isTrue)
            .having((e) => e.message, 'message', contains('99'))),
      );
    });

    test('Desktop file (7 decimal ticks, alpha) is read', () {
      const desktop = '''{
  "schemaVersion": 1,
  "name": "Desde Windows",
  "createdAt": "2026-10-09T13:21:05.1234567-03:00",
  "modifiedAt": "2026-10-09T13:25:00+00:00",
  "colors": [
    { "id": "0f8fad5b-d9cb-469f-a165-70867728950e", "name": "Overlay", "hex": "#000000", "alpha": 128 },
    { "id": "7c9e6679-7425-40de-944b-e07fc1f90ae7", "hex": "#5246BC" }
  ]
}''';
      final f = PaletteFile.decode(desktop);
      expect(f.name, 'Desde Windows');
      expect(f.createdAt, DateTime.utc(2026, 10, 9, 16, 21, 5, 123, 456));
      expect(f.colors[0].color, const Argb(128, 0, 0, 0));
      expect(f.colors[1].name, isNull);
    });

    test('Import always creates new palette and never touches existing', () {
      final svc = PaletteService(PaletteLibrary());
      final existing = svc.create(name: 'PuchiApp', activate: false);
      svc.addColors(existing.id, [
        (color: const Argb.fromRgb(82, 70, 188), name: 'Primary'),
        (color: const Argb(128, 255, 138, 0), name: 'Secondary'),
        (color: const Argb.fromRgb(34, 197, 94), name: null),
      ]);
      final createdAt = DateTime.parse('2026-10-09T10:00:00Z');
      final file = PaletteFile(
        name: 'PuchiApp',
        description: 'Importada',
        colors: [PaletteColor(hex: '#E24347', name: 'Red')],
        createdAt: createdAt,
        modifiedAt: createdAt.add(const Duration(minutes: 5)),
      );

      final imported = svc.import(file);
      expect(svc.find(existing.id)!.colors.length, 3);
      expect(imported.name, 'PuchiApp 2');
      expect(imported.description, 'Importada');
      expect(imported.colors.single.color, const Argb(255, 226, 67, 71));
      expect(imported.colors[0].name, 'Red');
      expect(imported.createdAt, createdAt);
      expect(imported.modifiedAt, createdAt.add(const Duration(minutes: 5)));
      expect(imported.colors[0].id, isNot(svc.find(existing.id)!.colors[0].id));
      expect(svc.library.activePaletteId, imported.id);
    });

    test('Import preserves more than 64 colors', () {
      final svc = PaletteService(PaletteLibrary());
      final many = List.generate(70, (i) => PaletteColor.create(Argb.fromRgb(i, 0, 0)));
      expect(svc.import(PaletteFile(name: 'Grande', colors: many)).colors.length, 70);
    });

    test('Import without name uses default name', () {
      final svc = PaletteService(PaletteLibrary());
      expect(svc.import(PaletteFile()).name, PaletteService.defaultName);
    });
  });

  group('Persistence', () {
    test('Missing file returns empty library', () {
      final r = Repositories.palettes(paths()).load();
      expect(r.value.palettes, isEmpty);
      expect(r.recoveredCorruptFile, isNull);
    });

    test('Palettes round trip with order, names and dates', () {
      final lib = PaletteLibrary();
      final svc = PaletteService(lib);
      final p = svc.create(name: 'PuchiApp');
      svc.addColors(p.id, [
        (color: const Argb.fromRgb(82, 70, 188), name: 'Primary'),
        (color: const Argb(128, 255, 138, 0), name: 'Secondary'),
        (color: const Argb.fromRgb(34, 197, 94), name: null),
      ]);
      Repositories.palettes(paths()).save(lib);

      final loaded = Repositories.palettes(paths()).load().value;
      final lp = loaded.palettes.single;
      expect(lp.name, 'PuchiApp');
      expect(lp.createdAt, p.createdAt);
      expect(lp.modifiedAt, p.modifiedAt);
      expect(lp.colors.map((c) => c.name), ['Primary', 'Secondary', null]);
      expect(lp.colors[1].color, const Argb(128, 255, 138, 0));
      expect(loaded.activePaletteId, p.id);
      final json = File(paths().palettes).readAsStringSync();
      expect(json, contains('"schemaVersion": 1'));
      expect(json, contains('"hex": "#5246BC"'));
    });

    test('Corrupt file is renamed and empty library returned', () {
      File(paths().palettes).writeAsStringSync('{ esto no es json');
      final r = Repositories.palettes(paths()).load();
      expect(r.value.palettes, isEmpty);
      expect(r.recoveredCorruptFile, isNotNull);
      expect(File(r.recoveredCorruptFile!).existsSync(), isTrue);
      expect(File(paths().palettes).existsSync(), isFalse);
      expect(RegExp(r'palettes\.corrupt-\d{8}-\d{6}\.json$').hasMatch(r.recoveredCorruptFile!), isTrue);
    });

    test('Migrates v0 array format', () {
      File(paths().palettes).writeAsStringSync(
          '[ { "id": "7f9c1b8e-0000-0000-0000-000000000001", "name": "Vieja", "colors": [ { "hex": "#5246BC", "name": "Primary" } ] } ]');
      final lib = Repositories.palettes(paths()).load().value;
      expect(lib.schemaVersion, PaletteLibrary.currentSchemaVersion);
      expect(lib.palettes.single.name, 'Vieja');
      expect(lib.palettes[0].colors[0].color, const Argb.fromRgb(82, 70, 188));
    });

    test('Atomic save replaces and keeps backup', () {
      final store = Repositories.palettes(paths());
      store.save(PaletteLibrary());
      final lib = PaletteLibrary();
      PaletteService(lib).create(name: 'Nueva');
      store.save(lib);
      expect(File('${paths().palettes}.bak').existsSync(), isTrue);
      expect(File('${paths().palettes}.tmp').existsSync(), isFalse);
      expect(File(paths().palettes).readAsStringSync(), contains('Nueva'));
    });

    test('Debounced save writes after delay and on flush', () async {
      final store = Repositories.palettes(paths(), debounce: const Duration(milliseconds: 50));
      final lib = PaletteLibrary();
      PaletteService(lib).create(name: 'Diferida');
      store.scheduleSave(lib);
      for (var i = 0; i < 40 && !File(paths().palettes).existsSync(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      expect(File(paths().palettes).readAsStringSync(), contains('Diferida'));

      PaletteService(lib).create(name: 'Inmediata');
      store.scheduleSave(lib);
      store.flush();
      expect(File(paths().palettes).readAsStringSync(), contains('Inmediata'));
    });

    test('History and settings round trip', () {
      final history = ColorHistory([const Argb.fromRgb(1, 2, 3), const Argb(128, 4, 5, 6)]);
      Repositories.history(paths()).save(history);
      expect(Repositories.history(paths()).load().value.items, history.items);

      final settings = AppSettings()
        ..theme = ThemePreference.dark
        ..wheelFocus = 0.5
        ..lastHue = 246
        ..scaleAnchor = ScaleAnchorMode.automatic;
      Repositories.settings(paths()).save(settings);
      final loaded = Repositories.settings(paths()).load().value;
      expect(loaded.theme, ThemePreference.dark);
      expect(loaded.wheelFocus, 0.5);
      expect(loaded.lastHue, 246);
      expect(loaded.scaleAnchor, ScaleAnchorMode.automatic);
      expect(File(paths().settings).readAsStringSync(), contains('"theme": "Dark"'));
    });

    test('Desktop history.json is readable', () {
      File(paths().history).writeAsStringSync('{ "schemaVersion": 1, "colors": ["#5246BC", "#80040506", "basura"] }');
      expect(Repositories.history(paths()).load().value.items,
          [const Argb.fromRgb(82, 70, 188), const Argb(128, 4, 5, 6)]);
    });
  });
}
