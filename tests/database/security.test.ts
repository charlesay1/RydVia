// @vitest-environment node
import { readFileSync } from 'node:fs';
import { PGlite } from '@electric-sql/pglite';
import { beforeAll, afterAll, describe, it, expect } from 'vitest';

// Disposable PostgreSQL with a minimal Supabase auth shim. No remote connection.
const db = new PGlite();
const alice = '11111111-1111-4111-8111-111111111111';
const bob = '22222222-2222-4222-8222-222222222222';
const admin = '33333333-3333-4333-8333-333333333333';
async function asUser<T>(user: string, operation: () => Promise<T>): Promise<T> {
  await db.exec('set role authenticated');
  await db.query("select set_config('request.jwt.claims', $1, false)", [JSON.stringify({sub:user,role:'authenticated'})]);
  try { return await operation(); } finally { await db.exec('reset role'); }
}
beforeAll(async () => {
  await db.exec(`
    create role anon nologin; create role authenticated nologin; create role service_role nologin bypassrls;
    create schema auth; grant usage on schema auth to authenticated;
    create table auth.users(id uuid primary key, phone text, raw_user_meta_data jsonb default '{}');
    create function auth.uid() returns uuid language sql stable as $$
      select (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')::uuid;
    $$;
    grant execute on function auth.uid() to authenticated;
    -- Exercise platform-style defaults rather than assuming PostgreSQL's defaults.
    alter default privileges grant execute on functions to anon, authenticated, service_role;
    alter default privileges in schema public grant all on tables to public, anon, authenticated, service_role;
  `);
  await db.exec(readFileSync(new URL('../../supabase/migrations/20261019000000_restrict_rls_auto_enable.sql', import.meta.url),'utf8'));
  await db.exec(readFileSync(new URL('../../supabase/migrations/20261019000100_identity_services.sql', import.meta.url),'utf8'));
  await db.exec(readFileSync(new URL('../../supabase/migrations/20261019000200_effective_product_access.sql', import.meta.url),'utf8'));
  for (const id of [alice,bob,admin]) await db.query('insert into auth.users(id,raw_user_meta_data) values ($1,$2)',[id,JSON.stringify({role:'admin'})]);
  await db.query("insert into public.user_roles(user_id,role) values ($1,'admin')",[admin]);
});
afterAll(async()=>{await db.close();});
describe.sequential('PostgreSQL migration and security behavior', () => {
  it('enables RLS on every exposed foundation table', async () => {
    const result=await db.query<{relname:string;relrowsecurity:boolean}>("select c.relname,c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r'");
    expect(result.rows).toHaveLength(10);
    expect(result.rows.every(row=>row.relrowsecurity)).toBe(true);
  });
  it('ignores role claims supplied through signup metadata and isolates profiles', async () => {
    await asUser(alice, async()=>{
      expect((await db.query('select id from public.profiles')).rows).toEqual([{id:alice}]);
      expect((await db.query('select role from public.user_roles')).rows).toEqual([{role:'customer'}]);
    });
  });
  it('denies anonymous identity and RPC access', async () => {
    await db.exec('set role anon');
    try {
      await expect(db.query('select * from public.profiles')).rejects.toMatchObject({code:'42501'});
      await expect(db.query('select * from public.available_services')).rejects.toMatchObject({code:'42501'});
      await expect(db.query('select public.access_profile()')).rejects.toMatchObject({code:'42501'});
      await expect(db.query("select public.complete_onboarding('Test','customer')")).rejects.toMatchObject({code:'42501'});
      await expect(db.query("select public.require_available_service('cars')")).rejects.toMatchObject({code:'42501'});
    } finally {await db.exec('reset role');}
  });
  it('restricts definer helpers despite pre-existing default client function grants', async () => {
    const result=await db.query(`select
      has_function_privilege('anon','private.has_admin()','EXECUTE') as anon_admin,
      has_function_privilege('authenticated','private.has_admin()','EXECUTE') as authenticated_admin,
      has_function_privilege('anon','private.bootstrap_profile()','EXECUTE') as anon_bootstrap,
      has_function_privilege('authenticated','private.bootstrap_profile()','EXECUTE') as authenticated_bootstrap`);
    expect(result.rows).toEqual([{anon_admin:false,authenticated_admin:true,anon_bootstrap:false,authenticated_bootstrap:false}]);
  });
  it('prevents self-granting roles and directly approving a driver profile', async () => {
    await asUser(alice, async()=>{
      await expect(db.query("insert into public.user_roles(user_id,role) values ($1,'admin')",[alice])).rejects.toMatchObject({code:'42501'});
      await expect(db.query("insert into public.driver_profiles(user_id,approval_status) values ($1,'approved')",[alice])).rejects.toMatchObject({code:'42501'});
      await expect(db.query("update public.profiles set onboarded=true where id=$1",[alice])).rejects.toMatchObject({code:'42501'});
    });
  });
  it('completes onboarding without promoting driver/business applicants', async () => {
    await asUser(alice, async()=>{
      await db.query("select public.complete_onboarding('Test applicant','driver')");
      await db.query("select public.complete_onboarding('Test applicant','driver')");
      expect((await db.query('select status from public.role_requests')).rows).toEqual([{status:'pending'}]);
      expect((await db.query('select role from public.user_roles')).rows).toEqual([{role:'customer'}]);
      const profile=await db.query<{profile:{onboarded:boolean;user_id:string;roles:string[]}}>('select public.access_profile() as profile');
      expect(profile.rows[0].profile).toEqual({onboarded:true,user_id:alice,roles:['customer']});
      await expect(db.query("select public.complete_onboarding('Test','admin')")).rejects.toMatchObject({code:'22023'});
    });
  });
  it('requires service, availability, and flag gates and denies unknown services', async () => {
    await asUser(alice, async()=>{
      expect((await db.query('select id from public.available_services where enabled')).rows).toHaveLength(0);
      await expect(db.query("select public.require_available_service('cars')")).rejects.toMatchObject({code:'42501'});
      await expect(db.query("select public.require_available_service('unknown')")).rejects.toMatchObject({code:'42501'});
      const mutation=await db.query("update public.services set enabled=true where id='cars' returning id");
      expect(mutation.rows).toHaveLength(0);
    });
    await asUser(admin, async()=>{
      await db.exec("update public.services set enabled=true where id='cars'; update public.service_availability set enabled=true where service_id='cars'; update public.feature_flags set enabled=true where key='service.cars';");
    });
    await asUser(alice,async()=>{await expect(db.query("select public.require_available_service('cars')")).resolves.toBeDefined();});
    await asUser(admin,async()=>{await db.exec("update public.feature_flags set enabled=false where key='service.cars'");});
    await asUser(alice,async()=>{await expect(db.query("select public.require_available_service('cars')")).rejects.toMatchObject({code:'42501'});});
  });
  it('does not expose another user role requests or vehicles', async () => {
    await asUser(bob,async()=>{
      expect((await db.query('select * from public.role_requests')).rows).toHaveLength(0);
      expect((await db.query('select * from public.driver_profiles')).rows).toHaveLength(0);
      expect((await db.query('select * from public.vehicles')).rows).toHaveLength(0);
    });
  });
  it('requires both role membership and approved product profiles and honors suspension', async () => {
    await db.query("insert into public.user_roles(user_id,role) values ($1,'driver'),($1,'business')",[alice]);
    await db.query("insert into public.business_profiles(user_id) values ($1)",[alice]);
    async function effectiveRoles() {
      return asUser(alice, async()=> (await db.query<{profile:{roles:string[]}}>('select public.access_profile() as profile')).rows[0].profile.roles);
    }
    expect(await effectiveRoles()).toEqual(['customer']);
    await db.query("update public.driver_profiles set approval_status='approved' where user_id=$1",[alice]);
    await db.query("update public.business_profiles set approval_status='approved' where user_id=$1",[alice]);
    expect(await effectiveRoles()).toEqual(['business','customer','driver']);
    await db.query("update public.driver_profiles set approval_status='suspended' where user_id=$1",[alice]);
    await db.query("update public.business_profiles set approval_status='rejected' where user_id=$1",[alice]);
    expect(await effectiveRoles()).toEqual(['customer']);
    await db.query("delete from public.user_roles where user_id=$1 and role in ('driver','business')",[alice]);
    await db.query("update public.driver_profiles set approval_status='approved' where user_id=$1",[alice]);
    expect(await effectiveRoles()).toEqual(['customer']);
  });
  it('allows admin approval and membership while denying business applicants self-promotion', async () => {
    await asUser(bob,async()=>{
      await db.query("select public.complete_onboarding('Business applicant','business')");
      await expect(db.query("insert into public.user_roles(user_id,role) values ($1,'business')",[bob])).rejects.toMatchObject({code:'42501'});
      expect((await db.query("update public.business_profiles set approval_status='approved' where user_id=$1 returning user_id",[bob])).rows).toHaveLength(0);
      expect((await db.query("update public.driver_profiles set approval_status='approved' where user_id=$1 returning user_id",[alice])).rows).toHaveLength(0);
    });
    await asUser(admin,async()=>{
      expect((await db.query('select id from public.profiles')).rows).toHaveLength(3);
      await db.query("update public.business_profiles set approval_status='approved' where user_id=$1",[bob]);
      await db.query("insert into public.user_roles(user_id,role) values ($1,'business')",[bob]);
      await db.query("update public.role_requests set status='approved' where user_id=$1 and requested_role='business'",[bob]);
    });
    await asUser(bob,async()=>{
      const access=await db.query<{profile:{roles:string[]}}>('select public.access_profile() as profile');
      expect(access.rows[0].profile.roles).toEqual(['business','customer']);
      expect((await db.query('select id from public.profiles')).rows).toEqual([{id:bob}]);
      await expect(db.query("insert into public.user_roles(user_id,role) values ($1,'admin')",[bob])).rejects.toMatchObject({code:'42501'});
    });
  });
  it('prepares a metadata-only catalog without reading user rows or exposing definitions', async () => {
    const sql=readFileSync(new URL('../../supabase/audit/catalog.sql',import.meta.url),'utf8');
    const result=await db.query<{inventory:{relations:{schema:string;name:string}[];policies:unknown[];functions:unknown[]}}>(sql);
    const inventory=result.rows[0].inventory;
    expect(inventory.relations.filter(row=>row.schema==='public')).toHaveLength(11); // ten tables plus invoker view
    expect(inventory.policies.length).toBeGreaterThan(10);
    expect(inventory.functions.length).toBeGreaterThan(0);
    const serialized=JSON.stringify(inventory);
    expect(serialized).not.toContain('+233241234567');
    expect(serialized).not.toContain('Test applicant');
    expect(serialized).not.toContain('jsonb_build_object'); // definitions are digests only
  });
});
