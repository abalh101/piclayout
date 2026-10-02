# Einstellungen, Sprachen und Foto-Bearbeitung

## Bedienung

Einstellungen über das Zahnrad auf der Startseite öffnen. Sprache, Format neuer
Collagen, PNG/JPEG, JPEG-Qualität (1–100) und Exportaktion (Galerie/Teilen) werden
lokal in `settings.json` im Application-Support-Verzeichnis gespeichert. Standard:
Systemsprache, 9:16, PNG, JPEG-Qualität 92, Galerie. Exportvorgaben initialisieren
den Exportdialog und lassen sich dort für den aktuellen Export ändern. Neue
Formatvorgaben verändern bestehende Projekte nicht.

Weitere Einträge: Problem melden, Datenschutz, tatsächliche Paketversion mit
Buildnummer, temporäre Exportdateien bereinigen und Über PicLayout. Die Bereinigung
löscht ausschließlich `piclayout_exports` im temporären App-Verzeichnis. Projekte,
importierte Fotos, Einstellungen und bereits in der Galerie gespeicherte Bilder
bleiben erhalten. Sie löscht keine System- oder Fremd-App-Caches.

Deutsch, Englisch, Arabisch, Türkisch, Französisch und Spanisch sind verfügbar.
Unter Einstellungen → Sprache eine Sprache oder „Systemsprache verwenden“ wählen.
Die App aktualisiert sich sofort; Arabisch erhält Flutter-RTL. Die vorhandene
manuelle Lokalisierung wurde in einen zentralen Katalog mit sechs Übersetzungen
pro Eintrag überführt. Technische Formate, App-/Markennamen sowie die etablierten
Style-Preset-Namen bleiben unverändert. Nutzertexte und gespeicherte Projektnamen
werden nicht übersetzt. Nicht unterstützte Systemsprachen verwenden Flutters
Fallback auf die erste unterstützte Sprache (Deutsch).

Ein Foto in der Collage antippen → Bearbeiten. Alternativ Foto auswählen und die
Foto-Schaltfläche öffnen. Filter und Regler zeigen eine Live-Vorschau. „Fertig“
übernimmt alle Änderungen als einen Undo-Schritt und startet den bestehenden
Autosave. Abbrechen, Zurück und Wegwischen verwerfen den Entwurf. Dasselbe Foto
später erneut antippen, um die gespeicherten Werte weiterzubearbeiten.

Filter: Original, Warm, Cool, Black & White, High Contrast, Soft Fade, Vivid,
Vintage, Sepia, Matte (Namen werden lokalisiert). Regler: Filterintensität,
Helligkeit, Kontrast, Sättigung und Wärme. „Original“ entfernt den Preset-Effekt;
manuelle Regler bleiben erhalten. „Zurücksetzen“ neutralisiert alle Foto-Effekte.
Die optionale Vignette ist nicht implementiert.

Ausschnitt, Zoom, Drehen, Spiegeln, Ersetzen, Entfernen und Fit/Fill bleiben
verfügbar. Filteränderungen verändern keine Transformationsdaten. Beim Ersetzen
beginnt das neue Foto ohne Filter, der bisherige Ausschnitt bleibt erhalten;
Undo stellt das vorherige Foto einschließlich seiner Effekte wieder her.

## Support konfigurieren

**Vor Veröffentlichung `AppConfig.supportEmail` in `lib/app/app_config.dart`
von `support@example.com` auf die echte Support-Adresse ändern.**

Problem melden öffnet einen E-Mail-Entwurf über `url_launcher`. Nur Betreff und
Text werden übergeben: App-Name, Version/Build, Betriebssystem, generischer
Gerätehinweis und die lokalisierte Aufforderung zur Problembeschreibung. Keine
Fotos, Anhänge, Projektdateien, Bildpfade, Geräte-IDs oder Hostnamen. Der Nutzer
versendet selbst. Falls keine Mail-App verfügbar ist oder das Öffnen fehlschlägt,
zeigt ein Dialog eine verständliche Erklärung, eine auswählbare Adresse und einen
Kopieren-Button. Metadaten stammen aus `package_info_plus`; bei einem Fehler der
Plattformabfrage werden fehlende Angaben mit „—“ gekennzeichnet.

Es wird direkt `launchUrl` mit Fehlerbehandlung verwendet, nicht `canLaunchUrl`.
Daher sind keine zusätzlichen Query-Schemes nötig. Query-Werte verwenden
`Uri.encodeComponent`, damit Leerzeichen und Sonderzeichen in Mail-Clients
funktionieren. Siehe die [offizielle url_launcher-Dokumentation](https://pub.dev/packages/url_launcher).

## Speicherung, Rendering und Grenzen

`PhotoAsset.adjustments` enthält `PhotoAdjustments` als additive JSON-Daten.
Projekte ohne diesen Eintrag erhalten neutrale Werte. Unbekannte Presets fallen
auf Original zurück; eingelesene Zahlen werden begrenzt. Die bisherige
Projektformatversion bleibt kompatibel. Quellbilder werden niemals überschrieben.
Vorlagen enthalten bewusst keine fotospezifischen Filter oder Bildpfade; beim
Anwenden einer Vorlage behalten vorhandene Fotos ihre Filter.

`PhotoFilterRenderer` berechnet eine gemeinsame RGB-Farbmatrix aus Preset,
Intensität und Reglern. Vorschau und dateibasierter Export verwenden sie in
`StyleRenderer.photo`. Es wird kein Bildschirmfoto exportiert. Rahmen, Schatten,
Hintergrund und Text werden wie bisher separat gezeichnet; Auswahlmarkierungen
gehören nicht zum Export. Der Foto-Blur-Hintergrund verwendet weiterhin das
Originalfoto mit seinen eigenen Style-Reglern, nicht den Foto-Filter.

Der Matrix-Cache ist auf 128 Einträge begrenzt. Vorschau-Bilder werden bis 1024 px
Kantenlänge einmal pro Pfad decodiert und beim Entfernen/Schließen freigegeben.
Reglerbewegungen decodieren keine Bilder erneut. Der Export lädt die gespeicherten
Quelldateien und gibt Bildressourcen frei. Die vorhandene Ladeanzeige und Sperre
gegen parallelen Export bleiben aktiv. Keine zusätzliche Pixelkopie pro Regler.

Gleiche Farbmatrix bedeutet gleiche Filterberechnung. Bildskalierung, Geräte-
Farbmanagement und verlustbehaftete JPEG-Kompression können minimale Abweichungen
verursachen. Die Tests vergleichen PNG-Pixel exakt und JPEG mit kleiner Toleranz.
Es gibt keinen neuen Cloud-Dienst, kein Backend, Konto, Tracking oder Werbung.

## Tests und Plattformprüfung

Neue Tests in `test/settings_test.dart` und `test/photo_adjustments_test.dart`:

- Settings-/Sprachpersistenz, manuelle Sprache vs. System, ältere/unvollständige
  und beschädigte Settings sowie serialisierte Schreibvorgänge.
- Live-Sprachwechsel, Arabisch/RTL, echter Sprachwahldialog auf 320 px,
  sechs vollständige Übersetzungsspalten, Mail-Fallback-Dialog.
- Mailto-Payload und Fehlerpfade über injizierten Launcher, keine privaten Daten.
- Cache-Bereinigung lässt Originalfotos und fremde temporäre Dateien bestehen.
- Foto-JSON, alte Projekte, neutrale/ungültige Werte und private-freie Vorlagen.
- Unveränderter Originalpfad/Ausschnitt, Undo/Redo, Autosave, späteres Bearbeiten
  und Abbrechen ohne Übernahme.
- Alle zehn Filter in PNG und JPEG; Vergleich mit gemeinsamem Preview-Renderer
  und byteweise unveränderte Originaldatei.

Android-Debug-Build hier versucht, aber kein Android SDK installiert. Auf diesem
Linux-Host sind kein Xcode/iOS-Build und keine echte Android-/iOS-Geräteprüfung
möglich. `flutter doctor -v` bestätigt die fehlende Android-Toolchain.

Auf echten Geräten prüfen:

1. Mail-Entwurf mit verschiedenen Mail-Apps, Sonderzeichen und ohne installierten
   Mail-Client; kopierte Support-Adresse und reale Version/Buildnummer.
2. Neustart nach Settings-/Sprachwechsel, Systemsprachwechsel und Arabisch/RTL,
   große Systemschrift, kleine Displays und lange französische/türkische Texte.
3. Import großer JPEG/HEIC-Dateien, flüssige Regler, alle Filter plus Zuschnitt,
   Zoom, Rotation, Spiegelung und Fit/Fill; Undo/Redo und Projekt-Neustart.
4. PNG/JPEG inklusive Transparenz, Text, Rahmen, Schatten und Style Studio;
   Galerie-Berechtigungen, Share Sheet und installierte/nicht installierte
   Social-Media-Ziele. Vorschau mit dem gespeicherten Ergebnis vergleichen.
5. Temporäre Exporte bereinigen; Projekte und Galerie-Bilder müssen bestehen bleiben.

## Geänderte Dateien dieser Erweiterung

Neu:

- `lib/features/settings/models/app_settings.dart`
- `lib/features/settings/services/settings_repository.dart`
- `lib/features/settings/services/problem_report_service.dart`
- `lib/features/settings/state/settings_controller.dart`
- `lib/core/localization/translations.dart`
- `lib/features/collage_editor/models/photo_adjustments.dart`
- `lib/features/collage_editor/rendering/photo_filter_renderer.dart`
- `lib/features/collage_editor/widgets/photo_edit_sheet.dart`
- `test/settings_test.dart`
- `test/photo_adjustments_test.dart`
- `docs/settings-and-photo-editing.md`

Erweitert:

- `lib/app/app_config.dart`, `lib/app/piclayout_app.dart`
- `lib/core/localization/app_localizations.dart`
- `lib/features/settings/settings_page.dart`
- `lib/features/collage_editor/editor_page.dart`
- `lib/features/collage_editor/models/photo_asset.dart`
- `lib/features/collage_editor/rendering/style_renderer.dart`
- `lib/features/collage_editor/state/collage_editor_controller.dart`
- `lib/features/collage_editor/widgets/collage_canvas.dart`
- `lib/features/collage_editor/widgets/styled_collage_scene.dart`
- `lib/features/collage_editor/widgets/style_studio_sheet.dart`
- `lib/features/collage_editor/widgets/text_overlay_sheet.dart`
- `lib/features/export/collage_exporter.dart`
- `lib/features/export/widgets/export_center.dart`
- `lib/features/home/home_page.dart`
- `lib/features/photo_import/selection_review_page.dart`
- `lib/features/projects/services/project_repository.dart`
- `lib/features/templates/widgets/templates_sheet.dart`
- `pubspec.yaml`, `pubspec.lock`, `README.md`

Prüfergebnis dieser Implementierung: `dart format .` erfolgreich;
`flutter analyze` ohne Befunde; `flutter test` mit 45 erfolgreichen Tests
(davon 12 neue). `git diff --check` ohne Befunde. `flutter build apk --debug`
wegen fehlendem Android SDK abgebrochen; kein APK und kein iOS-Build erzeugt.
