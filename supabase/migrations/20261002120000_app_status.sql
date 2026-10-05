-- Force update + announcement banner, read by the app at start.
-- Edit later in Table Editor → app_config → key "app".
--   min_version     versions below this see only "Time to update"
--   update_title / update_message   text on that screen
--   banner          null, or {"id": "...", "text": "...", "level": "info"|"warning", "url": "https://..."}
--                   change "id" to show a new banner to people who closed the last one
insert into public.app_config (key, value) values
  ('app', '{"min_version": "1.0.0", "banner": null}'::jsonb)
on conflict (key) do nothing;
