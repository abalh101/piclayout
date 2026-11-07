import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../../projects/models/collage_project.dart';
import '../collage_exporter.dart';
import '../export_settings.dart';
import '../models/social_share_preset.dart';
import 'gallery_save_service.dart';
import 'social_share_service.dart';

enum ExportPhase { idle, rendering, saving, sharing }

typedef RenderExport = Future<File> Function(
    CollageProject project, ExportSettings settings);

class ExportFlowController extends ChangeNotifier {
  ExportFlowController(
      {RenderExport? render,
      GallerySaveService? gallery,
      SocialShareService? share})
      : _render = render ?? const CollageExporter().export,
        _gallery = gallery ?? GallerySaveService(),
        _share = share ?? SocialShareService();
  final RenderExport _render;
  final GallerySaveService _gallery;
  final SocialShareService _share;
  ExportPhase phase = ExportPhase.idle;
  bool get busy => phase != ExportPhase.idle;
  bool _disposed = false;

  void _setPhase(ExportPhase value) {
    phase = value;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<String?> run(
      {required CollageProject project,
      required ExportSettings settings,
      required SocialShareDestination destination,
      required Rect origin,
      void Function(String message)? onNotice}) async {
    if (busy || _disposed) return null;
    _setPhase(ExportPhase.rendering);
    try {
      final file = await _render(project, settings);
      if (destination == SocialShareDestination.gallery) {
        _setPhase(ExportPhase.saving);
        await _gallery.save(file);
        return 'In Galerie gespeichert';
      }
      _setPhase(ExportPhase.sharing);
      return await _share.share(file, destination, origin, onNotice: onNotice);
    } finally {
      _setPhase(ExportPhase.idle);
    }
  }
}
