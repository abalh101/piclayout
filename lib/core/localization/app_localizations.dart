import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('de'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  bool get isGerman => locale.languageCode == 'de';

  String get appName => 'PicLayout';
  String get newCollage => isGerman ? 'Neue Collage' : 'New collage';
  String get recentProjects =>
      isGerman ? 'Zuletzt bearbeitet' : 'Recent projects';
  String get emptyProjectsTitle =>
      isGerman ? 'Noch keine Collagen' : 'No collages yet';
  String get emptyProjectsBody => isGerman
      ? 'Wähle Fotos aus und erstelle deine erste Collage.'
      : 'Pick photos and create your first collage.';
  String get settings => isGerman ? 'Einstellungen' : 'Settings';
  String get localPrivacyNote => isGerman
      ? 'Die Bearbeitung läuft lokal auf deinem Gerät. Es gibt keine Anmeldung, keine Analyse-SDKs und keine Bild-Uploads.'
      : 'Editing happens locally on your device. There are no accounts, analytics SDKs, or image uploads.';
  String get selectedPhotos =>
      isGerman ? 'Ausgewählte Fotos' : 'Selected photos';
  String get createCollage => isGerman ? 'Collage erstellen' : 'Create collage';
  String get remove => isGerman ? 'Entfernen' : 'Remove';
  String get cancel => isGerman ? 'Abbrechen' : 'Cancel';
  String get rename => isGerman ? 'Umbenennen' : 'Rename';
  String get duplicate => isGerman ? 'Duplizieren' : 'Duplicate';
  String get delete => isGerman ? 'Löschen' : 'Delete';
  String get export => isGerman ? 'Exportieren' : 'Export';
  String get share => isGerman ? 'Teilen' : 'Share';
  String get layout => isGerman ? 'Layout' : 'Layout';
  String get favorites => isGerman ? 'Favoriten' : 'Favorites';
  String get addFavorite =>
      isGerman ? 'Zu Favoriten hinzufügen' : 'Add to favorites';
  String get removeFavorite =>
      isGerman ? 'Aus Favoriten entfernen' : 'Remove from favorites';
  String get otherLayouts => isGerman ? 'Weitere Layouts' : 'Other layouts';
  String get variation => isGerman ? 'Variation' : 'Variation';
  String get saveAsTemplate =>
      isGerman ? 'Als Vorlage speichern' : 'Save as template';
  String get saveTemplate => isGerman ? 'Vorlage speichern' : 'Save template';
  String get myTemplates => isGerman ? 'Meine Vorlagen' : 'My templates';
  String get templateName => isGerman ? 'Vorlagenname' : 'Template name';
  String get includeTemplateText => isGerman
      ? 'Text-Overlays in die Vorlage übernehmen'
      : 'Include text overlays in template';
  String get noTemplates => isGerman
      ? 'Noch keine eigenen Vorlagen gespeichert.'
      : 'No custom templates saved yet.';
  String get applyTemplate => isGerman ? 'Anwenden' : 'Apply';
  String get templateSaved =>
      isGerman ? 'Vorlage gespeichert' : 'Template saved';
  String get layoutAdjusted => isGerman
      ? 'Für diese Bildanzahl wurde ein passendes Layout gewählt.'
      : 'A compatible layout was chosen for this photo count.';
  String get format => isGerman ? 'Format' : 'Format';
  String get style => isGerman ? 'Stil' : 'Style';
  String get photo => isGerman ? 'Foto' : 'Photo';
  String get textOverlay => isGerman ? 'Text' : 'Text';
  String get addText => isGerman ? 'Text hinzufügen' : 'Add text';
  String get textContent => isGerman ? 'Textinhalt' : 'Text content';
  String get fontSize => isGerman ? 'Schriftgröße' : 'Font size';
  String get textColor => isGerman ? 'Textfarbe' : 'Text color';
  String get textBackground => isGerman ? 'Texthintergrund' : 'Text background';
  String get textAlignment => isGerman ? 'Ausrichtung' : 'Alignment';
  String get none => isGerman ? 'Keiner' : 'None';
  String get left => isGerman ? 'Links' : 'Left';
  String get center => isGerman ? 'Mitte' : 'Center';
  String get right => isGerman ? 'Rechts' : 'Right';
  String get white => isGerman ? 'Weiß' : 'White';
  String get black => isGerman ? 'Schwarz' : 'Black';
  String get blue => isGerman ? 'Blau' : 'Blue';
  String get red => isGerman ? 'Rot' : 'Red';
  String get yellow => isGerman ? 'Gelb' : 'Yellow';
  String get selectTextHint => isGerman
      ? 'Tippe auf einen Text in der Collage oder füge einen neuen hinzu.'
      : 'Tap text on the collage or add a new one.';
  String get spacing => isGerman ? 'Abstand' : 'Spacing';
  String get outerMargin => isGerman ? 'Außenrand' : 'Outer margin';
  String get cornerRadius => isGerman ? 'Eckenradius' : 'Corner radius';
  String get stagger => isGerman ? 'Versatz' : 'Stagger';
  String get background => isGerman ? 'Hintergrund' : 'Background';
  String get fill => isGerman ? 'Ausfüllen' : 'Fill';
  String get fit => isGerman ? 'Einpassen' : 'Fit';
  String get resetCrop => isGerman ? 'Ausschnitt zurücksetzen' : 'Reset crop';
  String get rotate => isGerman ? 'Drehen' : 'Rotate';
  String get flip => isGerman ? 'Spiegeln' : 'Flip';
  String get replace => isGerman ? 'Ersetzen' : 'Replace';
  String get saveProject => isGerman ? 'Projekt speichern' : 'Save project';
  String get exportPng => isGerman ? 'PNG exportieren' : 'Export PNG';
  String get exportJpeg => isGerman ? 'JPEG exportieren' : 'Export JPEG';
  String get noPhotoSelected =>
      isGerman ? 'Kein Foto ausgewählt' : 'No photo selected';
  String get exportSize => isGerman ? 'Exportgröße' : 'Export size';
  String get projectName => isGerman ? 'Projektname' : 'Project name';
  String get done => isGerman ? 'Fertig' : 'Done';
  String get permissionOrPickerCancelled => isGerman
      ? 'Auswahl abgebrochen oder keine Fotos gewählt.'
      : 'Selection cancelled or no photos selected.';
  String get unsupportedExportWarning => isGerman
      ? 'Hinweis: Eine höhere Auflösung erzeugt keine zusätzlichen Details, wenn die Quelldateien klein sind.'
      : 'Note: A higher resolution cannot add detail if the source files are small.';
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
