import 'package:matiz_core/matiz_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  const violet = Argb.fromRgb(82, 70, 188);

  for (final input in const [
    '5246bc', '#5246BC', '  #5246bc ', 'rgb(82, 70, 188)', 'RGB(82 70 188)', 'rgba(82, 70, 188, 1)',
    '82 70 188', '82,70,188', '0xFF5246BC', '0x5246BC', '#FF5246BC', 'rgb(82, 70, 188);',
  ]) {
    test('Equivalent input "$input" parses to #5246BC', () => expect(ColorParser.parse(input), violet));
  }

  test('Short hex is expanded', () => expect(ColorParser.parse('#5AC')!.toHex(), '#55AACC'));

  test('Eight digit hex is ARGB', () => expect(ColorParser.parse('#805246BC'), const Argb(128, 82, 70, 188)));

  for (final input in const ['hsl(246, 47%, 51%)', 'hsl(246deg 47% 51%)', 'hsv(246, 63%, 74%)', 'hsb(246°, 63%, 74%)']) {
    test('HSL/HSV function "$input"', () {
      final c = ColorParser.parse(input)!;
      expectInRange((c.r - 82).abs(), 0, 3);
      expectInRange((c.g - 70).abs(), 0, 3);
      expectInRange((c.b - 188).abs(), 0, 3);
    });
  }

  for (final input in const [
    '', '   ', 'rgb(300, 0, 0)', 'rgb(-1, 0, 0)', 'rgb(1, 2)', '#12345', '#GGGGGG',
    'hsl(400, 50%, 50%)', 'hsl(200, 150%, 50%)', '256 0 0', 'rgba(1, 2, 3, 2)', 'banana',
  ]) {
    test('Invalid input "$input" is rejected', () => expect(ColorParser.parse(input), isNull));
  }

  test('Code formats', () {
    expect(ColorFormats.cssRgb(violet), 'rgb(82, 70, 188)');
    expect(ColorFormats.cssHsl(violet), 'hsl(246, 47%, 51%)');
    expect(ColorFormats.cSharpWpf(violet), 'Color.FromRgb(82, 70, 188)');
    expect(ColorFormats.cSharpArgb(violet), 'Color.FromArgb(255, 82, 70, 188)');
    expect(ColorFormats.xaml(violet), '#FF5246BC');
    expect(ColorFormats.dart(violet), 'Color(0xFF5246BC)');
    expect(ColorFormats.argbInt(violet), '0xFF5246BC');
    expect(ColorFormats.cssOklch(violet), startsWith('oklch(0.'));
    expect(ColorFormats.cssOklch(violet).contains(','), isFalse);
  });

  test('Alpha formats', () {
    const c = Argb(128, 82, 70, 188);
    expect(ColorFormats.cssRgb(c), 'rgba(82, 70, 188, 0.5)');
    expect(ColorFormats.argbHex(c), '#805246BC');
    expect(ColorFormats.cSharpWpf(c), 'Color.FromArgb(128, 82, 70, 188)');
  });

  test('Copy all block', () {
    expect(ColorFormats.copyAll(violet),
        'HEX: #5246BC\nRGB: 82, 70, 188\nHSL: 246°, 47%, 51%\nHSV: 246°, 63%, 74%\nCMYK: 56%, 63%, 0%, 26%');
  });

  test('Hex options', () {
    expect(ColorFormats.hex(violet, const FormatOptions(hexUppercase: false, hexHash: false)), '5246bc');
  });

  test('Formatter registry lookup', () {
    expect(ColorFormatters.get('dart').format(violet), 'Color(0xFF5246BC)');
    expect(ColorFormatters.get('unknown').id, 'hex');
    expect(ColorFormatters.all.map((f) => f.id).toSet().length, ColorFormatters.all.length);
  });
}
