# RydVia Phone Auth and SMS validation

> Historical preparation report. The current operational checklist is
> [AUTH_CONFIGURATION_CHECKLIST.md](AUTH_CONFIGURATION_CHECKLIST.md).
> All four migrations, including `20261019000300`, are now applied according to
> external live verification, and their local/remote history versions are synchronized.
> Statements below describing migration 4 as pending, the eighteen-policy baseline,
> or CLI access as unavailable describe the earlier preparation phase and are superseded.
> Live Auth/SMS configuration and real SMS delivery remain unverified.

Project: `kciwxgfvpozgmnaypyxb`. Date: October 19, 2026.
Status: **local preparation tested; live Auth configuration and real OTP are unverified**.
Do not call this phase complete or production-ready until the live configuration is
known and real delivery is proven or an actual provider-configuration blocker is recorded.

## Evidence and access boundary

The user externally verified the three original migrations are already applied:
restrict_rls_auto_enable, identity_services, effective_product_access. Live has ten
RLS-enabled tables, eighteen policies, thirteen services/flags/availability entries
all disabled, approval-gated Driver/Business access, and no production app users.
The platform helper denies PUBLIC/anon/authenticated execution. These facts are
user-supplied, not management observations from this session. Do not reapply those files.

Fresh tool discovery found no callable Supabase operations despite the installed
integration. No local management credentials or actual public-key configuration
are available. The user explicitly confirmed Auth settings have not been inspected.
No live request, OTP send, user creation, migration, or provider update was performed.
Unknown provider state must not be described as confirmed missing credentials.

## Required external read-only inspection

Record only non-secret configuration: Phone Auth enabled, signup/phone-confirmation
behavior, SMS provider, credential-presence booleans, OTP length/expiry, resend interval,
SMS/OTP/verification rate limits, CAPTCHA, site URL, redirect/deep-link allowlist, and
enabled Auth hooks (including Send SMS/Before User Created). Do not export hook URLs
containing secrets, hook signing keys, provider keys, JWTs, or test-OTP values.

Inspect the user-created trigger and function definition/owner/grants. Confirm
it remains attached to auth.users and creates profiles/customer membership/customer
profile without interpreting client metadata. Review any additional signup hook or
trigger before sending a test SMS: one failing hook can prevent signup altogether.

## Configuration preparation

Mobile reads the supplied project URL and public key from root `.env` copied from
`.env.example`; Admin uses `apps/admin_web/.env.local` from its own example. Both
examples have the correct URL and a blank public key. No service-role key is needed.
Never put management/SMS secrets in these client configuration files or Dart defines.
Set AUTH_OTP_LENGTH and AUTH_RESEND_SECONDS to match inspected live/provider policy;
client timers do not replace server limits. Supabase/provider configuration controls
expiry. Never enable SMS auto-confirm or fixed test OTPs to claim a real delivery test.

Hosted projects require Phone Auth enabled and a working SMS provider in Supabase
Authentication > Providers > Phone. Provider secret values belong in those protected
server-side settings, not chat, Git, Flutter, or browser environment variables.
For an optional local provider test, use a separate ignored server-only environment
and the CLI's env substitutions, never the root mobile environment. Supported setup
fields are documented in the [official CLI config reference](https://supabase.com/docs/guides/local-development/cli/config).

| Provider option (not a selection or configured-state claim) | Required configuration names |
| --- | --- |
| Twilio SMS | auth.sms.twilio.account_sid, auth_token, message_service_sid |
| Twilio Verify | auth.sms.twilio_verify.account_sid, auth_token, message_service_sid (Verify service) |
| MessageBird | auth.sms.messagebird.access_key, originator |
| Vonage | auth.sms.vonage.api_key, api_secret, from |
| Textlocal (community-supported) | auth.sms.textlocal.api_key, sender |

Configure only the selected provider. The official env-secret examples include
SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN, SUPABASE_AUTH_SMS_MESSAGEBIRD_ACCESS_KEY,
SUPABASE_AUTH_SMS_VONAGE_API_SECRET, and SUPABASE_AUTH_SMS_TEXTLOCAL_API_KEY.
No credential values or provider account are created here.

SMS OTP itself requires no RydVia DNS change. Provider sender identity/route
registration is a separate requirement; inspect the selected provider's Ghana rules.
For Twilio specifically, [Ghana guidance](https://www.twilio.com/en-us/guidelines/gh/sms)
calls for sender registration for MTN and recommends a pre-registered alphanumeric
sender for full coverage. [Trial limitations](https://www.twilio.com/docs/usage/trials)
can restrict recipients/countries; verify account eligibility and
[SMS geographic permissions](https://www.twilio.com/docs/messaging/guides/sms-geo-permissions)
or [Verify geographic permissions](https://www.twilio.com/docs/verify/preventing-toll-fraud/verify-geo-permissions)
for Ghana. Do not assume a trial can deliver to arbitrary Ghana recipients.

Current clients do not implement CAPTCHA challenges. If live Auth requires CAPTCHA,
add challenge/token handling before sign-in testing. Do not disable protection for
convenience. SMS-only numeric verification does not use an OAuth callback, but inspect
site/redirect settings and platform deep-link claims anyway; this phase does not
register unneeded custom schemes or claim OAuth/recovery links are validated.
See [Phone Auth](https://supabase.com/docs/guides/auth/phone-login) and
[rate-limit guidance](https://supabase.com/docs/guides/auth/rate-limits).

## App/service verification

All three mobile apps share the reviewed auth layer. The Ghana flag and +233 prefix
remain visible before focus; users may type national or international format without
the prefix being doubled. Input is normalized to +233 followed by nine national digits
in both controller and SDK adapter. Invalid numbers stop before transport. No local
phone-number persistence or sensitive production logging was added.

Mocked HTTP tests exercise the actual Supabase SDK (not a live service): public-key
SMS request without role metadata, numeric SMS verification, session recovery, local
logout, safe expired-code/rate/provider errors, and missing/mismatched profile denial.
UI/controller tests cover loading/retry/countdown, OTP paste, onboarding, role gates,
session revocation/restoration, and responsive Ghana input. Production sessions use
platform secure storage; device persistence/refresh still needs real-device validation.
SDK debug output is disabled at application startup. Reports/logs must omit actual
OTP/token values and real phone numbers; record only an appropriately masked recipient
after consent. No real recipient has been recorded in this repository.

Admin OTP remains server-only, rejects self-signup, verifies Auth users plus database
Admin membership on protected pages/API routes, and clears local cookies on logout.
Staff role assignment requires an audited privileged server/database action. Customer
signup metadata cannot assign Admin or any staff role.

## SECURITY DEFINER review: keep complete_onboarding

The authenticated-executable definer function is an intentional constrained write
boundary, not an unrestricted administration API. Normal callers have no direct profile
UPDATE grant. The RPC fixes an empty search_path, fully qualifies objects, derives
the target solely from auth.uid(), rejects absent authentication, accepts only the
three product request strings, bounds the name, and updates only that user's name
and onboarding state. Driver/Business inserts default pending and ON CONFLICT DO
NOTHING preserves existing approvals/requests. It never INSERTs user_roles or accepts
a target user ID, approval status, or staff-role parameter. Anonymous execution is
revoked, including explicit default grants. No dynamic SQL is used in this RPC.

Keep it. Do not grant direct writes or convert it to invoker without redesigning the
write boundary. The advisor warning deserves continued review rather than blanket
suppression; see [Supabase's Data API guidance](https://supabase.com/docs/guides/api/securing-your-api).
Tests reject admin, operations, finance, support, analytics, and null role requests,
and confirm repeated onboarding preserves approved application state.

## Prepared additive migration and advisor review

`20261019000300_auth_bootstrap_and_policy_cleanup.sql` is NEW, local-only, not applied
to production. The original three applied files remain byte-for-byte unchanged.
It adds the missing service_availability(flag_key) index; preserves vehicles_driver_idx;
makes the private signup trigger replay-safe using exact-key ON CONFLICT DO NOTHING;
and replaces eight overlapping Admin FOR ALL policies with equivalent dedicated
INSERT/UPDATE/DELETE policies. Existing SELECT policies remain. After this candidate,
there are thirty-four policies with one authenticated SELECT policy per app table.
The eighteen-policy count remains the externally verified current live state.

No tables/data, role grants, approvals, service gates, or RLS flags are removed or
relaxed. Policy replacements are transactional. Do not drop a vehicle index merely
because an unused-index advisor has no early-stage traffic history. Read the
[official advisor reference](https://supabase.com/docs/guides/observability/advisors).

Before external application, compare current policy definitions/names, trigger body
and ACL, and existing index definitions against the verified baseline. A collision
or drift must stop application. Trial the candidate on disposable Supabase, then
apply only this new version externally. Verify 34 policies, one SELECT path per table,
unchanged grants and RLS, both indexes, no client EXECUTE on bootstrap, duplicate
bootstrap safety, and unchanged roles/approvals/flags. Never replay migrations 000-002.

## Controlled real OTP test gate

After configuration is inspected and a provider is usable, choose a consenting test
recipient outside documentation/chat. Request a real code; confirm receipt and verify
it inside the application. Record only pass/fail, masked recipient, timestamps, and
non-sensitive provider error categories. Do not put the code in logs or test reports.
Verify actual auth.users/profile/customer membership/customer profile creation;
onboard Customer, request pending Driver/Business, and verify roles alone cannot
unlock those products. Approval plus membership should unlock; revoke/suspend and
confirm access closes. Provision/test Admin through the controlled staff path.

Test process restart/session restore/refresh/logout, invalid and truly expired codes,
resend, and bounded rate-limit handling without SMS flooding. Inspect failed deliveries
through protected provider tools, without copying PII/tokens here. A mocked expired
response is not a real expiration/delivery test. Do not proceed to ride booking yet.

## Requested phase report

| Item | Current result |
| --- | --- |
| 1. Phone Auth enabled | Unknown; user confirms settings not yet inspected. |
| 2. SMS provider | Unknown, including credential presence; not confirmed absent. |
| 3. OTP delivery | Unverified. |
| 4. Real OTP | Not run; live tools/config/public key/controlled recipient unavailable. |
| 5. Auth user creation | No live users created; SDK session transport mocked only. |
| 6. Profile bootstrap | Applied migration defines bootstrap; actual live SMS signup remains pending. Replay hardening tested locally. |
| 7. Customer bootstrap | Local SQL tests verify Customer-only membership/profile; live SMS signup pending. |
| 8. Driver | Local request pending; membership alone denied, approved profile plus role required. |
| 9. Business | Same approved-profile-plus-membership boundary verified locally. |
| 10. Admin | No client self-assignment; server session and DB-role gate tested. |
| 11. Session restore | SDK recovery/controller restoration tested locally; device/live pending. |
| 12. Logout | Local SDK session removal and Admin cookie clearing tested; device/live pending. |
| 13. Security | Constrained onboarding retained; no client service-role or sensitive logging added. CAPTCHA remains an explicit conditional blocker. |
| 14. Advisors | Flag-key index and SELECT-policy cleanup prepared; vehicle index preserved. |
| 15. New migration | 20261019000300_auth_bootstrap_and_policy_cleanup.sql; pending external review/application. |
| 16. Tests | All 56 web/PostgreSQL and 51 Dart/Flutter tests passed locally, along with analysis, zero-change scoped formatting, lint/types/builds/HTTP/token/native checks. CI reruns disposable Supabase pgTAP (24 assertions). No live test equivalence claimed. |
| 17-18. Commit/push | New commit required after all available local checks; no amend or force push. |
| 19. Blockers | Live Auth/provider inspection, public configuration, any provider/sender requirements, CAPTCHA if enabled, and controlled real-device SMS/session testing. |
| 20. Next phase | External read-only Auth inspection, safe configuration of the selected provider if required, and controlled real send/verify plus role/session validation. |
