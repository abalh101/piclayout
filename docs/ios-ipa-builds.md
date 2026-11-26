# PicLayout iOS builds

The current workflows are [iOS validation](../.github/workflows/ios-validation.yml), [iOS App Store release](../.github/workflows/ios-appstore-release.yml), and [iOS App Store screenshots](../.github/workflows/ios-screenshots.yml).

See the [iOS App Store release guide](IOS_APPSTORE_RELEASE.md) for Apple registration, signing, the Linux GitHub Actions workflow, and TestFlight. The validation job runs on pushes to main and builds a downloadable diagnostic Xcode archive without Apple signing secrets. The archive is unsigned. The manual release job can produce an App Store distribution IPA and upload it to Apple when explicitly enabled.
