create or replace function public.prevent_last_admin_removal()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  admin_count bigint;
begin
  if tg_op = 'UPDATE' then
    if old.role <> 'admin' or new.role = 'admin' then
      return new;
    end if;
  elsif tg_op = 'DELETE' then
    if old.role <> 'admin' then
      return old;
    end if;
  else
    return null;
  end if;

  perform pg_advisory_xact_lock(172839, 152637);

  select count(*)
  into admin_count
  from public.profiles
  where role = 'admin';

  if admin_count <= 1 then
    raise exception 'The final administrator cannot be demoted or deleted.'
      using errcode = '23514';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function public.prevent_last_admin_removal() from public, anon, authenticated;

create or replace function public.ensure_an_admin_remains()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  admin_count bigint;
begin
  if tg_op = 'UPDATE' then
    if old.role <> 'admin' or new.role = 'admin' then
      return null;
    end if;
  elsif old.role <> 'admin' then
    return null;
  end if;

  perform pg_advisory_xact_lock(172839, 152637);

  select count(*)
  into admin_count
  from public.profiles
  where role = 'admin';

  if admin_count = 0 then
    raise exception 'At least one administrator must remain.'
      using errcode = '23514';
  end if;

  return null;
end;
$$;

revoke all on function public.ensure_an_admin_remains() from public, anon, authenticated;

drop trigger if exists profiles_prevent_last_admin_demotion on public.profiles;
create trigger profiles_prevent_last_admin_demotion
  before update of role on public.profiles
  for each row
  when (old.role = 'admin' and new.role is distinct from 'admin')
  execute function public.prevent_last_admin_removal();

drop trigger if exists profiles_prevent_last_admin_deletion on public.profiles;
create trigger profiles_prevent_last_admin_deletion
  before delete on public.profiles
  for each row
  when (old.role = 'admin')
  execute function public.prevent_last_admin_removal();

drop trigger if exists profiles_ensure_an_admin_remains on public.profiles;
create constraint trigger profiles_ensure_an_admin_remains
  after update of role or delete on public.profiles
  deferrable initially deferred
  for each row
  execute function public.ensure_an_admin_remains();

drop policy if exists "Users register themselves for active events"
  on public.event_registrations;
create policy "Users register themselves for active events"
  on public.event_registrations for insert to authenticated
  with check (
    (select auth.uid()) = profile_id
    and exists (
      select 1
      from public.events
      where id = event_id
        and is_active
        and starts_at > now()
    )
  );
