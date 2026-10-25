-- Explicit Data API grants for every public table.
-- From 30 Oct 2026 Supabase no longer grants new public tables to the API
-- roles automatically, so a fresh project, preview branch or `db reset`
-- would otherwise get "permission denied". Row Level Security still decides
-- which rows each role can touch; these grants only open the table.
-- Only what the app uses: grants are added, nothing is revoked.

-- backups: each signed-in user reads and writes only their own row (RLS).
grant select, insert, update, delete on public.backups to authenticated;
grant select, insert, update, delete on public.backups to service_role;

-- app_config: read by the app before and after sign-in; edited in the
-- dashboard only.
grant select on public.app_config to anon, authenticated;
grant select, insert, update, delete on public.app_config to service_role;

-- feedback: the app may only add ideas (signed out too); notify-feedback
-- reads and marks them with the secret key.
grant insert on public.feedback to anon, authenticated;
grant select, insert, update, delete on public.feedback to service_role;
