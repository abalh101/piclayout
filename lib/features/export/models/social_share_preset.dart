import '../export_settings.dart';

enum SocialShareDestination {
  gallery('Galerie speichern', null),
  general('Allgemein teilen', null),
  instagramStory('Instagram Story', 'instagram'),
  instagramPost('Instagram Post', 'instagram'),
  snapchat('Snapchat', 'snapchat'),
  tiktok('TikTok / Reels', 'tiktok'),
  whatsapp('WhatsApp Status', 'whatsapp'),
  facebook('Facebook', 'facebook'),
  other('Andere App', null);

  const SocialShareDestination(this.label, this.app);
  final String label;
  final String? app;
}

class SocialSharePreset {
  const SocialSharePreset(this.id, this.label, this.width, this.height);
  final String id;
  final String label;
  final int width;
  final int height;
  double get aspectRatio => width / height;
  bool differsStrongly(double ratio) => (ratio / aspectRatio - 1).abs() > 0.2;
  ExportSettings settings(ExportFormat format) =>
      ExportSettings(width: width, height: height, format: format);

  static const story = SocialSharePreset('story', 'Story · 9:16', 1080, 1920);
  static const square =
      SocialSharePreset('square', 'Quadrat · 1:1', 1080, 1080);
  static const portrait =
      SocialSharePreset('portrait', 'Hochformat · 4:5', 1080, 1350);
  static const youtube =
      SocialSharePreset('youtube', 'YouTube Thumbnail · 16:9', 1280, 720);

  static List<SocialSharePreset> forDestination(
          SocialShareDestination destination) =>
      switch (destination) {
        SocialShareDestination.instagramStory ||
        SocialShareDestination.snapchat ||
        SocialShareDestination.tiktok ||
        SocialShareDestination.whatsapp =>
          const [story],
        SocialShareDestination.instagramPost ||
        SocialShareDestination.facebook =>
          const [square, portrait],
        _ => const [story, square, portrait, youtube],
      };
}
