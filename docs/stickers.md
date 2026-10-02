# Sticker, Emojis und Formen

Im Editor steht oberhalb der Fotoauswahl **Sticker**. Der Katalog enthält 23 Einträge:

- Emojis: ❤️ ✨ ⭐ 📍 😊 🔥.
- Formen: Kreis, Rechteck, abgerundetes Rechteck, Linie, Sprechblase.
- Pfeile: links, rechts, oben, unten.
- Herzen/Sterne: einfärbbares Herz und Stern.
- Social/Story: Standort-Pin, Kamera, Party-Symbol, WOW!-Label.
- Datum/Ort: lokal formatiertes Datum und ein frei bearbeitbares Ortslabel.

Ein Tippen fügt den Eintrag mittig ein. Es gibt weder Standortabfrage noch
Cloudzugriff. Datum und Ort sind einfache Textlabels; das Datum wird beim Einfügen
festgehalten und ändert sich später nicht automatisch.

## Bearbeiten

Sticker antippen und **Sticker bearbeiten** öffnen, oder direkt doppelt antippen.
Ziehen verschiebt; zwei Finger skalieren und drehen. Größe und Drehung sind auch
über Regler erreichbar. Der Bearbeitungsbereich bietet Farbe, Deckkraft,
optional einen Hintergrund, Duplizieren, Löschen und ganz nach vorne/hinten.
Emojis behalten die Farben der jeweiligen Geräte-Schrift. Formen, Symbole und
Label-Text sind einfärbbar. Im Sticker-Menü lassen sich bereits eingefügte Sticker
über eine Liste auswählen, auch wenn sie verdeckt oder transparent sind.

Positionen sind relativ zur Collage, Größen relativ zu ihrer kürzesten Seite.
Die Sticker-Mitte bleibt im Bild; Teile großer oder gedrehter Sticker können
über den Rand ragen und werden abgeschnitten. Labels umfassen höchstens zwei
Zeilen; längere Texte werden mit Auslassungszeichen dargestellt.

Alle Änderungen unterstützen Undo/Redo und Autosave. Eine Drag-/Pinch-Geste,
eine Reglerbewegung oder eine Texteingabe bis zum Abschluss zählt als ein Schritt.
Bearbeitungen werden direkt übernommen; **Fertig** schließt den Bereich.

Die feste Ebenenfolge lautet: Hintergrund, Fotos mit Filtern/Rahmen, Text,
Sticker. Vorne/hinten verändert die Reihenfolge innerhalb der Sticker-Ebene.
Sticker werden nicht zwischen Fotos oder bestehenden Text-Overlays einsortiert.

## Speicherung, Vorlagen und Export

`StickerOverlay` speichert ID, Typ, Inhalt, normalisierte Position, Skalierung,
Drehung, Farbe, optionalen Hintergrund und Deckkraft. Die Reihenfolge in der
Projektliste ist die dauerhafte Z-Reihenfolge. Es gibt keine Bildpfadfelder,
Bildimporte oder Downloads für Sticker; Symbole werden über bekannte IDs aufgelöst.
Labels enthalten nur eingegebenen Text. Unbekannte/beschädigte Stickereinträge
werden beim Laden übersprungen, ungültige Zahlen begrenzt. Alte Projekte ohne
Sticker laden mit einer leeren Liste.

Im Dialog **Als Vorlage speichern** ist **Sticker übernehmen** standardmäßig aus.
Ist es an, enthält die Vorlage die Sticker ohne Foto-Dateien oder Foto-Pfade.
Beim Anwenden erhalten die Sticker neue IDs und ersetzen die bisherigen Sticker.
Ist es aus, enthält die Vorlage keine Sticker und lässt vorhandene Sticker des
Zielprojekts unverändert. Alte Vorlagen verhalten sich genauso.

Vorschau, Layout-Editor und Export verwenden `StickerRenderer`. Export rendert
weiter aus den ursprünglichen Bilddateien auf eine eigene Zeichenfläche, ohne
Screenshot. PNG, JPEG, Galerie und Social Sharing enthalten die Sticker.
Auswahlrahmen und Touch-Flächen sind ausschließlich Editor-Widgets und werden
nicht exportiert. Originalfotos werden nicht verändert. Schrift-/Emoji-Darstellung
kann zwischen Android und iOS abweichen; auf demselben Gerät teilen Vorschau und
Export denselben Renderer. Es wurden keine Pakete oder Assets ergänzt.

## Dateien

Neu:

- `lib/features/stickers/sticker_overlay.dart`: Datenmodell und Katalog.
- `lib/features/stickers/sticker_renderer.dart`: gemeinsame Zeichenlogik und Maße.
- `lib/features/stickers/sticker_layer.dart`: Auswahl und Gesten.
- `lib/features/stickers/sticker_sheet.dart`: Katalog und Bearbeitung.
- `test/sticker_test.dart`, `test/sticker_editor_test.dart`: Modell-, Export- und UI-Tests.

Integration:

- `lib/features/projects/models/collage_project.dart`
- `lib/features/collage_editor/state/collage_editor_controller.dart`
- `lib/features/collage_editor/editor_page.dart`
- `lib/features/collage_editor/widgets/collage_canvas.dart`
- `lib/features/custom_layouts/widgets/layout_builder_page.dart`
- `lib/features/export/collage_exporter.dart`
- `lib/features/templates/models/collage_template.dart`
- `lib/features/templates/state/design_library_providers.dart`
- `lib/features/templates/widgets/templates_sheet.dart`
- `lib/core/localization/translations.dart`
- `test/design_library_editor_test.dart`
- `README.md` und dieses Dokument.

Bereits vorhandene Änderungen am eigenen Layout-Editor bleiben erhalten.

## Prüfungen

Automatisierte Tests prüfen JSON-Roundtrips, Altprojekte, beschädigte Daten,
Katalog-IDs ohne Bildpfade, Undo/Redo für Hinzufügen/Ändern/Duplizieren/Reihenfolge/
Löschen, lokale Speicherung, Autosave, optionale Vorlagen und neue IDs.
Pixeltests prüfen PNG/JPEG mit Sticker-Reihenfolge und Deckkraft zusammen mit
Foto-Filtern, Hintergrund, Rahmen und Text. Galerie und Social Sharing erhalten
im Test die echten Exportdateien über simulierte Plattform-Schnittstellen.
UI-Tests prüfen Hinzufügen, Auswahl, Ziehen, Zwei-Finger-Skalierung und -Drehung,
Größenänderung per Regler, Label-Bearbeitung,
Duplizieren und Löschen in allen sechs Sprachen, einschließlich Arabisch/RTL,
auf 320 × 640 Pixeln und im Dark Mode. Der bestehende Vorlagentest prüft die
neue Checkbox.

Erfolgreich ausgeführt: `dart format .` (79 Dateien), `flutter analyze`
(keine Befunde), `flutter test` (66 Tests erfolgreich) und `git diff --check`.
Sieben neue Tests ergänzen die zuvor 59 Tests; der vorhandene Vorlagentest wurde
um die optionale Sticker-Übernahme erweitert.

`flutter build apk --debug` wurde versucht: **No Android SDK found**.
Ein nativer Android-Build und iOS-Build wurden daher nicht bestätigt.

Auf echten Geräten prüfen:

1. Emoji- und Material-Symbole auf Android/iOS, insbesondere Herz und kombinierte
   Emoji-Zeichen; gleiche Darstellung in Vorschau und PNG/JPEG.
2. Drag, Pinch und Rotation mit zwei Fingern, auch an Collagerändern; anschließend
   Undo/Redo und Wiederöffnen des Projekts.
3. Kleine Bildschirme, große Systemschrift, Querformat, Dark Mode, arabische Labels
   und Tastatur; alle Regler und Aktionen müssen erreichbar bleiben.
4. Überlappende und transparente Sticker über die Liste erneut auswählen;
   Reihenfolge, Duplizieren, Löschen und Vorlagen mit/ohne Sticker prüfen.
5. PNG-Transparenz, JPEG-Hintergrund, Galerie und tatsächliche Social-Apps bei
   abweichenden Export-Seitenverhältnissen. Auswahlrahmen dürfen nirgends erscheinen.
6. Performance und Speicher bei vielen Stickern und zwölf hochauflösenden Fotos.
