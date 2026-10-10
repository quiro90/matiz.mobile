// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Matiz';

  @override
  String get tabCreate => 'Create';

  @override
  String get tabGenerate => 'Generate';

  @override
  String get tabPalettes => 'Palettes';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get toggleTheme => 'Switch light/dark theme';

  @override
  String get settings => 'Settings';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get copy => 'Copy';

  @override
  String get paste => 'Paste';

  @override
  String get share => 'Share';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get remove => 'Remove';

  @override
  String get view => 'View';

  @override
  String get more => 'More';

  @override
  String get sourceWheel => 'Wheel';

  @override
  String get sourceImage => 'Image';

  @override
  String get openImage => 'Open image';

  @override
  String get pasteAction => 'Paste color or image';

  @override
  String get camera => 'Camera';

  @override
  String get closeImage => 'Close image';

  @override
  String get previous => 'Previous';

  @override
  String get current => 'Current';

  @override
  String copyColorA11y(String hex) {
    return 'Copy color $hex';
  }

  @override
  String get addToPalette => 'Add to palette';

  @override
  String get recents => 'Recent';

  @override
  String get clearRecents => 'Clear recent colors';

  @override
  String get clearRecentsConfirm => 'Remove all recent colors?';

  @override
  String get noRecents => 'Colors you copy or pick appear here.';

  @override
  String get detailTitle => 'Color';

  @override
  String get colorInputHint => 'HEX, rgb(), hsl()…';

  @override
  String get invalidColor => 'Invalid color';

  @override
  String get grayEquivalent => 'Equivalent gray';

  @override
  String get focus => 'Focus';

  @override
  String get focusVivid => 'Vivid';

  @override
  String get focusPastel => 'Pastel';

  @override
  String get resetFocus => 'Reset focus';

  @override
  String get moreFormats => 'More formats';

  @override
  String get copyAll => 'Copy all';

  @override
  String get copyAs => 'Copy as';

  @override
  String get shareAs => 'Share as';

  @override
  String get exportOverlay => 'Export overlay';

  @override
  String get cmykApprox => 'Approximate, no ICC profile';

  @override
  String get alpha => 'Alpha';

  @override
  String get modeScale => 'Scale';

  @override
  String get modeTintsShades => 'Tints / Shades';

  @override
  String get modeNeutrals => 'Neutrals';

  @override
  String get modeHarmony => 'Harmonies';

  @override
  String get modeCustom => 'Custom';

  @override
  String get modeExtracted => 'From image';

  @override
  String get harmonyComplementary => 'Complementary';

  @override
  String get harmonyAnalogous => 'Analogous';

  @override
  String get harmonySplit => 'Split-complementary';

  @override
  String get harmonyTriadic => 'Triadic';

  @override
  String get harmonyTetradic => 'Tetradic';

  @override
  String get harmonyMonochromatic => 'Monochromatic';

  @override
  String get balanceLightness => 'Balanced lightness';

  @override
  String get addPoint => 'Add point';

  @override
  String get clearPoints => 'Clear';

  @override
  String get clearPointsConfirm =>
      'Remove all secondary points? The main color is kept.';

  @override
  String get customize => 'Customize';

  @override
  String get prefix => 'Prefix';

  @override
  String get addAll => 'Add all';

  @override
  String get useAsMain => 'Use as main color';

  @override
  String get copyHex => 'Copy HEX';

  @override
  String get copyRgb => 'Copy RGB';

  @override
  String get base => 'Base';

  @override
  String get extractCount => 'Number of colors';

  @override
  String get extractAgain => 'Extract again';

  @override
  String get customHint => 'Long-press the wheel or the image to add colors.';

  @override
  String get activePalette => 'Active palette';

  @override
  String get library => 'Library';

  @override
  String get newPalette => 'New';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get reloadInWheel => 'Load in wheel';

  @override
  String get exportFile => 'Export .mpalette';

  @override
  String get importFile => 'Import';

  @override
  String get exportImage => 'Export image';

  @override
  String get export => 'Export';

  @override
  String get exportCode => 'Code';

  @override
  String get exportPaletteImage => 'Palette';

  @override
  String get exportOverlayImage => 'Overlay';

  @override
  String get saveTo => 'Save to…';

  @override
  String get saveToGallery => 'Save to gallery';

  @override
  String get paletteName => 'Name';

  @override
  String get paletteDescription => 'Description';

  @override
  String get descriptionHint => 'Optional';

  @override
  String colorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count colors',
      one: '1 color',
      zero: 'no colors',
    );
    return '$_temp0';
  }

  @override
  String get emptyLibrary =>
      'You have no palettes yet. Create one or import a .mpalette file.';

  @override
  String get emptyPalette =>
      'Empty palette: add colors with + from Create or Generate.';

  @override
  String get replaceWithCurrent => 'Replace with current';

  @override
  String get moveFirst => 'Move to start';

  @override
  String get moveLast => 'Move to end';

  @override
  String get renameColor => 'Color name';

  @override
  String get reorderHint => 'Long-press and drag to reorder';

  @override
  String get activeBadge => 'Active';

  @override
  String get imageNotSupported => 'The file is not a supported image.';

  @override
  String get loupeHint => 'Drag: pick · Hold: add · Pinch: zoom';

  @override
  String get cameraHint => 'The color depends on the light and white balance.';

  @override
  String get cameraUse => 'Use';

  @override
  String get cameraAddSecondary => '+ Secondary';

  @override
  String get cameraFreeze => 'Freeze';

  @override
  String get cameraPermissionTitle => 'Camera access';

  @override
  String get cameraPermissionBody =>
      'Matiz uses the camera only to read the color under the reticle. Nothing is recorded or sent.';

  @override
  String get cameraDenied => 'Camera permission denied.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get cameraUnavailable => 'No camera available.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsCopy => 'Copy';

  @override
  String get settingsDefaultFormat => 'Main format';

  @override
  String get settingsHexUppercase => 'HEX in uppercase';

  @override
  String get settingsHexHash => 'Include #';

  @override
  String get settingsCopyOnPick => 'Copy when picking a color';

  @override
  String get settingsCopyOnPickHint => 'Image, camera and bubble';

  @override
  String get settingsScale => 'Design Scale';

  @override
  String get settingsScaleAnchor => 'Anchor';

  @override
  String get anchorFixed500 => 'Base at 500';

  @override
  String get anchorAuto => 'Automatic';

  @override
  String get settingsBubble => 'Floating bubble';

  @override
  String get settingsBubbleHint => 'Pick colors from other apps';

  @override
  String get bubbleHowTitle => 'How does it work?';

  @override
  String get bubbleHowBody =>
      'The bubble floats over other apps. Tap it to take a single screenshot (Android asks for your consent) and open it in Matiz to pick colors with the loupe.\n\n• Android may ask for consent on every capture.\n• Protected content (DRM video, banking apps) may appear black.\n• On HDR screens or with manufacturer color modes the captured value may differ from the original.';

  @override
  String get bubblePermissionOverlay =>
      'The bubble needs the \"Display over other apps\" permission.';

  @override
  String get bubblePermissionNotifications =>
      'The bubble needs notifications to keep running.';

  @override
  String get settingsAbout => 'About';

  @override
  String get support => 'Consider donating if Matiz is useful to you:';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get licenses => 'Open source licenses';

  @override
  String toastCopied(String value) {
    return 'Copied $value';
  }

  @override
  String toastCopiedAs(String format) {
    return 'Copied as $format';
  }

  @override
  String get toastCopyFailed => 'Could not copy';

  @override
  String toastAddedTo(String palette) {
    return 'Added to $palette';
  }

  @override
  String toastAddedCount(int count, String palette) {
    return '$count colors added to $palette';
  }

  @override
  String get toastMaxColors => 'Maximum 64 colors per palette';

  @override
  String toastAddedCustom(int count) {
    return 'Added to Custom ($count)';
  }

  @override
  String get toastCustomizeReplace =>
      'This will replace all colors loaded in Custom.';

  @override
  String toastCustomizeApplied(int count) {
    return '$count extracted colors loaded in Custom';
  }

  @override
  String toastExtracted(int count) {
    return '$count colors extracted';
  }

  @override
  String get toastReloadWarning =>
      'The palette will be loaded in the color wheel and current selections will be lost.';

  @override
  String toastPaletteDeleted(String name) {
    return 'Palette \"$name\" deleted';
  }

  @override
  String get toastColorDeleted => 'Color removed';

  @override
  String toastImported(String name) {
    return 'Palette \"$name\" imported';
  }

  @override
  String get toastImportFailed => 'The file is not a valid Matiz palette.';

  @override
  String get toastImportFuture =>
      'This palette was made with a newer version of Matiz.';

  @override
  String toastExported(String name) {
    return 'Palette \"$name\" exported';
  }

  @override
  String get toastSavedImage => 'Image saved';

  @override
  String get toastSaveFailed => 'Could not save';

  @override
  String get toastClipboardEmpty => 'The clipboard has no color or image.';

  @override
  String get toastFirstImageUsed => 'The first image was used';

  @override
  String get toastCorruptData =>
      'A data file was damaged and has been reset (backup kept).';

  @override
  String get toastNothingToExport => 'The palette has no colors.';

  @override
  String get exportTitle => 'Export image';

  @override
  String get exportOrientation => 'Orientation';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get vertical => 'Vertical';

  @override
  String get exportSize => 'Size';

  @override
  String get exportBackground => 'Background';

  @override
  String get bgLight => 'Light';

  @override
  String get bgDark => 'Dark';

  @override
  String get bgTransparent => 'Transparent';

  @override
  String get exportValues => 'Values';

  @override
  String get exportShape => 'Shape';

  @override
  String get shapeSquare => 'Square';

  @override
  String get shapeCircle => 'Circle';

  @override
  String get shapeTriangle => 'Triangle';

  @override
  String get exportOrder => 'Order';

  @override
  String get orderFirstLast => 'First → last';

  @override
  String get orderLastFirst => 'Last → first';

  @override
  String get previousCurrentTitle => 'Previous / Current';

  @override
  String get customExportTitle => 'Custom';

  @override
  String get tintsExportTitle => 'Tints and shades';

  @override
  String get imageColorsExportTitle => 'Image colors';

  @override
  String imageColorName(int index) {
    return 'Image $index';
  }

  @override
  String get grayscaleTitle => 'Grayscale';

  @override
  String get grayscaleReset => 'Reset grayscale';
}
