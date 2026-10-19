// @vitest-environment node
import { readFileSync } from 'node:fs';
import { PGlite } from '@electric-sql/pglite';
import { it, expect } from 'vitest';

const baseline = readFileSync(new URL('../../supabase/migrations/20261019000100_identity_services.sql', import.meta.url), 'utf8');
const shim = `create role anon nologin; create role authenticated nologin; create role service_role nologin bypassrls;
  create schema auth; grant usage on schema auth to authenticated;
  create table auth.users(id uuid primary key);
  create function auth.uid() returns uuid language sql stable as $$
    select (nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'sub')::uuid; $$;`;

it('rolls back a conflicting table without overwriting existing data or leaving partial objects', async () => {
  const db = new PGlite();
  try {
    await db.exec(shim);
    await db.exec("create table public.profiles(sentinel text); insert into public.profiles values ('preserve-existing-data');");
    await expect(db.exec(baseline)).rejects.toMatchObject({ code: '42P07' });
    await db.exec('rollback');
    expect((await db.query('select * from public.profiles')).rows).toEqual([{ sentinel: 'preserve-existing-data' }]);
    expect((await db.query("select to_regnamespace('private') as schema, to_regclass('public.user_roles') as roles")).rows).toEqual([{ schema: null, roles: null }]);
  } finally { await db.close(); }
});

it('refuses to reuse an existing private schema or change its objects and privileges', async () => {
  const db = new PGlite();
  try {
    await db.exec(shim);
    await db.exec("create schema private; grant usage on schema private to anon; create table private.existing(sentinel text); insert into private.existing values ('keep');");
    await expect(db.exec(baseline)).rejects.toMatchObject({ code: '42P06' });
    await db.exec('rollback');
    expect((await db.query('select * from private.existing')).rows).toEqual([{ sentinel: 'keep' }]);
    expect((await db.query("select has_schema_privilege('anon','private','USAGE') as unchanged")).rows).toEqual([{ unchanged: true }]);
  } finally { await db.close(); }
});

it('preserves existing Auth identities during the explicit customer backfill', async () => {
  const db = new PGlite();
  const id = '44444444-4444-4444-8444-444444444444';
  try {
    await db.exec(shim);
    await db.query('insert into auth.users(id) values ($1)', [id]);
    await db.exec(baseline);
    expect((await db.query('select id from auth.users')).rows).toEqual([{ id }]);
    expect((await db.query('select id,onboarded from public.profiles')).rows).toEqual([{ id, onboarded: false }]);
    expect((await db.query('select user_id,role from public.user_roles')).rows).toEqual([{ user_id: id, role: 'customer' }]);
  } finally { await db.close(); }
});
