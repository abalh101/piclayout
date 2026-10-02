# Bearbeitbare Projektdateien (.piclayout)

## Exportieren und importieren

Auf einer Projektkarte das Menü öffnen und **Projekt exportieren** wählen.
Im Editor ist dieselbe Aktion im zusätzlichen Menü der App-Leiste erreichbar;
dort wird der aktuelle Bearbeitungsstand inklusive noch nicht abgeschlossener
Autosave-Verzögerung verwendet. Nach der Erstellung öffnet sich das native
Teilen-Menü. Dort beispielsweise **In Dateien sichern**, Drive oder eine
Messenger-App wählen, sofern auf dem Gerät verfügbar. PicLayout selbst lädt
nichts hoch und benötigt weder Konto noch Backend. Die Ziel-App entscheidet,
ob sie die Datei speichern/versenden kann. Die Datei heißt etwa
`piclayout_project_Travel_Berlin.piclayout`.

Auf der Startseite **Projekt importieren** wählen und eine `.piclayout`-Datei
öffnen. Nach erfolgreicher Prüfung erscheint **Projekt importiert** und das
neue Projekt steht auf der Startseite zum Öffnen bereit. Jeder Import erhält
eine neue Projekt-ID und neue Bild-IDs; vorhandene Projekte werden nicht ersetzt.

Der Dateidialog zeigt bewusst alle Dokumenttypen an, weil Anbieter eigene
Dateiendungen nicht einheitlich filtern. Name und Inhalt werden nach der Auswahl
geprüft. Abbruch der Auswahl verändert keine Projekte und wird kurz bestätigt.
Während einer Archivoperation sind weitere Archivoperationen gesperrt; ein
Fortschrittsbalken zeigt die Verarbeitung an.

Der bisherige PNG/JPEG-Bildexport bleibt separat. Eine `.piclayout`-Datei ist
zum späteren Weiterbearbeiten bestimmt und lässt sich nicht als fertiges
Collage-Bild veröffentlichen.

## Archivformat, Version 1

Die Endung `.piclayout` bezeichnet intern ein ZIP-Archiv mit genau diesen Dateien:

```text
manifest.json
project.json
images/0.png
images/1.png
…
```

Beispielmanifest:

```json
{
  "format": "piclayout",
  "archiveVersion": 1,
  "projectFormatVersion": 1,
  "createdWithAppVersion": "0.1.0+1"
}
```

`project.json` enthält das vollständige aktuelle Projektmodell: Name,
Seitenverhältnis, Layout-ID, eingebettete eigene Layout-Geometrie, Canvas/Style,
Fototransformationen, Filter, Texte, Sticker und ihre Reihenfolge. Die Fotoeinträge
verwenden ausschließlich relative `localPath`-Werte wie `images/0.png` und neutrale
Dateinamen. Es ist keine globale Vorlagen- oder Layoutbibliothek erforderlich.
Favoriten, andere Projekte, Einstellungen und private Original-Dateinamen werden
nicht mitgenommen. Bewusst eingegebene Texte, Ortslabels und Projektnamen bleiben
als Nutzerinhalt erhalten.

Version 1 akzeptiert Projektformat 1. Ältere Projekte dieses Formats ohne optionale
Text-/Sticker-/Style-Felder verwenden die bestehenden Modell-Defaults. Unbekannte
Archiv- und Projektversionen werden abgelehnt, statt Daten still zu verlieren.
Zukünftige Migrationen können anhand beider Versionsfelder ergänzt werden;
`createdWithAppVersion` dient der Herkunftsinformation, nicht als Zugriffsprüfung.

## Bilder, Datenschutz und Grenzen

Export liest ausschließlich Bilder im privaten `images`-Verzeichnis des
betreffenden Projekts. Die app-internen Kopien und Originalfotos werden nicht
verändert. Bilder werden in ihrer dekodierten Auflösung als PNG neu kodiert;
damit enthält das Archiv keine eingebetteten EXIF-/GPS-/Text-Metadaten.
Transformationen und Filter bleiben separat editierbar. Das entspricht der
statischen Bilddarstellung der App, nicht einem byte-identischen Originalbackup:
Dateiformat, Metadaten und gegebenenfalls HDR/Farbprofil-Informationen werden
nicht konserviert. Bei animierten Quelldateien zählt das erste Bild.
PNG kann größer als das ursprüngliche JPEG/HEIC sein.

Grenzen: 1–12 Fotos, 128 MiB Archiv- und entpackte Gesamtdaten, maximal 32 MiB
pro Quell-/PNG-Bild, 40 Megapixel je Bild und 1 MiB je JSON-Datei. Im UI werden
diese Speichergrenzen verkürzt als MB angegeben. Für Export wird zusätzlich
Platz für JSON und ZIP-Struktur reserviert. Ein Gerät benötigt auch freien Platz
für die importierten PNGs und genügend Arbeitsspeicher zur Bilddekodierung.
Speicherplatzfehler (ENOSPC) haben eine eigene lokalisierte Meldung.

Import prüft erlaubte Eintragsnamen, Eintragsanzahl, doppelte Namen, relative
Bildreferenzen, Größen, tatsächliche entpackte Länge, CRC-Prüfsummen und
Bilddekodierung. Absolute Pfade, `..`, Backslashes, symbolische Links,
verschlüsselte ZIPs und nicht referenzierte Dateien werden abgelehnt.
ZIP-Store und Deflate werden unterstützt. Deflate wird mit begrenzter Ausgabe
im Hintergrund-Isolate entpackt; überhöhte oder gefälschte Größen werden gestoppt.
Archive werden niemals anhand ihrer Eintragspfade direkt ins Dateisystem entpackt.

Import schreibt zuerst in einen temporären Ordner neben dem Projektverzeichnis.
Erst nach vollständigem Erfolg wird dieser unter der neuen Projekt-ID atomar
umbenannt. Fehler räumen den Importordner auf. Bei einem Prozessabbruch kann ein
verwaister temporärer Ordner zurückbleiben; er wird nicht als Projekt angezeigt.
Die vom Export-Service erstellte temporäre Freigabedatei wird nach Rückkehr aus
dem Teilen-Menü entfernt. System-/Plugin-Caches unterliegen zusätzlich der
Bereinigung des Betriebssystems. Eine erfolgreiche Übergabe an das Teilen-Menü
bedeutet nicht automatisch, dass die Ziel-App eine dauerhafte Kopie gespeichert hat.

## Architektur und Dateien

Neu:

- `lib/features/project_archive/project_archive_service.dart`: ZIP-Service,
  Manifest, PNG-Portierung, Prüfung, neue IDs, transaktionaler Import,
  `ProjectArchiveException` mit lokalisierbaren Fehlercodes.
- `lib/features/project_archive/project_archive_controller.dart`: Dateiauswahl/
  Teilen hinter `ProjectArchivePlatform`, Operationssperre, temporäre Freigaben,
  Provider und App-Versionsinformation.
- `lib/features/project_archive/project_archive_actions.dart`: UI-Rückmeldungen
  und Aktualisierung der Startseite.
- `test/project_archive_test.dart`, `test/project_archive_ui_test.dart`.
- Dieses Dokument.

Geändert: `lib/features/home/home_page.dart`,
`lib/features/collage_editor/editor_page.dart`,
`lib/core/localization/translations.dart`, `pubspec.yaml`, `pubspec.lock`,
`README.md`. Das bestehende `ProjectRepository` bleibt unverändert.

`archive` (bereits indirekt vorhanden) ist jetzt eine direkte Abhängigkeit.
Die native Dateiauswahl verwendet das offizielle Flutter-Plugin
[file_selector](https://pub.dev/packages/file_selector); Teilen verwendet das
bereits vorhandene `share_plus`. Keine Cloud-, Analyse- oder Backend-Abhängigkeit.

## Tests und Geräteprüfung

Service-Tests prüfen Archivstruktur, Bilddaten, entfernte Metadaten/Pfade,
Datenerhalt, neue IDs, unabhängige wiederholte Importe, alte optionale Felder,
Versionsfehler, fehlende/defekte Bilder, Aufräumen, Traversierung, Links,
CRC-Manipulation, gefälschte Größen, Speicherfehler, Auswahlabbruch, falsche
Endungen, Operationssperre sowie Share-Fehler und temporäre Bereinigung.
UI-Tests prüfen Import, Startseitenaktualisierung, Abbruch, Fehlermeldung und
Projektkarten-Export in allen sechs Sprachen auf 320 × 640 Pixeln im Dark Mode.
Dateidialog und Teilen-Menü sind dabei simuliert.

`flutter build apk --debug` wurde versucht und scheiterte mit
**No Android SDK found**. Native Android- und iOS-Builds sind hier nicht bestätigt.

Auf echten Geräten prüfen:

1. Android-Dateiauswahl und iOS-Dateien: lokale Dateien und heruntergeladene
   Dokumente, unbekannte Dateiendungen, Abbruch, nicht mehr verfügbare Anbieter.
2. Teilen nach Dateien/Drive/Messenger, iPad-Popover, Abbruch und spätes Lesen
   durch Ziel-Apps. Gespeicherte Kopie nach Schließen der App erneut importieren.
3. Android → iOS und iOS → Android übertragen, alle Fotos, Zuschnitte, Filter,
   eigene Layouts, Texte, Sticker und Stil weiterbearbeiten und als Bild exportieren.
4. JPEG/HEIC, Orientierung, Transparenz, breite Farbräume/HDR: Vorschau und
   Import vergleichen; PNG-Portierung erhält keine vollständigen HDR-Metadaten.
5. Große Projekte nahe den Limits, knapper Speicher, Hintergrund/Neustart
   während der Verarbeitung und wiederholter Import ohne Überschreiben.
6. Große Systemschrift, kleine/querformatige Bildschirme und Arabisch/RTL.
