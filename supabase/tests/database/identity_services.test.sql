begin;
create extension if not exists pgtap with schema extensions;
select plan(19);
-- The platform helper is optional in a clean local stack. If present, clients
-- must have no effective EXECUTE privilege (including inherited PUBLIC grants).
select ok(coalesce((select not has_function_privilege('anon',p.oid,'EXECUTE')
  from pg_proc p where p.oid=to_regprocedure('public.rls_auto_enable()')),true),
  'anon cannot execute the optional RLS platform helper');
select ok(coalesce((select not has_function_privilege('authenticated',p.oid,'EXECUTE')
  from pg_proc p where p.oid=to_regprocedure('public.rls_auto_enable()')),true),
  'authenticated cannot execute the optional RLS platform helper');
select is((select count(*)::integer from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname in ('profiles','user_roles','role_requests','customer_profiles','driver_profiles','business_profiles','vehicles','services','feature_flags','service_availability') and c.relrowsecurity), 10, 'all foundation tables enable RLS');
insert into auth.users(id,phone) values
  ('11111111-1111-4111-8111-111111111111','+233241234567'),
  ('22222222-2222-4222-8222-222222222222','+233501234567');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',true);
select is((select count(*)::integer from public.profiles),1,'user cannot read other profiles');
select is((select count(*)::integer from public.user_roles where role='customer'),1,'user receives customer access only');
select throws_ok($$insert into public.user_roles(user_id,role) values ('11111111-1111-4111-8111-111111111111','admin')$$,'42501',null,'user cannot grant admin');
select lives_ok($$select public.complete_onboarding('Test driver','driver')$$,'user can request driver review');
select is((select count(*)::integer from public.user_roles where role='driver'),0,'review request does not grant driver access');
select is((select count(*)::integer from public.role_requests where requested_role='driver' and status='pending'),1,'review request is pending');
select is((select count(*)::integer from public.available_services where enabled),0,'services default disabled');
select throws_ok($$select public.require_available_service('cars')$$,'42501','Service unavailable','disabled service denied server-side');
select throws_ok($$select public.complete_onboarding('Test','admin')$$,'22023','Invalid role request','onboarding cannot request admin');
reset role;
set local role anon;
select throws_ok($$select * from public.profiles$$,'42501',null,'anonymous profile access is denied');
reset role;
insert into public.user_roles(user_id,role) values ('11111111-1111-4111-8111-111111111111','driver');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',true);
select is(public.access_profile()->'roles' ? 'driver',false,'pending profile blocks driver membership');
reset role;
update public.driver_profiles set approval_status='approved' where user_id='11111111-1111-4111-8111-111111111111';
set local role authenticated;
select is(public.access_profile()->'roles' ? 'driver',true,'approved profile permits granted driver role');
reset role;
update public.driver_profiles set approval_status='suspended' where user_id='11111111-1111-4111-8111-111111111111';
set local role authenticated;
select is(public.access_profile()->'roles' ? 'driver',false,'suspension revokes effective driver access');
reset role;
insert into public.user_roles(user_id,role) values ('22222222-2222-4222-8222-222222222222','business');
insert into public.business_profiles(user_id) values ('22222222-2222-4222-8222-222222222222');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}',true);
select is(public.access_profile()->'roles' ? 'business',false,'pending profile blocks business membership');
reset role;
update public.business_profiles set approval_status='approved' where user_id='22222222-2222-4222-8222-222222222222';
set local role authenticated;
select is(public.access_profile()->'roles' ? 'business',true,'approved profile permits granted business role');
reset role;
update public.business_profiles set approval_status='rejected' where user_id='22222222-2222-4222-8222-222222222222';
set local role authenticated;
select is(public.access_profile()->'roles' ? 'business',false,'rejection revokes effective business access');
reset role;
select * from finish();
rollback;
