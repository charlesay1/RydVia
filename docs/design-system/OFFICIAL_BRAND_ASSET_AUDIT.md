# Official brand asset enforcement

Audit date: October 20, 2026. Canonical source: `assets/brand/manifest.json`.
Approved logo masters: **NO**. Approved icon masters: **NO**.
Production release: **BLOCKED BY APPROVED MASTER ARTWORK**.

## Inventory and classifications

| Material | Classification | Result |
| --- | --- | --- |
| Primary symbol SVG, custom wordmark SVG | MISSING | No approved files; never reconstruct from the written brief. |
| Horizontal/stacked lockups; light/dark/monochrome variants | MISSING | No CSS inversion, recoloring or synthetic lookalikes. |
| App-icon master; Customer/Driver/Business launcher artwork | MISSING | No exports generated. |
| Favicon, PWA icons, Apple touch artwork | MISSING | Both web applications remain unbranded at these slots. |
| Official brand board/source guidelines; clear-space/minimum-size rules | MISSING | Do not invent dimensions or approve text specifications as artwork. |
| assets/brand/README.md | REFERENCE-ONLY | Text requirements and handoff instructions, not a logo source. |
| Four campaign WebPs | BACKGROUND-ONLY / generated provisional candidates | Inspected unchanged originals; no RydVia lettering, symbol, decal, launcher or embedded UI observed. Incidental product/vehicle details are not authoritative brand assets. |
| Local ignored UI screenshots | REFERENCE-ONLY | QA captures only; never crop, trace or extract a logo from them. |
| Nine existing 1×1 iOS launch PNGs | PROVISIONAL / duplicate placeholders | Retained; not launcher masters or hero backgrounds. |
| Existing Manrope/OFL and color tokens | Retained UI foundations | Not substitutes for the custom wordmark or approved graphic masters. |

No fake/generated RydVia logo usage was found in supplied campaign images, and none
was removed or newly created. No mockup, photograph or screenshot has been promoted
into an approved brand master. The four source images and all responsive copies
remain byte-for-byte unchanged.

## Shared UI slots

Flutter's `RydViaBrandSlot` provides one shared application-bar slot for Customer,
Driver and Business. Its plain app-name label has a visible DEV marker, a tooltip
and explicit accessibility text identifying pending official artwork. It loads no
fake logo, and remains legible/truncates safely at large text sizes.

Web `BrandSlot` is shared by the Public header/footer and Admin login/sidebar.
It visibly says Artwork pending; duplicate footer decoration is hidden from screen
readers. Normal page headings and navigation text remain ordinary UI copy. These
are development interfaces, not an attempt to reproduce custom Manrope letterforms.
Do not interpret their existence as completed official-logo rendering.

Photography remains separate from all brand slots, headlines, phone/+233 controls,
CTAs, legal links and navigation. No rasterized screen or AI-rendered text is used
as UI. The established palette, Manrope UI typography, spacing, themes, focus states
and Auth functionality remain. Dark/light slots use semantic text colors and no
asset filters. An approved SVG/native renderer will be integrated only after real
masters and usage guidelines are supplied; no dependency or fake SVG was added now.

## Native and web readiness

All three native products lack mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi launcher art, adaptive
foreground/background and monochrome layers. Android has no icon reference to a
nonexistent file. iOS has 19 AppIcon slots per app, including marketing artwork,
with no image filenames. These are configured empty slots, not completed icons.
Existing OS launch backgrounds are retained and distinct from launcher branding.

Admin and Public each lack favicon, PWA manifest/icons and Apple touch artwork.
They have no separate native launcher identity. No placeholder icon URL was added
to metadata, so this change creates no broken official-asset reference.

The bootstrap script previously stripped Android icon references unconditionally.
It now strips only newly generated Flutter template references; rerunning against
an existing app preserves future approved icon wiring. Native files were not
regenerated during this task.

## Approval and release controls

The manifest contains all sixteen required slots with null paths/approval records.
Verified handoff requires the actual master file, owner/reviewer identity, approval
date, provenance and SHA-256. The validator checks canonical containment (including
symlinks), recorded file hashes, classification, completeness and unregistered art.
Metadata is not a substitute for a human checking the authority and artwork itself.

`npm run check:brand` validates development inventory and runs in CI. Missing assets
are explicitly reported as blocked rather than filled with guesses. The separate
`npm run check:brand-release` must fail until masters, approved UI integration and
native/web exports are complete. The release check is not a deployment command;
no deployment workflow is present, and direct development builds remain available.
Any future distribution workflow must require this gate before publishing.

Never edit the register merely to turn a check green. Do not use a generated image,
provisional mockup or typed placeholder as provenance. Once genuine artwork arrives,
integrate exact approved variants with intrinsic proportions, supplied clear space,
appropriate native/SVG rendering and reviewed export mappings; preserve the masters.

## Validation

Full Flutter validation passed: zero-change formatting, clean package/application
analysis and 65 tests. Web lint/typecheck, 67 tests, both builds and Admin access
regression checks passed. Brand tests cover missing records, canonical paths,
unregistered art, approval hashes, accessible placeholder labels and the expected
nonzero release gate. Token checks (86), native structure checks (42), platform-script
syntax, CI YAML, secret scanning and repository verification passed.

Responsive browser QA covered 20 public/Admin viewport/theme combinations without
overflow or broken campaign images. Six Flutter welcome captures retain the DEV
marker, real UI controls and existing photography. No approved logo pixels exist
to evaluate for distortion or clearance; those checks remain blocked, not passed.
Final CI and native-device approval remain required. No database, migration, Auth
configuration or RLS changes are part of this task.
