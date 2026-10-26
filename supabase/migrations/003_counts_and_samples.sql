create function public.get_club_member_counts()
returns table (club_id uuid, member_count bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id, count(cm.profile_id)
  from public.clubs c
  left join public.club_memberships cm on cm.club_id = c.id
  where c.is_active or (select public.is_admin())
  group by c.id;
$$;

revoke all on function public.get_club_member_counts() from public, anon;
grant execute on function public.get_club_member_counts() to authenticated;

insert into public.clubs (name, description, category, icon, needs_admin_review)
values (
  'E-Cell FCRIT',
  'Entrepreneurship and innovation activities. Verify official details before further publication.',
  'Entrepreneurship',
  '🚀',
  true
)
on conflict (name) do nothing;

insert into public.announcements (
  slug, title, category, description, source, related_club_id, published_at
)
select
  'fintech-unlocked-2026',
  'FinTech Unlocked 2026',
  'Event Announcement',
  'SAMPLE ANNOUNCEMENT — PAST EVENT (22 October 2026)' || E'\n\n' ||
  'PRESS RELEASE | FINTECH UNLOCKED 2026' || E'\n\n' ||
  'E-CELL is excited to present “FinTech Unlocked” — an engaging online event exploring how AI, Engineering, and Innovation are reshaping the future of Finance!' || E'\n\n' ||
  'Join us to discover how emerging technologies, artificial intelligence, and innovative engineering solutions are transforming the financial world.' || E'\n\n' ||
  'Date: Thursday, 22nd October 2026' || E'\n' ||
  'Time: 7:30 PM' || E'\n' ||
  'Mode: Online' || E'\n\n' ||
  'Certificates will be provided, and the event is completely free of cost.' || E'\n\n' ||
  'Be a part of this exciting journey into the future of financial technology and innovation!' || E'\n\n' ||
  'Registration link: https://forms.gle/tQSsxVVjGMjPkizR6' || E'\n\n' ||
  'Let''s unlock new possibilities at the intersection of technology and finance!',
  'E-Cell FCRIT',
  id,
  '2026-10-22 00:00:00+00'
from public.clubs
where name = 'E-Cell FCRIT'
on conflict (slug) do nothing;
