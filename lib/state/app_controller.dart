import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:matiz_core/matiz_core.dart';

import '../l10n/generated/app_localizations.dart';
import '../platform/platform_bridge.dart';
import 'image_doc.dart';

/// Aviso breve (SnackBar) con acción opcional.
class Toast {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  const Toast(this.message, {this.actionLabel, this.onAction, this.duration = const Duration(seconds: 3)});
}

/// Punto secundario dibujado en la rueda (armonía o Personalizado).
class WheelMarker {
  final double hue;
  final double saturation;
  final Argb color;
  final bool selected;
  const WheelMarker(this.hue, this.saturation, this.color, this.selected);
}

/// Destinos de la barra inferior.
abstract final class Tabs {
  static const create = 0;
  static const generate = 1;
  static const palettes = 2;
}

/// Estado de la app: fuente única de verdad del color actual, paletas generadas, modo Personalizado,
/// biblioteca, imagen y ajustes. Equivalente móvil del MainViewModel de desktop.
class AppController extends ChangeNotifier {
  AppController({required this.dataDir, required this.platform});

  final String dataDir;
  final PlatformBridge platform;

  late final JsonStore<AppSettings> _settingsStore;
  late final JsonStore<ColorHistory> _historyStore;
  late final JsonStore<PaletteLibrary> _palettesStore;

  late AppSettings settings;
  late ColorHistory history;
  late PaletteService palettes;
  late ColorSession session;
  final FreePointSet freePoints = FreePointSet();

  final _toasts = StreamController<Toast>.broadcast();
  Stream<Toast> get toasts => _toasts.stream;

  /// Textos localizados (los fija la app al construirse y al cambiar de idioma).
  AppLocalizations? _t;
  AppLocalizations get t => _t!;
  set t(AppLocalizations value) {
    if (identical(_t, value)) return;
    _t = value;
    Texts.current = value.localeName.startsWith('es') ? SpanishTexts() : EnglishTexts();
    _genVersion++;
  }

  final List<String> _startupNotices = [];

  // ---------- Navegación ----------

  int tab = Tabs.create;
  bool showImage = false;

  void setTab(int value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
  }

  void setShowImage(bool value) {
    if (value && image == null) return;
    if (showImage == value) return;
    showImage = value;
    notifyListeners();
  }

  // ---------- Inicio ----------

  void load() {
    final paths = DataPaths(dataDir);
    _settingsStore = Repositories.settings(paths);
    _historyStore = Repositories.history(paths);
    _palettesStore = Repositories.palettes(paths);

    final s = _settingsStore.load();
    final h = _historyStore.load();
    final p = _palettesStore.load();
    settings = s.value;
    history = h.value;
    if ([s, h, p].any((r) => r.recoveredCorruptFile != null)) _startupNotices.add('corrupt');

    palettes = PaletteService(p.value);
    palettes.onChanged = () {
      _palettesStore.scheduleSave(palettes.library);
      notifyListeners();
    };
    history.onChanged = () => _historyStore.scheduleSave(history);

    final last = ColorParser.parse(settings.lastColor) ?? const Argb.fromRgb(82, 70, 188);
    final prev = settings.lastHue != null ? ColorState(settings.lastHue!, settings.lastSaturation ?? 0, 1) : null;
    session = ColorSession(ColorState.fromArgb(last, prev));
    session.onChanged = _onColorChanged;
    _harmony = settings.harmonyKind;
    _mode = settings.generationMode;
  }

  /// Avisos diferidos del arranque (necesitan los textos localizados).
  void showStartupNotices() {
    if (_startupNotices.remove('corrupt')) _toast(Toast(t.toastCorruptData, duration: const Duration(seconds: 6)));
  }

  /// Escribe cualquier guardado pendiente (al pasar a segundo plano).
  void flush() {
    _settingsStore.flush();
    _historyStore.flush();
    _palettesStore.flush();
  }

  void _toast(Toast t) => _toasts.add(t);

  void _saveSettings() => _settingsStore.scheduleSave(settings);

  // ---------- Color actual ----------

  ColorState get current => session.current;
  ColorState get previous => session.previous;
  Argb get currentArgb => session.current.argb;

  FormatOptions get formatOptions => settings.toFormatOptions();
  ColorFormatter get defaultFormatter => ColorFormatters.get(settings.defaultFormatId);

  double get wheelGamma => WheelMapping.gammaFromFocus(settings.wheelFocus);

  void _onColorChanged(ColorChange change) {
    if (change.kind != ColorChangeKind.preview) {
      settings.lastColor = change.state.argb.toString();
      settings.lastHue = change.state.hue;
      settings.lastSaturation = change.state.saturation;
      _saveSettings();
    }
    if (change.kind == ColorChangeKind.commit) {
      switch (change.source) {
        case ColorChangeSource.manualInput:
        case ColorChangeSource.image:
        case ColorChangeSource.camera:
        case ColorChangeSource.screenCapture:
          history.add(change.state.argb);
        default:
          break;
      }
    }
    notifyListeners();
  }

  void preview(ColorState state) => session.setPreview(state);

  void commit(ColorState state, [ColorChangeSource source = ColorChangeSource.picker]) => session.commit(state, source);

  void commitArgb(Argb color, ColorChangeSource source) {
    session.commitArgb(color, source);
    if (settings.copyOnPick &&
        (source == ColorChangeSource.image ||
            source == ColorChangeSource.camera ||
            source == ColorChangeSource.screenCapture)) {
      copyDefault(color);
    }
  }

  void undo() => session.undo();
  void redo() => session.redo();
  void restorePrevious() => session.restorePrevious();

  void grayEquivalent() => commitArgb(ColorMath.grayEquivalent(currentArgb), ColorChangeSource.gray);

  /// Entrada de texto en cualquier formato soportado. Devuelve false si es inválida.
  bool commitText(String text) {
    final c = ColorParser.parse(text);
    if (c == null) return false;
    commitArgb(c, ColorChangeSource.manualInput);
    return true;
  }

  // ---------- Copiar ----------

  Future<void> copyText(String text, {Argb? color, String? what}) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (color != null) history.add(color);
      _toast(Toast(what ?? t.toastCopied(text.length > 40 ? '${text.substring(0, 40)}…' : text),
          duration: const Duration(seconds: 2)));
      notifyListeners();
    } catch (_) {
      _toast(Toast(t.toastCopyFailed));
    }
  }

  Future<void> copyDefault(Argb c) => copyText(defaultFormatter.format(c, formatOptions), color: c);

  Future<void> copyHex(Argb c) => copyText(ColorFormats.hex(c, formatOptions), color: c);

  /// "Pegar" inteligente: imagen del portapapeles → modo Imagen; texto parseable → color.
  Future<void> pasteSmart() async {
    final img = await platform.clipboardImage();
    if (img != null && await loadImageBytes(img)) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && commitText(data!.text!)) return;
    _toast(Toast(t.toastClipboardEmpty));
  }

  void clearHistory() {
    history.clear();
    notifyListeners();
  }

  // ---------- Paletas generadas ----------

  GenerationMode _mode = GenerationMode.scale;
  HarmonyKind _harmony = HarmonyKind.complementary;
  int _genVersion = 0;
  int _selectedMarker = -1;

  GenerationMode get mode => _mode;
  HarmonyKind get harmony => _harmony;
  bool get hasExtracted => (image?.extracted.isNotEmpty ?? false);

  void setMode(GenerationMode m) {
    if (m == GenerationMode.extracted && !hasExtracted) return;
    if (_mode == m) return;
    _mode = m;
    _selectedMarker = -1;
    _genVersion++;
    if (m != GenerationMode.extracted) {
      settings.generationMode = m;
      _saveSettings();
    }
    notifyListeners();
  }

  void setHarmony(HarmonyKind k) {
    _harmony = k;
    _selectedMarker = -1;
    _genVersion++;
    settings.harmonyKind = k;
    _saveSettings();
    notifyListeners();
  }

  void setBalance(bool v) {
    settings.harmonyBalanceLightness = v;
    _genVersion++;
    _saveSettings();
    notifyListeners();
  }

  void setPrefix(String v) {
    settings.scalePrefix = v;
    _saveSettings();
  }

  Object? _genKeyState;
  int _genKeyVersion = -1;
  List<GeneratedColor> _generated = const [];

  /// Colores del modo activo, recalculados en vivo con el color actual.
  List<GeneratedColor> get generated {
    if (!identical(_genKeyState, session.current) || _genKeyVersion != _genVersion) {
      _generated = _compute(_mode);
      _genKeyState = session.current;
      _genKeyVersion = _genVersion;
    }
    return _generated;
  }

  List<GeneratedColor> generatedFor(GenerationMode m) => m == _mode ? generated : _compute(m);

  List<GeneratedColor> _compute(GenerationMode m) {
    final st = session.current;
    final c = st.argb;
    final anchor = settings.scaleAnchor;
    return switch (m) {
      GenerationMode.scale => DesignScale.generate(c, anchor),
      GenerationMode.harmony => PaletteGenerator.harmony(st, _harmony,
          anchor: anchor, balanceLightness: settings.harmonyBalanceLightness),
      GenerationMode.tintsShades => PaletteGenerator.tintsAndShades(c),
      GenerationMode.neutrals => PaletteGenerator.neutrals(c),
      GenerationMode.custom =>
        PaletteGenerator.freePoints(st, freePoints.offsets, balanceLightness: settings.harmonyBalanceLightness),
      GenerationMode.extracted => [
          for (var i = 0; i < (image?.extracted.length ?? 0); i++)
            GeneratedColor('${i + 1}', image!.extracted[i]),
        ],
    };
  }

  bool get markersVisible => _mode == GenerationMode.harmony || _mode == GenerationMode.custom;

  int get selectedGeneratedIndex => markersVisible ? _selectedMarkerSwatch : -1;
  int _selectedMarkerSwatch = -1;

  /// Puntos de la rueda (sin el base) e índice de su tarjeta.
  List<WheelMarker> get markers {
    if (!markersVisible) return const [];
    final list = <WheelMarker>[];
    final g = generated;
    var k = 0;
    for (var i = 0; i < g.length; i++) {
      if (g[i].isBase) continue;
      final hsv = ColorMath.toHsv(g[i].color);
      list.add(WheelMarker(g[i].wheelHue ?? hsv.h, g[i].wheelSaturation ?? hsv.s, g[i].color, k == _selectedMarker));
      k++;
    }
    return list;
  }

  int _markerToSwatch(int marker) {
    final g = generated;
    var k = 0;
    for (var i = 0; i < g.length; i++) {
      if (g[i].isBase) continue;
      if (k == marker) return i;
      k++;
    }
    return -1;
  }

  /// Toque en un punto de la rueda: lo selecciona y ofrece copiarlo sin cambiar el color actual.
  void selectMarker(int index) {
    final swatch = _markerToSwatch(index);
    if (swatch < 0) return;
    _selectedMarker = index;
    _selectedMarkerSwatch = swatch;
    notifyListeners();
    final s = generated[swatch];
    final text = defaultFormatter.format(s.color, formatOptions);
    final title = _mode == GenerationMode.harmony ? '${PaletteGenerator.harmonyName(_harmony)} ${s.label}' : s.label;
    _toast(Toast('$title  ·  $text',
        actionLabel: t.copy, onAction: () => copyText(text, color: s.color), duration: const Duration(seconds: 5)));
  }

  /// Inicio del arrastre de un punto: en Armonías convierte la figura a Personalizado.
  void beginMarkerDrag() {
    if (_mode == GenerationMode.harmony) {
      freePoints.fromHarmony(_harmony);
      _mode = GenerationMode.custom;
      settings.generationMode = _mode;
      _saveSettings();
      _genVersion++;
    }
  }

  void moveMarker(int index, double hue, double saturation) {
    if (_mode != GenerationMode.custom) return;
    freePoints.move(index, session.current, hue, saturation);
    _genVersion++;
    notifyListeners();
  }

  /// Doble toque en un punto: lo elimina (desde Armonías pasa a Personalizado sin ese punto).
  void removeMarker(int index) {
    if (_mode == GenerationMode.harmony) {
      final pts = FreePointSet.harmonyPoints(_harmony);
      if (index < pts.length) pts.removeAt(index);
      freePoints.replaceAll(pts);
      _switchToCustom();
    } else if (_mode == GenerationMode.custom) {
      freePoints.removeAt(index);
    }
    _selectedMarker = -1;
    _genVersion++;
    notifyListeners();
  }

  void _switchToCustom() {
    _mode = GenerationMode.custom;
    settings.generationMode = _mode;
    _saveSettings();
  }

  void _convertHarmonyIfNeeded() {
    if (_mode == GenerationMode.harmony) freePoints.fromHarmony(_harmony);
  }

  void _afterPointAdded() {
    _switchToCustom();
    _selectedMarker = -1;
    _genVersion++;
    notifyListeners();
    HapticFeedback.mediumImpact();
    _toast(Toast(t.toastAddedCustom(freePoints.length),
        actionLabel: tab == Tabs.generate ? null : t.view,
        onAction: tab == Tabs.generate ? null : () => setTab(Tabs.generate),
        duration: const Duration(seconds: 2)));
  }

  /// Mantener pulsado en la rueda: añade un punto en esa posición.
  void addPointAt(double hue, double saturation) {
    if (hue.isNaN) hue = session.current.hue;
    if (freePoints.isFull) return _toast(Toast(t.toastMaxColors));
    _convertHarmonyIfNeeded();
    freePoints.add(FreePointSet.offsetAt(session.current, hue, saturation));
    _afterPointAdded();
  }

  /// Añade un secundario que reproduce exactamente [c] (imagen, cámara, burbuja).
  void addPointFromColor(Argb c) {
    if (freePoints.isFull) return _toast(Toast(t.toastMaxColors));
    _convertHarmonyIfNeeded();
    freePoints.add(FreePointSet.offsetForColor(session.current, c));
    _afterPointAdded();
  }

  bool get canAddPoint => _mode == GenerationMode.harmony || !freePoints.isFull;

  /// Botón "+": opuesto al principal o al lado del último.
  void addPointButton() {
    if (_mode == GenerationMode.harmony) {
      freePoints.fromHarmony(_harmony);
    }
    if (!freePoints.isFull) freePoints.add(freePoints.nextAddPosition());
    _switchToCustom();
    _genVersion++;
    notifyListeners();
  }

  void clearPoints() {
    freePoints.clear();
    _genVersion++;
    notifyListeners();
  }

  /// "−" en una tarjeta de Personalizado. Quitar el principal promueve al primer secundario.
  void removeCustomCard(int index) {
    if (_mode != GenerationMode.custom) return;
    if (index == 0) {
      final promoted = freePoints.promoteFirst([for (final g in generated) g.color]);
      if (promoted != null) {
        _genVersion++;
        session.commitArgb(promoted, ColorChangeSource.generated);
      }
    } else {
      freePoints.removeAt(index - 1);
      _genVersion++;
      notifyListeners();
    }
  }

  /// "Personalizar" en De la imagen: los extraídos pasan a ser secundarios con brillo propio.
  void customizeFromImage({bool confirmed = false}) {
    final ex = image?.extracted ?? const <Argb>[];
    if (ex.isEmpty) return;
    if (!confirmed && !freePoints.isEmpty) {
      _toast(Toast(t.toastCustomizeReplace,
          actionLabel: t.customize,
          onAction: () => customizeFromImage(confirmed: true),
          duration: const Duration(seconds: 6)));
      return;
    }
    final st = session.current;
    freePoints.replaceAll([
      for (final c in ex.take(FreePointSet.maxPoints))
        () {
          final hsv = ColorMath.toHsv(c);
          return PointOffset(ColorMath.normalizeHue(hsv.h - st.hue), clampD(hsv.s, 0, 1) - st.saturation, hsv.v - st.value);
        }(),
    ]);
    if (ex.length > FreePointSet.maxPoints) _toast(Toast(t.toastMaxColors));
    _switchToCustom();
    _genVersion++;
    notifyListeners();
    _toast(Toast(t.toastCustomizeApplied(freePoints.length)));
  }

  void useGenerated(int index) {
    final g = generated;
    if (index < 0 || index >= g.length) return;
    session.commitArgb(g[index].color, ColorChangeSource.generated);
  }

  String generatedName(int index) {
    final g = generated[index];
    final prefix = settings.scalePrefix.trim().isEmpty ? 'Color' : settings.scalePrefix.trim();
    return switch (_mode) {
      GenerationMode.neutrals => 'Neutral ${g.label}',
      GenerationMode.extracted => t.imageColorName(index + 1),
      _ when g.isBase => prefix,
      _ => '$prefix ${g.label}',
    };
  }

  PaletteExportModel generatedExportModel() {
    final title = switch (_mode) {
      GenerationMode.scale => settings.scalePrefix,
      GenerationMode.harmony => PaletteGenerator.harmonyName(_harmony),
      GenerationMode.tintsShades => t.tintsExportTitle,
      GenerationMode.neutrals => 'Neutral',
      GenerationMode.custom => t.customExportTitle,
      GenerationMode.extracted => t.imageColorsExportTitle,
    };
    final g = generated;
    return PaletteExportModel(title, [for (var i = 0; i < g.length; i++) PaletteExportColor(generatedName(i), g[i].color)]);
  }

  void copyGeneratedAs(String formatId) {
    if (generated.isEmpty) return;
    final f = PaletteFormatters.get(formatId);
    copyText(f.format(generatedExportModel(), formatOptions), what: t.toastCopiedAs(f.displayName));
  }

  void addGeneratedToPalette(int index) => addToActive(generated[index].color, generatedName(index));

  void addAllGenerated() {
    final g = generated;
    if (g.isEmpty) return;
    final p = palettes.ensureActive();
    final added = palettes.addColors(p.id, [for (var i = 0; i < g.length; i++) (color: g[i].color, name: generatedName(i))]);
    if (added == 0) return _toast(Toast(t.toastMaxColors));
    _toast(Toast(t.toastAddedCount(added, p.name)));
  }

  // ---------- Paletas guardadas ----------

  Palette? get activePalette => palettes.active;

  void addToActive(Argb color, [String? name]) {
    final p = palettes.ensureActive();
    final added = palettes.addColor(p.id, color, name);
    if (added == null) return _toast(Toast(t.toastMaxColors));
    HapticFeedback.selectionClick();
    _toast(Toast(t.toastAddedTo(p.name), duration: const Duration(seconds: 2)));
  }

  void setActivePalette(String id) => palettes.setActive(id);

  Palette createPalette() => palettes.create();

  void duplicatePalette(String id) => palettes.duplicate(id);

  void deletePalette(String id) {
    final removed = palettes.delete(id);
    if (removed == null) return;
    _toast(Toast(t.toastPaletteDeleted(removed.palette.name),
        actionLabel: t.undo,
        onAction: () => palettes.restore(removed.palette, removed.index),
        duration: const Duration(seconds: 6)));
  }

  void renamePalette(String id, String name) => palettes.rename(id, name);
  void setPaletteDescription(String id, String? d) => palettes.setDescription(id, d);

  void removePaletteColor(String paletteId, String colorId) {
    final p = palettes.find(paletteId);
    if (p == null) return;
    final index = p.colors.indexWhere((c) => c.id == colorId);
    if (index < 0) return;
    final color = p.colors[index];
    palettes.removeColor(paletteId, colorId);
    _toast(Toast(t.toastColorDeleted,
        actionLabel: t.undo,
        onAction: () => palettes.insertColor(paletteId, color, index),
        duration: const Duration(seconds: 5)));
  }

  void renamePaletteColor(String paletteId, String colorId, String? name) =>
      palettes.renameColor(paletteId, colorId, name);

  void replacePaletteColor(String paletteId, String colorId) =>
      palettes.replaceColor(paletteId, colorId, currentArgb);

  void movePaletteColor(String paletteId, String colorId, int newIndex) =>
      palettes.moveColor(paletteId, colorId, newIndex);

  void usePaletteColor(Argb c) => session.commitArgb(c, ColorChangeSource.palette);

  /// "Cargar en la rueda": primer color = principal, resto = secundarios con su color exacto.
  void reloadInWheel(String paletteId, {bool confirmed = false}) {
    final p = palettes.find(paletteId);
    if (p == null || p.colors.isEmpty) return;
    if (!confirmed) {
      _toast(Toast(t.toastReloadWarning,
          actionLabel: t.reloadInWheel,
          onAction: () => reloadInWheel(paletteId, confirmed: true),
          duration: const Duration(seconds: 6)));
      return;
    }
    final colors = [for (final c in p.colors) c.color];
    session.commitArgb(colors.first, ColorChangeSource.palette);
    final st = session.current;
    freePoints.replaceAll([
      for (final c in colors.skip(1).take(FreePointSet.maxPoints)) FreePointSet.offsetForColor(st, c),
    ]);
    _switchToCustom();
    _selectedMarker = -1;
    _genVersion++;
    showImage = false;
    tab = Tabs.create;
    notifyListeners();
  }

  /// Contenido `.mpalette` de una paleta.
  Uint8List exportPaletteFile(Palette p) => Uint8List.fromList(utf8.encode(PaletteFile.from(p).encode()));

  String paletteFileName(Palette p) {
    final safe = p.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return '${safe.isEmpty ? 'palette' : safe}.mpalette';
  }

  void notifyExported(Palette p) => _toast(Toast(t.toastExported(p.name)));

  /// Importa un `.mpalette` (siempre como paleta nueva). Devuelve false si no es válido.
  bool importPaletteText(String text, {bool quiet = false}) {
    try {
      final file = PaletteFile.decode(text);
      final p = palettes.import(file);
      tab = Tabs.palettes;
      notifyListeners();
      _toast(Toast(t.toastImported(p.name)));
      return true;
    } on PaletteFileException catch (e) {
      if (!quiet) _toast(Toast(e.unsupportedVersion ? t.toastImportFuture : t.toastImportFailed));
      return false;
    }
  }

  void copyPaletteAs(Palette p, String formatId) {
    final f = PaletteFormatters.get(formatId);
    copyText(f.format(PaletteExportModel.from(p), formatOptions), what: t.toastCopiedAs(f.displayName));
  }

  String paletteAsText(Palette p, String formatId) =>
      PaletteFormatters.get(formatId).format(PaletteExportModel.from(p), formatOptions);

  // ---------- Imagen ----------

  ImageDoc? image;
  bool loadingImage = false;

  /// Carga una imagen y la muestra en Crear → Imagen; extrae colores en segundo plano.
  Future<bool> loadImageBytes(Uint8List bytes) async {
    loadingImage = true;
    notifyListeners();
    final doc = await ImageDoc.decode(bytes);
    loadingImage = false;
    if (doc == null) {
      notifyListeners();
      _toast(Toast(t.imageNotSupported));
      return false;
    }
    image?.dispose();
    image = doc;
    showImage = true;
    tab = Tabs.create;
    notifyListeners();
    await extract();
    return true;
  }

  void setExtractCount(int n) {
    settings.extractCount = n.clamp(1, DominantColors.maxCount);
    _saveSettings();
    notifyListeners();
  }

  Future<void> extract() async {
    final doc = image;
    if (doc == null) return;
    doc.extracting = true;
    notifyListeners();
    final count = settings.extractCount;
    final rgba = doc.rgba;
    final w = doc.width, h = doc.height;
    final result = await Isolate.run(() =>
        [for (final c in DominantColors.extract(rgba, w, h, w * 4, count, layout: PixelLayout.rgba)) c.toUInt32()]);
    if (!identical(doc, image)) return;
    doc.extracting = false;
    doc.extracted = [for (final v in result) Argb.fromUInt32(v)];
    _mode = GenerationMode.extracted;
    _selectedMarker = -1;
    _genVersion++;
    notifyListeners();
    _toast(Toast(t.toastExtracted(doc.extracted.length), duration: const Duration(seconds: 2)));
  }

  void closeImage() {
    image?.dispose();
    image = null;
    showImage = false;
    if (_mode == GenerationMode.extracted) _mode = settings.generationMode;
    _genVersion++;
    notifyListeners();
  }

  void pickFromImage(int x, int y) {
    final doc = image;
    if (doc == null) return;
    commitArgb(doc.pixelAt(x, y), ColorChangeSource.image);
  }

  void addSecondaryFromImage(int x, int y) {
    final doc = image;
    if (doc == null) return;
    addPointFromColor(doc.pixelAt(x, y));
  }

  /// Contenido recibido por Compartir / Abrir con / burbuja.
  Future<void> handleIncoming(IncomingContent content, Uint8List bytes) async {
    if (content.count > 1) _toast(Toast(t.toastFirstImageUsed));
    if (content.looksLikeImage) {
      if (await loadImageBytes(bytes)) return;
    }
    String? text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = null;
    }
    if (text != null && importPaletteText(text, quiet: true)) return;
    if (!content.looksLikeImage && await loadImageBytes(bytes)) return;
    _toast(Toast(t.toastImportFailed));
  }

  // ---------- Ajustes ----------

  void setTheme(ThemePreference v) {
    settings.theme = v;
    _saveSettings();
    notifyListeners();
  }

  void setLanguage(AppLanguage v) {
    settings.language = v;
    _saveSettings();
    platform.setAppLocale(switch (v) {
      AppLanguage.spanish => 'es',
      AppLanguage.english => 'en',
      AppLanguage.system => null,
    });
    notifyListeners();
  }

  void setDefaultFormat(String id) {
    settings.defaultFormatId = id;
    _saveSettings();
    notifyListeners();
  }

  void setHexUppercase(bool v) {
    settings.hexUppercase = v;
    _saveSettings();
    notifyListeners();
  }

  void setHexHash(bool v) {
    settings.hexHash = v;
    _saveSettings();
    notifyListeners();
  }

  void setCopyOnPick(bool v) {
    settings.copyOnPick = v;
    _saveSettings();
    notifyListeners();
  }

  void setFocus(double v) {
    settings.wheelFocus = clampD(v, -1, 1);
    _saveSettings();
    notifyListeners();
  }

  void setAnchor(ScaleAnchorMode m) {
    settings.scaleAnchor = m;
    _genVersion++;
    _saveSettings();
    notifyListeners();
  }

  void markCameraIntroShown() {
    settings.cameraIntroShown = true;
    _saveSettings();
  }

  void setBubbleEnabled(bool v) {
    settings.bubbleEnabled = v;
    _saveSettings();
    notifyListeners();
  }

  void showToast(String message) => _toast(Toast(message));

  @override
  void dispose() {
    flush();
    _toasts.close();
    image?.dispose();
    super.dispose();
  }
}
