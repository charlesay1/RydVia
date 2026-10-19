# RydVia bootstrap architecture

## Product boundaries

Exactly five deployable surfaces exist. `apps/customer_app`, `apps/driver_app`, and
`apps/business_app` are Flutter applications with distinct Android/iOS identities.
`apps/admin_web` and `apps/public_web` are Next.js App Router / TypeScript workspaces.
Courier jobs stay in the Driver App. Operations, finance, support, and analytics
remain Admin modules, not extra standalone applications.

## Shared packages

| Package | Responsibility |
| --- | --- |
| `rydvia_ui` | Preserved implementation of shared tokens, themes, components, service layout, and licensed Manrope |
| `rydvia_design_system` | Stable Flutter re-export and web theme/CSS/font entry points; no second token system |
| `rydvia_core` | Environment validation, Ghana phone/OTP validation, safe domain failures |
| `rydvia_models` | Backend-independent role, access profile, and service availability models |
| `rydvia_api` | Services repository contract and Supabase data adapter |
| `rydvia_auth` | Shared auth repository/controller, secure session persistence, theme preference adapter, welcome/OTP/onboarding/screens, and app session gate |
| `rydvia_location` | Explicit-permission location and map-appearance contracts; no implicit tracking |
| `rydvia_logging` | Allowlisted operational event records with no arbitrary PII/error payloads |
| `rydvia_analytics` | Typed opt-in analytics boundary with a no-op default |

Apps choose a product role at their composition root. Widgets call controllers and
repositories, not Supabase APIs. The startup composition creates Supabase adapters.
Auth is implemented once; changing a backend adapter does not require rewriting
welcome/OTP screens. Constructor injection enables tests without contacting the live
project. The admin dashboard has an injected fixture repository, not a live-data client.

## Authentication and navigation

Flow: restore session → fetch `access_profile` from the backend → welcome/code,
onboarding, pending approval, or product workspace. Phone numbers normalize to Ghana
E.164. OTP input uses a single native editing control for paste, backspace, numeric
keyboard, OS autofill, and screen-reader consistency. A full-length code advances
automatically. Resend timers and request locks prevent concurrent submissions; the
backend/provider must enforce authoritative rate limits. Expired/invalid codes and
network errors offer safe messages and retries without logging the input.

Supabase handles token refresh. Auth events, app resume, and manual approval checks
refresh server-backed access. Stale profile responses cannot restore a signed-out
session. Session credentials use platform secure storage; theme preferences use
shared preferences. A selected app role is not evidence of authorization. Driver
and business applicants create review requests and pending profiles; they never
self-grant access. Staff/admin roles require trusted provisioning.

## Services and availability

The local migration defines Cars, Motorbike, Pragya, Delivery, Aboboyaa, Van, Pickup,
Truck, Moving, Towing, Scheduled, Intercity, and Business. Effective availability is
the intersection of service, availability, and feature-flag gates. All default off.
The customer home filters availability snapshots and reflows naturally. It refreshes
at entry, on app resume, and by explicit refresh; no Realtime subscription is enabled.
Booking submission is not implemented in this phase. Future quote/booking RPCs must
check roles and availability in their own database transaction, including deep links.
The supplied availability guard alone is not a complete booking authorization layer.

Disabling a service should stop new requests; accepted work should retain its
snapshot and follow existing completion/cancellation rules. There is no booking
schema yet, so this is a policy direction to implement with the later booking phase.

## Branding and web

`design/tokens.json` generates Flutter, CSS, Android launch colors, and iOS launch
colors. `rydvia_design_system` forwards the preserved UI implementation. Manrope and
its OFL license are centrally stored in `rydvia_ui/fonts`. Web uses Next local font
optimization and shared CSS; no runtime external fonts or image hotlinks are used.
Web preferences restore before content paint and follow system mode by default.

Native launch surfaces follow system light/dark tokens. Persisted manual appearance
is restored before Flutter content; native cold-start behavior with a manual override
still needs device QA and any necessary platform-specific synchronization.

## Scope boundaries

This is a tested foundation, not a finished transport service. Full bookings,
dispatch, GPS/navigation, payments, job/order management, live admin authentication,
support operations, crash/analytics backends, final imagery, approved launcher assets,
and production legal content remain outside the implemented phase. Existing shells
state unavailable capabilities instead of simulating production success.
