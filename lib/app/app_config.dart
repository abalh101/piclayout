class AppConfig {
  const AppConfig._();

  // Set with --dart-define=SUPPORT_EMAIL=... for production builds.
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');

  static const _privacyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
  static const _privacyUrlDe = String.fromEnvironment('PRIVACY_POLICY_URL_DE');

  static Uri? privacyPolicyFor(String languageCode) {
    final url = languageCode == 'de' && _privacyUrlDe.isNotEmpty
        ? _privacyUrlDe
        : _privacyUrl;
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? uri
        : null;
  }

  static const appName = 'PicLayout';
  static const projectFormatVersion = 1;
  static const maxPhotos = 12;
  static const maxFreeformFrames = 20;
}
