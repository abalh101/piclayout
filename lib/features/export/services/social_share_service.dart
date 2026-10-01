import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/social_share_preset.dart';
import 'gallery_save_service.dart';

abstract interface class SocialSharePlatform {
  Future<bool?> isInstalled(String app);
  Future<bool> shareDirect(String app, String path);
  Future<void> shareSheet(String path, Rect origin);
}

class NativeSocialSharePlatform implements SocialSharePlatform {
  static const _channel = MethodChannel('piclayout/media');
  @override
  Future<bool?> isInstalled(String app) =>
      _channel.invokeMethod<bool>('isInstalled', {'app': app});
  @override
  Future<bool> shareDirect(String app, String path) async =>
      await _channel
          .invokeMethod<bool>('shareTo', {'app': app, 'path': path}) ??
      false;
  @override
  Future<void> shareSheet(String path, Rect origin) async {
    await Share.shareXFiles([XFile(path)], sharePositionOrigin: origin);
  }
}

class SocialShareService {
  SocialShareService({SocialSharePlatform? platform})
      : _platform = platform ?? NativeSocialSharePlatform();
  final SocialSharePlatform _platform;

  /// Returns a user-facing explanation when the native share sheet was used.
  Future<String?> share(
      File file, SocialShareDestination destination, Rect origin,
      {void Function(String message)? onNotice}) async {
    if (!await file.exists()) {
      throw const ExportFailure('Die exportierte Datei wurde nicht gefunden.');
    }
    String? notice;
    if (destination.app != null) {
      bool? installed;
      try {
        installed = await _platform.isInstalled(destination.app!);
        if (installed == true &&
            await _platform.shareDirect(destination.app!, file.path)) {
          return null;
        }
      } on PlatformException {
        // A missing activity or unavailable native target falls back to sharing.
      } on MissingPluginException {
        // Desktop/test hosts can still offer a system share sheet.
      }
      notice = installed == false
          ? '${destination.label}: Ziel-App nicht installiert. Wähle eine andere App im Teilen-Menü.'
          : 'Wähle die Ziel-App im Teilen-Menü. Den Upload bestätigst du dort selbst.';
      onNotice?.call(notice);
    }
    try {
      await _platform.shareSheet(file.path, origin);
    } catch (_) {
      throw const ExportFailure(
          'Das Teilen-Menü konnte nicht geöffnet werden. Du kannst das Bild in der Galerie speichern.');
    }
    return notice;
  }
}
