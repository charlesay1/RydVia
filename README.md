# RydVia

RydVia is a mobility, delivery, logistics, moving, and towing platform. The existing
project locations below are authoritative; the shared UI package is reusable work
for this product and does not define a separate application or deployment.

- Repository: [charlesay1/RydVia](https://github.com/charlesay1/RydVia).
- Local project: `C:\Users\ckora\RydVia`.
- Supabase project reference: `kciwxgfvpozgmnaypyxb`.
- Supabase dashboard: [project dashboard](https://supabase.com/dashboard/project/kciwxgfvpozgmnaypyxb).
- Supabase project URL: `https://kciwxgfvpozgmnaypyxb.supabase.co`.

The project URL above is documentation, not a runtime configuration. Applications
must load it and a public publishable/anon key through their environment configuration.
Never put service-role keys, database passwords, access tokens, private signing
credentials, or API secrets in client source or committed files.

The [initial audit](docs/REPOSITORY_SUPABASE_AUDIT.md) records the starting condition:
an empty remote and a local shared UI package. This bootstrap now contains the five
product surfaces, shared packages, local Supabase migrations, tests, and CI. Local
Git uses `main` with the supplied `origin`; no commit or push has been made.
Live Supabase configuration and migration history remain unverified.

- [Setup and environment](docs/setup/DEVELOPMENT.md)
- [Architecture](docs/architecture/OVERVIEW.md)
- [Security and Supabase rollout](docs/security/SECURITY.md)
- [Live reconciliation and authentication status](docs/security/LIVE_SUPABASE_RECONCILIATION.md)
- [Build and validation](docs/setup/BUILD.md)
- [Brand assets still required](assets/brand/README.md)
- [Bootstrap engineering report](docs/BOOTSTRAP_REPORT.md)

- [Design tokens](design/tokens.json): canonical palette, spacing, radius, motion, icon sizes, elevation, typography, and theme roles.
- [Flutter package](packages/rydvia_ui/README.md): Material 3 themes, components, theme preference controller, service catalog, and widget tests.
- [Brand and integration requirements](design/INTEGRATION.md): assets, application wiring, service lifecycle, and remaining implementation.
- [Web tokens](packages/rydvia_ui/web/tokens.css): generated CSS with system theme following, explicit theme overrides, and reduced-motion durations.

Generate and verify shared tokens on Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/generate-tokens.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-tokens.ps1
```

These commands set execution policy only for their child process.

Validate all Flutter/Dart projects:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-flutter.ps1
```

Validated SDK baseline: Flutter 3.47.7 / Dart 3.13.5 and Node 24.22.0. Use the npm
lockfile for both Next.js workspaces. Run `npm ci`, `npm run dev:public` (port 3000),
or `npm run dev:admin` (port 3001). Admin requires verified server-side session and
admin-role checks; its operational records remain labeled fixtures.

Licensed Manrope is bundled once for mobile and web. Approved logo masters, final
photography, legal text, production SMS setup, native toolchains/signing, and live
backend verification remain release blockers. No substitute logo was created.
