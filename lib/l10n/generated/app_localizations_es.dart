// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Matiz';

  @override
  String get tabCreate => 'Crear';

  @override
  String get tabGenerate => 'Generar';

  @override
  String get tabPalettes => 'Paletas';

  @override
  String get undo => 'Deshacer';

  @override
  String get redo => 'Rehacer';

  @override
  String get toggleTheme => 'Cambiar tema claro/oscuro';

  @override
  String get settings => 'Ajustes';

  @override
  String get close => 'Cerrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get ok => 'Aceptar';

  @override
  String get copy => 'Copiar';

  @override
  String get paste => 'Pegar';

  @override
  String get share => 'Compartir';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get rename => 'Renombrar';

  @override
  String get remove => 'Quitar';

  @override
  String get view => 'Ver';

  @override
  String get more => 'Más';

  @override
  String get sourceWheel => 'Rueda';

  @override
  String get sourceImage => 'Imagen';

  @override
  String get openImage => 'Abrir imagen';

  @override
  String get pasteAction => 'Pegar color o imagen';

  @override
  String get camera => 'Cámara';

  @override
  String get closeImage => 'Cerrar imagen';

  @override
  String get previous => 'Anterior';

  @override
  String get current => 'Actual';

  @override
  String copyColorA11y(String hex) {
    return 'Copiar color $hex';
  }

  @override
  String get addToPalette => 'Añadir a paleta';

  @override
  String get recents => 'Recientes';

  @override
  String get clearRecents => 'Vaciar recientes';

  @override
  String get clearRecentsConfirm => '¿Quitar todos los colores recientes?';

  @override
  String get noRecents => 'Los colores que copies o tomes aparecen aquí.';

  @override
  String get detailTitle => 'Color';

  @override
  String get colorInputHint => 'HEX, rgb(), hsl()…';

  @override
  String get invalidColor => 'Color inválido';

  @override
  String get grayEquivalent => 'Gris equivalente';

  @override
  String get focus => 'Enfoque';

  @override
  String get focusVivid => 'Vivo';

  @override
  String get focusPastel => 'Pastel';

  @override
  String get resetFocus => 'Restablecer enfoque';

  @override
  String get moreFormats => 'Más formatos';

  @override
  String get copyAll => 'Copiar todo';

  @override
  String get copyAs => 'Copiar como';

  @override
  String get shareAs => 'Compartir como';

  @override
  String get exportOverlay => 'Exportar superpuestos';

  @override
  String get cmykApprox => 'Aproximado, sin perfil ICC';

  @override
  String get alpha => 'Alfa';

  @override
  String get modeScale => 'Escala';

  @override
  String get modeTintsShades => 'Tints / Shades';

  @override
  String get modeNeutrals => 'Neutros';

  @override
  String get modeHarmony => 'Armonías';

  @override
  String get modeCustom => 'Personalizado';

  @override
  String get modeExtracted => 'De la imagen';

  @override
  String get harmonyComplementary => 'Complementaria';

  @override
  String get harmonyAnalogous => 'Análoga';

  @override
  String get harmonySplit => 'Complementaria dividida';

  @override
  String get harmonyTriadic => 'Triádica';

  @override
  String get harmonyTetradic => 'Tetrádica';

  @override
  String get harmonyMonochromatic => 'Monocromática';

  @override
  String get balanceLightness => 'Luminosidad equilibrada';

  @override
  String get addPoint => 'Añadir punto';

  @override
  String get clearPoints => 'Borrar';

  @override
  String get clearPointsConfirm =>
      '¿Quitar todos los puntos secundarios? Se conserva el color principal.';

  @override
  String get customize => 'Personalizar';

  @override
  String get prefix => 'Prefijo';

  @override
  String get addAll => 'Añadir todo';

  @override
  String get useAsMain => 'Usar como principal';

  @override
  String get copyHex => 'Copiar HEX';

  @override
  String get copyRgb => 'Copiar RGB';

  @override
  String get base => 'Base';

  @override
  String get extractCount => 'Cantidad de colores';

  @override
  String get extractAgain => 'Extraer de nuevo';

  @override
  String get customHint =>
      'Mantené pulsada la rueda o la imagen para añadir colores.';

  @override
  String get activePalette => 'Paleta activa';

  @override
  String get library => 'Biblioteca';

  @override
  String get newPalette => 'Nueva';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get reloadInWheel => 'Cargar en la rueda';

  @override
  String get exportFile => 'Exportar .mpalette';

  @override
  String get importFile => 'Importar';

  @override
  String get exportImage => 'Exportar imagen';

  @override
  String get export => 'Exportar';

  @override
  String get exportCode => 'Código';

  @override
  String get exportPaletteImage => 'Paleta';

  @override
  String get exportOverlayImage => 'Superpuestos';

  @override
  String get saveTo => 'Guardar en…';

  @override
  String get saveToGallery => 'Guardar en galería';

  @override
  String get paletteName => 'Nombre';

  @override
  String get paletteDescription => 'Descripción';

  @override
  String get descriptionHint => 'Opcional';

  @override
  String colorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count colores',
      one: '1 color',
      zero: 'sin colores',
    );
    return '$_temp0';
  }

  @override
  String get emptyLibrary =>
      'Todavía no tenés paletas. Creá una o importá un archivo .mpalette.';

  @override
  String get emptyPalette =>
      'Paleta vacía: añadí colores con + desde Crear o Generar.';

  @override
  String get replaceWithCurrent => 'Reemplazar con el actual';

  @override
  String get moveFirst => 'Mover al inicio';

  @override
  String get moveLast => 'Mover al final';

  @override
  String get renameColor => 'Nombre del color';

  @override
  String get reorderHint => 'Mantené pulsado y arrastrá para reordenar';

  @override
  String get activeBadge => 'Activa';

  @override
  String get imageNotSupported => 'El archivo no es una imagen compatible.';

  @override
  String get loupeHint => 'Arrastrá: elegir · Mantené: añadir · Pellizcá: zoom';

  @override
  String get cameraHint =>
      'El color depende de la luz y del balance de blancos.';

  @override
  String get cameraUse => 'Usar';

  @override
  String get cameraAddSecondary => '+ Secundario';

  @override
  String get cameraFreeze => 'Congelar';

  @override
  String get cameraPermissionTitle => 'Acceso a la cámara';

  @override
  String get cameraPermissionBody =>
      'Matiz usa la cámara solo para leer el color bajo la retícula. No se graba ni se envía nada.';

  @override
  String get cameraDenied => 'Permiso de cámara denegado.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get cameraUnavailable => 'No hay cámara disponible.';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsCopy => 'Copiar';

  @override
  String get settingsDefaultFormat => 'Formato principal';

  @override
  String get settingsHexUppercase => 'HEX en mayúsculas';

  @override
  String get settingsHexHash => 'Incluir #';

  @override
  String get settingsCopyOnPick => 'Copiar al tomar color';

  @override
  String get settingsCopyOnPickHint => 'Imagen, cámara y burbuja';

  @override
  String get settingsScale => 'Design Scale';

  @override
  String get settingsScaleAnchor => 'Ancla';

  @override
  String get anchorFixed500 => 'Base en 500';

  @override
  String get anchorAuto => 'Automático';

  @override
  String get settingsBubble => 'Burbuja flotante';

  @override
  String get settingsBubbleHint => 'Tomar colores de otras apps';

  @override
  String get bubbleHowTitle => '¿Cómo funciona?';

  @override
  String get bubbleHowBody =>
      'La burbuja flota sobre otras apps. Tocala para tomar una única captura de pantalla (Android te pide consentimiento) y abrirla en Matiz para elegir colores con la lupa.\n\n• Android puede pedir consentimiento en cada captura.\n• El contenido protegido (video con DRM, apps bancarias) puede verse negro.\n• En pantallas HDR o con modos de color del fabricante el valor capturado puede no coincidir con el original.';

  @override
  String get bubblePermissionOverlay =>
      'La burbuja necesita el permiso \"Mostrar sobre otras apps\".';

  @override
  String get bubblePermissionNotifications =>
      'La burbuja necesita notificaciones para seguir activa.';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get support => 'Considerá donar si Matiz te es útil:';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get licenses => 'Licencias de código abierto';

  @override
  String toastCopied(String value) {
    return 'Copiado $value';
  }

  @override
  String toastCopiedAs(String format) {
    return 'Copiado como $format';
  }

  @override
  String get toastCopyFailed => 'No se pudo copiar';

  @override
  String toastAddedTo(String palette) {
    return 'Añadido a $palette';
  }

  @override
  String toastAddedCount(int count, String palette) {
    return '$count colores añadidos a $palette';
  }

  @override
  String get toastMaxColors => 'Máximo 64 colores por paleta';

  @override
  String toastAddedCustom(int count) {
    return 'Añadido a Personalizado ($count)';
  }

  @override
  String get toastCustomizeReplace =>
      'Esta acción reemplazará todos los colores cargados en Personalizado.';

  @override
  String toastCustomizeApplied(int count) {
    return 'Se cargaron $count colores extraídos en Personalizado';
  }

  @override
  String toastExtracted(int count) {
    return '$count colores extraídos';
  }

  @override
  String get toastReloadWarning =>
      'Se cargará la paleta en la rueda cromática y se perderán las selecciones actuales.';

  @override
  String toastPaletteDeleted(String name) {
    return 'Paleta \"$name\" eliminada';
  }

  @override
  String get toastColorDeleted => 'Color eliminado';

  @override
  String toastImported(String name) {
    return 'Paleta \"$name\" importada';
  }

  @override
  String get toastImportFailed =>
      'El archivo no es una paleta de Matiz válida.';

  @override
  String get toastImportFuture =>
      'Esta paleta se creó con una versión más nueva de Matiz.';

  @override
  String toastExported(String name) {
    return 'Paleta \"$name\" exportada';
  }

  @override
  String get toastSavedImage => 'Imagen guardada';

  @override
  String get toastSaveFailed => 'No se pudo guardar';

  @override
  String get toastClipboardEmpty =>
      'El portapapeles no tiene un color ni una imagen.';

  @override
  String get toastFirstImageUsed => 'Se usó la primera imagen';

  @override
  String get toastCorruptData =>
      'Un archivo de datos estaba dañado y se reinició (se guardó una copia).';

  @override
  String get toastNothingToExport => 'La paleta no tiene colores.';

  @override
  String get exportTitle => 'Exportar imagen';

  @override
  String get exportOrientation => 'Orientación';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get vertical => 'Vertical';

  @override
  String get exportSize => 'Tamaño';

  @override
  String get exportBackground => 'Fondo';

  @override
  String get bgLight => 'Claro';

  @override
  String get bgDark => 'Oscuro';

  @override
  String get bgTransparent => 'Transparente';

  @override
  String get exportValues => 'Valores';

  @override
  String get exportShape => 'Forma';

  @override
  String get shapeSquare => 'Cuadrado';

  @override
  String get shapeCircle => 'Círculo';

  @override
  String get shapeTriangle => 'Triángulo';

  @override
  String get exportOrder => 'Orden';

  @override
  String get orderFirstLast => 'Primero → último';

  @override
  String get orderLastFirst => 'Último → primero';

  @override
  String get previousCurrentTitle => 'Anterior / Actual';

  @override
  String get customExportTitle => 'Personalizado';

  @override
  String get tintsExportTitle => 'Tints y shades';

  @override
  String get imageColorsExportTitle => 'Colores de la imagen';

  @override
  String imageColorName(int index) {
    return 'Imagen $index';
  }
}
