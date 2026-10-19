-- Prepared locally; pending live inventory and migration-history reconciliation.
-- Keep historical role grants while honoring suspended/pending product profiles.
begin;
create or replace function public.access_profile() returns jsonb
language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object('user_id', p.id, 'onboarded', p.onboarded,
    'roles', coalesce((
      select jsonb_agg(r.role order by r.role)
      from public.user_roles r where r.user_id = p.id
        and (r.role <> 'customer' or exists(select 1 from public.customer_profiles cp where cp.user_id = p.id))
        and (r.role <> 'driver' or exists(select 1 from public.driver_profiles dp where dp.user_id = p.id and dp.approval_status = 'approved'))
        and (r.role <> 'business' or exists(select 1 from public.business_profiles bp where bp.user_id = p.id and bp.approval_status = 'approved'))
    ), '[]'::jsonb))
  from public.profiles p where p.id = (select auth.uid());
$$;
revoke all on function public.access_profile() from public, anon, authenticated;
grant execute on function public.access_profile() to authenticated;
commit;
