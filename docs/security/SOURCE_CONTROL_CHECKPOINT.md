# RydVia source control checkpoint review

Date: October 19, 2026. Local branch: `main` (no commits at review time).
Origin: `https://github.com/charlesay1/RydVia.git`.
GitHub confirms the repository is public, empty, and has default branch `main`.
Git transport also returned no existing HEAD/main reference. No force push is planned.

Proposed commit message:
`Bootstrap RydVia apps, design system, auth foundation and Supabase security`

## Scope reviewed

The initial inventory contains 288 files: five application surfaces and native
scaffolding, shared packages/design tokens/font assets, dependency lockfiles, tests,
CI, setup/security/architecture documentation, local scripts, and Supabase artifacts.
This review document adds one file. Build/tool caches, temporary audit artifacts,
real environment files, and signing material are excluded.

The repository-local author uses the verified GitHub account `charlesay1` and its
GitHub noreply address. No global author or credential setting was changed.

## Secret and source review

The complete Git-eligible inventory was scanned for sensitive filenames, private
key headers, Supabase secret/management keys, service-role JWTs, GitHub/cloud/API
token signatures, credential-bearing URLs, and literal credential assignments.
No credential findings were detected. Test fixtures include explicitly synthetic
invalid keys; the environment examples contain blank public-key values.

Source review confirms public client-key configuration in Flutter and server-only
Supabase SSR usage in Admin; no browser/client service-role credentials are used.
The real `.env`/`.env.*`, signing files, credential stores, `.tools`, `.artifacts`,
dependency/build caches, and native local settings are ignored. `.env.example`
files are intentionally included as non-secret configuration templates.

The exact staged blobs were also scanned: 289 files, no detected secret or sensitive
path findings. Staging contains only blank environment examples, not real environment
configuration. A trailing space in the bundled font license was removed without
changing its wording. Pattern scans reduce risk but are not proof that every possible
credential format is absent.

## Validation rerun

- 53 web/PostgreSQL/security tests passed across ten files.
- Analysis passed across all twelve Dart/Flutter projects; 44 tests passed.
- Both Next.js production builds, lint, type checking, and local Admin HTTP checks passed.
- Dart formatting passed; 86 token/contrast/consistency assertions and 42 native
  identity/structure checks passed.
- Repository origin and actual Git-ignore probes passed.
- Supabase pgTAP cannot run here: Supabase CLI is absent and Docker's Linux engine
  is unavailable. Android/iOS compilation and real OTP/device validation remain pending.
- `npm audit --omit=dev --audit-level=high`: zero reported vulnerabilities.
- Full `npm audit --audit-level=high`: five high-severity findings along one
  development-only dependency chain, described below. This check does not pass.

## Unresolved dependency finding

`eslint-config-next@16.4.2` -> `@next/eslint-plugin-next@16.4.2` ->
`fast-glob@3.3.1` -> `micromatch@4.0.8` -> `braces@3.0.3`.

The [reviewed advisory GHSA-vfj7-8cjw-p6xm](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm)
describes stack exhaustion from deeply nested brace patterns. The advisory lists
no patched version. Official npm metadata confirms the latest braces version is
3.0.3 and the current Next lint plugin still depends on fast-glob. Updating fast-glob
to 3.3.3 would retain micromatch/braces. The installed chain is development lint
tooling; the production-only dependency audit is clean. That limits the observed
scope but does not erase the finding.

No forced downgrade, audit suppression, unreviewed dependency fork, or removal of
framework lint checks was used to claim a clean audit. The user's instruction
conditions checkpointing/pushing on successful validation and no security issue.
The user explicitly approved **creating a local commit and holding the push** after
reviewing this finding. This authorizes the local source checkpoint with the finding
documented; it does not clear the dependency audit or authorize publication. No push
will be attempted in this checkpoint.

## Migration review

The confirmed application order is:

1. `supabase/migrations/20261019000000_restrict_rls_auto_enable.sql`
2. `supabase/migrations/20261019000100_identity_services.sql`
3. `supabase/migrations/20261019000200_effective_product_access.sql`

No destructive SQL statements were found. All ten intended public app tables
enable RLS. Isolated PostgreSQL tests confirm anon/authenticated cannot execute
the helper after migration 000, including PUBLIC grants, and automatic RLS remains
functional. Unexpected inherited grants abort and roll back. Those are local
results; the externally reported live helper privilege finding is still pending
external migration application. Existing table/private-schema conflicts fail without
overwriting data, and existing Auth IDs are preserved by the explicit backfill.

No applications were deployed and no live Supabase operation was attempted.

## Controlled Supabase next step

The local checkpoint is authorized; publication remains held. After resolving the
dependency/publication decision and confirming the source revision to apply,
use an externally authorized Supabase environment to follow
[MIGRATION_APPLICATION.md](MIGRATION_APPLICATION.md): recheck project/history/schema
and data preflight, trial on a disposable Supabase stack, apply the three versioned
files in order, verify helper ACL/RLS/grants, then configure and validate real Phone
Auth/SMS and product session gates. Supabase is not production-ready.
