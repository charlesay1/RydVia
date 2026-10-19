-- First migration for the externally verified project with no remote migrations.
-- Preserve the existing helper, its owner/body, and any automatic RLS event trigger.
-- PUBLIC must also be revoked: its privileges are inherited by every database role.
begin;
do $migration$
declare
  helper regprocedure := pg_catalog.to_regprocedure('public.rls_auto_enable()');
begin
  if helper is not null then
    revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
    -- Fail closed if an unexpected inherited grant still provides client access.
    if pg_catalog.has_function_privilege('anon', helper, 'EXECUTE')
       or pg_catalog.has_function_privilege('authenticated', helper, 'EXECUTE') then
      raise exception 'rls_auto_enable still has inherited client EXECUTE privileges; review role memberships'
        using errcode = '42501';
    end if;
  end if;
end;
$migration$;
commit;
