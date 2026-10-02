import 'package:flutter/widgets.dart';
import 'translations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('de'),
    Locale('en'),
    Locale('ar'),
    Locale('tr'),
    Locale('fr'),
    Locale('es')
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('de'));
  }

  String tr(String key) {
    final values = translations[key];
    if (values == null) {
      for (final separator in [' · ', ': ']) {
        if (key.contains(separator)) {
          return key.split(separator).map(tr).join(separator);
        }
      }
      return key;
    }
    final index =
        ['de', 'en', 'ar', 'tr', 'fr', 'es'].indexOf(locale.languageCode);
    return values[index < 0 ? 1 : index];
  }

  bool get isGerman => locale.languageCode == 'de';

  String get appName => 'PicLayout';
  String get newCollage => tr('newCollage');
  String get recentProjects => tr('recentProjects');
  String get emptyProjectsTitle => tr('emptyProjectsTitle');
  String get emptyProjectsBody => tr('emptyProjectsBody');
  String get settings => tr('settings');
  String get localPrivacyNote => tr('localPrivacyNote');
  String get selectedPhotos => tr('selectedPhotos');
  String get createCollage => tr('createCollage');
  String get remove => tr('remove');
  String get cancel => tr('cancel');
  String get rename => tr('rename');
  String get duplicate => tr('duplicate');
  String get delete => tr('delete');
  String get export => tr('export');
  String get share => tr('share');
  String get layout => tr('layout');
  String get favorites => tr('favorites');
  String get addFavorite => tr('addFavorite');
  String get removeFavorite => tr('removeFavorite');
  String get otherLayouts => tr('otherLayouts');
  String get variation => tr('variation');
  String get saveAsTemplate => tr('saveAsTemplate');
  String get saveTemplate => tr('saveTemplate');
  String get myTemplates => tr('myTemplates');
  String get templateName => tr('templateName');
  String get includeTemplateText => tr('includeTemplateText');
  String get noTemplates => tr('noTemplates');
  String get applyTemplate => tr('applyTemplate');
  String get templateSaved => tr('templateSaved');
  String get layoutAdjusted => tr('layoutAdjusted');
  String get format => tr('format');
  String get style => tr('style');
  String get photo => tr('photo');
  String get textOverlay => tr('textOverlay');
  String get addText => tr('addText');
  String get textContent => tr('textContent');
  String get fontSize => tr('fontSize');
  String get textColor => tr('textColor');
  String get textBackground => tr('textBackground');
  String get textAlignment => tr('textAlignment');
  String get none => tr('none');
  String get left => tr('left');
  String get center => tr('center');
  String get right => tr('right');
  String get white => tr('white');
  String get black => tr('black');
  String get blue => tr('blue');
  String get red => tr('red');
  String get yellow => tr('yellow');
  String get selectTextHint => tr('selectTextHint');
  String get spacing => tr('spacing');
  String get outerMargin => tr('outerMargin');
  String get cornerRadius => tr('cornerRadius');
  String get stagger => tr('stagger');
  String get background => tr('background');
  String get fill => tr('fill');
  String get fit => tr('fit');
  String get resetCrop => tr('resetCrop');
  String get rotate => tr('rotate');
  String get flip => tr('flip');
  String get replace => tr('replace');
  String get saveProject => tr('saveProject');
  String get exportPng => tr('exportPng');
  String get exportJpeg => tr('exportJpeg');
  String get noPhotoSelected => tr('noPhotoSelected');
  String get exportSize => tr('exportSize');
  String get projectName => tr('projectName');
  String get done => tr('done');
  String get permissionOrPickerCancelled => tr('permissionOrPickerCancelled');
  String get unsupportedExportWarning => tr('unsupportedExportWarning');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((it) => it.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final languageCode = isSupported(locale) ? locale.languageCode : 'en';
    return AppLocalizations(Locale(languageCode));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
