import 'dart:convert';

import 'package:matiz_core/matiz_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  const violet = Argb.fromRgb(82, 70, 188);
  const lighter = Argb.fromRgb(0x67, 0x5B, 0xCE);

  group('Session', () {
    test('Previous and current after drag', () {
      final s = ColorSession(ColorState.fromArgb(violet));
      for (var i = 0; i < 100; i++) {
        s.setPreview(ColorState(246 + i * 0.01, 0.6, 0.8));
      }
      s.commit(ColorState.fromArgb(lighter));
      expect(s.previous.argb, violet);
      expect(s.current.argb, lighter);
      expect(s.undoCount, 1);
      s.restorePrevious();
      expect(s.current.argb, violet);
      expect(s.previous.argb, lighter);
    });

    test('Undo reverts whole drag and redo reapplies', () {
      final s = ColorSession(ColorState.fromArgb(violet));
      s.setPreview(ColorState(10, 0.5, 0.5));
      s.setPreview(ColorState(20, 0.5, 0.5));
      s.commit(ColorState(30, 0.5, 0.5));
      expect(s.undo(), isTrue);
      expect(s.current.argb, violet);
      expect(s.redo(), isTrue);
      expect(s.current.argb, ColorState(30, 0.5, 0.5).argb);
      s.undo();
      s.commitArgb(lighter, ColorChangeSource.manualInput);
      expect(s.canRedo, isFalse);
    });

    test('Undo stack is limited', () {
      final s = ColorSession(ColorState.fromArgb(violet));
      for (var i = 0; i < 80; i++) {
        s.commitArgb(Argb.fromRgb(i, 0, 0), ColorChangeSource.manualInput);
      }
      expect(s.undoCount, ColorSession.undoLimit);
    });

    test('Gray commit keeps hue', () {
      final s = ColorSession(ColorState.fromArgb(violet));
      s.commitArgb(const Argb.fromRgb(128, 128, 128), ColorChangeSource.manualInput);
      expectPrecision(s.current.hue, ColorState.fromArgb(violet).hue, 9);
    });
  });

  test('History dedupes, moves to front and limits', () {
    final h = ColorHistory();
    for (var i = 0; i < 35; i++) {
      h.add(Argb.fromRgb(i, 0, 0));
    }
    expect(h.items.length, ColorHistory.capacity);
    expect(h.items[0], const Argb.fromRgb(34, 0, 0));
    expect(h.items, isNot(contains(const Argb.fromRgb(0, 0, 0))));
    final fifth = h.items[4];
    h.add(fifth);
    expect(h.items[0], fifth);
    expect(h.items.where((c) => c == fifth).length, 1);
  });

  group('PaletteService', () {
    var now = DateTime.utc(2026, 10, 8, 12);
    PaletteService newService() => PaletteService(PaletteLibrary(), clock: () => now);
    setUp(() => now = DateTime.utc(2026, 10, 8, 12));

    void fill(PaletteService s, Palette p, int count) {
      for (var i = 0; i < count; i++) {
        expect(s.addColor(p.id, Argb.fromRgb(i, 0, 0)), isNotNull);
      }
    }

    test('Create with default unique names', () {
      final s = newService();
      final a = s.create();
      final b = s.create();
      expect(a.name, 'Untitled palette');
      expect(b.name, 'Untitled palette 2');
      expect(a.createdAt, a.modifiedAt);
      expect(a.colors, isEmpty);
      expect(s.active!.id, b.id);
    });

    test('Operations update modified date', () {
      final s = newService();
      final p = s.create(name: 'PuchiApp');
      now = now.add(const Duration(minutes: 5));
      final c = s.addColor(p.id, violet, 'Primary')!;
      expect(p.modifiedAt, now);
      s.renameColor(p.id, c.id, 'Brand');
      s.replaceColor(p.id, c.id, const Argb.fromRgb(1, 2, 3));
      expect(p.colors[0].name, 'Brand');
      expect(p.colors[0].hex, '#010203');
    });

    test('Move, duplicate, delete, restore', () {
      final s = newService();
      final p = s.create(name: 'PuchiApp');
      s.addColors(p.id, [
        (color: const Argb.fromRgb(1, 0, 0), name: 'A'),
        (color: const Argb.fromRgb(2, 0, 0), name: 'B'),
        (color: const Argb.fromRgb(3, 0, 0), name: 'C'),
      ]);
      s.moveColor(p.id, p.colors[2].id, 0);
      expect(p.colors.map((c) => c.name), ['C', 'A', 'B']);
      final copy = s.duplicate(p.id)!;
      expect(copy.name, 'PuchiApp (copy)');
      expect(copy.colors[0].id, isNot(p.colors[0].id));
      final removed = s.delete(p.id)!;
      expect(s.find(p.id), isNull);
      s.restore(removed.palette, removed.index);
      expect(s.palettes.indexOf(p), 0);
    });

    test('Ensure active creates palette when empty', () {
      final s = newService();
      final p = s.ensureActive();
      expect(p.name, PaletteService.defaultName);
      expect(identical(p, s.active), isTrue);
    });

    test('Alpha is kept', () {
      final pc = PaletteColor.create(const Argb(128, 82, 70, 188));
      expect(pc.hex, '#5246BC');
      expect(pc.alpha, 128);
      expect(pc.color, const Argb(128, 82, 70, 188));
    });

    test('AddColor at limit returns null and modifies nothing', () {
      final s = newService();
      final p = s.create(name: 'Llena');
      fill(s, p, PaletteService.maxColors);
      final before = p.modifiedAt;
      now = before.add(const Duration(minutes: 1));
      expect(s.addColor(p.id, const Argb.fromRgb(255, 0, 0)), isNull);
      expect(p.colors.length, PaletteService.maxColors);
      expect(p.modifiedAt, before);
    });

    test('AddColors bulk that does not fit adds nothing', () {
      final s = newService();
      final p = s.create(name: 'Casi llena');
      fill(s, p, 60);
      final before = p.modifiedAt;
      final added = s.addColors(p.id, [for (var i = 0; i < 6; i++) (color: Argb.fromRgb(i, 1, 1), name: null)]);
      expect(added, 0);
      expect(p.colors.length, 60);
      expect(p.modifiedAt, before);
    });

    test('AddColors bulk that fits adds all in order', () {
      final s = newService();
      final p = s.create(name: 'Con hueco');
      fill(s, p, 3);
      final added = s.addColors(p.id, [for (var i = 0; i < 10; i++) (color: Argb.fromRgb(i, 1, 1), name: 'C$i')]);
      expect(added, 10);
      expect(p.colors.length, 13);
      expect(p.colors[3].name, 'C0');
      expect(p.colors[12].color, const Argb.fromRgb(9, 1, 1));
    });

    test('Palette created outside the limit is preserved', () {
      final s = newService();
      final external = Palette(
          name: 'Externa', colors: List.generate(70, (i) => PaletteColor.create(Argb.fromRgb(i, 0, 0), 'C$i')));
      s.library.palettes.add(external);
      expect(s.find(external.id)!.colors.length, 70);
      expect(s.addColor(external.id, const Argb.fromRgb(255, 0, 0)), isNull);
      expect(external.colors.length, 70);
    });
  });

  group('Export', () {
    const puchi = PaletteExportModel('PuchiApp', [
      PaletteExportColor('Primary', Argb.fromRgb(0x52, 0x46, 0xBC)),
      PaletteExportColor('Secondary', Argb.fromRgb(0xFF, 0x8A, 0x00)),
    ]);

    test('CSS variables', () {
      expect(PaletteFormatters.css(puchi, FormatOptions.defaults),
          ':root {\n  --primary: #5246BC;\n  --secondary: #FF8A00;\n}');
    });

    test('JSON object', () {
      final doc = jsonDecode(PaletteFormatters.json(puchi, FormatOptions.defaults)) as Map;
      expect(doc['Primary'], '#5246BC');
      expect(doc['Secondary'], '#FF8A00');
    });

    test('Dart class', () {
      final dart = PaletteFormatters.dart(puchi);
      expect(dart, contains('class PuchiApp {'));
      expect(dart, contains('static const Color primary = Color(0xFF5246BC);'));
      expect(dart, contains('static const Color secondary = Color(0xFFFF8A00);'));
    });

    test('C# class', () {
      final cs = PaletteFormatters.cSharp(puchi);
      expect(cs, contains('public static class PuchiApp'));
      expect(cs, contains('public static readonly Color Primary = Color.FromArgb(255, 82, 70, 188);'));
    });

    test('Scale steps and tailwind', () {
      const scale = PaletteExportModel('Primary', [
        PaletteExportColor('Primary 50', Argb.fromRgb(250, 250, 255)),
        PaletteExportColor('Primary 950', Argb.fromRgb(10, 10, 30)),
      ]);
      final css = PaletteFormatters.css(scale, FormatOptions.defaults);
      expect(css, contains('--primary-50:'));
      expect(css, contains('--primary-950:'));
      expect(PaletteFormatters.tailwind(scale, FormatOptions.defaults), contains('--color-primary-50:'));
      expect(PaletteFormatters.dart(scale), contains('primary50'));
    });

    test('Unnamed and duplicate names', () {
      const p = PaletteExportModel('Mi paleta', [
        PaletteExportColor(null, Argb.fromRgb(1, 1, 1)),
        PaletteExportColor('Primary', Argb.fromRgb(2, 2, 2)),
        PaletteExportColor('primary', Argb.fromRgb(3, 3, 3)),
      ]);
      final css = PaletteFormatters.css(p, FormatOptions.defaults);
      expect(css, contains('--color-1:'));
      expect(css, contains('--primary:'));
      expect(css, contains('--primary-2:'));
      expect(PaletteFormatters.dart(p), contains('class MiPaleta'));
      expect(PaletteFormatters.dart(p), contains('color1'));
    });

    for (final row in const [
      ['Primary Dark', 'primary-dark', 'primaryDark', 'PrimaryDark'],
      ['Señal ámbar', 'senal-ambar', 'senalAmbar', 'SenalAmbar'],
      ['primaryDark', 'primary-dark', 'primaryDark', 'PrimaryDark'],
      ['500', '500', 'color500', 'Color500'],
    ]) {
      test('Identifier naming "${row[0]}"', () {
        expect(IdentifierNaming.kebab(row[0]), row[1]);
        expect(IdentifierNaming.camel(row[0]), row[2]);
        expect(IdentifierNaming.pascal(row[0]), row[3]);
      });
    }

    test('Diacritics table is consistent', () {
      expect(IdentifierNaming.removeDiacritics('ÁÉÍÓÚáéíóúÑñÜü'), 'AEIOUaeiouNnUu');
    });
  });
}
