// @vitest-environment node
import { readFileSync } from 'node:fs';
import { PGlite } from '@electric-sql/pglite';
import { it, expect } from 'vitest';

const migration = readFileSync(new URL('../../supabase/migrations/20261019000000_restrict_rls_auto_enable.sql', import.meta.url), 'utf8');
const roles = 'create role anon nologin; create role authenticated nologin; create role service_role nologin;';

// First PostgreSQL WASM startup can exceed five seconds on shared CI runners.
it('allows a clean local database without creating or replacing the platform helper', async () => {
  const db = new PGlite();
  try {
    await db.exec(roles);
    await db.exec(migration);
    await db.exec(migration);
    expect((await db.query("select to_regprocedure('public.rls_auto_enable()') as helper")).rows).toEqual([{ helper: null }]);
  } finally { await db.close(); }
}, 30_000);

it('removes explicit and PUBLIC client grants without breaking automatic RLS or trusted grants', async () => {
  const db = new PGlite();
  try {
    await db.exec(roles);
    await db.exec(`
      create function public.rls_auto_enable() returns event_trigger
      language plpgsql security definer set search_path = '' as $$
      declare command record;
      begin
        for command in select * from pg_catalog.pg_event_trigger_ddl_commands() loop
          if command.schema_name = 'public' and command.command_tag = 'CREATE TABLE' then
            execute pg_catalog.format('alter table %s enable row level security', command.object_identity);
          end if;
        end loop;
      end; $$;
      grant execute on function public.rls_auto_enable() to public, anon, authenticated, service_role;
      create event trigger fixture_enable_rls on ddl_command_end when tag in ('CREATE TABLE')
        execute function public.rls_auto_enable();
    `);
    const definition = "select pg_get_functiondef('public.rls_auto_enable()'::regprocedure) as body, proowner from pg_proc where oid='public.rls_auto_enable()'::regprocedure";
    const before = (await db.query(definition)).rows;
    await db.exec(migration);
    await db.exec(migration);
    expect((await db.query(definition)).rows).toEqual(before);
    expect((await db.query(`select
      has_function_privilege('anon','public.rls_auto_enable()','EXECUTE') as anon,
      has_function_privilege('authenticated','public.rls_auto_enable()','EXECUTE') as authenticated,
      has_function_privilege('service_role','public.rls_auto_enable()','EXECUTE') as trusted
    `)).rows).toEqual([{ anon: false, authenticated: false, trusted: true }]);
    for (const role of ['anon', 'authenticated']) {
      await db.exec(`set role ${role}`);
      try { await expect(db.query('select public.rls_auto_enable()')).rejects.toMatchObject({ code: '42501' }); }
      finally { await db.exec('reset role'); }
    }
    await db.exec('create table public.fixture_after_hardening(id integer)');
    expect((await db.query("select relrowsecurity from pg_class where oid='public.fixture_after_hardening'::regclass")).rows).toEqual([{ relrowsecurity: true }]);
    expect((await db.query("select evtenabled from pg_event_trigger where evtname='fixture_enable_rls'")).rows).toEqual([{ evtenabled: 'O' }]);
  } finally { await db.close(); }
});

it('aborts rather than claiming success when another inherited role still grants execution', async () => {
  const db = new PGlite();
  try {
    await db.exec(roles);
    await db.exec(`create role inherited_executor nologin;
      grant inherited_executor to authenticated;
      create function public.rls_auto_enable() returns void language sql security definer as $$ select; $$;
      grant execute on function public.rls_auto_enable() to inherited_executor;`);
    await expect(db.exec(migration)).rejects.toMatchObject({ code: '42501' });
    await db.exec('rollback');
    expect((await db.query("select has_function_privilege('anon','public.rls_auto_enable()','EXECUTE') as unchanged")).rows).toEqual([{ unchanged: true }]);
  } finally { await db.close(); }
});
