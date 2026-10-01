import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../../projects/models/collage_project.dart';
import '../collage_exporter.dart';
import '../export_settings.dart';
import '../models/social_share_preset.dart';
import 'gallery_save_service.dart';
import 'social_share_service.dart';

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
  bool busy = false;

  Future<String?> run(
      {required CollageProject project,
      required ExportSettings settings,
      required SocialShareDestination destination,
      required Rect origin,
      void Function(String message)? onNotice}) async {
    if (busy) return null;
    busy = true;
    notifyListeners();
    try {
      final file = await _render(project, settings);
      if (destination == SocialShareDestination.gallery) {
        await _gallery.save(file);
        return 'In Galerie gespeichert';
      }
      return await _share.share(file, destination, origin, onNotice: onNotice);
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
