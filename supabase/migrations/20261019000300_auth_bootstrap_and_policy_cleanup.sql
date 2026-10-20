-- Candidate only: apply externally after comparing the three verified live migrations.
-- Preserve user IDs, existing approvals/roles, service settings, RLS, and vehicle index.
begin;
create index service_availability_flag_key_idx on public.service_availability(flag_key);

create or replace function private.bootstrap_profile() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id) values (new.id) on conflict (id) do nothing;
  insert into public.user_roles(user_id, role) values (new.id, 'customer')
    on conflict (user_id, role) do nothing;
  insert into public.customer_profiles(user_id) values (new.id)
    on conflict (user_id) do nothing;
  return new;
end;
$$;
revoke all on function private.bootstrap_profile() from public, anon, authenticated;

-- Existing read policies already include intended self/admin or catalog reads.
-- Replace FOR ALL admin policies with equivalent INSERT/UPDATE/DELETE policies
-- so each table has exactly one permissive SELECT policy for authenticated users.
do $policies$
declare target record;
begin
  for target in select * from (values
    ('user_roles','roles'), ('role_requests','requests'),
    ('driver_profiles','drivers'), ('business_profiles','businesses'),
    ('vehicles','vehicles'), ('services','services'),
    ('feature_flags','flags'), ('service_availability','availability')
  ) as targets(table_name, policy_prefix) loop
    execute pg_catalog.format('drop policy %I on public.%I', target.policy_prefix || '_admin', target.table_name);
    execute pg_catalog.format('create policy %I on public.%I for insert to authenticated with check ((select private.has_admin()))', target.policy_prefix || '_admin_insert', target.table_name);
    execute pg_catalog.format('create policy %I on public.%I for update to authenticated using ((select private.has_admin())) with check ((select private.has_admin()))', target.policy_prefix || '_admin_update', target.table_name);
    execute pg_catalog.format('create policy %I on public.%I for delete to authenticated using ((select private.has_admin()))', target.policy_prefix || '_admin_delete', target.table_name);
  end loop;
end;
$policies$;
commit;
