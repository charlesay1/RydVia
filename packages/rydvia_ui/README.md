# rydvia_ui

The preserved implementation package is exposed to new apps through
`package:rydvia_design_system/rydvia_design_system.dart`. Existing `rydvia_ui`
imports remain supported. There is one token and component system.

## Themes and preferences

Implement `RydViaThemeStore` using the app's existing persistent settings store.
Call `WidgetsFlutterBinding.ensureInitialized()`, then await `controller.restore()`
before `runApp`. Present startup or retry UI if storage fails. Unknown stored values
fall back to system mode. Failed writes propagate and leave the selected mode intact.
Await a change before accepting the next one; conflicting writes are rejected.
The controller does not write to disk until an application supplies this adapter.

Rebuild the existing `MaterialApp` or `MaterialApp.router` with a `ListenableBuilder`
listening to the controller. Configure:

```dart
theme: RydViaTheme.light(),
darkTheme: RydViaTheme.dark(),
themeMode: controller.mode,
themeAnimationDuration: reduceMotion ? Duration.zero : RydViaMotion.theme,
themeAnimationCurve: Curves.easeInOut,
```

Resolve `reduceMotion` from platform accessibility settings at the app root and
rebuild when those settings change. Under a `MediaQuery`, use
`RydViaTheme.animationDuration(context)`. The controller defaults to
`ThemeMode.system`; persist overrides using `setMode(ThemeMode.light)`,
`setMode(ThemeMode.dark)`, or `setMode(ThemeMode.system)`.

Licensed variable Manrope and its OFL license are bundled under `fonts/` and
registered at weights 400, 700, and 800. Typography references the package-qualified
family; Next.js consumes the same font file through the design-system web entry point.
There is no runtime external font request.
Use `Theme.of(context).textTheme` for UI and the `price`/`kpi` tokens for numeric emphasis.
For wide layouts, choose `display` and `h1` deliberately; allow text scaling everywhere.

## Components

The package exports `RydViaButton`, `RydViaTextField`, `RydViaSearchField`,
`RydViaCard`, `RydViaServiceTile`, `RydViaServiceGrid`, `RydViaVehicleCard`,
`RydViaBottomSheet`, `RydViaAppBar`, `RydViaChip`, `RydViaPrice`,
`RydViaDriverCard`, `RydViaTripCard`, `RydViaMapControl`,
`RydViaEmptyState`, `RydViaLoadingState`, and `RydViaErrorState`.

Labels and formatted prices come from the host app. Default English state labels
are scaffolding; add app localization before shipping. Material outlined icons are
used consistently. The app bar displays a screen title; it is not a logo lockup.

`RydViaServiceGrid` wraps naturally without fixed row heights. Feed it a new
`RydViaServiceCatalog` on each authoritative backend snapshot. Missing flags are
disabled. Supply the catalog in Ride, Deliver, Move order with secondary services
afterwards. Service groupings support multiple vehicle products under the same group.
Filtering never changes an active booking object. Never treat client visibility as
booking authorization.

## Web integration

Import `web/tokens.css` into the existing dashboard framework. Apply semantic
variables such as `--rv-background`, `--rv-surface`, `--rv-text`, and `--rv-action`.
With no `data-theme` on the document root, the CSS follows system preferences.
Set `data-theme="light"` or `data-theme="dark"` for a manual override. The existing
web settings layer must persist it and restore it before first paint. CSS does not
implement persistence. Theme durations become zero under reduced motion.

The six brand colors are immutable. `accessibleIndigo` is a semantic action color
for normal-size white text; `accessibleLightIndigo` provides readable dark-mode
action labels and pairs with Navy text on filled buttons. `lightSecondaryText` is used where muted slate does not
meet the target on warm off-white. Coral is an accent or warning treatment, never
an error. Success uses accessible green on light surfaces. Input boundaries use
secondary text color for control contrast; subtle borders are reserved for surfaces.

## Verification

`flutter test` covers palette, theme contrast, system following, persisted overrides,
storage failure, service visibility and reflow, responsive layouts at 320/768/1280,
double text scale, loading/error states, and basic accessibility guidelines.
The 18 UI tests have been executed successfully during bootstrap. See the current
engineering report for whole-product results. Goldens require approved assets and
reviewed rendered screens; no unreviewed
golden baselines were generated.

Framework references: [ThemeData](https://api.flutter.dev/flutter/material/ThemeData-class.html),
[ColorScheme](https://api.flutter.dev/flutter/material/ColorScheme-class.html), and
[MaterialApp theme animations](https://api.flutter.dev/flutter/material/MaterialApp/themeAnimationStyle.html).
