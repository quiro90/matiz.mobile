import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Matiz'**
  String get appName;

  /// No description provided for @tabCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get tabCreate;

  /// No description provided for @tabGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get tabGenerate;

  /// No description provided for @tabPalettes.
  ///
  /// In en, this message translates to:
  /// **'Palettes'**
  String get tabPalettes;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @toggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch light/dark theme'**
  String get toggleTheme;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @sourceWheel.
  ///
  /// In en, this message translates to:
  /// **'Wheel'**
  String get sourceWheel;

  /// No description provided for @sourceImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get sourceImage;

  /// No description provided for @openImage.
  ///
  /// In en, this message translates to:
  /// **'Open image'**
  String get openImage;

  /// No description provided for @pasteAction.
  ///
  /// In en, this message translates to:
  /// **'Paste color or image'**
  String get pasteAction;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @closeImage.
  ///
  /// In en, this message translates to:
  /// **'Close image'**
  String get closeImage;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @copyColorA11y.
  ///
  /// In en, this message translates to:
  /// **'Copy color {hex}'**
  String copyColorA11y(String hex);

  /// No description provided for @addToPalette.
  ///
  /// In en, this message translates to:
  /// **'Add to palette'**
  String get addToPalette;

  /// No description provided for @recents.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recents;

  /// No description provided for @clearRecents.
  ///
  /// In en, this message translates to:
  /// **'Clear recent colors'**
  String get clearRecents;

  /// No description provided for @clearRecentsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove all recent colors?'**
  String get clearRecentsConfirm;

  /// No description provided for @noRecents.
  ///
  /// In en, this message translates to:
  /// **'Colors you copy or pick appear here.'**
  String get noRecents;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get detailTitle;

  /// No description provided for @colorInputHint.
  ///
  /// In en, this message translates to:
  /// **'HEX, rgb(), hsl()…'**
  String get colorInputHint;

  /// No description provided for @invalidColor.
  ///
  /// In en, this message translates to:
  /// **'Invalid color'**
  String get invalidColor;

  /// No description provided for @grayEquivalent.
  ///
  /// In en, this message translates to:
  /// **'Equivalent gray'**
  String get grayEquivalent;

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// No description provided for @focusVivid.
  ///
  /// In en, this message translates to:
  /// **'Vivid'**
  String get focusVivid;

  /// No description provided for @focusPastel.
  ///
  /// In en, this message translates to:
  /// **'Pastel'**
  String get focusPastel;

  /// No description provided for @resetFocus.
  ///
  /// In en, this message translates to:
  /// **'Reset focus'**
  String get resetFocus;

  /// No description provided for @moreFormats.
  ///
  /// In en, this message translates to:
  /// **'More formats'**
  String get moreFormats;

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get copyAll;

  /// No description provided for @copyAs.
  ///
  /// In en, this message translates to:
  /// **'Copy as'**
  String get copyAs;

  /// No description provided for @shareAs.
  ///
  /// In en, this message translates to:
  /// **'Share as'**
  String get shareAs;

  /// No description provided for @exportOverlay.
  ///
  /// In en, this message translates to:
  /// **'Export overlay'**
  String get exportOverlay;

  /// No description provided for @cmykApprox.
  ///
  /// In en, this message translates to:
  /// **'Approximate, no ICC profile'**
  String get cmykApprox;

  /// No description provided for @alpha.
  ///
  /// In en, this message translates to:
  /// **'Alpha'**
  String get alpha;

  /// No description provided for @modeScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get modeScale;

  /// No description provided for @modeTintsShades.
  ///
  /// In en, this message translates to:
  /// **'Tints / Shades'**
  String get modeTintsShades;

  /// No description provided for @modeNeutrals.
  ///
  /// In en, this message translates to:
  /// **'Neutrals'**
  String get modeNeutrals;

  /// No description provided for @modeHarmony.
  ///
  /// In en, this message translates to:
  /// **'Harmonies'**
  String get modeHarmony;

  /// No description provided for @modeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get modeCustom;

  /// No description provided for @modeExtracted.
  ///
  /// In en, this message translates to:
  /// **'From image'**
  String get modeExtracted;

  /// No description provided for @harmonyComplementary.
  ///
  /// In en, this message translates to:
  /// **'Complementary'**
  String get harmonyComplementary;

  /// No description provided for @harmonyAnalogous.
  ///
  /// In en, this message translates to:
  /// **'Analogous'**
  String get harmonyAnalogous;

  /// No description provided for @harmonySplit.
  ///
  /// In en, this message translates to:
  /// **'Split-complementary'**
  String get harmonySplit;

  /// No description provided for @harmonyTriadic.
  ///
  /// In en, this message translates to:
  /// **'Triadic'**
  String get harmonyTriadic;

  /// No description provided for @harmonyTetradic.
  ///
  /// In en, this message translates to:
  /// **'Tetradic'**
  String get harmonyTetradic;

  /// No description provided for @harmonyMonochromatic.
  ///
  /// In en, this message translates to:
  /// **'Monochromatic'**
  String get harmonyMonochromatic;

  /// No description provided for @balanceLightness.
  ///
  /// In en, this message translates to:
  /// **'Balanced lightness'**
  String get balanceLightness;

  /// No description provided for @addPoint.
  ///
  /// In en, this message translates to:
  /// **'Add point'**
  String get addPoint;

  /// No description provided for @clearPoints.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearPoints;

  /// No description provided for @clearPointsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove all secondary points? The main color is kept.'**
  String get clearPointsConfirm;

  /// No description provided for @customize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customize;

  /// No description provided for @prefix.
  ///
  /// In en, this message translates to:
  /// **'Prefix'**
  String get prefix;

  /// No description provided for @addAll.
  ///
  /// In en, this message translates to:
  /// **'Add all'**
  String get addAll;

  /// No description provided for @useAsMain.
  ///
  /// In en, this message translates to:
  /// **'Use as main color'**
  String get useAsMain;

  /// No description provided for @copyHex.
  ///
  /// In en, this message translates to:
  /// **'Copy HEX'**
  String get copyHex;

  /// No description provided for @copyRgb.
  ///
  /// In en, this message translates to:
  /// **'Copy RGB'**
  String get copyRgb;

  /// No description provided for @base.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get base;

  /// No description provided for @extractCount.
  ///
  /// In en, this message translates to:
  /// **'Number of colors'**
  String get extractCount;

  /// No description provided for @extractAgain.
  ///
  /// In en, this message translates to:
  /// **'Extract again'**
  String get extractAgain;

  /// No description provided for @customHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press the wheel or the image to add colors.'**
  String get customHint;

  /// No description provided for @activePalette.
  ///
  /// In en, this message translates to:
  /// **'Active palette'**
  String get activePalette;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @newPalette.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newPalette;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @reloadInWheel.
  ///
  /// In en, this message translates to:
  /// **'Load in wheel'**
  String get reloadInWheel;

  /// No description provided for @exportFile.
  ///
  /// In en, this message translates to:
  /// **'Export .mpalette'**
  String get exportFile;

  /// No description provided for @importFile.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importFile;

  /// No description provided for @exportImage.
  ///
  /// In en, this message translates to:
  /// **'Export image'**
  String get exportImage;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get exportCode;

  /// No description provided for @exportPaletteImage.
  ///
  /// In en, this message translates to:
  /// **'Palette'**
  String get exportPaletteImage;

  /// No description provided for @exportOverlayImage.
  ///
  /// In en, this message translates to:
  /// **'Overlay'**
  String get exportOverlayImage;

  /// No description provided for @saveTo.
  ///
  /// In en, this message translates to:
  /// **'Save to…'**
  String get saveTo;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to gallery'**
  String get saveToGallery;

  /// No description provided for @paletteName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get paletteName;

  /// No description provided for @paletteDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get paletteDescription;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get descriptionHint;

  /// No description provided for @colorsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no colors} =1{1 color} other{{count} colors}}'**
  String colorsCount(int count);

  /// No description provided for @emptyLibrary.
  ///
  /// In en, this message translates to:
  /// **'You have no palettes yet. Create one or import a .mpalette file.'**
  String get emptyLibrary;

  /// No description provided for @emptyPalette.
  ///
  /// In en, this message translates to:
  /// **'Empty palette: add colors with + from Create or Generate.'**
  String get emptyPalette;

  /// No description provided for @replaceWithCurrent.
  ///
  /// In en, this message translates to:
  /// **'Replace with current'**
  String get replaceWithCurrent;

  /// No description provided for @moveFirst.
  ///
  /// In en, this message translates to:
  /// **'Move to start'**
  String get moveFirst;

  /// No description provided for @moveLast.
  ///
  /// In en, this message translates to:
  /// **'Move to end'**
  String get moveLast;

  /// No description provided for @renameColor.
  ///
  /// In en, this message translates to:
  /// **'Color name'**
  String get renameColor;

  /// No description provided for @reorderHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press and drag to reorder'**
  String get reorderHint;

  /// No description provided for @activeBadge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeBadge;

  /// No description provided for @imageNotSupported.
  ///
  /// In en, this message translates to:
  /// **'The file is not a supported image.'**
  String get imageNotSupported;

  /// No description provided for @loupeHint.
  ///
  /// In en, this message translates to:
  /// **'Drag: pick · Hold: add · Pinch: zoom'**
  String get loupeHint;

  /// No description provided for @cameraHint.
  ///
  /// In en, this message translates to:
  /// **'The color depends on the light and white balance.'**
  String get cameraHint;

  /// No description provided for @cameraUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get cameraUse;

  /// No description provided for @cameraAddSecondary.
  ///
  /// In en, this message translates to:
  /// **'+ Secondary'**
  String get cameraAddSecondary;

  /// No description provided for @cameraFreeze.
  ///
  /// In en, this message translates to:
  /// **'Freeze'**
  String get cameraFreeze;

  /// No description provided for @cameraPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera access'**
  String get cameraPermissionTitle;

  /// No description provided for @cameraPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Matiz uses the camera only to read the color under the reticle. Nothing is recorded or sent.'**
  String get cameraPermissionBody;

  /// No description provided for @cameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied.'**
  String get cameraDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No camera available.'**
  String get cameraUnavailable;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get settingsCopy;

  /// No description provided for @settingsDefaultFormat.
  ///
  /// In en, this message translates to:
  /// **'Main format'**
  String get settingsDefaultFormat;

  /// No description provided for @settingsHexUppercase.
  ///
  /// In en, this message translates to:
  /// **'HEX in uppercase'**
  String get settingsHexUppercase;

  /// No description provided for @settingsHexHash.
  ///
  /// In en, this message translates to:
  /// **'Include #'**
  String get settingsHexHash;

  /// No description provided for @settingsCopyOnPick.
  ///
  /// In en, this message translates to:
  /// **'Copy when picking a color'**
  String get settingsCopyOnPick;

  /// No description provided for @settingsCopyOnPickHint.
  ///
  /// In en, this message translates to:
  /// **'Image, camera and bubble'**
  String get settingsCopyOnPickHint;

  /// No description provided for @settingsScale.
  ///
  /// In en, this message translates to:
  /// **'Design Scale'**
  String get settingsScale;

  /// No description provided for @settingsScaleAnchor.
  ///
  /// In en, this message translates to:
  /// **'Anchor'**
  String get settingsScaleAnchor;

  /// No description provided for @anchorFixed500.
  ///
  /// In en, this message translates to:
  /// **'Base at 500'**
  String get anchorFixed500;

  /// No description provided for @anchorAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get anchorAuto;

  /// No description provided for @settingsBubble.
  ///
  /// In en, this message translates to:
  /// **'Floating bubble'**
  String get settingsBubble;

  /// No description provided for @settingsBubbleHint.
  ///
  /// In en, this message translates to:
  /// **'Pick colors from other apps'**
  String get settingsBubbleHint;

  /// No description provided for @bubbleHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How does it work?'**
  String get bubbleHowTitle;

  /// No description provided for @bubbleHowBody.
  ///
  /// In en, this message translates to:
  /// **'The bubble floats over other apps. Tap it to take a single screenshot (Android asks for your consent) and open it in Matiz to pick colors with the loupe.\n\n• Android may ask for consent on every capture.\n• Protected content (DRM video, banking apps) may appear black.\n• On HDR screens or with manufacturer color modes the captured value may differ from the original.'**
  String get bubbleHowBody;

  /// No description provided for @bubblePermissionOverlay.
  ///
  /// In en, this message translates to:
  /// **'The bubble needs the \"Display over other apps\" permission.'**
  String get bubblePermissionOverlay;

  /// No description provided for @bubblePermissionNotifications.
  ///
  /// In en, this message translates to:
  /// **'The bubble needs notifications to keep running.'**
  String get bubblePermissionNotifications;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Consider donating if Matiz is useful to you:'**
  String get support;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get licenses;

  /// No description provided for @toastCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied {value}'**
  String toastCopied(String value);

  /// No description provided for @toastCopiedAs.
  ///
  /// In en, this message translates to:
  /// **'Copied as {format}'**
  String toastCopiedAs(String format);

  /// No description provided for @toastCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not copy'**
  String get toastCopyFailed;

  /// No description provided for @toastAddedTo.
  ///
  /// In en, this message translates to:
  /// **'Added to {palette}'**
  String toastAddedTo(String palette);

  /// No description provided for @toastAddedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} colors added to {palette}'**
  String toastAddedCount(int count, String palette);

  /// No description provided for @toastMaxColors.
  ///
  /// In en, this message translates to:
  /// **'Maximum 64 colors per palette'**
  String get toastMaxColors;

  /// No description provided for @toastAddedCustom.
  ///
  /// In en, this message translates to:
  /// **'Added to Custom ({count})'**
  String toastAddedCustom(int count);

  /// No description provided for @toastCustomizeReplace.
  ///
  /// In en, this message translates to:
  /// **'This will replace all colors loaded in Custom.'**
  String get toastCustomizeReplace;

  /// No description provided for @toastCustomizeApplied.
  ///
  /// In en, this message translates to:
  /// **'{count} extracted colors loaded in Custom'**
  String toastCustomizeApplied(int count);

  /// No description provided for @toastExtracted.
  ///
  /// In en, this message translates to:
  /// **'{count} colors extracted'**
  String toastExtracted(int count);

  /// No description provided for @toastReloadWarning.
  ///
  /// In en, this message translates to:
  /// **'The palette will be loaded in the color wheel and current selections will be lost.'**
  String get toastReloadWarning;

  /// No description provided for @toastPaletteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Palette \"{name}\" deleted'**
  String toastPaletteDeleted(String name);

  /// No description provided for @toastColorDeleted.
  ///
  /// In en, this message translates to:
  /// **'Color removed'**
  String get toastColorDeleted;

  /// No description provided for @toastImported.
  ///
  /// In en, this message translates to:
  /// **'Palette \"{name}\" imported'**
  String toastImported(String name);

  /// No description provided for @toastImportFailed.
  ///
  /// In en, this message translates to:
  /// **'The file is not a valid Matiz palette.'**
  String get toastImportFailed;

  /// No description provided for @toastImportFuture.
  ///
  /// In en, this message translates to:
  /// **'This palette was made with a newer version of Matiz.'**
  String get toastImportFuture;

  /// No description provided for @toastExported.
  ///
  /// In en, this message translates to:
  /// **'Palette \"{name}\" exported'**
  String toastExported(String name);

  /// No description provided for @toastSavedImage.
  ///
  /// In en, this message translates to:
  /// **'Image saved'**
  String get toastSavedImage;

  /// No description provided for @toastSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save'**
  String get toastSaveFailed;

  /// No description provided for @toastClipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'The clipboard has no color or image.'**
  String get toastClipboardEmpty;

  /// No description provided for @toastFirstImageUsed.
  ///
  /// In en, this message translates to:
  /// **'The first image was used'**
  String get toastFirstImageUsed;

  /// No description provided for @toastCorruptData.
  ///
  /// In en, this message translates to:
  /// **'A data file was damaged and has been reset (backup kept).'**
  String get toastCorruptData;

  /// No description provided for @toastNothingToExport.
  ///
  /// In en, this message translates to:
  /// **'The palette has no colors.'**
  String get toastNothingToExport;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export image'**
  String get exportTitle;

  /// No description provided for @exportOrientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get exportOrientation;

  /// No description provided for @horizontal.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get horizontal;

  /// No description provided for @vertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get vertical;

  /// No description provided for @exportSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get exportSize;

  /// No description provided for @exportBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get exportBackground;

  /// No description provided for @bgLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get bgLight;

  /// No description provided for @bgDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get bgDark;

  /// No description provided for @bgTransparent.
  ///
  /// In en, this message translates to:
  /// **'Transparent'**
  String get bgTransparent;

  /// No description provided for @exportValues.
  ///
  /// In en, this message translates to:
  /// **'Values'**
  String get exportValues;

  /// No description provided for @exportShape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get exportShape;

  /// No description provided for @shapeSquare.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get shapeSquare;

  /// No description provided for @shapeCircle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get shapeCircle;

  /// No description provided for @shapeTriangle.
  ///
  /// In en, this message translates to:
  /// **'Triangle'**
  String get shapeTriangle;

  /// No description provided for @exportOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get exportOrder;

  /// No description provided for @orderFirstLast.
  ///
  /// In en, this message translates to:
  /// **'First → last'**
  String get orderFirstLast;

  /// No description provided for @orderLastFirst.
  ///
  /// In en, this message translates to:
  /// **'Last → first'**
  String get orderLastFirst;

  /// No description provided for @previousCurrentTitle.
  ///
  /// In en, this message translates to:
  /// **'Previous / Current'**
  String get previousCurrentTitle;

  /// No description provided for @customExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customExportTitle;

  /// No description provided for @tintsExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Tints and shades'**
  String get tintsExportTitle;

  /// No description provided for @imageColorsExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Image colors'**
  String get imageColorsExportTitle;

  /// No description provided for @imageColorName.
  ///
  /// In en, this message translates to:
  /// **'Image {index}'**
  String imageColorName(int index);

  /// No description provided for @grayscaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get grayscaleTitle;

  /// No description provided for @grayscaleReset.
  ///
  /// In en, this message translates to:
  /// **'Reset grayscale'**
  String get grayscaleReset;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
