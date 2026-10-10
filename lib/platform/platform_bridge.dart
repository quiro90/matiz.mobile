import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Contenido recibido desde el sistema: "Compartir", "Abrir con" o una captura de la burbuja.
class IncomingContent {
  /// Ruta local (copia en la caché de la app) del contenido recibido.
  final String path;
  final String? mime;
  final String? name;

  /// share | view | capture
  final String kind;

  /// Cantidad de elementos compartidos (se usa el primero).
  final int count;

  const IncomingContent({required this.path, this.mime, this.name, required this.kind, this.count = 1});

  static IncomingContent? fromMap(Object? m) {
    if (m is! Map) return null;
    final path = m['path'];
    if (path is! String) return null;
    return IncomingContent(
      path: path,
      mime: m['mime'] as String?,
      name: m['name'] as String?,
      kind: (m['kind'] as String?) ?? 'share',
      count: (m['count'] as int?) ?? 1,
    );
  }

  bool get looksLikeImage =>
      kind == 'capture' || (mime?.startsWith('image/') ?? false) || RegExp(r'\.(png|jpe?g|webp|gif|bmp|heic|heif)$', caseSensitive: false).hasMatch(name ?? path);
}

/// Servicios de plataforma propios (canal `matiz/platform`). En plataformas sin implementación
/// devuelve valores neutros y las funciones dependientes se ocultan.
class PlatformBridge {
  static const _channel = MethodChannel('matiz/platform');
  static const _events = EventChannel('matiz/incoming');

  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// La burbuja flotante solo existe en Android.
  bool get bubbleSupported => isAndroid;

  Future<IncomingContent?> initialContent() async {
    if (!isAndroid) return null;
    try {
      return IncomingContent.fromMap(await _channel.invokeMethod('getInitialContent'));
    } on PlatformException {
      return null;
    }
  }

  Stream<IncomingContent> get incoming => isAndroid
      ? _events.receiveBroadcastStream().map(IncomingContent.fromMap).where((e) => e != null).cast<IncomingContent>()
      : const Stream.empty();

  /// Bytes de una imagen en el portapapeles (null si no hay).
  Future<Uint8List?> clipboardImage() async {
    if (!isAndroid) return null;
    try {
      return await _channel.invokeMethod<Uint8List>('getClipboardImage');
    } on PlatformException {
      return null;
    }
  }

  /// Guarda un PNG en la galería (álbum Pictures/Matiz) sin permisos (API 29+).
  Future<bool> saveImageToGallery(Uint8List png, String fileName) async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('saveToGallery', {'bytes': png, 'name': fileName}) ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Sincroniza el idioma por app del sistema (Android 13+). null = idioma del sistema.
  Future<void> setAppLocale(String? languageTag) async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('setAppLocale', {'tag': languageTag ?? ''});
    } on PlatformException {
      // No crítico.
    }
  }

  Future<void> openAppSettings() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('openAppSettings');
    } on PlatformException {
      // No crítico.
    }
  }

  // ---------- Burbuja ----------

  Future<bool> canDrawOverlays() async =>
      isAndroid && (await _channel.invokeMethod<bool>('canDrawOverlays') ?? false);

  /// Abre la pantalla del sistema para conceder "Mostrar sobre otras apps". Devuelve el estado al volver.
  Future<bool> requestOverlayPermission() async =>
      isAndroid && (await _channel.invokeMethod<bool>('requestOverlayPermission') ?? false);

  Future<bool> requestNotificationPermission() async =>
      isAndroid && (await _channel.invokeMethod<bool>('requestNotificationPermission') ?? false);

  Future<bool> startBubble() async => isAndroid && (await _channel.invokeMethod<bool>('startBubble') ?? false);

  Future<void> stopBubble() async {
    if (isAndroid) await _channel.invokeMethod('stopBubble');
  }

  Future<bool> isBubbleRunning() async =>
      isAndroid && (await _channel.invokeMethod<bool>('isBubbleRunning') ?? false);
}
