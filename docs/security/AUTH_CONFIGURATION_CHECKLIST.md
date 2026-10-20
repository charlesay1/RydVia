# RydVia Auth configuration inspection

Project: `kciwxgfvpozgmnaypyxb`. Inspection prepared October 19, 2026.

All four migration versions are synchronized. This task performs no migration,
`db push`, deployment, configuration change, Auth request, or SMS test. Live Auth
settings below remain **unknown** until inspected in the Dashboard. CLI migration
access does not establish what Auth settings are enabled. Local `supabase/config.toml`
describes disposable development configuration, not hosted configuration.

## Manual Dashboard checklist

Open the [RydVia project](https://supabase.com/dashboard/project/kciwxgfvpozgmnaypyxb).
Navigation labels may read **Sign In / Providers** or **Providers**, and **Attack
Protection** or **Bot and Abuse Protection**. Record actual values before changing
anything. Expected values below are compatibility requirements or proposed targets,
not claims about current configuration.

| Page | Setting to inspect | Expected value / acceptance condition |
| --- | --- | --- |
| Authentication > Sign In / Providers > Phone | Phone provider | Enabled before any real phone sign-in trial. SMS confirmation required; no auto-confirm or fixed test-phone/code bypass for a delivery test. |
| Authentication > Sign In / Providers | Allow new users to sign up | Enabled for mobile self-registration. Anonymous sign-in is not used and should remain disabled unless separately required. |
| Phone provider | SMS provider | Record the actual selected provider; none is selected by this repository. It must have a usable sender/service and Ghana delivery permission. If a Send SMS hook replaces it, inspect that path instead. |
| Phone provider | Credentials and sender/service identifiers | All fields required by the selected provider populated in protected settings. Record only present/missing booleans, never values. Check account funding, trial recipient restrictions and Ghana sender/route eligibility in the provider console. |
| Phone provider | SMS OTP length | Six digits to match `AUTH_OTP_LENGTH=6`. If a provider controls length, confirm its effective length and align both mobile and Admin configuration (supported 6–10). |
| Phone provider | SMS OTP expiry | Record actual seconds, including provider-controlled expiry for Verify/custom hooks. Proposed initial target: 300 seconds; requires explicit configuration approval later. This is independent of the resend interval and JWT expiry. No live expiry has been verified. |
| Phone provider / Authentication > Rate Limits | Minimum interval between SMS requests | 60 seconds to match `AUTH_RESEND_SECONDS=60`. If the enforced interval is longer, increase the client timer before testing. Client countdown cannot enforce server limits. |
| Authentication > Rate Limits | SMS sent, OTP requests, verification, token refresh | Record each displayed quota, unit, scope (project/IP/user), and burst behavior. Keep finite limits; do not raise them to bypass errors. Retain existing limits pending review. Reference defaults, not RydVia targets: SMS 30/hour/project; sign-in/OTP-related requests and verification 30/5 minutes/IP; token requests 150/5 minutes/IP. |
| Authentication > Attack Protection | CAPTCHA enabled, provider, credential presence | Record enabled status, provider and secret-presence boolean. Production target is bot protection with a supported challenge/token flow. Current clients do not submit CAPTCHA tokens: if enabled, this is an integration blocker; preserve protection. If disabled, record a production-readiness gap. |
| Authentication > URL Configuration | Site URL | Exact approved web origin; HTTPS for production. The production origin is not specified in this repository. Local config uses `http://localhost:3000`; do not treat that as the production target or substitute the Supabase API URL. |
| Authentication > URL Configuration | Redirect URLs | Only explicitly approved callback URLs for implemented flows; no broad production wildcards or unknown domains. Numeric SMS OTP currently uses no redirect. No production callback URL has been selected. |
| Authentication > URL Configuration + native app manifests | Deep links | No Auth callback scheme/app-link/universal-link is currently implemented for the three mobile apps. None is required for numeric SMS OTP. Do not add placeholder schemes; future link-based flows need per-app native registration, ownership verification and matching allowlisted callback URLs. |
| Authentication > Auth Hooks | Send SMS, Before User Created, Custom Access Token, others | No hooks required by the checked-in implementation. Record each enabled hook and its purpose; any existing hook requires review before testing. A Send SMS hook changes the delivery path; signup/token hooks must not block legitimate signup or grant staff/product approval from untrusted metadata. Do not copy secret hook URLs or signing keys. |
| Authentication > Sessions (and JWT settings if shown separately) | JWT lifetime, refresh rotation/reuse, inactivity/time-box/single-session limits | Record actual settings and plan availability. Local reference: JWT 3600 seconds, refresh rotation enabled, reuse interval 10 seconds. Keep rotation enabled; review any stricter limits against restart/background behavior. These are session settings, not SMS code settings. |
| Authentication > Users + Database > Triggers/Functions (read-only inspection) | Signup/bootstrap | On a future verified signup, exactly one Auth user, matching public profile, customer membership and customer profile. `rydvia_auth_user_created` enabled on `auth.users`, targeting private SECURITY DEFINER `bootstrap_profile`; no PUBLIC/anon/authenticated EXECUTE. Driver/Business requests remain pending until approved plus role; no signup Admin grant. Inspect counts/metadata without exporting phone numbers. |
| Project Settings > API Keys (legacy keys tab if needed) | Client credentials | Use this project's publishable key, or legacy anon key, through ignored environment configuration. Never use secret/service-role or management credentials in Flutter/browser code. Record key type/project match only. |

Provider credential presence depends on the selection: Twilio/Twilio Verify need
account SID, auth token and the appropriate Messaging/Verify service SID; MessageBird
needs access key and originator; Vonage needs API key, API secret and sender; Textlocal
needs API key and sender. Inspect only the selected provider's displayed fields.

## Local application evidence

Customer, Driver and Business entry points call `launchRydVia` with their respective
product roles. The same `SupabaseAuthRepository` requests an SMS OTP with
`shouldCreateUser: true`, normalizes the phone again at the SDK boundary, verifies
with `OtpType.sms`, requires a returned session, and obtains access through the
database `access_profile` RPC. OTP requests contain no requested role metadata.
Driver/Business access requires the approval-backed role returned by the database;
selecting an app is not an approval or role grant.

`AppConfig` defaults to six digits and 60 seconds. Both client configuration validators
accept publishable/legacy-anon keys and reject secret/service-role keys. The two
`.env.example` files contain the correct project URL and blank public keys; actual
`.env` and Admin `.env.local` files are absent at this inspection. No configured
application connectivity or successful live Auth flow is inferred from the examples.
Environment files and private signing credentials are ignored by Git.

The mobile SDK retains automatic refresh and session persistence defaults. Each app
uses a separate `FlutterSecureStorage` session key; startup restores the session and
rechecks database access. Auth-state changes refresh access or return to sign-in.
Logout uses `SignOutScope.local` and removes persisted credentials; it is not an
all-device logout and does not instantly invalidate already-issued JWTs elsewhere.
SDK debug logging is disabled. Admin uses server-side Auth and database-role checks,
not client-only authorization, and disables self-signup for its OTP requests.

Ghana normalization accepts national mobile input with or without its leading zero,
or `+233`/`233` international input; strips spaces, parentheses and hyphens; then emits
`+233` plus nine digits starting with 2 or 5. Invalid lengths/other country prefixes
are rejected before transport. A trunk zero after an international country code,
duplicated prefixes and unsupported `00233` input are rejected, not repaired. See
[the phone contract](GHANA_PHONE_NORMALIZATION.md). This validates format, not ownership or routability.
The UI keeps the Ghana flag and +233 visible without doubling the prefix.

## External behavior checks for a later authorized test phase

After configuration review and explicit authorization for real SMS testing, validate
each of Customer, Driver and Business on a device: request and receive a real code,
verify it, inspect the bootstrap records, then check the correct role/approval gate.
For each app, background/resume across token expiry (refresh), terminate/relaunch
(restore), log out and relaunch (no restored session), and test bounded resend and
invalid/expired-code errors. Check Ghana input variants normalize to the same recipient.
For Driver/Business, test pending denial and approved-plus-role access separately.
Admin signup remains disabled and access needs an explicitly provisioned Admin role.

Record only pass/fail, non-sensitive configuration, timestamps and error categories.
Never record OTPs, JWTs, refresh tokens, provider secrets or real recipient numbers.
No behavior checks in this section were executed against live Supabase in this task.
Real-device refresh/restore/logout and real SMS delivery remain unverified. OTP is
**not production-ready** until actual SMS send and verification succeed and the
remaining access/session/protection checks pass.

## Local verification performed

- `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate-auth.ps1`:
  analysis clean; latest full Flutter validation passes 39 Auth tests (mocked
  transport; no SMS).
- `flutter test` in `packages/rydvia_core`: three tests passed.
- Admin Auth tests: 15 passed in the latest full 57-test web/database run.
- Existing credential scanner: no findings in tracked/index blobs or eligible
  working files; rerun before checkpointing subsequent changes.
- Git ignore checks protect `.env`, Admin `.env.local` and Supabase `.temp`.
  The checklist preparation changed only documentation. Subsequent phone
  normalization hardening is documented in GHANA_PHONE_NORMALIZATION.md; migrations
  remain unchanged.

## References

- [Supabase Phone Auth](https://supabase.com/docs/guides/auth/phone-login)
- [Auth rate limits](https://supabase.com/docs/guides/auth/rate-limits)
- [CAPTCHA integration](https://supabase.com/docs/guides/auth/auth-captcha)
- [URL configuration](https://supabase.com/docs/guides/auth/redirect-urls)
- [Auth hooks](https://supabase.com/docs/guides/auth/auth-hooks)
- [Sessions](https://supabase.com/docs/guides/auth/sessions)

Stop after inspection. No new migration, deployment or SMS/OTP test is authorized by
this checklist preparation task.
