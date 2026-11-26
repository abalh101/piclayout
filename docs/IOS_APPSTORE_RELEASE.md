# Release PicLayout on the Apple App Store

PicLayout uses the existing bundle ID `com.abalh101.piclayout` and targets iPhone and iPad on iOS/iPadOS 15.0 or later. The first store version is `1.0.0` with build `1`, if that number is still unused. Use Photo & Video and English (U.S.) as the primary category and locale.

GitHub Actions runs Xcode 26.5 on the ARM64 `macos-26` image with Flutter 3.47.5 and the iOS 26-series SDK. Apple requires Xcode 26 and the iOS 26 SDK or later for uploads. Apple’s separate minimum deployment target is iOS 13, and PicLayout targets iOS 15. Runner uses the checked-in workspace, shared scheme, scene lifecycle, and Flutter SwiftPM integration. No CocoaPods setup is needed with the current plugin set. [Apple submission requirements](https://developer.apple.com/news/upcoming-requirements/), [GitHub runner software](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md), [Flutter SwiftPM guide](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers).

You can complete the web portal, OpenSSL, and GitHub steps on Linux. The GitHub macOS jobs handle Xcode compilation, Simulator, signing, validation, and optional upload. Use physical iPhone and iPad hardware for TestFlight verification. The repository contains no Apple credentials.

## 1. Register or confirm the Bundle ID

1. Sign in to [Apple Developer](https://developer.apple.com/account/) as a member of the correct team and record the 10-character Team ID from Membership Details. Confirm enrollment in the Apple Developer Program.
2. Go to **Certificates, Identifiers & Profiles → Identifiers** and search for `com.abalh101.piclayout`. Reuse the existing explicit ID if your team owns it.
3. If the ID is available, choose **+ → App IDs → App**, enter **PicLayout**, select **Explicit**, then enter `com.abalh101.piclayout`. Leave optional capabilities off for this release. Photos, the picker, and the share sheet do not require additional app entitlements.
4. If your team already has a production ID for PicLayout that differs from the repository default, use that same ID for the app record and provisioning profile. Set the GitHub variable `IOS_BUNDLE_ID` to it. The default lives in `ios/Flutter/AppIdentity.xcconfig`. For local macOS builds, the ignored `ios/Flutter/LocalIdentity.xcconfig` can set `PICLAYOUT_BUNDLE_ID = your.registered.identifier`.

## 2. Create the record in App Store Connect

In [App Store Connect](https://appstoreconnect.apple.com/), go to **Apps → + → New App**. Select iOS, name **PicLayout**, primary language **English (U.S.)**, the matching Bundle ID, and an internal SKU such as `piclayout-ios`. Reuse an existing record for the same ID. Set the primary category to **Photo & Video** under **App Information**. Confirm name availability and the publisher information with Apple. [Create an app record](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app).

## 3. Prepare an Apple Distribution certificate and private key

If you have a current Apple Distribution `.p12` for the correct team with its matching private key and password, reuse it. The downloaded `.cer` alone contains no private key. If creating a new pair, run the following on Linux outside the repository. Use a private directory and keep a protected backup.

```bash
umask 077
mkdir -p "$HOME/piclayout-signing"
cd "$HOME/piclayout-signing"
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -aes-256-cbc -out distribution.key
openssl req -new -key distribution.key -out PicLayout.certSigningRequest
```

Enter your actual certificate request identity when OpenSSL prompts. In **Apple Developer → Certificates → +**, select **Apple Distribution**, upload `PicLayout.certSigningRequest`, and download the resulting certificate as `distribution.cer`. Then run:

```bash
openssl x509 -inform DER -in distribution.cer -out distribution.pem
openssl x509 -in distribution.pem -noout -subject -issuer -enddate
cmp <(openssl pkey -in distribution.key -pubout) \
    <(openssl x509 -in distribution.pem -pubkey -noout)
openssl pkcs12 -export -inkey distribution.key -in distribution.pem \
  -out PicLayout-Distribution.p12 \
  -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
```

Use a nonempty export password and store it securely. The PKCS#12 flags support macOS Keychain import. If certificate trust fails, check that the runner trusts the Apple WWDR G3 intermediate and that the certificate is current. You can include the official G3 intermediate in your PKCS#12 by downloading it from Apple PKI, converting it with `openssl x509 -inform DER -in AppleWWDRCAG3.cer -out AppleWWDRCAG3.pem`, and adding `-certfile AppleWWDRCAG3.pem` to the export command. [Apple WWDR intermediates](https://developer.apple.com/help/account/certificates/wwdr-intermediate-certificates/), [Apple PKI](https://www.apple.com/certificateauthority/).

## 4. Create the provisioning profile

In **Apple Developer → Profiles → +**, choose **App Store Connect** under Distribution. Select the exact explicit Bundle ID, then the same Apple Distribution certificate used in the PKCS#12. Name it **PicLayout App Store**, generate it, and download it as `PicLayout-AppStore.mobileprovision` into your private directory. App Store profiles are for App Store Connect and TestFlight distribution. The CI check compares the app ID, team, profile type, expiry and certificate fingerprint. [Create an App Store provisioning profile](https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile).

Encode both files using GNU Base64 on Linux.

```bash
cd "$HOME/piclayout-signing"
umask 077
base64 -w0 PicLayout-Distribution.p12 > PicLayout-Distribution.p12.base64
base64 -w0 PicLayout-AppStore.mobileprovision > PicLayout-AppStore.mobileprovision.base64
```

The Base64 files contain the same sensitive material as the originals. Keep signing material outside the source tree and out of logs and artifacts.

## 5. Prepare App Store Connect upload authentication

This step is needed only when you enable workflow upload. In **App Store Connect → Users and Access → Integrations → App Store Connect API → Team Keys**, request API access if your account requires it. Create a team key authorized to upload builds. Use the least role your account allows for the task, normally **Developer** for build upload. Record the Key ID and Issuer ID and download `AuthKey_<KEY_ID>.p8` once. Keep the complete key including both PEM marker lines. An App Store Connect API key authenticates upload. The distribution certificate, private key, and profile perform code signing. [App Store Connect API keys](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api/), [Apple build upload roles and tools](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/).

### Reuse signing assets from SalahTrack

- **Apple Distribution.** A current certificate and matching private key can sign PicLayout if both apps use the same Apple Developer Team. Reuse the original password-protected PKCS#12. Select that certificate when generating PicLayout's own App Store Connect provisioning profile for `com.abalh101.piclayout`. Check the Team ID and expiry before copying settings. [Apple certificate overview](https://developer.apple.com/help/account/certificates/certificates-overview/).
- **App Store Connect API.** An active SalahTrack team key can upload PicLayout builds if it belongs to the same App Store Connect account and has an upload role such as Developer. Reuse its Key ID, Issuer ID and original private key as a set. The workflow requires an issuer-based team key. [Apple API key types](https://developer.apple.com/documentation/AppStoreConnectAPI/creating-api-keys-for-app-store-connect-api).
- **Secret names.** Where SalahTrack uses `IOS_CERTIFICATE_BASE64` and `IOS_CERTIFICATE_PASSWORD`, the PicLayout names are `IOS_DISTRIBUTION_CERTIFICATE_BASE64` and `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`. SalahTrack's `APP_STORE_CONNECT_KEY_ID` maps to `APP_STORE_CONNECT_API_KEY_ID`. Put the original multiline `.p8` in `APP_STORE_CONNECT_API_PRIVATE_KEY`. If the value in protected storage is the Base64 form used for `APP_STORE_CONNECT_API_KEY_BASE64`, decode it privately before setting the PicLayout secret. Use your protected copies of the credentials and use a separate temporary keychain password.

## 6. Complete the privacy and support pages

Fill in `[PUBLISHER LEGAL NAME AND CONTACT ADDRESS]` and `[PUBLIC SUPPORT AND PRIVACY EMAIL]` in [English privacy](privacy/index.html), [German privacy](privacy/de.html), and [support](support/index.html). Provide a working public email link, actual publisher/contact details, and any retention or other information required for your support process and territories. Check both policy versions for consistency. Remove the `noindex` tag when ready for public indexing.

After your explicit decision to publish, use **GitHub → Repository → Settings → Pages → Build and deployment → Deploy from a branch → main → /docs → Save**. The checked-in `.nojekyll` serves the static HTML as written. Confirm that the hosting plan and repository visibility support Pages. For the default project URL, the expected paths are below. Confirm the actual host under **Settings → Pages** and verify each page in an unauthenticated browser. [GitHub Pages source configuration](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).

| Page | Default project hosting pattern |
| --- | --- |
| English privacy | `https://abalh101.github.io/piclayout/privacy/` |
| German privacy | `https://abalh101.github.io/piclayout/privacy/de.html` |
| Support | `https://abalh101.github.io/piclayout/support/` |

For another host, adjust the hosting paragraph in both policies, then use the actual HTTPS URLs. Before signing, CI checks that both variables load public PicLayout HTML policies and that the published pages have real contact details in place of the template markers. Confirm that the support mailbox is monitored and that the separate support page works. Preview locally from Linux with `python3 -m http.server 8000 --bind 127.0.0.1 --directory docs`, then visit `http://127.0.0.1:8000/`.

## 7. Add the GitHub Actions configuration

In **Repository → Settings → Secrets and variables → Actions**, use **New repository secret** or **New repository variable** in the corresponding tab. Restrict write access to trusted maintainers. The iOS workflows pin GitHub Actions to reviewed commit SHAs.

| Setting | Where | Value |
| --- | --- | --- |
| `APPLE_TEAM_ID` | Secret | The Apple Developer 10-character team identifier. |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Secret | Contents of `PicLayout-Distribution.p12.base64`. |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Secret | Password used to export the `.p12`. |
| `IOS_PROVISIONING_PROFILE_BASE64` | Secret | Contents of `PicLayout-AppStore.mobileprovision.base64`. |
| `KEYCHAIN_PASSWORD` | Secret | A new random password for the runner keychain. Generate one with `openssl rand -hex 32` in a private terminal. |
| `APP_STORE_CONNECT_API_KEY_ID` | Secret, upload only | Team API Key ID. |
| `APP_STORE_CONNECT_ISSUER_ID` | Secret, upload only | Team API Issuer ID. |
| `APP_STORE_CONNECT_API_PRIVATE_KEY` | Secret, upload only | Complete multiline contents of `AuthKey_<KEY_ID>.p8`. |
| `IOS_BUNDLE_ID` | Variable, optional | Leave unset for `com.abalh101.piclayout`. Supply a different value only for your existing production record. |
| `SUPPORT_EMAIL` | Variable | Actual public support mailbox. |
| `PRIVACY_POLICY_URL` | Variable | Published English HTTPS privacy policy. |
| `PRIVACY_POLICY_URL_DE` | Variable | Published German HTTPS privacy policy. |
| `marketing_version` | Workflow input | Three numeric segments, initially `1.0.0`. |
| `build_number` | Workflow input | An unused positive integer from 1 to 9999, initially `1`. |
| `upload_to_app_store_connect` | Workflow input | Unchecked by default. Check only when you intend to send the build to Apple. |

If you had configured the retired `ios-ipa.yml` template, migrate its values as follows. `IOS_TEAM_ID` becomes `APPLE_TEAM_ID`, `IOS_CERTIFICATE_BASE64` becomes `IOS_DISTRIBUTION_CERTIFICATE_BASE64`, `IOS_CERTIFICATE_PASSWORD` becomes `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`, and `IOS_KEYCHAIN_PASSWORD` becomes `KEYCHAIN_PASSWORD`. `IOS_PROVISIONING_PROFILE_BASE64` keeps its name. Use original files or your password manager to populate the current Secrets.

From Linux with an authorized GitHub CLI login, the file-based secret commands below pass values over stdin. Use the repository UI for the remaining secrets and variables.

```bash
gh secret set IOS_DISTRIBUTION_CERTIFICATE_BASE64 --repo abalh101/piclayout < PicLayout-Distribution.p12.base64
gh secret set IOS_PROVISIONING_PROFILE_BASE64 --repo abalh101/piclayout < PicLayout-AppStore.mobileprovision.base64
gh secret set APP_STORE_CONNECT_API_PRIVATE_KEY --repo abalh101/piclayout < AuthKey_YOUR_KEY_ID.p8
```

Replace the last filename with your actual downloaded filename before running it. Repository variable values are public build configuration. Keep certificates, keys, profiles and passwords in protected storage.

## 8. Run unsigned validation and screenshots

After the workflow files are available on the default branch, go to **Actions → iOS validation → Run workflow → main**. The same job runs for pushes to `main` and relevant pull requests. It runs Flutter checks, compiles an unsigned iPhoneOS archive, builds a Simulator app, and inspects both products. The Simulator tests cover app startup, editor exports, and native saving to Photos with add-only permission. GitHub saves `PicLayout-unsigned-xcarchive` as a diagnostic artifact. It contains an unsigned Xcode archive ZIP.

Run **Actions → iOS App Store screenshots** to produce iPhone and iPad assets in English, German and Arabic. Use [the screenshot checklist](../appstore/screenshots-checklist.md) to inspect them and reproduce individual scenes. Both jobs run without Apple credentials.

## 9. Produce and inspect the first signed IPA

1. Confirm the validation job passes and the app record, configuration values and signing files are ready.
2. Go to **Actions → iOS App Store release → Run workflow**. Select **main**. Enter `1.0.0` for marketing version and `1` for build number if Apple has not accepted it. Leave upload unchecked. Choose **Run workflow**.
3. Inspect the **Verify App Store IPA** step. The job verifies both code signatures and validates the archive and IPA bundles, arm64 device executable, package integrity and code signature, correct version, distribution entitlements, localized usage text and packaged privacy manifests.
4. Download **PicLayout-AppStore-1.0.0-1** from the run’s **Artifacts**. Extract the zip to obtain the signed `.ipa`. The artifact is retained for seven days. Install through TestFlight after Apple processes an upload.

Optional Linux CLI dispatch and download, after the owner decides to run the workflows.

```bash
gh workflow run ios-appstore-release.yml --ref main \
  -f marketing_version=1.0.0 -f build_number=1 -f upload_to_app_store_connect=false
gh run list --workflow ios-appstore-release.yml --limit 5
gh run watch RUN_ID --exit-status
gh run download RUN_ID -n PicLayout-AppStore-1.0.0-1
```

Use the actual numeric run ID. The macOS job uses an ephemeral keychain, profile and signing configuration, then removes them. The export sets `testFlightInternalTestingOnly` and `manageAppVersionAndBuildNumber` to false. Check the exported build number in App Store Connect and confirm that Apple does not mark the build as internal-only. If code signing reports a mismatch, check the portal App ID, profile’s certificate selection and expiration, and certificate private key/password. If the signing step passes but archive export fails, inspect the Xcode output and confirm the same profile is available to Runner for Release.

## 10. Upload to Apple from Linux through CI

After artifact-only validation, reopen **iOS App Store release** on the same release revision, enter `1.0.0` and `1` if it remains unused, enable **Validate with Apple and upload to App Store Connect**, and run it. This builds and validates another IPA from the selected revision and version, then uses Xcode’s `xcrun altool` with the team key to validate and upload it. Check the branch’s selected commit before dispatch. The workflow ends with binary delivery. App Review submission and release are owner actions. [Apple supported upload tools](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/), [Apple altool key location](https://help.apple.com/asc/appsaltool/en.lproj/static.html).

If you have access to a Mac, you can instead upload the previously downloaded artifact itself with Apple Transporter. Reserve the next build number for each new accepted binary. If delivery times out, check **App Store Connect → TestFlight → Builds** and Apple’s processing email before retrying to avoid a duplicate build number.

## 11. TestFlight and App Store Connect setup

1. **TestFlight.** In **Apps → PicLayout → TestFlight → Builds → iOS**, wait for processing and resolve export compliance if prompted. Under **Internal Testing**, use **+** to create a group and add eligible App Store Connect users. Select the processed build, use **+** next to **Groups**, and add the group. Testers accept the invitation and install the build in the TestFlight app on iPhone and iPad. Check the [device matrix](../appstore/release-checklist.md). External testing may require Apple’s beta review. [Add testers to builds](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-testers-to-builds/).
2. **App Privacy.** Go to **Apps → PicLayout → App Privacy**. Add the HTTPS privacy URLs and complete/publish the label after reviewing [the privacy evidence](../appstore/app-privacy.md). Read any manifest warnings Apple reports during processing.
3. **App Information.** Enter localized app names and subtitles, primary category, Content Rights, Age Rating, and copyright. Use [the age rating and compliance notes](../appstore/age-rating.md). Under Business or the applicable compliance page, enter EU trader information if applicable. Verify availability, pricing, and storefront requirements.
4. **Version page.** Add descriptions, keywords, promotional text, support URL, and the reviewed screenshots per locale from [appstore/](../appstore/). Start with English (U.S.) and German, then add Arabic, Türkçe, French (France), and Spanish (Spain). Use the English policy URL for locales without a translated policy. Apple does not show a What’s New field for the first version. The localized `release-notes.txt` files document the initial release for your records. [App Store Connect version fields](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).
5. **Review Information.** Enter your real contact name, email and international-format telephone number. Leave sign-in required off. Paste [review-notes.txt](../appstore/review-notes.txt) and make sure its demo path works on the submitted build.
6. **Confirm the build.** Select the same processed `1.0.0 (1)` build you approved in TestFlight in the version’s Build section. App Store Connect uses one upload for testing and the public release. Check export compliance, screenshots, support and privacy URLs, and metadata. Choose the manual release option.
7. **Submit and release manually.** Select **Add for Review**, then **Submit for Review** in the review submission section when ready. After Apple approves the app, choose **Release This Version** when you intend to publish. [Apple submission instructions](https://developer.apple.com/app-store/submitting/).

## 12. Future updates

Use the existing `main` workflow and the same registered app identity. Change `version:` in `pubspec.yaml` when the source defaults should reflect a new release. Dispatch inputs override the iOS build version without changing Android signing. Keep a record of accepted builds in App Store Connect and increment the build number for retry binaries and subsequent updates. Renew distribution material before expiration, rotate API keys if necessary, and run unsigned validation, archive checks, TestFlight, and device QA again for each release. For updates, enter the actual changes in What’s New for each locale.
