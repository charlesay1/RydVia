# Build and validation

Run from the repository root after dependency/tool setup:

```powershell
dart format --output=none --set-exit-if-changed packages apps/customer_app/lib apps/driver_app/lib apps/business_app/lib
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-flutter.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-tokens.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-platforms.ps1
npm run lint
npm run typecheck
npm test
npm run build
```

The Flutter script resolves, analyzes, and runs available tests for every shared
package and all three apps, failing immediately on errors. Dart-only packages use
Dart tooling; Flutter projects use Flutter tooling. Lockfiles are retained. CI
runs these checks plus a disposable Supabase stack and pgTAP suite. CI has not run
remotely because no source has been pushed. GitHub Actions versions are major-tag
references; pin reviewed action commit SHAs before enforcing a hardened release pipeline.

Android (requires Android SDK/JDK):

```powershell
cd apps/customer_app
flutter build apk --debug --dart-define-from-file=../../.env
```

Repeat for Driver and Business. Release signing is deliberately not configured;
the generated debug-key release fallback has been removed. Supply signing material
through untracked local configuration or CI secrets and validate it before release.

iOS/iPad on macOS with Xcode and signing:

```text
cd apps/customer_app
flutter pub get
flutter build ios --no-codesign --dart-define-from-file=../../.env
```

Then configure/review signing and archive through Xcode for distribution. Native
identity/XML checks on Windows do not compile Swift, plugins, storyboards, or an IPA.
AppIcon slots exist but approved icon artwork is absent; all template launcher
images were removed. Both platforms remain blocked for release until artwork,
signing, real-device secure storage, cold startup/theme behavior, and SMS flows pass.

Next.js production builds support `npm run start --workspace @rydvia/public-web`
and the corresponding Admin workspace. The public shell has server-rendered info
and legal routes. No Site, cloud hosting deployment, or remote repository push was
performed. A production build is not proof of browser or end-to-end readiness.
