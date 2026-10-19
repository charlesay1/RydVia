# RydVia bootstrap engineering report

Date: October 19, 2026. This report covers the bootstrap/authentication phase, not
a completed transport service or a production launch approval.

Historical bootstrap report. The subsequent
[live reconciliation/auth readiness report](security/LIVE_SUPABASE_RECONCILIATION.md)
supersedes Admin gate status, candidate migration status, and current test totals.

| Required item | Result |
| --- | --- |
| 1. Repository condition at start | Remote exists but was empty with no branches; local folder contained earlier shared UI files and no Git checkout. All prior files were audited. |
| 2. Architecture created | Five official surfaces, shared package boundaries, preserved UI implementation with design-system entry point, shared auth/domain/data contracts. |
| 3. Created/modified areas | `apps/`, `packages/`, `supabase/`, `assets/brand/`, canonical/generated design tokens, scripts, `.github/workflows/ci.yml`, environment example, ignore rules, architecture/setup/security docs, npm and Dart lockfiles. |
| 4. Customer App | Native welcome, phone OTP, profile onboarding, server-backed session gate, appearance preferences, and backend-fed service display. Booking workflows are not implemented. |
| 5. Driver App | Distinct native identity; shared welcome/OTP/onboarding and approval gate. Jobs, navigation, earnings, and payouts are not implemented. |
| 6. Business App | Distinct native identity; shared welcome/OTP/onboarding and approval gate. Operational orders, analytics, and payments are not implemented. |
| 7. Admin Dashboard | Responsive fixture shell with metrics, accessible chart summary, booking table, filters, module navigation, loading/error/empty states, and appearance controls. All data is explicitly synthetic; live admin authentication/authorization is not connected. |
| 8. Public Website | Responsive Next.js shell, requested hero/navigation/service cards, functional informational/partner/support/legal routes, launch-status disclosure, and appearance controls. Store links, final legal text, and photos are pending. |
| 9. Supabase configuration completed | Local CLI configuration, client adapter/environment boundary, migration for identity/roles/profiles/vehicles/services/flags/availability, constrained RPCs, local policy and pgTAP test sources. No remote configuration or deployment performed. |
| 10. RLS/security | Every exposed local foundation table enables RLS; anonymous access revoked; role metadata cannot escalate privilege; pending review does not grant roles; secure session store; SDK debug logs disabled. Local PostgreSQL tests pass. Live security remains unverified. |
| 11. Launcher icons | Android/iOS identities and iPhone/iPad AppIcon slots exist. Template launcher images removed; approved Customer/Driver/Business icons and web icons cannot be exported without original artwork. |
| 12. Android validation | Flutter doctor confirms Android SDK is absent; no JDK was discoverable. Android compilation cannot run here. Identity/XML checks are separate from compilation. |
| 13. iOS structural readiness | Xcode projects/workspaces, Info.plists, Swift entry points, iPhone/iPad settings, bundle IDs, and launch color assets exist. Windows cannot compile/verify Xcode plugins or signing. |
| 14. Web build | Both Next.js 16.4.2 production builds passed with bundled local Manrope. No hosting deployment performed. |
| 15. Tests executed | Web/component/fixture/theme tests; in-memory PostgreSQL migration/RLS tests; Dart core/logging tests; Flutter theme/component/auth/responsive/navigation tests; token and native-structure checks. Final suite totals are recorded below after verification. |
| 16. Pass/fail | Earlier accessibility-handle cleanup and deprecated Supabase API issues were corrected; final validation results below distinguish executed checks from unavailable platform/live tests. |
| 17. Remaining blockers | Authenticated Supabase management access, live schema reconciliation, real public key and SMS provider validation, Android SDK/JDK, macOS/Xcode/signing, approved logos/photos, legal/store/support release content, browser/device end-to-end QA, production workflow implementation. |
| 18. Exact next step | Connect an authorized Supabase management session for `kciwxgfvpozgmnaypyxb`; inspect live schema/migrations/Auth/RLS and reconcile this baseline in a non-production environment before applying changes. |

## Validation record

The full Flutter/Dart validation script completed successfully across all 12 projects.
All 41 Dart/Flutter tests passed: 3 core validation, 1 safe logging, 18 shared UI,
and 19 authentication/responsive/navigation tests. All projects analyzed without
issues, including Customer, Driver, and Business. Formatting completed successfully.
All 14 web/database tests, web lint and type checks, both Next.js production builds,
86 token/contrast assertions plus generated-output consistency, and 42 native
identity/structure checks passed. No known failing executed tests remain.

The final repository check also passed: the supplied `origin`, real Git ignore
behavior for environment/signing files, and scoped secret-pattern checks. The
format-only check reported 35 files with 0 changes. Git/SDK checkout ownership was
restored to the workspace user after elevated downloads; no global Git trust
exception or access-permission change was used.

`flutter doctor -v` completed using the workspace-local SDK. It found no Android
SDK and no Visual Studio desktop toolchain. Docker's executable exists but its
Linux daemon was unavailable, so the Supabase CLI/pgTAP suite was not executed
locally. PGlite tests execute the actual migration and RLS behavior with a minimal
Auth shim; they do not verify the live project, SMS delivery, or Supabase gateway.

No browser connection was available for visual browser automation. No approved
golden baselines were produced. Mobile device storage/session refresh, OTP autofill,
native back behavior, cold-start manual theme overrides, plugin integration, and
launcher artwork still require real-device/macOS validation.

## Preservation and safety

`packages/rydvia_ui`, its tests, and canonical colors were retained. Changes add the
product architecture rather than replacing it. New shared auth UI was split into
focused welcome/OTP/onboarding/home/legal files. Manrope/OFL is bundled once.
Git was initialized on local `main` and `origin` set to the supplied GitHub URL.
No commits, pushes, production migrations, role grants, secrets, or deployments were
made. The `.env.example` contains the public project URL and an empty public-key slot.
