import 'dart:io';
import 'package:flutter/services.dart';

class ExportFailure implements Exception {
  const ExportFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract interface class GalleryPlatform {
  Future<void> save(String path);
}

class NativeGalleryPlatform implements GalleryPlatform {
  static const channel = MethodChannel('piclayout/media');
  @override
  Future<void> save(String path) =>
      channel.invokeMethod<void>('saveToGallery', {'path': path});
}

class GallerySaveService {
  GallerySaveService({GalleryPlatform? platform})
      : _platform = platform ?? NativeGalleryPlatform();
  final GalleryPlatform _platform;

  Future<void> save(File file) async {
    if (!await file.exists()) {
      throw const ExportFailure(
          'Die exportierte Datei wurde nicht gefunden. Bitte erneut exportieren.');
    }
    try {
      await _platform.save(file.path);
    } on PlatformException catch (error) {
      throw ExportFailure(switch (error.code) {
        'permission_denied' =>
          'Fotozugriff abgelehnt. Bitte erlaube das Speichern in den Systemeinstellungen.',
        'unavailable' => 'Die Galerie ist auf diesem Gerät nicht verfügbar.',
        'file_missing' => 'Die exportierte Datei wurde nicht gefunden.',
        _ =>
          'Speichern fehlgeschlagen. Bitte prüfe den freien Speicher und versuche es erneut.',
      });
    } on MissingPluginException {
      throw const ExportFailure(
          'Galerie speichern wird auf diesem Gerät nicht unterstützt.');
    }
  }
}
