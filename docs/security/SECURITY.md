# Security and Supabase rollout

## Verified boundaries

Local migrations enable RLS on every exposed foundation table, revoke anonymous
table access, and restrict administrative mutations to a server-backed admin role.
Role grants never come from client signup metadata. Ordinary onboarding can update
only the current user's name/onboarding state and request pending Driver/Business
review. It cannot approve profiles or grant staff/admin roles. Vehicles default
unapproved. No public storage bucket or Realtime publication is created.

`access_profile` and the availability view use invoker security. Definer functions
fix an empty search path, qualify referenced objects, constrain inputs, and revoke
public execution. The admin predicate checks only the authenticated user's role.
The Auth user-created trigger gives basic Customer membership; privileged approval
requires a trusted administrative procedure. No initial admin is seeded.

Supabase handles session refresh and verification. Flutter persists tokens using
platform secure storage; ordinary theme preferences use shared preferences. SDK
debug logging is disabled. Operational logging accepts only predefined event types
and timestamps, never arbitrary metadata, phone numbers, OTPs, passwords, tokens,
raw exceptions, or precise locations. Analytics is no-op unless explicitly replaced
with an approved, consent-aware adapter. Data retention, deletion, device compromise,
and deployment threat models still need a release security review.

## External live verification and pending rollout

The user externally verified that the original three migrations are applied: ten
RLS-enabled app tables, eighteen policies, thirteen disabled services/flags/availability
entries, approval-gated product access, no app users, and denied PUBLIC/anon/authenticated
execution of public.rls_auto_enable(). This session performs local work only. Auth/SMS
settings are not inspected yet; local tests do not establish production readiness.
No remote project change was performed here. The new 0003 candidate adds replay-safe
bootstrap, a flag-key index, and separate Admin write policies without changing access.
See [Auth/SMS validation](AUTH_SMS_VALIDATION.md) for onboarding definer-function review,
pending live checks, and the candidate's application boundary. Do not replay 000-002.

The first local migration revokes PUBLIC/anon/authenticated helper execution while
preserving automatic RLS event triggers. Foundation migrations explicitly revoke
client defaults before granting intended access, and refuse an existing private
schema. Follow [the application runbook](MIGRATION_APPLICATION.md) for exact order
and [the reconciliation report](LIVE_SUPABASE_RECONCILIATION.md) for evidence.

Before remote deployment:

1. Use the externally authorized Supabase environment for the supplied project;
   do not attempt live management from this VS Code session.
2. Inspect configuration and migration history; inspect schema/policy metadata
   before any user data. Do not print secrets or unnecessary PII.
3. Compare existing objects against this local baseline. Create reconciliation
   migrations instead of applying a conflicting create-table baseline blindly.
4. Review changes and backups in the correct non-production environment, then run
   Supabase pgTAP and API-level authorization tests with representative roles.
5. Configure the real SMS provider with server-side credentials, abuse controls,
   country restrictions/rate limits, verified signup behavior, and matching OTP rules.
6. Provision the first admin through a trusted, audited server-side action. Review
   Driver/Business approvals and role revocation as separate privileged operations.
7. Validate session restoration, refresh expiry, logout, secure storage, backend
   outage/retry behavior, and rejected direct/API/deep-link requests on devices.

Never weaken RLS to make a client flow work. Do not expose a service-role key through
Flutter, `NEXT_PUBLIC_*`, browser JavaScript, or public website settings. `.env` and
signing files are ignored; examples contain only public URLs and blank key slots.
Use secret managers/CI secret settings for server-only credentials. Git ignore rules
do not remove already-tracked secrets; review staged diffs before committing.

The Admin surface now requires server-side session/role verification, with private
no-store responses and server-only phone OTP actions for provisioned accounts.
Operational records remain fixtures. See the current live reconciliation report;
real provider/session/role validation is still pending. Before live operational data,
implement authorized data repositories, an appropriate CSP/nonce policy, deployment
headers, audit trails, least-privilege roles, and end-to-end permission tests. Current shared
web headers include nosniff, referrer policy, and disabled camera/mic/geolocation.

## Service lifecycle

All service gates start disabled. Effective availability requires all three gates.
The guard RPC denies unavailable/unknown services, but future booking and quote
transactions must call an equivalent guard and enforce eligibility within the same
transaction. Current shells cannot submit bookings. Active-booking disable policies,
refunds, cancellation, and financial authorization are not implemented yet.
