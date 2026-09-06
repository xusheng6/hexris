# App Store submission

## Binary

- Display name: Hexris
- Bundle identifier: `com.hexris.hexris`
- Version: `1.0.2`
- Build: `3`
- Minimum iOS version: `13.0`
- Devices: iPhone and iPad
- Encryption declaration: no non-exempt encryption
- Signing team: `S43CW2YD69`

Build with:

```bash
flutter analyze
flutter test
flutter build ipa --release
```

Artifacts are produced at:

- `build/ios/archive/Runner.xcarchive`
- `build/ios/ipa/hexris.ipa`

The exported IPA uses an Apple Distribution certificate and an Xcode-managed
App Store provisioning profile. Upload it with Xcode Organizer or Transporter.

## App Store Connect checklist

Binary preparation does not create or complete the App Store Connect product
page. Before submission, confirm the following in App Store Connect:

- The app record uses bundle ID `com.hexris.hexris`.
- Version `1.0.2` exists and build `3` has finished processing.
- App name, subtitle, description, keywords, support URL, and privacy-policy URL
  are complete.
- Current iPhone and iPad screenshots are uploaded for every required display
  class.
- The updated age-rating questionnaire is complete.
- App Privacy answers accurately state that the app has no tracking and reflect
  any diagnostics collected by the final distribution configuration.
- Pricing, availability, category, content rights, and review contact details
  are complete.
- Export-compliance questions match `ITSAppUsesNonExemptEncryption = false`.
- The latest developer agreements are accepted.

Do not reuse build number `3` after uploading it. Increment the build component
in `pubspec.yaml` for every subsequent upload.
