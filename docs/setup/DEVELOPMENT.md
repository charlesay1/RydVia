# Development setup and environment

## Toolchains

Test baseline: Flutter 3.47.7 / Dart 3.13.5, Node.js 24.22.0, Git for Windows
2.56.0.windows.2. Windows-local tools were downloaded from official vendors with
SHA256 verification and stored in ignored `.tools/`. No system PATH was changed.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/bootstrap-tools.ps1
Set-ExecutionPolicy -Scope Process Bypass
. ./scripts/with-tools.ps1
flutter doctor -v
```

The script bootstraps portable tools on Windows x64. Other platforms should install
the pinned Flutter release and Node 24 through official tooling and keep Git on PATH.
Java/JDK 17+, the Android SDK, accepted Android licenses, and an emulator/device are
needed for Android. macOS/Xcode, Apple signing, and platform plugin dependencies are
required for iOS/iPad. Docker Desktop is installed locally but its Linux daemon was
not running during bootstrap. Supabase CLI database validation requires Docker.

## Configuration

Copy the root `.env.example` to `.env` locally. Set only a public Supabase
publishable/anon key in this client configuration. The authoritative project URL
is already in the example; it is not hard-coded into Dart source. Never put a
service-role/secret key, database password, access token, or signing key in that file
when passing it to a client build. Dart defines are embedded in binaries and are not
a secret store. `AppConfig` rejects secret-key prefixes and legacy JWTs that do not
claim the public anon role, as a misuse guard rather than a substitute for server
signature validation. No production credentials were supplied or generated.

`AUTH_OTP_LENGTH` (default 6) and `AUTH_RESEND_SECONDS` (default 60) must match the
inspected provider policy. SMS delivery, provider credentials, cost/rate controls,
captcha/abuse protections, and remote signup configuration remain unverified.

Run a native app from its directory:

```powershell
cd apps/customer_app
flutter pub get
flutter run --dart-define-from-file=../../.env
```

Use the same command from `driver_app` or `business_app` for those products.
Without valid public configuration the app fails closed with a startup error.
Without migrated backend RPCs, login cannot complete product access checks.

## Web

From the repository root:

```powershell
npm ci
npm run dev:public
# In another terminal:
npm run dev:admin
```

Public: `http://localhost:3000`. Protected Admin: `http://localhost:3001`.
The Public shell needs no Supabase credentials. For Admin, copy
`apps/admin_web/.env.example` to `apps/admin_web/.env.local` and set the public key
locally. Next.js loads environment files relative to that workspace; it does not
automatically load the monorepo root's mobile `.env`. Admin configuration is
server-only, with no `NEXT_PUBLIC_*` keys or browser Supabase client. The server
verifies sessions and database admin membership; missing configuration fails closed.
Operational records remain labeled fixtures until a live repository is implemented.
See [live reconciliation](../security/LIVE_SUPABASE_RECONCILIATION.md) for the externally
verified empty live baseline and pending SMS validation. Apply the prepared files only
from the authorized external environment, following the
[migration runbook](../security/MIGRATION_APPLICATION.md).
No privileged environment variables belong in browser code.

## Local database

With Supabase CLI and a running Docker daemon:

```powershell
supabase start
supabase db reset --local
supabase test db
```

The local configuration does not link or modify the supplied remote project.
Never run a remote reset. Reconcile live schema and migration history first; see
the security runbook. Normal `npm test` also executes migration and RLS behavior
against isolated in-memory PostgreSQL via PGlite, with a minimal Supabase Auth shim.
That suite is not a test of the live SMS provider, Supabase API gateway, or Storage.
