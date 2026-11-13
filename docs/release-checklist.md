# PicLayout Release-Checkliste

## Photo Adjustments Studio (2026-11-13)

Implementation, processing order, compatibility and limitations:
[Photo Adjustments Studio](photo-adjustments-and-editor-polish.md).

- [x] Android emulator smoke tests: native shader/PNG/JPEG agreement with
  crop/rotation/flip; twelve 1600×1200 photos, live tint gesture, undo/redo,
  comparison, save/reopen, exports and cache release. Android 17 / API 37,
  x86_64, Impeller OpenGLES; two integration tests passed on 2026-11-13.
- [ ] Profile 12 high-resolution photos on Android and iPhone/iPad, including
  shader sliders, repeated exports, memory and background/resume.
- [ ] Compare all controls with PNG/JPEG, crop/rotation/flip, transparent photos
  and editorial callouts on platform GPU backends.
- [ ] Verify hold/toggle comparison with TalkBack/VoiceOver, RTL, large type,
  landscape/tablets, reset confirmation and one undo per gesture.
- [ ] Exercise process interruption, recovered saves, low storage, missing photos,
  gallery permission denial and rapid repeated export taps.

Vignette is now implemented in Adjust. Sharpness remains unavailable.

Validation on Windows: `dart format .` completed (125 Dart files),
`flutter analyze` reported no issues, `flutter test` passed 192 tests, and
`flutter test --concurrency=1` passed 192 tests without cleanup errors.
`flutter build apk --debug` produced `build/app/outputs/flutter-apk/app-debug.apk`.
Existing KGP/native-access/SDK-tooling warnings remain. Follow-up verification
passed both Android emulator integration tests and all 192 host tests. The Flutter
SDK's `integration_test` development dependency and its transitive test packages
were added. Physical-device profiling and iOS verification remain open. No signing
files or credentials were added; older sections retain their historical counts.

Status: Quellcode für Release-Vorbereitung eingerichtet; Store-Freigabe erst nach
den unten dokumentierten manuellen Prüfungen. Häkchen gelten pro Release-Kandidat.
Keine Produktionsschlüssel oder Store-Zugangsdaten gehören ins Repository.

## Abschließender Bugcheck (10.11.2026)

- **168 Tests erfolgreich**, normal und seriell unter Windows; keine Tests
  übersprungen, keine Cleanup-Fehler unterdrückt.
- Analyse ohne Befunde, Formatprüfung und `git diff --check` erfolgreich.
- Android-Debug-APK mit den Korrekturen neu gebaut.
- Fehler bei Fotolöschung, Nummerierung/Beschriftung, Zuschnitt, sichtbarem
  Undo-Text, Vorlagenformatierung, Autosave/Löschen und Verbindungslinien behoben.
- Details und verbleibende native Geräteprüfungen: [Bugcheck](bug-audit.md).

## Editorial- und Story-Designs (10.11.2026)

- Vollständige Windows-Suite: **163 Tests erfolgreich**, normal und mit
  `--concurrency=1`; darin 29 neue Tests für Designs, Ebenen und Rendering.
- `flutter analyze --no-pub`: keine Befunde. `dart format lib test`:
  118 Dateien, zuletzt keine weiteren Änderungen erforderlich.
- `flutter build apk --debug --no-pub`: erfolgreich;
  `build/app/outputs/flutter-apk/app-debug.apk`.
- Alle sieben gerenderten Preset-Layouts und die geladene Canvas-Vorschau
  visuell geprüft; native Schriftdarstellung bleibt ein Gerätecheck.
- Build-Warnungen: Java Native Access, KGP in `package_info_plus`/`share_plus`
  und unterschiedliche Android-SDK-XML-Versionen.
- Keine mobilen Geräte verbunden; native Galerie-/Sharing-Tests, iOS-Build
  und signierte Release-Builds bleiben offen.
- Bedienung, Architektur und Prüfdetails:
  [Editorial & Story Designs](editorial-story-designs.md).

## Erneute lokale Prüfung vor den Editorial-Designs (10.11.2026)

- `flutter test --no-pub --reporter expanded`: alle 134 Tests erfolgreich,
  einschließlich der korrigierten Demo-Bildtests.
- `flutter analyze --no-pub`: keine Befunde.
- `dart format --output=none --set-exit-if-changed lib test`: 108 Dateien,
  keine Änderungen erforderlich.
- Veralteten Hinweis auf vier offene Windows-Cleanup-Fehler in der README
  durch den bestätigten Teststatus ersetzt.
- Keine neuen Plattform-Builds oder Geräteprüfungen in diesem Durchlauf;
  der letzte APK-Build und die visuellen Prüfungen sind unten dokumentiert.

## Aktueller Prüfstand: Editor-Überarbeitung (07.11.2026)

- Formatprüfung: 108 Dart-Dateien, keine Änderungen erforderlich.
- `flutter analyze --no-pub`: keine Befunde.
- Vollständige Testsuite: **134 Tests erfolgreich**, sowohl im normalen Lauf
  als auch mit `--concurrency=1` unter Windows.
- Veralteten Demo-Test korrigiert: Bildformat automatisch erkennen, Kopien
  byteweise und Bildmaße gegen die Original-Assets prüfen.
- `flutter build apk --debug --no-pub`: erfolgreich. APK:
  `build/app/outputs/flutter-apk/app-debug.apk`.
- Editor-Ansichten bei 430 × 932 und 740 × 360 visuell geprüft.
- Native Geräteprüfungen, iOS-Kompilierung und signierte Release-Builds bleiben
  offen. Build-Warnungen und Umfang: [Editor-Audit](editor-refinement-audit.md).

Die folgenden Ergebnisse vom Oktober dokumentieren frühere Prüfstände.

## Ergebnis des Qualitäts-Passes (11.10.2026)

**Current Windows test status:** the later cleanup pass resolved all four fixture
failures. `dart format .` completed, `flutter analyze` found no issues, and both
normal and serial full-suite runs pass **all 116 tests**. CI now includes Windows
and Ubuntu. The older failing-run details below are historical; the cleanup
blocker is resolved. See [windows-test-cleanup.md](windows-test-cleanup.md).

- `flutter pub get`: erfolgreich. Die zurückgezogene indirekte Version
  `jni_flutter 1.0.4` wurde im Lockfile gezielt auf `1.0.4+1` aktualisiert.
- `dart format .`: erfolgreich; `flutter analyze`: keine Befunde.
- `flutter test` nach Ergänzung eigener Formate/Crop-Grenzen: 105 erfolgreiche
  Einträge, vier Fehler beim Löschen temporärer
  Bildverzeichnisse unter Windows (`PathAccessException`, OS-Fehler 32).
  Betroffen: `demo_projects_test.dart`, `design_library_editor_test.dart`,
  `layout_recommendation_ui_test.dart`, `text_overlay_editor_test.dart`.
  Die Support-Konfigurations-, Pfad- und neun neuen Format-/Crop-Tests sind erfolgreich. Der Gesamtlauf ist
  **nicht grün**. Vor Release die Dateisperren in den Test-Fixtures klären und
  einen vollständig erfolgreichen lokalen/CI-Lauf dokumentieren; Fehler wurden
  weder unterdrückt noch Tests übersprungen. Aktuelles Log: `build/custom-ratios-crop-tests.log`
  (lokal, von Git ignoriert). Der neue GitHub-Workflow wurde noch nicht remote ausgeführt.
- `flutter build apk --debug`: erfolgreich; Kotlin-Integration kompiliert.
- `flutter build appbundle --release` ohne Signing-Dateien: erwarteter Abbruch
  mit klarer Signing-Meldung. Ein echt signierter Release-Build ist noch offen.
- iOS-Projektkonfiguration geprüft; iOS-Kompilierung/Gerätetests auf Windows nicht möglich.
- Platzhaltersuche: keine Beispiel-App-ID oder aktive Beispiel-Support-Adresse
  mehr im Produktcode. Beispiel-Domains bleiben nur als Validierungsregeln bzw.
  negative Testdaten. Keine Keystore-Dateien oder Signing-Secrets hinzugefügt.

## Additional checks: 12 photos, dividers and iOS workflow

Current validation after fixture cleanup: `dart format .` completed,
`flutter analyze` reported no issues, and both normal and serial full-suite runs
pass **all 116 tests**, including all ten newly added feature tests. The former
four Windows cleanup failures are resolved; no error was suppressed or test
skipped. APK/iOS builds and remote workflow execution were outside this reduced,
source-only validation scope. Details: [windows-test-cleanup.md](windows-test-cleanup.md).

- [ ] Exercise 1–12 photo import, reorder, replacement, removal, reopen, templates
  and project archives; verify existing 1–6 photo behavior.
- [ ] Drag vertical/horizontal inner canvas dividers; verify minimum cell sizes,
  live updates, one undo step per gesture, redo, autosave and close/reopen.
- [ ] Compare edited preview with PNG/JPEG, gallery saves and social shares,
  including crop, rotation, flip, filters, text and stickers on 12 photos.
- [ ] Check unsupported layouts retain their appearance and do not switch
  geometry when attempting to enable divider mode.
- [ ] Run the manual iOS workflow on macOS CI. Its default unsigned archive needs
  no signing secrets and is not installable on an iPhone.
- [ ] When ready for distribution, configure the five signing secrets listed in
  [ios-ipa-builds.md](ios-ipa-builds.md), select a matching App Store/Ad Hoc profile,
  and verify installation through TestFlight or a registered test device.

Feature details: [twelve-photos-and-dividers.md](twelve-photos-and-dividers.md).
No local IPA build, signing-material handling or remote workflow run is part of
this Windows source-only feature pass.

## Gemeinsame Vorbereitung

- [ ] Verantwortlichen, Release-Datum und getesteten Git-Commit festhalten.
- [ ] `com.abalh101.piclayout` im eigenen Play-/Apple-Konto registrieren und die
  Verfügbarkeit bestätigen. Android namespace/applicationId und iOS Runner
  (Debug/Profile/Release) verwenden diese ID; RunnerTests nutzt `.RunnerTests`.
  Nach Erstveröffentlichung die Store-ID beibehalten. Der ID-Wechsel erzeugt
  gegenüber alten Beispiel-ID-Installationen eine neue App mit separaten Daten;
  benötigte Projekte vorher als `.piclayout` exportieren.
- [ ] Echte, betreute Support-Mailbox einrichten und in **jedem** Produktionsbuild
  `--dart-define=SUPPORT_EMAIL=...` übergeben. Im Repository ist keine echte Adresse
  vorhanden. Leere, ungültige und example.com/.org/.net-Adressen deaktivieren
  „Problem melden“. Der Wert ist öffentlich im App-Binary, kein Geheimnis.
- [ ] `pubspec.yaml` von aktuell `0.1.0+1` auf die gewünschte Store-Version setzen;
  Buildnummer für jeden Upload erhöhen. Optional `--build-name`/`--build-number`
  konsistent für beide Plattformen verwenden. Version im Einstellungsbildschirm
  und im Support-Entwurf kontrollieren.
- [ ] Mit Flutter **3.47.4 / Dart 3.13.3** (wie CI) `flutter pub get`,
  `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test` ausführen.
  `pubspec.lock` mitführen. CI läuft bei Push/PR und prüft Dart-Code; sie ersetzt
  keine nativen Builds oder echte Geräteprüfungen.
- [x] Windows-Dateisperren der Test-Aufräumroutinen beheben und die gesamte
  Testsuite ohne Fehler abschließen (134 Tests in beiden Läufen am 07.11.2026).

## Android: Signing und Build

- [ ] Android SDK/JDK einrichten, `flutter doctor -v` prüfen; offene Lizenzen lokal
  mit `flutter doctor --android-licenses` bearbeiten. Tatsächlich aufgelöste
  minSdk/targetSdk/compileSdk gegen die aktuellen Store-Anforderungen prüfen.
- [ ] Upload-Key außerhalb des Repositorys erzeugen oder vorhandenen verwenden.
  Beispiel für ein Terminal im eigenen Benutzerverzeichnis:

  ```text
  keytool -genkeypair -v -keystore piclayout-upload.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```

  Passwörter interaktiv eingeben, nicht als Kommandozeilenargument. Schlüssel,
  Passwörter und Wiederherstellungsinformationen geschützt sichern. Bei bestehender
  Store-App den zugehörigen Upload-Key verwenden; Play App Signing konfigurieren.
- [ ] `android/key.properties.example` nach `android/key.properties` kopieren und
  `storeFile`, `storePassword`, `keyAlias`, `keyPassword` lokal setzen. `storeFile`
  ist absolut oder relativ zu `android/`, auf Windows bevorzugt `C:/.../...jks`.
  Die Beispieldatei enthält absichtlich keine Werte. Echte Properties/Keystores
  sind ignoriert; keine Schlüssel oder Passwörter in Logs/CI-Artefakte aufnehmen.
  In einem späteren Release-CI-Job nur geschützte Secrets nutzen und temporäre
  Signing-Dateien nach dem Build entfernen; keine Secrets für PR-Jobs freigeben.
- [ ] Ohne vollständige Properties und existierenden Keystore muss ein Release
  mit verständlichem Signing-Fehler abbrechen. Kein Debug-Signing-Fallback;
  `androiddebugkey` wird ebenfalls abgelehnt. Debug-Builds benötigen keinen Key.
- [ ] Mit echter Support-Adresse bauen:

  ```text
  flutter build appbundle --release --dart-define=SUPPORT_EMAIL=<echte-Support-Adresse>
  flutter build apk --release --dart-define=SUPPORT_EMAIL=<echte-Support-Adresse>
  ```

  Winkelklammer-Ausdruck vor Ausführung ersetzen. AAB:
  `build/app/outputs/bundle/release/app-release.aab`; APK:
  `build/app/outputs/flutter-apk/app-release.apk`.
- [ ] APK mit `apksigner verify --verbose --print-certs` prüfen und Zertifikat mit
  dem eigenen Upload-Key vergleichen. AAB-Signatur ebenfalls prüfen; über Play
  Internal Testing das tatsächlich ausgelieferte Paket testen (R8/Release-Modus).
- [ ] Build-Warnungen zu KGP in `package_info_plus`/`share_plus` vor zukünftigen
  Flutter-Upgrades prüfen. Der aktuelle Pass führt keine Major-Migration ein.

## iOS: Signing und Build (macOS/Xcode)

- [ ] macOS, kompatibles Xcode und die benötigte Plugin-Paketverwaltung einrichten;
  `flutter pub get`, dann `ios/Runner.xcworkspace` öffnen. Native Integration der
  verwendeten Flutter-Version prüfen; CocoaPods nur falls das Setup es benötigt.
- [ ] Runner-Team, App-ID, Capabilities und Distribution-Provisioning konfigurieren.
  Zertifikate/Private Keys im Keychain bzw. geschütztem Secret-Speicher halten.
  Kein Team oder Zertifikat wird hier erfunden. RunnerTests separat prüfen.
- [ ] Bundle-ID, Anzeigename, Deployment Target, Buildnummer und Icons in Xcode
  prüfen. `Info.plist` bezieht die ID aus `PRODUCT_BUNDLE_IDENTIFIER` und Versionen
  aus `FLUTTER_BUILD_NAME`/`FLUTTER_BUILD_NUMBER`.
- [ ] `flutter build ipa --release --dart-define=SUPPORT_EMAIL=<echte-Support-Adresse>`
  ausführen; Platzhalter vorher ersetzen. Archiv in `build/ios/archive`, IPA in
  `build/ios/ipa`. In Xcode Organizer validieren, nach App Store Connect hochladen
  und per TestFlight auf iPhone und iPad prüfen.

## Store Assets und Privacy

- [ ] Vorhandene Icons aus `assets/branding` bzw. Plattform-Assets visuell prüfen;
  bei Änderungen `tool/generate_icons.py` verwenden. Screenshots für reale
  Geräte/Sprachen, Android Feature Graphic, Beschreibung, Kategorien,
  Altersfreigabe, Support-URL, Datenschutz-URL und Release Notes vorbereiten.
  Store-Screenshots und veröffentlichte URLs sind noch nicht im Projekt enthalten.
- [ ] Öffentliche Datenschutzerklärung mit tatsächlichem Betreiber und Kontakt
  veröffentlichen; lokale Projekt-/Fotoverarbeitung, Galerie-Speicherung,
  nutzerinitiierte Weitergabe an andere Apps und Support-E-Mail erklären.
  Betriebssystem-Backups und Verhalten der Ziel-Apps berücksichtigen.
- [ ] Play Data Safety und App Store App Privacy anhand des finalen Binaries,
  aller SDKs und des tatsächlichen Betriebs ausfüllen. Die lokale App-Notiz ersetzt
  weder diese Angaben noch eine öffentliche Datenschutzerklärung.
- [ ] iOS Foto-Purpose-Strings (`NSPhotoLibraryUsageDescription`,
  `NSPhotoLibraryAddUsageDescription`) für alle unterstützten Store-Sprachen
  prüfen/lokalisieren; derzeit sind sie deutsch. Privacy-Manifeste/Required Reason
  APIs der App und Plugins im Xcode-Archiv prüfen und zutreffend ergänzen.
- [ ] Android-Permissions im zusammengeführten Release-Manifest prüfen:
  WRITE_EXTERNAL_STORAGE nur bis API 28, MediaStore ab API 29, FileProvider nicht
  exportiert und URI-Freigabe funktionierend; keine unnötigen Berechtigungen.

## Testgeräte und Regressionen

- [ ] Freie Collage: 20 unterschiedliche hochauflösende JPEG/HEIC-Fotos auf
  echten Android-/iOS-Geräten in Profile/Release prüfen: Speicher, Bildrate,
  wiederholter PNG/JPEG-Export, Hintergrund/Resume und Ressourcenfreigabe.
  Emulator-Messung und automatisierte Prüfungen stehen in
  [freeform-collage.md](freeform-collage.md).
- [ ] Rahmen-/Crop-Gesten, Rotation, Sperren, Platzhalter, spätere Fotoauswahl,
  Vorlagenzuordnung, Archive und fehlende Dateien prüfen. TalkBack/VoiceOver,
  kleine Displays, große Schrift und RTL auch mit nativer Tastatur testen.

- [ ] Mindestens echtes Android auf aktuellem und niedrigstem unterstützten OS,
  Android 9/API 28 (falls unterstützt), Android 10+/API 29+, iPhone und iPad testen.
  Modell/OS/Buildnummer/Ergebnis protokollieren. Emulatoren ergänzen diese Tests.
- [ ] Gallery Save: PNG/JPEG, Transparenz, Text/Sticker, genaue Pixelmaße, wiederholtes
  Speichern, Galerie-Sichtbarkeit und Wiederöffnen; Berechtigung erlaubt/abgelehnt,
  später in Einstellungen geändert, voller/unverfügbarer Speicher. iOS add-only.
- [ ] Social Share: Instagram Story/Post, Snapchat, TikTok/Reels, WhatsApp Status,
  Facebook, Other App und allgemeines Teilen mit Ziel-App installiert/fehlend;
  Android URI-Leserechte und Fallback, iOS Share Sheet/iPad-Popover, Abbruch und
  tatsächlicher Import. Das Ziel entscheidet über Story/Status und Veröffentlichung;
  PicLayout garantiert keinen direkten Upload. Auch `.piclayout`-Archive übertragen
  und danach auf beiden Plattformen erneut importieren.
- [ ] 1–12 Fotos, große JPEG/HEIC-Dateien, Rotation/Spiegelung/Fit/Fill,
  zwölf hochauflösende Fotos und wiederholte Exporte auf Speicher/Jank prüfen.
  Eigene Formate einschließlich 21:9, gespeicherte Formate nach Neustart und
  Fill-Crop-Grenzen bei Zoom, Drehung und Spiegelung prüfen. Fit darf bewusst
  freie Flächen zeigen; Fill muss die Fotozelle vollständig bedecken.
- [ ] Projekt-Neustart, Autosave, Undo/Redo, Vorlagen, eigene Layouts, Sticker,
  Onboarding/Demos, RTL, alle sechs Sprachen, Dark Mode, große Schrift,
  Querformat, kleine Displays und Screenreader prüfen.
- [ ] Support-Mail mit/ohne Mail-App, kopierte Adresse und Sonderzeichen testen.
  Schnelle Export-Taps, Hintergrund/Resume und Abbruch während Export testen.

## Bewusst verbleibende Release-TODOs

Produktions-Signing, echte Support-Mailbox, Store-Konten/ID-Registrierung,
öffentliche Privacy-/Support-URLs, Store Assets, lokalisierte iOS-Purpose-Strings,
Privacy-Manifest-Prüfung, finale App-Version sowie signierte Release- und echte
Gerätetests müssen vom Betreiber abgeschlossen werden. Schärfen ist nicht
implementiert und darf nicht als verfügbar beworben werden. Demo-Bilder,
Preset-Namen und Beispiel-Archivmanifest sind absichtliche Produkt-/Dokubeispiele.
Storyboard-First-Responder-Platzhalter und CFBundleSignature `????` sind Xcode-
Standardwerte, keine fehlenden App-Konfigurationswerte.

Offizielle Build-Schritte: [Flutter Android Release](https://docs.flutter.dev/deployment/android),
[Flutter iOS Release](https://docs.flutter.dev/deployment/ios).
Privacy-Manifest-Prüfung: [Apple-Dokumentation](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk).
