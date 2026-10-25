-- Email the owner for each new idea (Me → Suggest a feature).
-- After an insert, pg_net calls the notify-feedback edge function with the
-- row id only; the function reads the row itself and sends one email.
-- notified_at records when that email went out (null = not sent yet).

create extension if not exists pg_net with schema extensions;

alter table public.feedback add column if not exists notified_at timestamptz;

create or replace function public.feedback_notify()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform net.http_post(
    url := 'https://znwxockfqnacqjkgupfw.supabase.co/functions/v1/notify-feedback',
    body := jsonb_build_object('id', new.id),
    headers := '{"Content-Type": "application/json"}'::jsonb
  );
  return new;
end;
$$;

-- Only the trigger runs it.
revoke all on function public.feedback_notify() from public, anon, authenticated;

drop trigger if exists feedback_notify on public.feedback;
create trigger feedback_notify
  after insert on public.feedback
  for each row execute function public.feedback_notify();
