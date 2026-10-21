# RydVia shared design system

Canonical source: `design/tokens.json`. Preserve the six locked master colors.
`scripts/generate-tokens.ps1` emits Dart, CSS, Android launch themes, and iOS launch
colors/storyboards. Regenerate after changing canonical values and run token checks.
Generated Dart uses formatter-off directives to remain deterministic across tooling.

The existing `rydvia_ui` implementation is preserved. New apps import
`rydvia_design_system`, which re-exports it without duplicating styles. Web shells
use the same package's CSS, theme control/bootstrap, local font, and error boundary.
Accessible action/secondary/success/error variants supplement immutable brand colors.
Coral is not an error color; green remains an operational supporting accent.

Spacing, radius, typography, icon size, elevation, and motion are reusable tokens.
Manrope/OFL are bundled centrally; never use the interface font as a replacement
for the approved custom logo wordmark. See `assets/brand/README.md` for missing masters.

System appearance is default. Flutter manual overrides persist with shared
preferences; web uses guarded local storage and prepaint restoration. Controls and
bottom sheets observe reduced-motion settings. Native OS-themed launch surfaces
use token colors; manual-override cold starts still require device verification.

Mobile welcomes are native widgets with flexible, keyboard-aware scrolling, not
screenshots. Their shared photographic surface preserves the 3:2 campaign frame,
uses bounded decode sizes and has an icon fallback. Captions and forms remain on
solid surfaces. Generated campaign candidates await final brand/locality approval;
see `assets/photography/manifest.json` and `docs/design-system/VISUAL_ASSET_AUDIT.md`.
Phone selectors alone show the Ghana flag. Service tiles use one consistent Material
outlined icon family. Product roles share styling and differ through labels/content.

Important validation: light/dark contrast, large text, tap targets, service reflow,
OTP input/paste, errors/loading/retry, and theme persistence. Final screenshot/golden
approval and native launcher safe-area checks require the approved assets and device QA.
