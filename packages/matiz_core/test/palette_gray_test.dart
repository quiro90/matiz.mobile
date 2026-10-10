import 'dart:convert';
import 'dart:io';

import 'package:matiz_core/matiz_core.dart';
import 'package:test/test.dart';

void main() {
  Palette paletteWithGray({int? grayPercent, int alpha = 255}) {
    final p = Palette(name: 'Gris');
    p.grayPercent = grayPercent;
    p.colors.addAll([
      PaletteColor.create(const Argb.fromRgb(82, 70, 188), 'Primary'),
      PaletteColor.create(Argb(alpha, 255, 138, 0), 'Secondary'),
    ]);
    return p;
  }

  group('ColorMath.mixToGray', () {
    const red = Argb.fromRgb(255, 0, 0);

    test('0 % devuelve el color original', () {
      expect(ColorMath.mixToGray(red, 0), red);
      expect(ColorMath.mixToGray(red, 0.0), red);
    });

    test('100 % devuelve el gris equivalente', () {
      expect(ColorMath.mixToGray(red, 1.0), ColorMath.grayEquivalent(red));
    });

    test('Valores fuera de rango se acotan y NaN devuelve el original', () {
      expect(ColorMath.mixToGray(red, -0.5), red);
      expect(ColorMath.mixToGray(red, 1.5), ColorMath.grayEquivalent(red));
      expect(ColorMath.mixToGray(red, double.nan), red);
    });

    test('El alfa se conserva en todos los porcentajes', () {
      const translucent = Argb(128, 255, 0, 0);
      for (final amount in [0.0, 0.25, 0.57, 1.0]) {
        final mixed = ColorMath.mixToGray(translucent, amount);
        expect(mixed.a, 128);
      }
    });

    test('Un color neutro no cambia (su gris equivalente es él mismo)', () {
      const gray = Argb.fromRgb(128, 128, 128);
      final equivalent = ColorMath.grayEquivalent(gray);
      for (final amount in [0.25, 0.57, 1.0]) {
        // propiedad: mezclar hacia el mismo color es identidad
        expect(ColorMath.mixToGray(gray, amount), equivalent);
      }
    });
  });

  group('grayPercent en Palette (palettes.json)', () {
    test('Por defecto es 0 % (null) y toJson no incluye la clave', () {
      final p = paletteWithGray();
      expect(p.grayPercent, isNull);
      final j = p.toJson();
      expect(j.containsKey('grayPercent'), isFalse);
    });

    test('Round trip JSON conserva el porcentaje', () {
      final p = paletteWithGray(grayPercent: 57);
      final restored = Palette.fromJson(p.toJson());
      expect(restored.grayPercent, 57);
    });

    test('Lectura tolerante: 0, negativos, >100 y no enteros se normalizan a null', () {
      int? read(Object? v) => Palette.fromJson({'grayPercent': v}).grayPercent;
      expect(read(0), isNull);
      expect(read(-3), isNull);
      expect(read(150), isNull);
      expect(read('57'), isNull);
      expect(read(null), isNull);
      expect(read(57), 57);
    });

    test('JSON escrito por desktop (grayPercent + hex originales) se lee igual', () {
      const desktop = '''
{
  "id": "a6b0c1c2-d3e4-45f6-a7b8-c9d0e1f2a3b4",
  "name": "ChewisPalette",
  "createdAt": "2026-10-09T21:25:19.4174115+00:00",
  "modifiedAt": "2026-10-10T15:41:11.0222052+00:00",
  "grayPercent": 57,
  "colors": [
    { "id": "e8bb79dd-2a01-4d0c-962c-c03fd9630c9c", "name": "primary 1", "hex": "#8065A1" }
  ]
}''';
      final p = Palette.fromJson(jsonDecode(desktop) as Map<String, Object?>);
      expect(p.grayPercent, 57);
      expect(p.colors.single.hex, '#8065A1');
    });
  });

  group('grayPercent en PaletteFile (.mpalette)', () {
    test('encode conserva el porcentaje y los hex originales (sin gris horneado)', () {
      final p = paletteWithGray(grayPercent: 57);
      final text = PaletteFile.from(p).encode();
      expect(text, contains('"grayPercent": 57'));
      expect(text, contains('"hex": "#5246BC"'));

      final decoded = PaletteFile.decode(text);
      expect(decoded.grayPercent, 57);
      expect(decoded.colors[0].hex, '#5246BC');

      final roundTrip = decoded.toPalette();
      expect(roundTrip.grayPercent, 57);
      expect(roundTrip.colors[0].color, const Argb.fromRgb(82, 70, 188));
    });

    test('Archivo sin grayPercent lee 0 %', () {
      final p = paletteWithGray();
      final decoded = PaletteFile.decode(PaletteFile.from(p).encode());
      expect(decoded.grayPercent, isNull);
      expect(decoded.toPalette().grayPercent, isNull);
    });

    test('.mpalette real de desktop con grayPercent se importa con su porcentaje', () {
      final svc = PaletteService(PaletteLibrary());
      const desktop = '''
{
  "schemaVersion": 1,
  "name": "ChewisPalette",
  "createdAt": "2026-10-09T21:25:19.4174115+00:00",
  "modifiedAt": "2026-10-10T15:41:11.0222052+00:00",
  "grayPercent": 57,
  "colors": [
    { "id": "e8bb79dd-2a01-4d0c-962c-c03fd9630c9c", "name": "primary 1", "hex": "#8065A1" }
  ]
}''';
      final imported = svc.import(PaletteFile.decode(desktop));
      expect(imported.grayPercent, 57);
      expect(imported.colors.single.color, const Argb.fromRgb(128, 101, 161));
      expect(imported.colors.single.hex, '#8065A1');
    });

    test('Persistencia por archivo: paleta con 57 % sobrevive guardar/leer biblioteca', () {
      final dir = Directory.systemTemp.createTempSync('matiz-gray-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = Repositories.palettes(DataPaths(dir.path));
      final svc = PaletteService(PaletteLibrary());
      final p = svc.ensureActive();
      svc.addColor(p.id, const Argb.fromRgb(82, 70, 188), 'Primary');
      svc.setGrayPercent(p.id, 57);
      store.save(svc.library);

      final reloaded = PaletteService(store.load().value);
      expect(reloaded.find(p.id)!.grayPercent, 57);
    });

    test('Paleta guardada antes de la feature (sin clave) lee 0 %', () {
      final dir = Directory.systemTemp.createTempSync('matiz-gray-legacy-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final legacyJson = '''
{
  "palettes": [
    {
      "id": "11111111-2222-3333-4444-555555555555",
      "name": "Legado",
      "createdAt": "2026-01-01T00:00:00.0000000Z",
      "modifiedAt": "2026-01-01T00:00:00.0000000Z",
      "colors": [ { "id": "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee", "name": "X", "hex": "#5246BC" } ]
    }
  ]
}''';
      File('${dir.path}${Platform.pathSeparator}palettes.json').writeAsStringSync(legacyJson);
      final restored = PaletteService(Repositories.palettes(DataPaths(dir.path)).load().value);
      expect(restored.palettes.single.grayPercent, isNull);
    });
  });

  group('PaletteService.setGrayPercent', () {
    test('Acuta el porcentaje entre 0 y 100; 0 restaura (null)', () {
      final p = paletteWithGray();
      final svc = PaletteService(PaletteLibrary(palettes: [p]));
      svc.setGrayPercent(p.id, 57);
      expect(p.grayPercent, 57);
      svc.setGrayPercent(p.id, 150);
      expect(p.grayPercent, 100);
      svc.setGrayPercent(p.id, -5);
      expect(p.grayPercent, isNull);
      svc.setGrayPercent(p.id, 40);
      svc.setGrayPercent(p.id, 0);
      expect(p.grayPercent, isNull);
    });

    test('NO modifica modifiedAt (es estado de presentación)', () {
      final p = paletteWithGray();
      final svc = PaletteService(PaletteLibrary(palettes: [p]));
      final before = p.modifiedAt;
      svc.setGrayPercent(p.id, 57);
      expect(p.modifiedAt, before);
    });

    test('No notifica si el valor no cambia', () {
      final p = paletteWithGray(grayPercent: 57);
      final svc = PaletteService(PaletteLibrary(palettes: [p]));
      var calls = 0;
      svc.onChanged = () => calls++;
      svc.setGrayPercent(p.id, 57);
      expect(calls, 0);
      svc.setGrayPercent(p.id, 58);
      expect(calls, 1);
    });

    test('create y duplicate nacen en 0 % aunque la fuente tenga gris', () {
      final p = paletteWithGray(grayPercent: 57);
      final svc = PaletteService(PaletteLibrary(palettes: [p]));
      final copy = svc.duplicate(p.id)!;
      expect(copy.grayPercent, isNull);
      expect(svc.create(name: 'Otra', activate: false).grayPercent, isNull);
    });

    test('delete + restore conserva el porcentaje', () {
      final p = paletteWithGray(grayPercent: 57);
      final svc = PaletteService(PaletteLibrary(palettes: [p]));
      final deleted = svc.delete(p.id)!;
      svc.restore(deleted.palette, deleted.index);
      expect(svc.find(p.id)!.grayPercent, 57);
    });

    test('Import sin grayPercent queda en 0 %', () {
      final svc = PaletteService(PaletteLibrary());
      final imported = svc.import(PaletteFile(name: 'Sin gris', colors: [PaletteColor(hex: '#5246BC')]));
      expect(imported.grayPercent, isNull);
    });
  });

  group('PaletteExportModel.fromGrayed (WYSIWYG)', () {
    test('0 % es idéntico a from()', () {
      final p = paletteWithGray();
      final plain = PaletteExportModel.from(p);
      final grayed = PaletteExportModel.fromGrayed(p);
      expect(grayed.name, plain.name);
      expect(grayed.colors.map((c) => c.color), plain.colors.map((c) => c.color));
    });

    test('Con 57 % aplica el mismo porcentaje a todos los colores, sin mutar la paleta', () {
      final p = paletteWithGray(grayPercent: 57);
      final originals = p.colors.map((c) => c.color).toList();
      final grayed = PaletteExportModel.fromGrayed(p);

      expect(grayed.name, p.name);
      for (var i = 0; i < p.colors.length; i++) {
        expect(grayed.colors[i].name, p.colors[i].name);
        expect(grayed.colors[i].color, ColorMath.mixToGray(p.colors[i].color, 0.57));
      }
      expect(p.colors.map((c) => c.color), originals);
      expect(p.grayPercent, 57);
    });

    test('Los colores con alfa mezclan canales y conservan alfa', () {
      final p = paletteWithGray(grayPercent: 100, alpha: 128);
      final grayed = PaletteExportModel.fromGrayed(p);
      final translucent = grayed.colors[1].color;
      expect(translucent.a, 128);
      final equivalent = ColorMath.grayEquivalent(const Argb(128, 255, 138, 0));
      expect(translucent, equivalent);
    });
  });

  test('Los archivos .mpalette y palettes.json son válidos tras un ciclo completo', () {
    final dir = Directory.systemTemp.createTempSync('matiz-gray-cycle-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = Repositories.palettes(DataPaths(dir.path));
    final svc = PaletteService(PaletteLibrary());
    final p = svc.ensureActive();
    svc.addColor(p.id, const Argb.fromRgb(82, 70, 188), 'Primary');
    svc.setGrayPercent(p.id, 30);
    store.save(svc.library);

    final lib = store.load().value;
    expect(PaletteService(lib).find(p.id)!.grayPercent, 30);

    final path = '${dir.path}${Platform.pathSeparator}ciclo.mpalette';
    PaletteFile.from(svc.find(p.id)!).write(path);
    final read = PaletteFile.read(path);
    expect(read.grayPercent, 30);
  });
}