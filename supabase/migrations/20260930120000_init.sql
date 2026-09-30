-- Kindose · first database setup
-- Run once in Supabase → SQL Editor → New query → paste → Run.
--
-- Tables
--   backups     one copy of each user's data (the app uploads it on "Back up now")
--   app_config  small settings the app reads at start (discount offer, flags)
--
-- Security: Row Level Security is on for every table. A signed-in user can
-- only read and write their own backup. Nobody can change app_config from
-- the app; you edit it in the dashboard.

-- ------------------------------------------------------------------ backups

create table if not exists public.backups (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  data        jsonb       not null,
  app_version text,
  platform    text,
  size_bytes  integer,
  updated_at  timestamptz not null default now()
);

comment on table public.backups is
  'One backup per user. Replaced on every "Back up now". Deleted with the user.';

alter table public.backups enable row level security;

create policy "backups: read own"
  on public.backups for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "backups: create own"
  on public.backups for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "backups: replace own"
  on public.backups for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "backups: delete own"
  on public.backups for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- Keep updated_at right even if the app forgets to send it.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists backups_touch on public.backups;
create trigger backups_touch
  before insert or update on public.backups
  for each row execute function public.touch_updated_at();

-- --------------------------------------------------------------- app_config

create table if not exists public.app_config (
  key        text primary key,
  value      jsonb       not null,
  updated_at timestamptz not null default now()
);

comment on table public.app_config is
  'Read by the app at start. Edit rows in the dashboard (Table Editor).';

alter table public.app_config enable row level security;

-- Everyone may read (the offer can show before sign-in). No write policy,
-- so the app can never change it.
create policy "app_config: anyone can read"
  on public.app_config for select
  to anon, authenticated
  using (true);

drop trigger if exists app_config_touch on public.app_config;
create trigger app_config_touch
  before insert or update on public.app_config
  for each row execute function public.touch_updated_at();

-- Empty offer config: the app keeps its built-in defaults until you fill
-- this in (same keys as OfferConfig.fromJson).
insert into public.app_config (key, value)
values ('paywall_offer', '{}'::jsonb)
on conflict (key) do nothing;
