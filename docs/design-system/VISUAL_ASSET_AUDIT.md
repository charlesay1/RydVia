# Real-world visual upgrade — October 20, 2026

## Existing assets and implementation

The initial tracked inventory contained nine PNGs: the three iOS `LaunchImage`
variants for each of Customer, Driver and Business. These are template launch
placeholders, not usable hero photography, logos or approved launcher icons.
All nine are byte-identical 1×1 PNGs: classified **placeholder / duplicate**.
They are retained; no asset was deleted. There were no existing hero photos,
screenshots, brand boards, stock-image hotlinks or approved vector logos to reuse.
Manrope/OFL, native launch colors, brand tokens, outlined icons, existing page
structure, Auth controls, legal routes and server-side authorization are retained.

Mobile welcomes previously used solid navy panels; the public hero used a text-only
navy scene. Admin login had no photography. The operational dashboard remains
unchanged and data-first. No approved logo was recreated or embedded in imagery.

## Asset mapping and provenance

Four standalone images were produced with the built-in imagegen tool. Each exact
prompt and review status is in `assets/photography/manifest.json`. These are
**generated Ghana/Accra-inspired campaign candidates**, not documentary photographs,
verified Ghana locations, actual staff/customer portraits or final brand-approved
assets. Do not describe their subjects as actual RydVia partners.

| Canonical asset in `packages/rydvia_ui/assets/photography` | Use | Review |
| --- | --- | --- |
| customer.webp | Customer welcome; public customer story | Natural phone interaction, cream/indigo wardrobe, practical sedan, leafy commercial setting. |
| driver.webp | Driver welcome; public driver story | Independent professional in navy polo beside an ordinary SUV; plausible mirrors, windows and wheels. |
| business.webp | Business welcome; public business story | Homewares/personal-care retail, tablet, POS, shelves and parcels; broader than food commerce. |
| ecosystem.webp | Public hero; Admin login side panel | Customer foreground, driver/car midground, merchant at shop edge; one coherent scene. |

Faces, eyes, hands, devices, bags, clothing and vehicle geometry were inspected at
source and rendered sizes. No obvious generation defects were observed at the
supplied resolution. This review is not a legal or documentary-authenticity claim.
The same restrained light, wardrobe and environment direction ties the four scenes
together. No flags, fake RydVia decals, logos, baked headlines, controls or watermarks
are used. Vehicle bodies at frame edges are intentional environmental framing;
no additional responsive crop removes a face. No repeated or visibly defective
people were accepted.

Final Ghana-locality, brand and legal review remains a release blocker. An owned,
licensed Ghana shoot can replace individual canonical files without recreating UI.
Approved vector logo/launcher masters and actual-device visual approval are separate
existing blockers. No changes here approve a deployment.

## Shared rendering and asset pipeline

Canonical WebP files are 1536×1024, approximately 175–203 KB each. Mobile bundles
them once through `rydvia_ui`; the shared widget bounds decode width by display
size/device ratio. `scripts/sync-photography.mjs` creates 768×512 exports and copies
the original WebPs to web public directories. These copies are deployment exports,
not independent sources. `--check` verifies exports without writing; normal sync
only changes missing/different files. Existing Next/Sharp tooling is reused; no
application dependency was added. Full PNG generation outputs remain in ignored
local QA storage and the original imagegen directory, not application bundles.

Web uses one shared `CampaignPhoto` component and Next Image with a local loader.
The configured source widths are exactly 768/1536; URLs serve locally hosted WebPs,
not third-party image hosts. Hero/login images load eagerly, secondary stories lazily.
Stable dimensions prevent layout jumps. Both platforms preserve the original 3:2
frame on every breakpoint with explicit cover/focal settings. Keeping the source
aspect ratio avoids destructive portrait/center cropping entirely.

Photography has no text overlay. All copy, headings, phone fields, buttons and legal
links remain accessible UI on solid token surfaces. Web photos have descriptive
alt text; repeated Admin and mobile decoration is excluded from screen readers.
Failure states retain the same frame and existing contrast tokens. Manual/system
appearance, reduced motion and focus styles are preserved.

## Validation

- Full Flutter package/application resolution, zero-change formatting, analysis
  and tests: 63 tests passed, including real asset decoding and fallback behavior.
- Existing welcome tests cover all three roles at widths 320/390/430/768 with
  double text scale; OTP/phone behavior and role gates continue to pass.
- Web lint, typecheck, 59 tests, both production builds and Admin HTTP fail-closed
  checks pass. Asset tests validate declared paths, dimensions, compression and
  byte-identical full-size web copies.
- Browser QA: public and Admin login at 320/390/768/1440/1920 pixels in light/dark
  (20 combinations); images loaded, 3:2 frames retained and no horizontal overflow.
  Missing-image fallbacks and visible keyboard focus passed. Admin preview used
  synthetic public configuration, with no live Auth/OTP requests or form submission.
- Six actual Flutter welcome captures (three roles × light/dark) were inspected.
  Headless test emoji/icon glyphs do not replace native-device verification.
- Screenshots are ignored QA artifacts under `.artifacts/visuals`, never screen
  assets. Final native compilation, hardware text rendering and platform safe-area
  checks remain pending.
- Run token/native checks, the shared secret scanner and repository verification
  before checkpointing. CI remains the final check of the pushed revision.
- The first CI run passed the visual tests but two PostgreSQL WASM cold-start
  cases exceeded the default five seconds. Only those two integration cases now
  have a bounded 30-second timeout; all SQL/RLS assertions remain unchanged.

No backend migration, service flag, role/profile policy or production SMS setting
is changed by this visual work.
