class AppConfig {
  const AppConfig._();

  // Set with --dart-define=SUPPORT_EMAIL=... for production builds.
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');

  static const appName = 'PicLayout';
  static const projectFormatVersion = 1;
  static const maxPhotos = 12;
}
