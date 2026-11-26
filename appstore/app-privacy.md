# App Privacy and iOS manifest

## Source and dependency audit

| Scope | Finding |
| --- | --- |
| Photo picker and editing | The iOS picker stages only user-selected assets, one file at a time. The editor copies selected assets into its sandbox. Photo adjustment, preview, layout ranking, and export run locally. |
| Local persistence | Projects, backup snapshots, photos, preferences, onboarding state, and designs use app-sandbox files. Recent exports use file timestamps for cleanup. Project deletion and cache clearing are user-controlled. iOS backup settings govern eligible OS backups. |
| Photo authorization | Photos saving asks for add-only authorization. The system photo picker supplies selections without requesting broad library access. The localized read purpose string covers linked `image_picker_ios` Photos APIs. No camera, microphone, location, tracking permission, social scheme probes, or custom entitlements are configured. |
| Files and sharing | The iOS Files plugin imports a local copy. Images and archives are handed to Apple’s share sheet as file URLs. Sharing is initiated by the user. An external destination controls further transfer and storage. |
| External links | Settings opens the published privacy page in the browser and opens an editable mail draft for issue reports. The draft includes the app version and generic platform information. The app does not send it. |
| Dependency inventory | The pinned iOS native packages are `file_selector_ios 0.5.3+6`, `image_picker_ios 0.8.13+9`, `package_info_plus 9.0.1`, `share_plus 10.1.4`, and `url_launcher_ios 6.4.2`. Their source manifests report no collection or tracking. Dart FFI `path_provider_foundation 2.6.0` resolves system directory locations. The Dart image, ZIP, state, and identifier dependencies operate on local data. `integration_test` is a dev dependency. |
| Flutter engine | Its own `Flutter.framework` manifest includes file timestamp reasons `0A2A.1` and `C617.1`, and boot time reason `35F9.1`. Retain the SDK manifests in the archive. |
| Runner | `ios/Runner/PrivacyInfo.xcprivacy` declares no tracking or collected data, and file timestamp reason `C617.1` for app-container file metadata, including export retention. Source review found no app-level UserDefaults, disk space polling, boot-time measurement, or active-keyboard access. |

The unsigned and signed CI jobs check the built bundle for the Runner manifest, the Flutter engine manifest, and the SwiftPM plugin manifests. Check the Xcode privacy report when a Mac is available and inspect Apple’s build processing messages. Re-audit when upgrading Flutter, native assets, or plugins. [Required reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons), [SDK manifest requirements](https://developer.apple.com/support/third-party-SDK-requirements/).

## Owner confirmation in App Store Connect

- **Data collection.** Source review supports a proposed **Data Not Collected** label for the shipped app’s editor with the audited dependencies and no added services. Confirm the final bundle, every partner, and the support process before choosing it. Apple treats data collection as off-device transmission accessible beyond the time needed to service a request. Consider Apple’s optional disclosure criteria for infrequent, affirmative support contact. If the actual process or an integrated service falls outside those criteria, disclose the applicable contact, user content, and diagnostic types for the relevant purposes. [Apple App Privacy details](https://developer.apple.com/app-store/app-privacy-details/).
- **Tracking.** The reviewed app has no tracking, analytics, ads, tracking domains, or tracking permission. Confirm the release binary and the actual support/website configuration before declaring. The website and support correspondence are explained separately in the policy.
- **Policy URLs.** Provide the English HTTPS privacy page and the German variant for German metadata. The policy must also be reachable from Settings → Privacy in the signed build. Confirm the publisher identity, contact details, retention terms and any jurisdiction-specific obligations before making the pages public. [App Review Guidelines §5.1.1](https://developer.apple.com/app-store/review/guidelines/#privacy).
