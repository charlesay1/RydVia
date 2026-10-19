-- LOCAL FOUNDATION ONLY. Inspect/reconcile the live project before applying.
-- Deliberately fail on conflicting existing tables; never silently replace schema.
begin;
-- An existing private schema requires reconciliation; do not change its grants.
create schema private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

-- Revoke both PUBLIC and explicit client defaults before granting intended access.
-- Supabase installations may grant functions to anon/authenticated by default.

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (char_length(display_name) between 2 and 80),
  onboarded boolean not null default false,
  created_at timestamptz not null default now()
);
create table public.user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('customer','driver','business','admin','operations','finance','support','analytics')),
  created_at timestamptz not null default now(),
  primary key (user_id, role)
);
create table public.role_requests (
  user_id uuid not null references public.profiles(id) on delete cascade,
  requested_role text not null check (requested_role in ('driver','business')),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  primary key (user_id, requested_role)
);
create table public.customer_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table public.driver_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  approval_status text not null default 'pending' check (approval_status in ('pending','approved','rejected','suspended')),
  created_at timestamptz not null default now()
);
create table public.business_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  approval_status text not null default 'pending' check (approval_status in ('pending','approved','rejected','suspended')),
  created_at timestamptz not null default now()
);
create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.driver_profiles(user_id) on delete cascade,
  registration text not null unique check (char_length(registration) between 3 and 24),
  vehicle_type text not null,
  approved boolean not null default false,
  created_at timestamptz not null default now()
);
create index vehicles_driver_idx on public.vehicles(driver_id);
create table public.services (
  id text primary key,
  name text not null,
  service_group text not null check (service_group in ('ride','deliver','move','towing','business','scheduled','intercity')),
  enabled boolean not null default false,
  sort_order integer not null
);
create table public.feature_flags (
  key text primary key,
  enabled boolean not null default false,
  updated_at timestamptz not null default now()
);
create table public.service_availability (
  service_id text primary key references public.services(id),
  flag_key text not null references public.feature_flags(key),
  enabled boolean not null default false
);

create function private.has_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.user_roles where user_id = (select auth.uid()) and role = 'admin');
$$;
revoke all on function private.has_admin() from public, anon, authenticated;
grant execute on function private.has_admin() to authenticated;

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.role_requests enable row level security;
alter table public.customer_profiles enable row level security;
alter table public.driver_profiles enable row level security;
alter table public.business_profiles enable row level security;
alter table public.vehicles enable row level security;
alter table public.services enable row level security;
alter table public.feature_flags enable row level security;
alter table public.service_availability enable row level security;

revoke all on public.profiles, public.user_roles, public.role_requests,
  public.customer_profiles, public.driver_profiles, public.business_profiles,
  public.vehicles, public.services, public.feature_flags, public.service_availability
  from public, anon, authenticated;
grant select on public.profiles, public.user_roles, public.role_requests,
  public.customer_profiles, public.driver_profiles, public.business_profiles,
  public.vehicles, public.services, public.feature_flags, public.service_availability
  to authenticated;
-- Mutations are RPC-only for ordinary users. Admin writes still require RLS.
grant insert, update, delete on public.user_roles, public.role_requests,
  public.driver_profiles, public.business_profiles, public.vehicles,
  public.services, public.feature_flags, public.service_availability to authenticated;
grant all on public.profiles, public.user_roles, public.role_requests,
  public.customer_profiles, public.driver_profiles, public.business_profiles,
  public.vehicles, public.services, public.feature_flags, public.service_availability to service_role;

create policy profiles_read on public.profiles for select to authenticated
  using (id = (select auth.uid()) or (select private.has_admin()));
create policy roles_read on public.user_roles for select to authenticated
  using (user_id = (select auth.uid()) or (select private.has_admin()));
create policy roles_admin on public.user_roles for all to authenticated
  using ((select private.has_admin())) with check ((select private.has_admin()));
create policy requests_read on public.role_requests for select to authenticated
  using (user_id = (select auth.uid()) or (select private.has_admin()));
create policy requests_admin on public.role_requests for all to authenticated
  using ((select private.has_admin())) with check ((select private.has_admin()));
create policy customers_read on public.customer_profiles for select to authenticated
  using (user_id = (select auth.uid()) or (select private.has_admin()));
create policy drivers_read on public.driver_profiles for select to authenticated
  using (user_id = (select auth.uid()) or (select private.has_admin()));
create policy drivers_admin on public.driver_profiles for all to authenticated
  using ((select private.has_admin())) with check ((select private.has_admin()));
create policy businesses_read on public.business_profiles for select to authenticated
  using (user_id = (select auth.uid()) or (select private.has_admin()));
create policy businesses_admin on public.business_profiles for all to authenticated
  using ((select private.has_admin())) with check ((select private.has_admin()));
create policy vehicles_read on public.vehicles for select to authenticated
  using (driver_id = (select auth.uid()) or (select private.has_admin()));
create policy vehicles_admin on public.vehicles for all to authenticated
  using ((select private.has_admin())) with check ((select private.has_admin()));
create policy services_read on public.services for select to authenticated using (true);
create policy services_admin on public.services for all to authenticated
  using ((select private.has_admin())) with check ((select private.has_admin()));
create policy flags_read on public.feature_flags for select to authenticated using (true);
create policy flags_admin on public.feature_flags for all to authenticated
  using ((select private.has_admin())) with check ((select private.has_admin()));
create policy availability_read on public.service_availability for select to authenticated using (true);
create policy availability_admin on public.service_availability for all to authenticated
  using ((select private.has_admin())) with check ((select private.has_admin()));

create view public.available_services with (security_invoker = true) as
select s.id, s.name, s.service_group, s.sort_order,
  (s.enabled and coalesce(a.enabled, false) and coalesce(f.enabled, false)) as enabled
from public.services s left join public.service_availability a on a.service_id = s.id
left join public.feature_flags f on f.key = a.flag_key;
revoke all on public.available_services from public, anon, authenticated;
grant select on public.available_services to authenticated, service_role;

create function private.bootstrap_profile() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id) values (new.id);
  insert into public.user_roles(user_id, role) values (new.id, 'customer');
  insert into public.customer_profiles(user_id) values (new.id);
  return new;
end;
$$;
revoke all on function private.bootstrap_profile() from public, anon, authenticated;
create trigger rydvia_auth_user_created after insert on auth.users
for each row execute function private.bootstrap_profile();
-- Do not read client-controlled metadata for roles, approval, or admin access.
insert into public.profiles(id) select id from auth.users;
insert into public.user_roles(user_id, role) select id, 'customer' from public.profiles;
insert into public.customer_profiles(user_id) select id from public.profiles;

create function public.access_profile() returns jsonb
language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object('user_id', p.id, 'onboarded', p.onboarded,
    'roles', coalesce((select jsonb_agg(r.role order by r.role) from public.user_roles r where r.user_id = p.id), '[]'::jsonb))
  from public.profiles p where p.id = (select auth.uid());
$$;
revoke all on function public.access_profile() from public, anon, authenticated;
grant execute on function public.access_profile() to authenticated;

create function public.complete_onboarding(display_name_input text, requested_role text) returns void
language plpgsql security definer set search_path = '' as $$
declare current_user_id uuid := auth.uid();
begin
  if current_user_id is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  if requested_role is null or requested_role not in ('customer','driver','business') then
    raise exception 'Invalid role request' using errcode = '22023';
  end if;
  if display_name_input is null or char_length(trim(display_name_input)) not between 2 and 80 then
    raise exception 'Invalid profile name' using errcode = '22023';
  end if;
  update public.profiles set display_name = trim(display_name_input), onboarded = true where id = current_user_id;
  if not found then raise exception 'Profile missing' using errcode = '22023'; end if;
  if requested_role in ('driver','business') then
    insert into public.role_requests(user_id, requested_role) values (current_user_id, requested_role) on conflict do nothing;
    if requested_role = 'driver' then
      insert into public.driver_profiles(user_id) values (current_user_id) on conflict do nothing;
    else
      insert into public.business_profiles(user_id) values (current_user_id) on conflict do nothing;
    end if;
  end if;
end;
$$;
revoke all on function public.complete_onboarding(text, text) from public, anon, authenticated;
grant execute on function public.complete_onboarding(text, text) to authenticated;

-- Database enforcement boundary for future quote/booking RPCs. Not a booking schema.
create function public.require_available_service(service_id_input text) returns void
language plpgsql stable security invoker set search_path = '' as $$
begin
  if auth.uid() is null or not exists(select 1 from public.available_services where id = service_id_input and enabled) then
    raise exception 'Service unavailable' using errcode = '42501';
  end if;
end;
$$;
revoke all on function public.require_available_service(text) from public, anon, authenticated;
grant execute on function public.require_available_service(text) to authenticated;

insert into public.services(id,name,service_group,sort_order) values
  ('cars','Ride','ride',10), ('motorbike','Motorbike','ride',20), ('pragya','Pragya','ride',30),
  ('delivery','Deliver','deliver',40), ('aboboyaa','Aboboyaa','move',50), ('van','Van','move',60),
  ('pickup','Pickup','move',70), ('truck','Truck','move',80), ('moving','Move','move',90),
  ('towing','Towing','towing',100), ('scheduled','Scheduled rides','scheduled',110),
  ('intercity','Intercity','intercity',120), ('business','Business services','business',130);
insert into public.feature_flags(key) select 'service.' || id from public.services;
insert into public.service_availability(service_id,flag_key) select id, 'service.' || id from public.services;
commit;
