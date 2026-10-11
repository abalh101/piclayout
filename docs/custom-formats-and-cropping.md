# Eigene Formate und Crop-Grenzen

Im Editor unter **Format → Eigenes Format** Breite und Höhe eingeben, zum Beispiel
3 und 2, 21 und 9 oder 1920 und 1080. Die Eingaben definieren das Verhältnis,
nicht die Exportauflösung. Positive Werte bis 1.000.000, höchstens drei
Nachkommastellen (Punkt oder Komma) und Verhältnisse von 1:8 bis 8:1 sind erlaubt.
**Speichern und anwenden** legt ein wiederverwendbares Format in der lokalen
Design-Bibliothek ab und ändert das Projekt als einen Undo-Schritt. Abbrechen
verändert nichts; ein Speicherfehler wird angezeigt und das Format nicht angewendet.

Gleichwertige Eingaben werden gekürzt und nicht doppelt gespeichert: 300:200 wird
3:2, 21:9 wird 7:3. Ein Verhältnis, das einem vorhandenen Preset entspricht,
verwendet dieses Preset. Bestehende Presets bleiben erhalten. Gespeicherte eigene
Formate erscheinen als zusätzliche Chips in jedem Editor. Das aktuell im Projekt
enthaltene eigene Format erscheint auch dann, wenn es nicht in dieser Bibliothek
gespeichert ist. Die IDs `custom_<Breite>_<Höhe>` tragen alle nötigen Formatdaten;
Projekte, Designvorlagen und `.piclayout`-Archive benötigen deshalb keine fremde
Bibliothek, um das Verhältnis wiederherzustellen. Alte Projekte bleiben kompatibel.

Der Export bietet passende Auflösungen für das aktuelle Format. Die lange Seite
ist auf 8192 Pixel begrenzt; nach dieser Begrenzung identische Größen erscheinen
nur einmal. Pixelabmessungen werden auf ganze Zahlen gerundet. Social-Presets mit
einem anderen Verhältnis verwenden weiterhin das bestehende Reflow-Verhalten.

Im **Fill-Modus** beträgt der minimale Zoom 1× relativ zur bildfüllenden
Basisskalierung. Verschiebungen enden dort, wo eine Bildkante die Zellkante
erreicht. Die Berechnung berücksichtigt Originalabmessungen, Zellform,
Vierteldrehungen und Zoom; Spiegeln verändert die zulässigen Grenzen nicht.
Direkte Crop-Gesten speichern die begrenzten Werte. Format-/Layoutwechsel
behalten die gespeicherten Transformationen bei und begrenzen den sichtbaren
Ausschnitt beim Rendern für die neue Zellform. Undo kann dadurch den alten
Zuschnitt vollständig wiederherstellen. Reset setzt Zoom, Verschiebung, Drehung,
Spiegelung und Fit-Modus auf die bisherigen Standardwerte zurück.

**Fit** bleibt frei verschiebbar und erlaubt Zoom ab 0,5× sowie bewusst sichtbare
Hintergrundflächen. Vorschau und Export verwenden dieselbe `PhotoCrop`-Berechnung
und denselben `StyleRenderer`. Die verkleinerte Vorschau behält dafür die natürlichen
Bildabmessungen vor dem Downsampling. Cropping ist bei gleicher Zellgeometrie
identisch; Bildschärfe, JPEG-Kompression und Pixelrundung können sich unterscheiden.
Eine Foto-Geste ist ein Undo-Schritt; die bestehenden Autosave-Regeln bleiben aktiv.

Tests in `test/custom_aspect_ratio_test.dart` und `test/photo_crop_test.dart`
prüfen Eingabegrenzen, Normalisierung, Bibliotheks-Neustart, paralleles Speichern,
Fehlerbehandlung, Projekt-/Vorlagenkompatibilität, sechs Dialogsprachen auf 320 px,
Undo/Redo, Autosave, 300 reproduzierbare Crop-Geometrien, Rotation/Flip/Fit/Reset,
Originalabmessungen beim Downsampling und PNG/JPEG-Konsistenz. Auf Geräten zusätzlich
Pinch-/Drag-Gesten, große Fotos, Formatwechsel und Exportauflösungen prüfen.
