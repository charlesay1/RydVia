# RydVia repository and Supabase audit

Audit date: October 19, 2026. Scope: inspect the supplied existing project and all
previously created local work before integrating the next master architecture prompt.
Status: local and GitHub inspection complete; live Supabase audit blocked by access.

Historical starting-state audit. The subsequently supplied master bootstrap prompt
authorized local architecture and migration work despite pending live access. See
the [bootstrap report](BOOTSTRAP_REPORT.md) for the current repository and test state.

## Authoritative locations

- Local workspace: `C:\Users\ckora\RydVia`.
- GitHub: `https://github.com/charlesay1/RydVia.git`.
- Supabase reference: `kciwxgfvpozgmnaypyxb`.
- Dashboard: `https://supabase.com/dashboard/project/kciwxgfvpozgmnaypyxb`.
- Project URL: `https://kciwxgfvpozgmnaypyxb.supabase.co`.

These identify the existing project. They are not evidence of live backend settings.
The public project URL belongs in application environment configuration when a
runtime integration exists. No credentials were requested, read, written, or committed.

## Verified repository state

The authenticated GitHub connection successfully retrieved metadata for
`charlesay1/RydVia`: repository ID `1412559673`, visibility `public`, configured
default branch `main`, and reported size `0`.

The repository root contents request returned HTTP 404 with the explicit message
"This repository is empty." The branch-list request succeeded with `[]`. The
configured default branch name therefore does not establish an existing branch.

Evidence endpoints queried read-only:

- `https://api.github.com/repos/charlesay1/RydVia`
- `https://api.github.com/repos/charlesay1/RydVia/contents/`
- `https://api.github.com/repos/charlesay1/RydVia/branches`

The local root contains `README.md`, `design/`, `packages/`, and `scripts/` from
the earlier implementation. There is no `.git`, `AGENTS.md`, application directory,
Supabase configuration, migration, SQL file, environment file, or backend adapter.
All 17 previously created files were read during this audit, including generated
Flutter/CSS outputs, both widget test files, both PowerShell scripts, and documentation.

Git, GitHub CLI, Flutter, Dart, Node, npm, and Supabase CLI were not discoverable
through `Get-Command` in this execution environment. This describes tool discovery
here, not the contents of every other machine or development environment.

## Supabase verification matrix

| Area | Local evidence | Live verification |
| --- | --- | --- |
| Project configuration | No `supabase/config.toml` or linked-project metadata | Unverified |
| Environment variables | No `.env`, `.env.example`, runtime environment loader, or CI configuration | Unverified; deployment secrets were not accessed |
| Authentication | No Supabase client initialization, providers, redirect config, auth routes, or session adapter | Unverified |
| Migrations | No migration directory or SQL files | Remote migration history unverified |
| Database schema | No schema definitions or generated database types | Tables, views, functions, triggers, and grants unverified |
| Row Level Security | No version-controlled policies | RLS enablement, policy coverage, and authorization behavior unverified |
| Storage | No bucket definitions or storage API abstraction | Bucket visibility, limits, and storage policies unverified |
| Realtime | No subscriptions or channel management | Publication membership and channel authorization unverified |
| Edge Functions | No function source or deployment configuration | Deployed functions and their authentication settings unverified |
| Roles and profiles | No role/profile schema, claims, or ownership model | Role definitions and privilege enforcement unverified |
| API/service abstractions | UI-only `RydViaServiceCatalog`; no Supabase SDK dependency | RPC/REST contracts and booking authorization unverified |

The Supabase dashboard was attempted through the browser tool, but no browser
connection was available; its inventory returned no browsers. No dashboard page
was loaded. Plugin discovery found an available Supabase integration, but it was
not installed or connected. A connection suggestion was issued; it does not grant
access. No live SQL, Auth, Storage, Realtime, or Edge Function read was possible.

An application project URL alone does not supply management access. The absence
of local backend files is not evidence that the live project has no schema or RLS.

## Reusable work to preserve

Keep `packages/rydvia_ui` and the existing canonical `design/tokens.json` until
the master architecture calls for a specific change. Preserve the locked palette,
generated CSS/Dart consistency, themes, semantic color extension, shared components,
injected settings-store interface, and immutable service availability snapshots.
Preserve tests as a starting point; their presence is not proof of runtime correctness.

Important integration gaps found in existing work:

- Theme persistence is an interface, not a connected settings implementation.
- Service flags filter client presentation only. They do not authorize requests,
  consume a backend stream, or enforce booking lifecycle policies.
- No actual app composition, routing, authentication, map integration, or operational
  dashboard exists locally.
- Fonts and approved logo assets are absent. Typography cannot yet be visually approved.
- Flutter compilation, analysis, widget tests, and rendering remain unverified.

No package rename, app creation, new schema, policy change, function deployment,
or backend migration is justified by this audit alone. The next master prompt
will determine architecture; live inspection must precede backend structural changes.

## Security and environment handling for integration

Reuse the existing live Supabase project once authenticated access is available.
Inspect metadata and policy definitions before user rows or sensitive logs. Avoid
selecting secrets, private signing material, and unnecessary personal data.

When implementing runtime configuration, add an `.env.example` with the public
project URL and an empty publishable/anon-key placeholder, with no real credentials.
Exclude real environment files and signing credentials from version control before
creating them. Client applications may use a public publishable/anon key through
environment configuration; privileged keys must remain in trusted server-side
configuration. Do not hard-code credentials, bypass RLS, or invent a duplicate schema.
Record required schema/policy changes as migrations and inspect migration history
before applying them. No backend changes have been made during this audit.

## Validation and next dependencies

The existing PowerShell token suite was rerun for this audit using
`powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-tokens.ps1`.
It passed 86 token/contrast assertions and generated-output consistency validation.
Flutter remains unavailable, and prior analysis
and widget-test attempts could not start. No new runtime implementation was added
in this audit, so those Flutter suites were not represented as passing.

Install/connect the Supabase integration to permit a read-only audit of the supplied
project, then verify every live area above. Review the next user-provided master
prompt before architectural implementation. The repository location and Supabase
project identity are already supplied and must not be requested again.
