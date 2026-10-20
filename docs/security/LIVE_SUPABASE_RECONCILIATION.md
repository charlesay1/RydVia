# Live Supabase reconciliation and current Auth phase

Project: RydVia (`kciwxgfvpozgmnaypyxb`). Date: October 19, 2026.
Source baseline: `e0194144455a7755ee018e06f884f314393e6199` (green CI).

## Externally verified live state

The user confirms these migrations have already been applied and verified externally:

1. restrict_rls_auto_enable (local file 20261019000000)
2. identity_services (local file 20261019000100)
3. effective_product_access (local file 20261019000200)

Do not reapply them. Their source files are preserved unchanged. The verified live
result is ten RydVia tables with RLS, eighteen policies, thirteen services, thirteen
feature flags, thirteen availability rows, and all three service gates disabled.
Driver/Business product access requires approved profiles plus role membership.
The platform rls_auto_enable function denies PUBLIC/anon/authenticated execution.
No production app users exist yet. This supersedes the earlier empty-schema snapshot.
These are externally verified user-supplied facts, not fresh queries from this session.

## Current phase: live Auth and SMS

The user confirms Auth settings have NOT been inspected yet. Phone Auth enablement,
provider selection/credentials, delivery, OTP expiry/resend/rates, CAPTCHA, site URL,
redirects, and additional Auth hooks remain unknown. Unknown does not mean disabled
or unconfigured. Real send/receipt/verification, Auth signup bootstrap, and live
session/device behavior remain untested. OTP is NOT production-ready.

Supabase is installed/enabled, but this session exposes no callable Supabase tools.
No real public-key environment is configured here. No live requests, migration,
provider updates, users, OTPs, or deployments were performed. Credentials were not
requested in chat. Keep this VS Code session on local preparation while external
Supabase access handles the read-only configuration inventory.

## Local work prepared

The shared mobile SDK adapter normalizes Ghana numbers at its transport boundary,
uses only public client configuration, verifies profile identity, handles missing
bootstrap safely, redacts provider errors, and logs out the current session. The
Ghana flag/+233 prefix is visible without focus and is not inserted twice into the
phone value. Secure session storage, loading/retry/resend controls, onboarding,
approval gates, and server-side Admin authorization remain in place and tested.

The authenticated SECURITY DEFINER complete_onboarding RPC is retained intentionally:
self-only auth.uid target, fixed empty search path, bounded name/product inputs,
no user_roles writes, no staff requests, and pending-only application creation.
There is no client-supplied target, role grant, or approval parameter.

New candidate `20261019000300_auth_bootstrap_and_policy_cleanup.sql` is prepared
locally, NOT applied live. It makes bootstrap replay-safe without overwriting state,
indexes service_availability.flag_key, retains vehicles_driver_idx, and replaces
redundant Admin ALL policies with dedicated write policies. After external application,
expect 34 policies with one authenticated SELECT policy per table, not the current
verified 18. RLS, grants, identities, approvals, and disabled flags remain unchanged.

See [AUTH_SMS_VALIDATION.md](AUTH_SMS_VALIDATION.md) for all twenty requested results,
provider credential names/storage, Ghana sender/trial requirements, the security
review, safe candidate preflight/post-checks, and the controlled real OTP test gate.

The next step is external read-only Auth inspection, followed by selected-provider
configuration only where required and consented real send/verify/session/role tests.
Do not proceed to ride-booking implementation or claim production-ready OTP.
