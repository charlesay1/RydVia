# Flutter CI formatting correction

The initial checkpoint is preserved at
`a86ab99817c2b123f8d9fcff32ed38decf3701dd`. Its first
[validation run](https://github.com/charlesay1/RydVia/actions/runs/39213170215)
passed web/database and local Supabase/pgTAP, but stopped Flutter before analysis/tests.

## Reproduction and cause

The failed command was:

```text
dart format --output=none --set-exit-if-changed packages apps/customer_app/lib apps/driver_app/lib apps/business_app/lib
```

A clean `git archive` snapshot without `.dart_tool` reproduced the exact thirteen
files and exit code 1. After offline dependency resolution for all twelve packages/apps,
the identical command passed: 35 files, zero changes, exit code 0. Neither check
rewrote source. The resolved working copy also passed an actual scoped formatter
run and its no-change check: 34 handwritten files, zero changes.

The packages declare Dart SDK constraints starting at 3.8. Resolution records
`languageVersion: 3.8` in package_config.json. The old workflow formatted before
resolution, so the formatter did not have that package language context. The same
local Dart 3.13.5 reproduced both outcomes, demonstrating an ordering/context issue
rather than requiring a formatter-version change or source reformat. Generated
tokens were not among the thirteen files; they already carry `dart format off`.

The thirteen files reported by CI and reproduced locally were:

```text
packages/rydvia_auth/lib/src/auth_controller.dart
packages/rydvia_auth/lib/src/mobile_app.dart
packages/rydvia_auth/lib/src/startup.dart
packages/rydvia_auth/lib/src/ui/home_screen.dart
packages/rydvia_auth/lib/src/ui/onboarding_screen.dart
packages/rydvia_auth/lib/src/ui/otp_screen.dart
packages/rydvia_auth/lib/src/ui/welcome_screen.dart
packages/rydvia_auth/test/auth_controller_test.dart
packages/rydvia_auth/test/auth_screens_test.dart
packages/rydvia_auth/test/navigation_test.dart
packages/rydvia_core/lib/rydvia_core.dart
packages/rydvia_logging/test/logging_test.dart
packages/rydvia_ui/test/components_test.dart
```

## Focused fix and validation entry point

The workflow now delegates Flutter validation to `scripts/validate-flutter.ps1`
without a premature root formatting step. For each of the nine shared packages and
three mobile apps, the script resolves dependencies, checks handwritten `lib`/`test`
formatting, analyzes, then runs available tests. It fails on any nonzero formatter,
analyzer, resolver, or test exit. `-SkipResolve` requires existing package metadata.

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
. ./scripts/with-tools.ps1
./scripts/validate-flutter.ps1
```

The formatter does not rewrite files during validation. Build output, `.dart_tool`,
node_modules, vendored fonts/native files, and generated `.g.dart`/`.freezed.dart`
files are outside its scope. Canonical generated tokens retain their generator check.

No application source, package SDK constraint, dependency version, or Supabase migration
changes are required. The fix is committed separately, without amending the checkpoint
or rewriting history. Live Supabase application and deployment remain outside this phase.

## Local validation record

Commands run from the repository root after loading `scripts/with-tools.ps1`:

```powershell
./scripts/validate-flutter.ps1
npm run lint
npm run typecheck
npm test
npm run build
npm run test:admin-http
./scripts/test-tokens.ps1
./scripts/test-platforms.ps1
./scripts/verify-repository.ps1
git diff --check
git diff --exit-code a86ab99817c2b123f8d9fcff32ed38decf3701dd -- supabase/migrations
```

The Flutter validator executed `flutter pub get` / `dart pub get`, scoped
`dart format --output=none --set-exit-if-changed`,
`flutter analyze --fatal-infos` / `dart analyze --fatal-infos`, and
`flutter test` / `dart test` for each applicable package. All twelve projects
analyzed without issues; all 34 handwritten source/test files needed zero formatting
changes; all 44 Dart/Flutter tests passed. The separate actual formatter invocation
before the fix also changed zero files.

All 53 web/PostgreSQL tests passed, as did lint, types, both production Next.js builds,
Admin HTTP authorization checks, 86 token assertions, and 42 native-structure checks.
Secret/ignore checks passed, and all three migrations remain byte-for-byte unchanged.
The local Supabase CLI is absent and Docker's Linux engine unavailable; isolated
PostgreSQL tests ran locally, while the GitHub local-Supabase job reruns real pgTAP.
No live backend configuration or real SMS validation is performed in this CI phase.
