# iOS archive and IPA workflow template

`.github/workflows/ios-ipa.yml` is manual-only (`workflow_dispatch`) and runs on
GitHub-hosted macOS. It runs `flutter pub get`, the Dart format check,
`flutter analyze`, and `flutter test` before building. Nothing is submitted to
Apple automatically. No signing files, secrets, or generated artifacts are stored
in the repository. This template has not been executed against an Apple account.

## Use without signing secrets

No Apple secrets are needed now. After this workflow is available on your
repository's default branch, open **Actions → iOS IPA template → Run workflow**
and leave **signed** unchecked. The job runs
`flutter build ipa --release --no-codesign` and uploads the compressed Xcode
archive as **PicLayout-unsigned-archive-NOT-INSTALLABLE**. Download it from the
run's **Artifacts** section. It is an archive for later signing on a Mac; it is
not an IPA and cannot be installed on an iPhone.

Local iOS builds are unavailable on this Windows workspace: Flutter's iOS build
requires macOS and Xcode. No certificate/profile/key has been read, changed,
printed, installed, or uploaded as part of this implementation.

## Optional future signed builds

For a signed installable/distributable IPA, first enroll in the Apple Developer
Program and register the explicit App ID **com.abalh101.piclayout**. Prepare a
matching **Apple Distribution** certificate with its private key, exported as a
password-protected PKCS#12 file, and a current distribution provisioning profile.
Configure the following under **Settings → Secrets and variables → Actions →
Repository secrets** when you are ready; do not put any values in source control.

| Exact secret name | Required value |
| --- | --- |
| `IOS_CERTIFICATE_BASE64` | Base64 contents of the Apple Distribution `.p12`, including its private key. |
| `IOS_CERTIFICATE_PASSWORD` | The nonempty password used to protect that `.p12`. |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64 contents of the matching `.mobileprovision`. |
| `IOS_KEYCHAIN_PASSWORD` | A strong, nonempty random password for the temporary CI keychain. |
| `IOS_TEAM_ID` | The 10-character Apple Developer Team ID owning the certificate, profile and App ID. |

Also set the public repository **variable** `SUPPORT_EMAIL` to your real support
address before a production release; it is not a signing secret. Without it,
PicLayout disables its email support action. Update `version: ...+...` in
`pubspec.yaml` before each App Store Connect upload; every upload needs a new build
number. Store assets, privacy declarations and device testing still follow
[release-checklist.md](release-checklist.md).

When ready, run the workflow with **signed** checked on a trusted branch/ref:

- **app-store-connect:** use an App Store distribution provisioning profile.
  The artifact is for upload to App Store Connect and TestFlight/App Store
  distribution. It cannot be installed directly by copying it to an iPhone.
- **release-testing:** use an Ad Hoc distribution profile containing the UDIDs
  of all intended iPhones. Direct installation works only on those registered
  devices while the signing certificate/profile remain valid.

The signed template checks missing secrets with a clear error, validates profile
team, App ID, expiry and distribution type, installs signing material in a
temporary runner keychain, sets manual signing for Runner only in the disposable
checkout, and runs `flutter build ipa --release --export-options-plist=...`.
It uploads only `build/ios/ipa/*.ipa`, then cleans up its temporary signing files.
Enterprise and development profiles are outside this template's scope.
Certificate/profile compatibility is ultimately validated by Xcode.

## Download and install later

1. Open a successful signed workflow run in **Actions**.
2. Download **PicLayout-signed-ipa** from **Artifacts** within seven days.
3. Unzip the downloaded artifact to obtain the `.ipa` file.
4. For **release-testing**, connect a registered iPhone to a Mac and install the
   IPA through Xcode's **Window → Devices and Simulators → Installed Apps (+)**
   or Apple Configurator. The device must be included in the Ad Hoc profile.
5. For **app-store-connect**, upload the IPA using Apple's Transporter on a Mac,
   wait for processing, assign testers in App Store Connect, and install through
   the TestFlight app. Upload authentication uses your Apple account and is
   separate from this workflow; no App Store Connect API key is required merely
   to build/download the artifact.

A downloadable `.ipa` is only installable on real iPhones when it is signed for
the correct distribution method and profile, or delivered through TestFlight.
Downloading a GitHub artifact does not bypass Apple's signing rules.

References: [Flutter iOS release guide](https://docs.flutter.dev/deployment/ios),
[GitHub macOS signing guidance](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications),
[Apple distribution guidance](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases).
