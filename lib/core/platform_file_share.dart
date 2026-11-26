import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareLocalFile(String path, Rect origin,
    {String? mimeType}) async {
  if (Platform.isIOS) {
    await const MethodChannel('piclayout/media').invokeMethod<void>(
      'shareFile',
      {
        'path': path,
        'x': origin.left,
        'y': origin.top,
        'width': origin.width,
        'height': origin.height,
      },
    );
    return;
  }
  await Share.shareXFiles([XFile(path, mimeType: mimeType)],
      sharePositionOrigin: origin);
}
