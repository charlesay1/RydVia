# Controlled RydVia migration application

Prepared locally for project `kciwxgfvpozgmnaypyxb`. Execute remote operations only
from the externally authorized Supabase environment. No remote application is
authorized from this VS Code session. Do not reset the remote database.

## Preflight

1. Confirm project identity and health, zero migration history, no application tables,
   zero Auth users, and zero buckets/functions against the supplied external snapshot.
   If identities/data have appeared, preserve them and review the intended backfill.
2. Inspect existing schemas, functions, triggers, policies, grants, role memberships,
   and default privileges. In particular, the `private` schema must be absent for
   this fresh baseline. Check for all ten table names, `available_services`, the
   three public RPCs, and `rydvia_auth_user_created` on `auth.users`. Any collision
   requires reconciliation before proceeding; never remove an object to clear it.
3. Record the existing `public.rls_auto_enable()` definition/owner, its ACL, and any
   event trigger attached to it. The fix changes privileges only. Use a migration
   identity authorized to revoke grants on that function. Do not copy secrets or
   user data into logs or this repository.
4. Establish a protected backup/restore path and trial the exact files on a disposable
   Supabase stack or staging project, including the existing helper/event trigger.
   Run `supabase test db` locally after migrations. PGlite tests also run via `npm test`.

## Apply these exact files in order

Use the external environment's versioned migration operation and record each version.
Do not paste SQL without recording migration history or blindly push an unreviewed
directory. Each file contains a transaction; apply separately and verify each result.

1. [`20261019000000_restrict_rls_auto_enable.sql`](../../supabase/migrations/20261019000000_restrict_rls_auto_enable.sql)
2. [`20261019000100_identity_services.sql`](../../supabase/migrations/20261019000100_identity_services.sql)
3. [`20261019000200_effective_product_access.sql`](../../supabase/migrations/20261019000200_effective_product_access.sql)

These versions precede any remote history in the externally verified empty project.
If history is no longer empty, stop and reconcile versions before applying. Never
rename, edit, or replay a migration after it has been recorded remotely. The baseline
is intentionally not idempotent; duplicate application must fail rather than replace data.

After migration 000, confirm both privileges below are false and the helper body,
owner, and event-trigger attachment are unchanged. Do not disable/drop the helper.
If it disappeared since preflight, stop and explain the changed platform state.

```sql
select
  has_function_privilege('anon', 'public.rls_auto_enable()', 'EXECUTE') as anon_execute,
  has_function_privilege('authenticated', 'public.rls_auto_enable()', 'EXECUTE') as authenticated_execute;
```

An inherited grant causes this migration to abort and roll back. Review the unexpected
role membership/grant externally; do not broaden the migration to revoke unrelated roles
without understanding the impact. Explicit trusted grants are retained.

After migration 001, confirm ten app tables, eighteen RLS policies, thirteen services,
thirteen flags, thirteen availability entries, and the invoker view. With the supplied
zero-user snapshot, profile/role/product tables should remain empty until real signup.
Never enable service flags as part of migration validation.

After migration 002, verify `access_profile()` retains invoker security, denies anon,
and requires both approved product profiles and role membership for Driver/Business.
An approved request alone does not confer access. Provision approval and membership
through a trusted administrative path; do not grant roles using client metadata.

## Verification artifacts

- [`supabase/audit/catalog.sql`](../../supabase/audit/catalog.sql): read-only metadata
  inventory; hashes definitions to avoid logging bodies or policy literals. Compare
  against a fresh local baseline, allowing for PostgreSQL/platform ownership differences
  only after review. Catalog row estimates do not prove table emptiness.
- [`supabase/tests/database/identity_services.test.sql`](../../supabase/tests/database/identity_services.test.sql):
  nineteen pgTAP assertions; run on disposable/local Supabase with seeded test identities.
  It rolls its transaction back. Do not use fixed fixture IDs on a live project without
  reviewing collisions. It does not test real Auth SMS or deployed API transport.
- `tests/database/security.test.ts`, `migration-safety.test.ts`, and
  `rls-auto-enable.test.ts`: disposable PostgreSQL checks for RLS, roles, default grants,
  helper/event-trigger behavior, rollback, and ID preservation.

Test anonymous and authenticated API permissions in staging, not just owner SQL.
Verify Customer isolation, Driver/Business pending/approved/suspended/rejected states,
Admin session verification plus server-backed membership, and unauthorized role writes.
Check function/table privileges against explicit and inherited grants.

If any application step fails, do not continue or reset. A failed file rolls back;
earlier successful files remain. Compare state and migration history, then prepare a
forward correction that preserves data. No automatic destructive rollback is provided.

## Configuration and real Auth validation

Set only the public publishable/anon key in the ignored mobile `.env` and Admin
`.env.local`, using their checked-in examples. Never embed service-role/provider or
management credentials in clients. Inspect live Phone Auth, provider credentials and
sender/service registration, country permissions, signup, OTP/rate policies, CAPTCHA,
and redirects before testing. The client OTP length/resend settings must match.

Use controlled recipients to validate actual OTP delivery and verification, then
session restoration/refresh/logout and each product gate. Current CAPTCHA challenge
integration is absent; if required by live Auth, implement it before this phase passes.
Provision the first staff account and Admin membership through a trusted audited path.
Admin OTP deliberately uses `shouldCreateUser: false`.

No bucket or Edge Function is required for this initial Auth foundation. Preserve
any that appear after the supplied snapshot. Keep Realtime unchanged unless a reviewed
requirement calls for publications/subscriptions. Production readiness remains pending
these deployed permission, provider, session, and device checks.
