import '../../collage_editor/models/aspect_ratio_preset.dart';
import '../../export/export_settings.dart';

enum ExportAction { gallery, share }

class AppSettings {
  const AppSettings(
      {this.languageCode,
      this.aspectRatioId = '9_16',
      this.exportFormat = ExportFormat.png,
      this.jpegQuality = 92,
      this.exportAction = ExportAction.gallery,
      this.recentRatios = const [],
      this.favoriteRatios = const []});
  static const languages = ['de', 'en', 'ar', 'tr', 'fr', 'es'];
  final String? languageCode;
  final String aspectRatioId;
  final ExportFormat exportFormat;
  final int jpegQuality;
  final ExportAction exportAction;
  final List<String> recentRatios;
  final List<String> favoriteRatios;
  AppSettings copyWith(
          {String? languageCode,
          bool useSystemLanguage = false,
          String? aspectRatioId,
          ExportFormat? exportFormat,
          int? jpegQuality,
          ExportAction? exportAction,
          List<String>? recentRatios,
          List<String>? favoriteRatios}) =>
      AppSettings(
          languageCode:
              useSystemLanguage ? null : languageCode ?? this.languageCode,
          aspectRatioId: aspectRatioId ?? this.aspectRatioId,
          exportFormat: exportFormat ?? this.exportFormat,
          jpegQuality: jpegQuality ?? this.jpegQuality,
          exportAction: exportAction ?? this.exportAction,
          recentRatios: recentRatios ?? this.recentRatios,
          favoriteRatios: favoriteRatios ?? this.favoriteRatios);
  Map<String, Object?> toJson() => {
        'languageCode': languageCode,
        'aspectRatioId': aspectRatioId,
        'exportFormat': exportFormat.name,
        'jpegQuality': jpegQuality,
        'exportAction': exportAction.name,
        'recentRatios': recentRatios,
        'favoriteRatios': favoriteRatios,
      };
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
      languageCode: languages.contains(json['languageCode'])
          ? json['languageCode'] as String
          : null,
      aspectRatioId: AspectRatios.byId(json['aspectRatioId'] is String
              ? json['aspectRatioId'] as String
              : '')
          .id,
      exportFormat:
          json['exportFormat'] == 'jpeg' ? ExportFormat.jpeg : ExportFormat.png,
      recentRatios: _ratios(json['recentRatios']),
      favoriteRatios: _ratios(json['favoriteRatios']),
      jpegQuality: json['jpegQuality'] is num
          ? (json['jpegQuality'] as num).toInt().clamp(1, 100)
          : 92,
      exportAction: json['exportAction'] == 'share'
          ? ExportAction.share
          : ExportAction.gallery);

  static List<String> _ratios(Object? items) => items is! List
      ? const []
      : items
          .whereType<String>()
          .map(AspectRatios.customById)
          .nonNulls
          .map((ratio) => ratio.id)
          .toSet()
          .take(8)
          .toList();
}
