# Bugcheck vom 14.11.2026: Freie Collage

Der unterbrochene Korrekturdurchlauf ist abgeschlossen. Die Änderungen betreffen
Rahmenbearbeitung, asynchrone Fotoimporte und die Darstellung leerer Rahmen.

| Auslöser | Korrektur |
| --- | --- |
| Ungültiges Design mit mehr als 20 Rahmen anwenden | Validierung erfolgt vor Änderungen an Auswahl und Undo/Redo. Ein abgewiesenes Design lässt den bisherigen Zustand erhalten. |
| Größenänderung eines seitenverhältnisgesperrten Rahmens an den Modellgrenzen | Beide Dimensionen verwenden einen gemeinsam begrenzten Skalierungsfaktor. Das Seitenverhältnis bleibt erhalten. |
| Während eines Fotoaustauschs den Modus oder die Fotozuordnung ändern | Der Import prüft den aktuellen Rahmen erneut und überschreibt keine inzwischen geänderte Zuordnung. |
| Fotoimport schlägt teilweise fehl, wird verworfen oder endet nach dem Schließen des Editors | Frische, noch nicht übernommene Projektkopien werden aufgeräumt; Originaldateien und Bilder aus Projekt-/Undo-Zuständen bleiben erhalten. Die Bereinigung prüft alle Zielpfade vor dem Löschen. |
| Leerer Rahmen liegt hinter einer anderen Ebene | Platzhaltersymbol und Nummer werden innerhalb ihrer Ebene gezeichnet und berücksichtigen Rotation und Deckkraft. |
| Quelle einer Rahmenminiatur wird ersetzt oder entfernt | Der Vorschaustatus wird mit der Bildreferenz erneuert; freigegebene Bilder werden nicht weiter angezeigt. |
| Weitere Fotos zu einer bestehenden Collage hinzufügen | Die Auswahlprüfung zeigt keine wirkungslose Formatwahl mehr. |

`test/freeform_bug_regression_test.dart` enthält zehn Regressionstests für
Zustandserhalt, Seitenverhältnisse, konkurrierende Änderungen, Importfehler,
Editor-Schließen, Ebenenüberdeckung und Bildfreigabe.

Abschließende Prüfung unter Windows:

- `flutter test --no-pub --reporter expanded --timeout 45s`: **229 bestanden**.
  Lokales Protokoll: `build/freeform-bug-tests.log`.
- `flutter analyze --no-pub`: keine Befunde.
- `dart format --output=none --set-exit-if-changed lib test`: 132 Dateien,
  keine Formatänderungen erforderlich.
- `git diff --check`: keine Whitespace-Fehler.
- `flutter build apk --debug --no-pub`: erfolgreich; aktualisierte APK unter
  `build/app/outputs/flutter-apk/app-debug.apk`. Bestehende Hinweise zu Java
  Native Access, Kotlin-Plugins und SDK-XML bleiben bestehen.

In diesem Durchlauf ist kein Android-/iOS-Gerät verbunden; die drei erfolgreichen
Emulatortests im Freeform-Bericht stammen aus dem vorherigen Funktionsdurchlauf.
Native Galerie-/Sharing-Abläufe und echte Geräteleistung bleiben offen.

---

# Bugcheck vom 10.11.2026

Geprüft wurden Editorzustände, Fotos und Ebenen, Vorlagen, Undo/Redo,
Projektzugriffe sowie Vorschau und Export. Der Ausgangsstand bestand alle
163 vorhandenen Tests; gezielte zusätzliche Szenarien deckten trotzdem Fehler auf.

## Behobene Fehler

| Auslöser | Vorher | Korrektur und Absicherung |
| --- | --- | --- |
| Foto aus einem angewandten Design entfernen | Unabhängige Titel, Ortslabels und Hintergründe konnten mitgelöscht werden, weil sie eine Foto-ID trugen. | Nur fotoabhängige Ebenen werden entfernt. Neue unabhängige Ebenen und Vorlagentitel erhalten keine Foto-ID; alte Verknüpfungen werden beim Entfernen gelöst. Regression mit Vorlage, Text, Dekoration und Undo. |
| Nummerierungsstil oder Bildunterschrift ändern | Die gesamte Anordnung wurde neu berechnet und manuell verschobene Fotos sprangen zurück. Texteingabe und Wechsel zur eigenen Beschriftung erzeugten zwei Undo-Schritte. | Neuaufteilung nur bei Geometrieänderungen. Beschriftung und Nummerierungsmodus werden gemeinsam geändert; ein Undo stellt beides wieder her. |
| Dasselbe Foto in verschieden großen Ebenen zuschneiden | Die Begrenzung orientierte sich an der ersten statt der ausgewählten Ebene; zulässiges Verschieben konnte blockiert werden. | Die ausgewählte Fotoebene bestimmt die Zuschnittgrenzen. Regression mit quadratischer und schmaler Ebene desselben Fotos. |
| Undo/Redo während der Texteingabe im Designfenster | Das Projekt wurde korrekt zurückgesetzt, das Eingabefeld zeigte weiterhin den neueren Text. | Ein eigener Textcontroller synchronisiert externe Änderungen und erhält beim Tippen den Cursor. Bestehende Tests prüfen das sichtbare Feld in allen sechs Sprachen. |
| Vorlage ohne eigene Textinhalte speichern | Nummerierungen verloren Schriftfamilie, Farbe und weitere Textgestaltung. | Nur Textinhalt und private IDs werden entfernt; die Gestaltung bleibt erhalten. Bestehende Vorlagentests prüfen Schrift und Farbe. |
| Projekt löschen, während Autosaves warten | Speichern und Löschen griffen gleichzeitig auf Dateien zu; auf Windows reproduzierbar als fehlende temporäre Projektdatei. | Löschen wartet auf bereits eingereihte Speicherungen. Spätere Speicherungen desselben gelöschten Projekts werden abgewiesen; wiederholte Löschanforderungen teilen sich den laufenden Vorgang. Originaldateien bleiben unverändert. |
| Eigenständige Verbindungslinie mit noch fehlenden Bildmetadaten exportieren | Vorschau und Export verwendeten unterschiedliche Seitenverhältnisse für den Linienanfang. | Der Export ermittelt echte Bildabmessungen und hält sie pro Datei vor. Pixelvergleich für Linien vor und hinter der Fotoebene. |

Die Fehler bei Fotolöschung, Nummerierung, Zuschnitt, sichtbarem Undo-Text,
gleichzeitigem Speichern/Löschen und Verbindungslinien wurden vor ihrer Korrektur
mit fehlschlagenden Regressionstests reproduziert. Die Vorlagenformatierung wurde
im Code geprüft und durch zusätzliche Assertions abgesichert.

## Abschließende Prüfungen

- `flutter test --no-pub --reporter expanded --timeout 45s`: **168 bestanden**.
- Derselbe Lauf mit `--concurrency=1`: **168 bestanden**, keine Cleanup-Fehler.
- `flutter analyze --no-pub`: keine Befunde.
- `dart format --output=none --set-exit-if-changed lib test`: 118 Dateien,
  keine Formatänderungen erforderlich.
- `git diff --check`: keine Whitespace-Fehler.
- `flutter build apk --debug --no-pub`: erfolgreich. Aktualisierte APK:
  `build/app/outputs/flutter-apk/app-debug.apk`.

Der Android-Build meldet weiterhin Hinweise zu Java Native Access und dem
Kotlin Gradle Plugin in `package_info_plus` und `share_plus`. Sie verhindern
den aktuellen Debug-Build nicht; ein zukünftiges Toolchain-Upgrade muss diese
Abhängigkeiten berücksichtigen.

## Grenzen

Die automatisierte Prüfung beweist keine vollständige Bugfreiheit. Es ist kein
mobiles Testgerät verbunden: `flutter devices` erkennt nur Windows, Chrome und
Edge. Native Galerie- und Sharing-Abläufe, Berechtigungen, Touchverhalten und
Speicherverbrauch mit großen Bildern auf Android/iOS bleiben Geräteprüfungen.
iOS-Kompilierung und signierte Release-Builds wurden nicht durchgeführt.
