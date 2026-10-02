import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/app_config.dart';

typedef MailLauncher = Future<bool> Function(Uri uri);

class AppMetadata {
  const AppMetadata(
      {required this.version, required this.platform, required this.device});
  final String version, platform, device;
  static Future<AppMetadata> load() async {
    final info = await PackageInfo.fromPlatform();
    return AppMetadata(
        version: '${info.version}+${info.buildNumber}',
        platform: Platform.operatingSystem,
        // Intentionally no model, identifier, hostname or paths.
        device: Platform.isAndroid
            ? 'Android device'
            : Platform.isIOS
                ? 'iOS device'
                : 'Desktop device');
  }
}

class ProblemReportService {
  ProblemReportService({MailLauncher? launch}) : _launch = launch ?? _open;
  final MailLauncher _launch;
  static Future<bool> _open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
  Uri mailto(AppMetadata metadata, {required String prompt}) {
    final fields = {
      'subject': '${AppConfig.appName} – Problem',
      'body':
          '$prompt\n\n${AppConfig.appName}\nVersion: ${metadata.version}\nPlatform: ${metadata.platform}\nDevice: ${metadata.device}',
    };
    return Uri(
        scheme: 'mailto',
        path: AppConfig.supportEmail,
        query: fields.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&'));
  }

  Future<bool> open(AppMetadata metadata, {required String prompt}) async {
    try {
      return await _launch(mailto(metadata, prompt: prompt));
    } catch (_) {
      return false;
    }
  }
}
