-- Free week + discount offer settings the app reads at start.
-- Edit these rows later in Table Editor → app_config (no app update needed).
--
-- access:
--   free_days                 length of the free week
--   start_after_install_days  week starts at the first dose, or this many
--                             days after install if no dose yet
--   gating_on                 false = everything open for everyone
--
-- paywall_offer: the one-time discount after closing the paywall. Prices
-- shown in the app come from the store; the strings are only a fallback.

insert into public.app_config (key, value) values
  ('access', '{"free_days": 7, "start_after_install_days": 7, "gating_on": true}'::jsonb),
  ('paywall_offer', '{
     "enabled": true,
     "offering_id": "offer_30",
     "product_id": "kindose_plus_yearly_offer",
     "discount_percent": 30,
     "offer_price": "$34.99",
     "regular_price": "$49.99",
     "per_month": "$2.92/mo",
     "price_note": "for your first year, then $49.99/year",
     "fine_print": "$34.99 today for 12 months, then $49.99/year. Cancel anytime.",
     "cta": "Get 30% off",
     "max_shows": 1,
     "cooldown_days": 30
   }'::jsonb)
on conflict (key) do update set value = excluded.value, updated_at = now();
