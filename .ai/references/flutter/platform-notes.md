# Flutter — platform-specific notes

## Android

- Manifest at `android/app/src/main/AndroidManifest.xml`. Add `<uses-permission>` only when needed; `INTERNET` is enough for an HTTP-only app.
- Share-target intent filters live on `MainActivity` (`android.intent.action.SEND` / `SEND_MULTIPLE`).
- `applicationId` and `namespace` in `android/app/build.gradle`/`build.gradle.kts` use reverse-DNS (`ch.freaxnx01.<app>`).
- `compileOptions` and `kotlinOptions` target Java/Kotlin 17.
- Release signing: **never commit a keystore or `key.properties`**. Reference them via env-driven Gradle properties; default to debug-signed in dev as the scaffolded `buildTypes.release` does.
- `minSdk` / `targetSdk` come from `flutter.*` — do not hand-pin unless a plugin requires it.

## iOS

- Bundle ID set in Xcode (`Runner.xcodeproj`); keep it in sync with the Android `applicationId`.
- Permissions go in `ios/Runner/Info.plist` with `NSCameraUsageDescription`, etc. — every entry needs a human-readable purpose string or App Store review will reject.
- Dart-side code targets iOS through the same code path; only branch on `Platform.isIOS` / `defaultTargetPlatform == TargetPlatform.iOS` when behaviour genuinely differs.
- Building for iOS requires macOS + Xcode + a CocoaPods install (`cd ios && pod install`) after adding/upgrading plugins.

## Desktop (Windows / macOS / Linux)

- Confirm desktop support is enabled (`flutter config --enable-windows-desktop`, etc.) and the platform folder is committed.
- Some plugins are mobile-only — guard their use behind a platform check, e.g.:

  ```dart
  bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  ```

- Window size, title, and min size are configured in `windows/runner/main.cpp` and `linux/my_application.cc`.

## Web

- Only enable web support when actually shipping a web build — it adds wasm/JS interop pitfalls (no `dart:io`, `flutter_secure_storage` falls back to localStorage, etc.).
- `flutter build web --release` outputs to `build/web/`. Serve with proper cache headers.
