-- Feature ideas and improvements sent from Me → Suggest a feature.
-- Read them in Table Editor → feedback (newest first).
--
-- Security: anyone using the app may add a row (signed out too). Nobody
-- can read, change or delete rows from the app; only the dashboard can.
-- A signed-in user's rows are deleted with their account.

create table if not exists public.feedback (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        references auth.users (id) on delete cascade,
  kind        text        not null check (kind in ('feature', 'improvement')),
  message     text        not null check (char_length(message) between 3 and 1000),
  app_version text,
  platform    text,
  created_at  timestamptz not null default now()
);

comment on table public.feedback is
  'Ideas sent from the app. Insert only from the app; read in the dashboard.';

create index if not exists feedback_created_at on public.feedback (created_at desc);

alter table public.feedback enable row level security;

-- Signed out: no user id. Signed in: only their own id, never someone else's.
create policy "feedback: anyone can send"
  on public.feedback for insert
  to anon, authenticated
  with check (user_id is null or user_id = (select auth.uid()));
