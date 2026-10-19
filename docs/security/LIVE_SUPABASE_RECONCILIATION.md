# Live Supabase reconciliation and local application readiness

Date: October 19, 2026. Project: RydVia (`kciwxgfvpozgmnaypyxb`).
Project URL: `https://kciwxgfvpozgmnaypyxb.supabase.co`.

**Local migration set prepared and tested. Supabase is not production-ready.**
No live Supabase management, remote SQL, migration, configuration change, OTP send,
or deployment was attempted from this VS Code session. Live facts below were
externally verified and supplied by the user; they were not independently queried here.

## Externally verified live state

| Item | Verified state |
| --- | --- |
| Project status | `ACTIVE_HEALTHY` |
| App-specific public tables | None |
| Auth users | 0 |
| Storage buckets | 0 |
| Remote migrations | 0 |
| Deployed Edge Functions | 0 |
| Security finding | `public.rls_auto_enable()` is SECURITY DEFINER and executable by `anon` and `authenticated`. |

The empty application schema and migration history support a fresh foundation
application. They do not prove the absence of unrelated functions, a `private`
schema, event triggers, schema-level defaults, custom roles, or Realtime publications.
Phone Auth, SMS provider, CAPTCHA, OTP policy, Auth site/redirect settings, and live
Realtime settings were not included in the supplied verification and remain unknown.
Do not attempt live management from this session; use the externally authorized environment.

## Local migration review and application order

All three files are local candidates ready for controlled external application in
this exact order. No remote migration has been applied by this session. See
[MIGRATION_APPLICATION.md](MIGRATION_APPLICATION.md) for preflight and verification.

| Order | File | Effect and safety boundary |
| --- | --- | --- |
| 1 | `supabase/migrations/20261019000000_restrict_rls_auto_enable.sql` | Revoke helper execution from PUBLIC, anon, and authenticated; check effective privileges and abort if another inherited grant remains. Preserve the function body, owner, event triggers, and explicit trusted grants. No-op if the helper is absent on a clean local stack. |
| 2 | `supabase/migrations/20261019000100_identity_services.sql` | Create the private helper schema, ten app tables, eighteen policies, five functions, signup trigger, invoker availability view, and thirteen disabled services/flags. Explicitly remove inherited/default client grants before restoring intended access. Refuse an existing private schema or conflicting objects. |
| 3 | `supabase/migrations/20261019000200_effective_product_access.sql` | Replace access_profile with the same signature, requiring approved Driver/Business profiles plus membership. Restore only intended authenticated execution after revoking PUBLIC/anon/authenticated defaults. |

The two original migrations were edited locally because external verification shows
zero remote migrations. Do not edit migration history after these files are applied.

There are no DROP TABLE, DROP SCHEMA, TRUNCATE, or data-deleting statements in the
migration set. CREATE OR REPLACE affects only the RydVia access_profile function in
migration 002; the platform helper is never replaced. REVOKE statements intentionally
reduce client privileges. Foreign-key ON DELETE CASCADE rules describe future parent
deletion behavior; they do not delete rows during migration application.

Migration 001 deliberately backfills every existing Auth identity with a Customer
profile/membership. The supplied snapshot has zero users. If that count changes,
review those identities before application; IDs are preserved. Transactions roll back
a failed migration. Previously committed migrations remain applied if a later file
fails; inspect and correct the failure without dropping data or replaying migration 001.
An existing private schema or name/signature collision requires a revised additive
migration, not deletion or blind history repair.

## Role and RLS boundaries

All ten app tables enable RLS. The availability view uses invoker security. Privileged
helpers use fixed empty search paths and qualified references. No initial Admin is
seeded, and signup metadata never grants privileged roles.

| Actor | Intended access |
| --- | --- |
| Anonymous | No app table/view reads or app RPC execution; no RLS helper execution. |
| Customer | Own profile/memberships/requests; authenticated service catalog; own onboarding through validated RPC. No direct role, approval, profile, or feature mutations. |
| Driver | Customer foundation plus effective Driver membership only when a granted role and approved Driver profile both exist. Pending/suspended/rejected profiles do not pass the product gate. |
| Business | Customer foundation plus effective Business membership only when a granted role and approved Business profile both exist. Requests never self-promote. |
| Admin | Verified Auth user plus database-backed Admin membership. Admin RLS policies permit intended role/approval/vehicle/service writes. Flutter/client signup cannot grant Admin. |

The guard RPC denies unavailable or unknown services. All thirteen service,
availability, and flag gates default off. Deep booking workflows are not implemented.
No Storage buckets or Realtime publications are created by these migrations.

## Auth services and application configuration

Customer, Driver, and Business share phone normalization, OTP request/verification,
resend handling, onboarding, session restoration/expiry/logout, and database-backed
product gates. Sessions use platform secure storage; SDK debug logging is disabled.
Tests cover restoration and revoked product access. These are local tests, not live SMS tests.

Admin uses server-only Supabase SSR clients, verified getUser(), database-backed role
checks on protected pages/API routes, HttpOnly cookies, and private/no-store responses.
Admin OTP requests disable public account creation. Accounts and initial Admin grants
must be provisioned through an audited privileged path outside client code. Dashboard
operational records remain labeled fixtures.

Source review found no service-role credential usage in Flutter or browser Next.js.
Both configurations reject secret/service-role keys. The only source service_role
reference in Flutter is a negative key-validation test. Auth failures/logging avoid
raw provider errors, OTPs, phone values, and access tokens.

Use root `.env.example` -> ignored `.env` for mobile and
`apps/admin_web/.env.example` -> ignored `apps/admin_web/.env.local` for Admin.
Both examples contain the supplied URL and a blank public publishable/anon key;
no real key is configured here. Never place management/provider/service-role secrets
in mobile defines or NEXT_PUBLIC variables. Auth OTP length and resend settings must
match the externally inspected Auth policy.

Phone OTP still requires external verification/enabling of Phone Auth, provider
selection, valid server-side provider credentials, a configured sender/service,
recipient-country delivery permission, rate/abuse controls, and real send/verify
validation. Supply the selected provider's required account/API credentials and
sender/service identifiers through Supabase's protected configuration. Exact missing
provider fields cannot be determined until that configuration is inspected externally.
If CAPTCHA is enabled, add the corresponding challenge/token integration before
claiming readiness; current clients do not implement CAPTCHA. Do not disable it for convenience.

## Local validation

- 53 web/database tests passed across ten files, including real isolated PostgreSQL
  migrations/RLS, hostile default grants, helper privilege revocation, inherited-grant
  failure rollback, preserved automatic RLS, collision rollback, Auth ID backfill,
  role approval/revocation, Admin gates, and sanitized audit tooling.
- All twelve Dart/Flutter projects analyzed without issues; 44 tests passed
  (core 3, logging 1, UI 18, auth 22).
- Web type checking and lint passed. Dart formatting passed with no changes.
- 86 token/contrast/consistency assertions and 42 native structure checks passed.
- Both Next.js production builds passed. Local production Admin HTTP checks passed:
  missing configuration and forged cookies fail closed without exposing dashboard data.
- Supabase pgTAP source is prepared with nineteen assertions. It requires Supabase
  CLI and a running local Docker stack; isolated PGlite does not replace that check.
  Supabase CLI is absent and Docker's Linux-engine pipe is unavailable in this
  environment, so pgTAP could not be rerun here.
- Actual SMS, deployed APIs/RLS, mobile secure storage on devices, Android/iOS builds,
  and live authenticated connectivity are not validated by these local results.

## Exact next phase

From the external Supabase-enabled environment, recheck the supplied snapshot and
object-collision preflight; apply the three migrations through versioned migration
operations in order; verify the helper ACL, RLS, policies, data counts, and grants.
Then configure and validate real phone OTP/session flows for each product and provision
a trusted Admin account. Keep service flags off until authorized product validation.
Do not proceed to deep ride-booking work or mark production-ready yet.
