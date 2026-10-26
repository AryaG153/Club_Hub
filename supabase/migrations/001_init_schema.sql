create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  display_name text not null check (length(trim(display_name)) between 1 and 120),
  email text not null,
  department text,
  student_id text,
  role text not null default 'student' check (role in ('student', 'admin')),
  is_suspended boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check (length(trim(name)) between 2 and 160),
  description text not null default '',
  category text not null default 'General',
  icon text not null default '✨',
  logo_url text,
  featured boolean not null default false,
  is_active boolean not null default true,
  needs_admin_review boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.club_memberships (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  club_id uuid not null references public.clubs(id) on delete cascade,
  joined_at timestamptz not null default now(),
  unique(profile_id, club_id)
);

create table public.events (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  title text not null check (length(trim(title)) between 2 and 180),
  description text not null default '',
  venue text not null default '',
  organizer text not null default '',
  starts_at timestamptz not null,
  featured boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.event_registrations (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  registered_at timestamptz not null default now(),
  unique(profile_id, event_id)
);

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  slug text unique,
  title text not null check (length(trim(title)) between 2 and 180),
  category text not null default 'General',
  description text not null,
  source text not null,
  related_club_id uuid references public.clubs(id) on delete set null,
  image_path text,
  published_at timestamptz not null default now(),
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index profiles_role_created_at_idx on public.profiles(role, created_at desc);
create index clubs_active_category_idx on public.clubs(is_active, category);
create index memberships_club_id_idx on public.club_memberships(club_id);
create index events_active_starts_at_idx on public.events(is_active, starts_at);
create index event_registrations_event_id_idx on public.event_registrations(event_id);
create index announcements_published_idx
  on public.announcements(is_published, published_at desc);

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger clubs_set_updated_at before update on public.clubs
  for each row execute function public.set_updated_at();
create trigger events_set_updated_at before update on public.events
  for each row execute function public.set_updated_at();
create trigger announcements_set_updated_at before update on public.announcements
  for each row execute function public.set_updated_at();

create function public.create_profile_for_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  full_name text;
  chosen_username text;
begin
  full_name := nullif(trim(new.raw_user_meta_data ->> 'full_name'), '');
  chosen_username := nullif(trim(new.raw_user_meta_data ->> 'username'), '');
  if chosen_username is null then
    chosen_username := lower(split_part(coalesce(new.email, new.id::text), '@', 1))
      || '-' || substr(new.id::text, 1, 6);
  end if;

  insert into public.profiles (
    id, username, display_name, email, department, student_id
  )
  values (
    new.id,
    chosen_username,
    coalesce(full_name, chosen_username),
    coalesce(new.email, ''),
    nullif(trim(new.raw_user_meta_data ->> 'department'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'student_id'), '')
  );
  return new;
end;
$$;

create trigger auth_user_profile_created
  after insert on auth.users
  for each row execute function public.create_profile_for_auth_user();
