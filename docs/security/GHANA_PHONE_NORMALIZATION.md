# Ghana phone identity contract

All Customer, Driver and Business apps use `normalizeGhanaPhone` from
`packages/rydvia_core`. Keep normalization out of app-specific screens. The shared
controller validates before sending; `SupabaseAuthRepository` independently applies
the same normalizer immediately before both OTP request and verification. This
protects callers that bypass the UI/controller. Verification uses the canonical
phone saved by the successful request, including resend. No direct Twilio client
or new phone storage is introduced.

Contract: raw input -> remove spaces/hyphens/parentheses -> distinguish Ghana
national/international prefix -> validate nine-digit mobile subscriber -> E.164.

| Accepted input (synthetic test examples) | Canonical value |
| --- | --- |
| `0244163371` | `+233244163371` |
| `024 416 3371` | `+233244163371` |
| `24 416 3371` | `+233244163371` |
| `+233244163371` | `+233244163371` |
| `+233 24 416 3371` | `+233244163371` |
| `233244163371` | `+233244163371` |
| `(024) 416-3371` | `+233244163371` |

Only national input may lose a single trunk zero. Country-code input with a trunk
zero (`+2330…` or `2330…`) is rejected rather than silently repaired. Empty/alphabetic
input, wrong lengths, repeated zeros/country codes, multiple plus signs, `00233`,
other countries, extensions, dots, slashes and zero-width characters are rejected.
Subscriber digits must start with 2 or 5; this is format validation, not proof of
allocation, number ownership or SMS delivery. Normalization is idempotent.

The existing Ghana flag/+233 prefix and local/international input UX remain. The
OTP screen displays the canonical identity; invalid values produce only
`Enter a valid Ghana mobile number.` The Admin server-side TypeScript validator
implements the equivalent strict contract, with parity cases in web tests.

Privacy: no phone diagnostic logging is needed. `SafeLogger` accepts only fixed
operational events and timestamps, with no arbitrary PII/OTP/token metadata. Tests
verify those fields and safe error mapping even when a synthetic provider response
contains phone/code text. Raw input is transient UI state; canonical identity is
used in the Auth request and in-memory flow state. No raw-phone database field or
new migration is needed. Existing stored production identities are not rewritten.

Coverage includes every accepted format and malformed-prefix rejection, idempotence,
SDK HTTP payloads for request and verification, zero transport calls for invalid
input, and Customer/Driver/Business UI/controller paths. Transport tests use the
actual Supabase SDK with a mocked HTTP client: they send no SMS and use no secrets.

Run `scripts/validate-flutter.ps1` for all Dart packages/apps and `npm test` for
web/database tests. The broader validation also runs web lint/typecheck/builds,
Admin HTTP gates, token consistency and native structure checks. Follow
[the Auth checklist](AUTH_CONFIGURATION_CHECKLIST.md) before a separately authorized
real send/verify trial. Live provider setup and real-device SMS/session checks are
still pending; this change does not establish production OTP readiness.

Validation for this change: 39 shared Auth tests, three core validation tests and
18 UI tests plus the existing logging test pass (61 Dart/Flutter tests total).
All 57 web/PostgreSQL tests, lint, typecheck, both Next.js builds, Admin HTTP gates,
86 token assertions and 42 native structure assertions pass. Formatting checks
report zero changes after formatting; package/application analysis is clean.
Local Docker's Linux engine is unavailable, so disposable Supabase pgTAP runs in
GitHub CI rather than on this host. No live database or SMS test is performed.
