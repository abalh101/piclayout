# Smart Auto Layout und Layout-Empfehlungen

## Bedienung

Im Editor steht vor der vollständigen Layout-Bibliothek der Abschnitt
**Empfohlen**. Er zeigt die drei am höchsten bewerteten vorhandenen Layouts,
kleine farbige Vorschauen und je eine kurze Begründung. Antippen einer Karte
wendet sie an. **Auto Layout** übernimmt die erste Empfehlung. Die vollständige
Bibliothek, Favoriten, eigene Layouts und Layoutvariation bleiben verfügbar.

Auto Layout ändert nur die Layout-ID und löst gegebenenfalls die aktive eigene
Aufteilung ab. Foto-Reihenfolge, gespeicherte Zuschnitte/Zoom/Drehung, Filter,
Text, Sticker und Canvas-Style bleiben erhalten. Eine andere Zellaufteilung
kann trotzdem andere Bildausschnitte sichtbar machen. Die Änderung ist ein
Undo-Schritt; Undo stellt auch ein vorheriges eigenes Layout wieder her.
Erneutes Anwenden desselben aktiven Standardlayouts erzeugt keinen leeren
Undo-Schritt. Wie andere Layoutänderungen wird Auto Layout automatisch gespeichert.

Im Foto-Auswahlschritt sind Zielformat und Empfehlungen direkt verfügbar.
Ohne manuelle Wahl wird die beste Empfehlung verwendet. Eine Karte kann direkt
gewählt werden; ein Formatwechsel oder das Entfernen eines Fotos setzt diese
Wahl zurück und berechnet neue Vorschläge. Umsortieren berücksichtigt die neue
Foto-Reihenfolge, erhält aber eine ausdrücklich gewählte Layout-ID. Während der
Projekterstellung sind Änderungen an der Auswahl gesperrt.

Alle neuen Bezeichnungen und Begründungen sind in Deutsch, Englisch, Arabisch,
Türkisch, Französisch und Spanisch vorhanden. Es gibt keine KI-Bezeichnungen,
Motiverkennung, Cloud-Anfragen oder neuen Abhängigkeiten.

## Nachvollziehbare Bewertung

Die Engine prüft ausschließlich Layouts der bestehenden Bibliothek mit passender
Fotoanzahl (1–12). Sie bewertet das Foto an seiner unveränderten Position gegen
die zugehörige Zelle im Zielformat. Editor-Drehungen um 90°/270° tauschen für die
Bewertung Breite und Höhe; die gespeicherten Originalabmessungen bleiben gleich.

Der Score besteht aus:

- **Formateignung, bis 60 Punkte:** Mittelwert von
  `min(Fotoverhältnis / Zellverhältnis, Zellverhältnis / Fotoverhältnis)`.
  Bei unbekannten Abmessungen wird neutral `0,65` eingesetzt.
- **Flächennutzung, bis 8 Punkte:** Anteil der von Zellen belegten Normalfläche.
  Unvollständige Raster erhalten dadurch weniger Punkte.
- **Regelboni:** siehe Tabelle. Die Werte sind Rangpunkte, keine Prozentangaben.

| Regel | Bonus | Beispielbegründung |
| --- | ---: | --- |
| Mindestens 67 % Hochformatfotos und passende Hochformatzellen | 12 | Passt zu vielen Hochformatbildern |
| Mindestens 67 % Querformatfotos und passende Querformatzellen | 12 | Breite Felder für Querformatbilder |
| Quadratisches Zielformat mit vollständig belegtem Raster | 12 | Ausgeglichenes Raster für ein Quadrat |
| Hoch- und Querformat gemischt, asymmetrisches/Hero-Layout | 18 | Abwechslungsreich für gemischte Fotoformate |
| Sechs Fotos in 9:16, Raster 2×3 oder zwei versetzte Spalten | 22 | Gut für 6 Bilder im Story-Format |
| Erstes Foto mindestens 2:1, Hero oben mit breitem Hauptfeld | 28 | Hebt das erste breite Foto hervor |
| Erstes Foto höchstens 1:2, Hero links mit hohem Hauptfeld | 28 | Hebt das erste hohe Foto hervor |

Boni können zusammenwirken. Bei gleichen Scores entscheidet die Layout-ID,
damit dieselben Eingaben immer dieselbe Reihenfolge ergeben. Die Begründung
nennt eine zutreffende Regel, bei mehreren die spezifischere. Fehlen passende
Regeln, lautet sie „Passend zu Fotoanzahl und Zielformat“.

Die bestehende Bibliothek platziert das Hero-Foto an Position 0. Ein breites
Foto weiter hinten wird daher nicht ungefragt umsortiert und bekommt keine
irreführende Hero-Begründung. Es fließt trotzdem an seiner tatsächlichen
Zellposition in die Formateignung ein. Empfehlungen sind eine geometrische
Heuristik: Motive/Gesichter, vorhandene Zoom-Ausschnitte, Filter und Textinhalte
werden nicht analysiert. Rahmen, Abstände und Rundungen sind keine zusätzlichen
Score-Eingaben; die gespeicherte Versetzung wird berücksichtigt.

Die Miniaturen zeichnen dieselben normalisierten Zellen und Fotoindizes wie die
Layout-Bibliothek. Sie zeigen keine privaten Fotos und sind schematische
Layoutvorschauen, keine Exportvorschauen.

## Foto-Metadaten und Kompatibilität

`PhotoAsset.metadata` enthält optional ausschließlich `width` und `height`.
Orientierung, Seitenverhältnis sowie sehr breit/sehr hoch/normal werden daraus
abgeleitet. Quadrat bedeutet gleiche Breite und Höhe. Ab 2:1 gilt ein Bild als
sehr breit, bis 1:2 als sehr hoch.

Beim normalen Fotoimport und Ersetzen werden die Abmessungen aus der lokalen
Projektkopie gelesen. Beim Projektarchiv-Import werden sie aus dem tatsächlichen
importierten PNG neu ermittelt. Es werden keine Originalfotos geändert.

Alte Projekte ohne dieses optionale Feld bleiben unverändert ladbar. Beim
Öffnen im Editor werden fehlende Werte nacheinander aus den lokalen Dateien
nachgeladen, ohne vollständige Pixelbilder zu dekodieren. Flutter liest die
angezeigten Abmessungen einschließlich EXIF-Orientierung. Die Werte werden
in den aktuellen Zustand und vorhandene Undo/Redo-Zustände eingetragen und
anschließend über das bestehende Autosave gespeichert. Das ist kein eigener
Bearbeitungsschritt. Parallel erfolgte Änderungen und Fotoersetzungen werden
nicht durch einen alten Projekt-Schnappschuss überschrieben.

Fehlende, beschädigte oder nicht unterstützte Dateien bleiben unbekannt; Anzahl
und Zielformat reichen weiterhin für Vorschläge. Beim Laden bleibt das bisherige
Layout aktiv. Auto Layout wird erst nach Abschluss der Metadatenprüfung aktiviert.
Ergebnisse werden bei Änderungen an Reihenfolge, Format, Fotoanzahl oder Drehung
neu berechnet. Bereits bekannte Abmessungen erfordern dabei keine Dateizugriffe.
Empfehlungen enthalten nur Layout, Zahlenwerte und Übersetzungsschlüssel,
keine Foto-IDs, Originalnamen oder Bildpfade. Vorlagen enthalten weiterhin
keine Fotos oder privaten Dateipfade.

## Neue und geänderte Dateien

Neu:

- `lib/features/collage_editor/models/photo_metadata.dart`
- `lib/features/layout_recommendations/photo_metadata_reader.dart`
- `lib/features/layout_recommendations/layout_recommendation_service.dart`
- `lib/features/layout_recommendations/recommended_layouts.dart`
- `test/layout_recommendation_test.dart`
- `test/layout_recommendation_ui_test.dart`
- Dieses Dokument.

Integration:

- `lib/features/collage_editor/models/photo_asset.dart`
- `lib/features/collage_editor/state/collage_editor_controller.dart`
- `lib/features/collage_editor/editor_page.dart`
- `lib/features/projects/services/project_repository.dart`
- `lib/features/project_archive/project_archive_service.dart`
- `lib/features/photo_import/selection_review_page.dart`
- `lib/core/localization/translations.dart`
- `test/design_library_editor_test.dart` (Bild-Fixture mit bekannten Abmessungen)
- `README.md`

## Tests und Geräteprüfung

Elf neue Tests prüfen Orientierung/Kategorien, optionale JSON-Felder, sichere
Fallbacks, PNG- und alle acht JPEG-EXIF-Orientierungen, unveränderte Quelldateien,
Import/Ersetzen, Nachladen alter Projekte, gleichzeitige Bearbeitung während
des Nachladens, deterministische Empfehlungen für 1–12 Fotos, Story/Querformat/
Quadrat/Mischformate, positionsgerechte Hero-Regeln, Drehung, Datenschutz,
Datenerhalt und Undo/Redo. Widget-Tests decken Vorschauen und Begründungen in
allen sechs Sprachen, Arabisch/RTL, Dark Mode, große Schrift und kleine Displays
sowie den Weg von Format-/Layoutwahl über Projekterstellung bis Auto Layout/Undo
im Editor ab.

Abschließend ausgeführt:

- `dart format .`: erfolgreich.
- `flutter analyze`: keine Befunde.
- `flutter test`: **95 Tests erfolgreich**, einschließlich der bestehenden Tests.
- `flutter build apk --debug`: versucht, abgebrochen mit **No Android SDK found**.

Native Android-/iOS-Builds und tatsächliche Touch-Bedienung sind hier nicht
bestätigt. Auf echten Android-/iOS-Geräten prüfen:

1. 1–12 Bilder, gemischte Orientierungen, Panorama, sehr hohes Foto und sechs
   Hochformatfotos in 9:16. Vorschau und tatsächlich angewendetes Layout vergleichen.
2. HEIC/HEIF und gedrehte Kamerafotos auf den Zielplattformen; Metadaten nach
   Ersetzen, Drehen, Entfernen, Umsortieren und Projektarchiv-Import prüfen.
3. Auto Layout nach Zoom/Filter/Text/Sticker/Style und bei eigenem Layout;
   einmal Undo/Redo sowie Speichern, App-Neustart und PNG/JPEG-Export prüfen.
4. Horizontal durch Empfehlungen scrollen, manuell wählen und jederzeit zur
   normalen Bibliothek wechseln. Auswahlschritt mit vielen Fotos und langem
   Dateinamen prüfen.
5. Kleine Displays, Querformat, große Systemschrift, Screenreader,
   helle/dunkle Darstellung und Arabisch/RTL.
6. Große Bilddateien und ältere Projekte: Ladezeit, Speicherbedarf und
   Bedienbarkeit während der Metadatenprüfung beobachten.
