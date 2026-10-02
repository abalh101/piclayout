# Onboarding, Beispiele und Einstiegstipps

## Bedienung

Beim ersten Start nach Installation dieses Funktionsstands zeigt PicLayout fünf
kurze Seiten: Willkommen, Fotos auswählen, Layouts/Vorlagen, Bearbeiten und
Exportieren. Die gespeicherte Sprache wird vor der Anzeige geladen. Weiter,
Zurück und Wischen wechseln die Seite. Überspringen beendet die Einführung;
auf der letzten Seite führen Loslegen zur Startseite und Beispiel öffnen zur
Beispielauswahl. Abschluss und Überspringen speichern denselben lokalen
Erledigt-Zustand. Ohne diese neue Zustandsdatei sehen auch bestehende
Installationen die Einführung einmal.

Es werden beim App-Start keine Demo-Projekte ungefragt angelegt. Auf der
Startseite bleiben Neue Collage und Beispiel öffnen immer erreichbar, auch
wenn bereits Projekte vorhanden sind. Der Leerzustand erklärt lokale
Bearbeitung und unveränderte Originalfotos.

Die Einstellungen enthalten:

- Onboarding erneut anzeigen (setzt den automatischen Erststartstatus nicht zurück).
- Tipps zurücksetzen (gilt beim nächsten Öffnen des jeweiligen Bereichs).
- Beispielprojekte (dieselbe Auswahl wie auf der Startseite).

## Die fünf Designs

| Beispiel | Format | Fotos | Gestaltung |
| --- | --- | --- | --- |
| Instagram Story Collage | 9:16 | 3 | Dunkler Rand, runde Ecken, Text und Stern |
| Reise Collage | 4:3 | 4 | Cremefarbener Rahmen, Text |
| Geburtstag / Event Collage | 4:5 | 3 | Rosa Hintergrund, runde Ecken, Text und Stern |
| Minimal Clean Collage | 3:4 | 2 | Weißer Rand, klare Kanten, Text |
| Social Media Post | 1:1 | 4 | Heller violetter Rahmen, Text |

Jedes Öffnen erstellt ein eigenes normales Projekt mit neuen Projekt-, Foto-,
Text- und Sticker-IDs. Die Beispieldefinitionen bleiben unverändert. Fotos,
Texte und Sticker der Kopie lassen sich bearbeiten, speichern, rückgängig
machen und exportieren. Ein weiteres Öffnen desselben Beispiels erstellt eine
weitere unabhängige Kopie. Die Projektnamen und Beispieltexte verwenden die
aktuell ausgewählte Sprache und bleiben anschließend normaler Projektinhalt.

## Demo-Assets

`assets/demo/demo_1.png` bis `demo_6.png`: sechs originale, abstrakte Grafiken
mit farbigen Kreisen oder Streifen und den Nummern 1–6. Sie enthalten keine
Fotografien, privaten Inhalte, heruntergeladenen Bilder oder Netzverweise.
Jede Grafik hat 480 × 640 Pixel. Zusammen benötigen sie 23.829 Byte (etwa
23,3 KiB). Die bestehenden Bild- und Exportfunktionen verwenden diese PNGs
wie reguläre importierte Fotos.

Reproduzierbare Erzeugung (Python und Pillow):

```bash
python3 tool/generate_demo_assets.py
```

Die Factory lädt die gebündelten Assets kurz in ein temporäres Verzeichnis,
importiert sie über ProjectRepository und entfernt das temporäre Verzeichnis
anschließend. Die endgültigen Fotos gehören nur zur jeweiligen Projektkopie.
Beispieldefinitionen enthalten Assetnummern; gespeichertes `project.json`
enthält ausschließlich relative `images/...`-Bildpfade. Zur Laufzeit löst das
bestehende Repository diese wie bei anderen Projekten zu lokalen Dateipfaden auf.

## Einstiegstipps und Speicherung

Kompakte, schließbare Hinweise erscheinen im scrollbaren Werkzeugbereich des
Editors (Foto antippen bzw. Text/Sticker ziehen), in den Fotowerkzeugen
(Zwei-Finger-Zoom in der Collage) und im Export Center (Galerie/Social Media).
Sie blockieren keine Gesten und öffnen keine zusätzlichen Dialoge.

Jedes Thema erscheint höchstens zweimal. Eine Anzeige wird lokal gezählt;
Schließen blendet das Thema unabhängig vom Zähler dauerhaft aus. Tipps
zurücksetzen löscht Zähler und geschlossene Themen, aber nicht den
Onboarding-Abschluss. Beim nächsten Öffnen können sie wieder erscheinen.
Scheitert die Speicherung eines geschlossenen Tipps, erscheint ein Fehlerhinweis.
Optionale Tipps verhindern bei Ladefehlern nicht die Bearbeitung.

`onboarding.json` liegt im Application-Support-Verzeichnis und enthält nur:
`completed`, `tipViews` und `dismissedTips`. Alle Änderungen werden serialisiert
und über eine temporäre Datei atomar geschrieben. Keine neue Abhängigkeit,
Cloud, Anmeldung, Werbung oder Telemetrie.

## Architektur

- `lib/features/onboarding/`: Startentscheidung, fünf Seiten und Repository.
- `lib/features/demo_projects/`: unveränderliche Designs, Factory, Beispielauswahl.
- `lib/features/tutorial_tips/`: Controller und Hinweis-Widget.
- Integration in App-Start, Startseite, Einstellungen, Editor und Export Center.
- Alle neuen Texte in `lib/core/localization/translations.dart` für Deutsch,
  Englisch, Arabisch, Türkisch, Französisch und Spanisch.

## Validierung

Neue Tests in `test/onboarding_test.dart` und `test/demo_projects_test.dart`:

- Erststart, alle fünf Seiten, Abschluss, Neustart ohne automatische Wiederholung.
- Wiederholung über Einstellungen, Überspringen, Beispielaktion am Ende.
- Persistenz, beschädigte Zustandsdatei, parallele Tipp-Zähler, Speicherfehler,
  Schließen und Zurücksetzen ohne Verlust des Onboarding-Abschlusses.
- Alle fünf Designs, unabhängige Kopien, neue IDs, unveränderte Assets,
  relative gespeicherte Bildpfade, reguläres Laden und temporäre Bereinigung.
- Bearbeiten, Undo/Redo, Speichern sowie PNG/JPEG-Export eines Beispiels.
- Alle sechs Sprachen, Arabisch/RTL, Dark Mode, 320 × 640 Pixel, große Schrift
  (Faktor 1,6) sowie Querformat 640 × 320 auf der Abschlussseite.

Bestehende App-Einstellungstests starten explizit mit abgeschlossenem Onboarding.

Ausgeführt:

- `dart format .` erfolgreich.
- `flutter analyze` ohne Befunde.
- `flutter test`: **84 Tests erfolgreich**, einschließlich der bestehenden Tests.
- `flutter build apk --debug`: versucht, **No Android SDK found**.

Native Builds und echte Touch-Bedienung sind damit nicht bestätigt.

## Auf echten Geräten prüfen

1. Frische Installation: Seitenwechsel durch Wischen, Weiter/Zurück, Überspringen,
   Loslegen und Beispiel öffnen; App schließen und erneut starten.
2. Alle fünf Beispiele öffnen, Fotos ersetzen, Text/Stern verschieben, speichern
   und erneut öffnen; dasselbe Beispiel erneut öffnen und Unabhängigkeit prüfen.
3. Foto-, Zoom-, Text/Sticker- und Exporttipps schließen; Neustart und
   Tipps zurücksetzen prüfen. Hinweise dürfen keine Bedienflächen verdecken.
4. Kleine Displays, Querformat, größte Systemschrift, helle/dunkle Darstellung,
   Screenreader und Arabisch/RTL einschließlich Seitenwechsel und Navigation.
5. Demo-Collage in Galerie speichern, an Social Apps übergeben und als
   .piclayout-Projekt sichern/importieren. Editor und Ergebnis vergleichen.
