# Campus Companion — Flutter source

This is the cross-platform Flutter application source for Android and iOS.

## Build native platform folders
Flutter SDK is required. From this directory run:

```bash
flutter create --platforms=android,ios .
flutter pub get
```

Then:
- Android: `flutter run` or `flutter build apk`
- iOS: on macOS with Xcode installed, `flutter run` or `flutter build ios`

An iOS `.ipa` cannot be built on Windows; Apple signing and Xcode on macOS are required.

## Included
- Timetable parsed from `Updated Final MTT SEM I 26-27.xlsx`, Table 3.
- Division A–R and batch 1–3 selectors.
- Batch-tagged `-1/-2/-3` entries are assigned only to their matching batch.
- Unsuffixed subjects are treated as common to all three batches.
- Empty intervals are rendered as FREE.
- Reminder lead time is an integer from 0 to 20 minutes.
- One voice preview using the device's default English text-to-speech voice.
- Weekly local notifications for every class across Monday–Friday, using the selected division and batch.

## Important source-data rule
The workbook does not explain every ambiguous or malformed combined cell. This app preserves the source text in the embedded data and parses slash-separated subject/faculty/room lists by matching positions. Please review the few irregular source cells before publishing. Native voice availability depends on voices installed on each phone; the app cannot guarantee three voices on every device.

## Reminder behaviour
Tap **Enable weekly lecture reminders** after choosing your division and batch. The app schedules repeating notifications for all classes Monday–Friday, using the selected 0–20 minute lead time. Changing division, batch, or lead time and tapping the button again replaces the previously scheduled reminders. The schedule uses the PCCOE local timezone (Asia/Kolkata). Notifications are system notifications; they can appear while the app is closed, subject to OS permissions and battery/background restrictions. The single voice preview is an in-app TTS preview and is not claimed to speak while the app is closed.


## Build an Android APK without a PC (GitHub Actions)
This source bundle is prepared for a cloud build from a phone:
1. Create a GitHub repository in your mobile browser.
2. Upload `Campus_Companion_Flutter_Source_Fixed.zip` to the repository root.
3. Create `.github/workflows/build-apk.yml` in the repository and paste the contents of the companion `build-apk.yml` file supplied with this bundle.
4. Open the repository's Actions tab, choose **Build Campus Companion APK**, and tap **Run workflow**.
5. When the workflow finishes successfully, open its run, scroll to **Artifacts**, and download `campus-companion-android-apk`.
6. Extract the artifact ZIP on your Android phone and tap `app-release.apk` to install it.

The cloud workflow generates the Android platform project, configures scheduled-notification receivers and builds the APK. The workflow compiles the release APK; compilation errors stop the build.

No Android signing key is included. GitHub Actions produces a build suitable for direct testing/sideloading; a Play Store release requires a separately managed signing/release process.
