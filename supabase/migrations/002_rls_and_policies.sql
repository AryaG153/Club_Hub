create function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'admin'
  );
$$;

revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

create function public.prevent_profile_role_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role is distinct from old.role
    and coalesce(current_setting('request.jwt.claim.role', true), '') <> 'service_role'
    and session_user <> 'postgres' then
    raise exception 'Profile roles may only be changed by the trusted admin function.';
  end if;
  return new;
end;
$$;

create trigger profiles_prevent_role_change
  before update of role on public.profiles
  for each row execute function public.prevent_profile_role_change();

alter table public.profiles enable row level security;
alter table public.clubs enable row level security;
alter table public.club_memberships enable row level security;
alter table public.events enable row level security;
alter table public.event_registrations enable row level security;
alter table public.announcements enable row level security;

revoke all on public.profiles, public.clubs, public.club_memberships,
  public.events, public.event_registrations, public.announcements
  from anon, authenticated;
grant select on public.profiles, public.clubs, public.club_memberships,
  public.events, public.event_registrations, public.announcements to authenticated;
grant update (display_name, department, student_id) on public.profiles to authenticated;
grant insert (profile_id, club_id), delete on public.club_memberships to authenticated;
grant insert (profile_id, event_id), delete on public.event_registrations to authenticated;
grant insert, update, delete on public.clubs, public.events, public.announcements
  to authenticated;

create policy "Users read own profile and admins read profiles"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = id or (select public.is_admin()));
create policy "Users update their own non-role profile fields"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "Authenticated users read active clubs"
  on public.clubs for select to authenticated
  using (is_active or (select public.is_admin()));
create policy "Admins insert clubs"
  on public.clubs for insert to authenticated
  with check ((select public.is_admin()));
create policy "Admins update clubs"
  on public.clubs for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));
create policy "Admins delete clubs"
  on public.clubs for delete to authenticated
  using ((select public.is_admin()));

create policy "Users read own memberships and admins read all"
  on public.club_memberships for select to authenticated
  using ((select auth.uid()) = profile_id or (select public.is_admin()));
create policy "Users join clubs as themselves"
  on public.club_memberships for insert to authenticated
  with check (
    (select auth.uid()) = profile_id
    and exists (select 1 from public.clubs where id = club_id and is_active)
  );
create policy "Users leave their own clubs and admins manage memberships"
  on public.club_memberships for delete to authenticated
  using ((select auth.uid()) = profile_id or (select public.is_admin()));

create policy "Authenticated users read active events"
  on public.events for select to authenticated
  using (is_active or (select public.is_admin()));
create policy "Admins insert events"
  on public.events for insert to authenticated
  with check ((select public.is_admin()));
create policy "Admins update events"
  on public.events for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));
create policy "Admins delete events"
  on public.events for delete to authenticated
  using ((select public.is_admin()));

create policy "Users read own registrations and admins read all"
  on public.event_registrations for select to authenticated
  using ((select auth.uid()) = profile_id or (select public.is_admin()));
create policy "Users register themselves for active events"
  on public.event_registrations for insert to authenticated
  with check (
    (select auth.uid()) = profile_id
    and exists (select 1 from public.events where id = event_id and is_active)
  );
create policy "Users cancel own registrations and admins manage registrations"
  on public.event_registrations for delete to authenticated
  using ((select auth.uid()) = profile_id or (select public.is_admin()));

create policy "Authenticated users read published announcements"
  on public.announcements for select to authenticated
  using (is_published or (select public.is_admin()));
create policy "Admins insert announcements"
  on public.announcements for insert to authenticated
  with check ((select public.is_admin()));
create policy "Admins update announcements"
  on public.announcements for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));
create policy "Admins delete announcements"
  on public.announcements for delete to authenticated
  using ((select public.is_admin()));
