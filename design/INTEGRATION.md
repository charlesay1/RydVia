# RydVia integration and asset ledger

This document records the original design-only integration plan. The later
[bootstrap architecture](../docs/architecture/OVERVIEW.md) and
[engineering report](../docs/BOOTSTRAP_REPORT.md) supersede its implementation status.

## Authority

The earlier master brand directive locks these six colors: Indigo #4C6BFF,
Midnight Navy #0F1B3D, Violet Blue #6366F1, Warm Coral #FF8A6B,
Charcoal #1F2937, and Warm Off White #FAF7F2. The newer design brief retains that
direction. Accessible semantic variants supplement the palette without replacing it.

The brand expression is “Premium mobility. Warm technology. Effortless movement.”
The approved custom RydVia wordmark is distinct from interface typography.

## Missing source assets

No logo artwork or brand board was present. Obtain the original vector symbol and
custom wordmark, approved horizontal and stacked lockups, light/dark variants,
monochrome variants, and brand board. Preserve the flowing interconnected R + V,
integrated upper-right Coral pin, original silhouette, proportions, and approved
gradient treatment. Do not draw, trace, generate, or substitute a replacement.

Once assets are supplied, use the approved horizontal lockup in dashboard sidebars
and roomy headers, the approved symbol in compact controls, and the approved full
lockup on splash/login and receipts. Verify clear space and minimum sizes against
the brand board rather than inventing measurements. Keep gradients confined to
approved artwork. Verify contrast on Navy, Deep Midnight, White, and Warm Off White.
Vehicle markers must use approved marker artwork, not an improvised brand symbol.

Launcher exports remain blocked: iOS 1024x1024, Play Store 512x512, Android adaptive
foreground/background with platform safe areas, monochrome themed icon, and web
favicons. Preserve the original symbol, use a Navy background where approved,
omit text and baked corner rounding, and verify dimensions/safe areas automatically.
Do not create separate applications merely to represent product roles.

## Application integration still required

The existing repository and Supabase project locations are recorded in the
[repository audit](../docs/REPOSITORY_SUPABASE_AUDIT.md). GitHub currently reports an
empty repository, and the live backend has not yet been inspected. Use the next
master prompt and verified project state before adding dependencies or changing
authentication, routing, deployment, or data contracts. Connect theme persistence,
maps and map styles, native launch backgrounds,
status/navigation bars, and the existing user settings screen. Verify cold startup
in both themes and changes while a map or bottom sheet is visible.

Compose the customer home around Ride, Deliver, Move, then secondary services.
Implement and validate complete ride, delivery/logistics, and towing workflows using
the current backend. This package provides primitives, not booking orchestration,
fare calculation, dispatch, tracking, payment, or rating functionality.

Build role-specific dashboard layouts in the existing web framework using the same
tokens. KPI styles, chart palettes, navigation, responsive tables, filters, date
ranges, and non-color status labels need real operational data and screen validation.

## Service availability and existing bookings

The backend must supply a versioned service catalog or the equivalent existing
contract, stream or refresh changes, and authorize new requests transactionally.
Clients must invalidate a disabled selection and refresh an estimate before confirming.
Recheck availability server-side at quote and booking creation, including direct/deep
link requests. Fail closed for new requests when authoritative availability cannot
be established; show a retryable error rather than a stale enabled list.

Recommended lifecycle for review when the backend is available: disabling a service
stops new quotes/bookings; already accepted bookings retain their snapshot and
continue through completion/cancellation under existing rules. Cancelling in-flight
work requires a separate explicit operational action with notification and refund
handling. This policy is a proposal, not an implemented backend guarantee.

## Validation still required

Run Flutter dependency resolution, analysis, and tests with the supported SDK.
Run existing app regression suites, dashboard lint/type checks/tests, backend
availability/authorization tests, and navigation/deep-link tests after integration.
Review screen-reader output, keyboard focus, text scaling, localized long labels,
reduced motion, real map transitions, and launcher assets on devices. Capture and
approve goldens only after licensed Manrope and approved artwork are available.

No application screens were modified because no application source was present.
No existing backend integration, authentication, or deployment configuration was changed.
