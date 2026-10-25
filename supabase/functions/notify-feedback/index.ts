// Kindose · notify-feedback
//
// Emails the owner when someone sends an idea from Me → Suggest a feature.
// A trigger on public.feedback calls this with the new row's id only.
//
// The body is never trusted: we read the row again with the secret key and
// claim it (notified_at) before sending, so each idea is emailed once and
// calling this by hand can't send anything that isn't a real new row.
// That's why verify_jwt is off (the trigger has no user session).
//
// Secrets (Dashboard → Edge Functions → Secrets, or `supabase secrets set`):
//   RESEND_API_KEY   from resend.com → API Keys
//   FEEDBACK_EMAIL   where to send (your Resend account email while you
//                    use the onboarding@resend.dev sender)
//   FEEDBACK_FROM    optional, e.g. "Kindose <ideas@yourdomain.com>" once
//                    a domain is verified in Resend
//
// Deploy:  supabase functions deploy notify-feedback --no-verify-jwt

import { createClient } from "npm:@supabase/supabase-js@2";

const url = Deno.env.get("SUPABASE_URL")!;

// New projects expose secret keys as a JSON map; older ones as a single key.
function secretKey(): string {
  const raw = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (raw) {
    try {
      const key = JSON.parse(raw)["default"];
      if (typeof key === "string" && key.length > 0) return key;
    } catch (_) {
      // fall through
    }
  }
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

const escape = (s: string) =>
  s.replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!
  );

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  let id = "";
  try {
    id = String((await req.json())?.id ?? "");
  } catch (_) {
    // empty or bad body
  }
  if (!uuid.test(id)) return json({ error: "bad_request" }, 400);

  const apiKey = Deno.env.get("RESEND_API_KEY") ?? "";
  const to = Deno.env.get("FEEDBACK_EMAIL") ?? "";
  if (!apiKey || !to) {
    // Not set up yet: leave the row unclaimed so nothing is lost.
    console.error("RESEND_API_KEY or FEEDBACK_EMAIL is not set");
    return json({ error: "not_configured" }, 503);
  }

  const admin = createClient(url, secretKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Claim the row: only one call can turn notified_at from null to now.
  const { data: row, error } = await admin
    .from("feedback")
    .update({ notified_at: new Date().toISOString() })
    .eq("id", id)
    .is("notified_at", null)
    .select("kind, message, app_version, platform, user_id, created_at")
    .maybeSingle();
  if (error) {
    console.error("claim failed", error.message);
    return json({ error: "failed" }, 500);
  }
  if (!row) return json({ ok: true, skipped: true }); // unknown or already sent

  const label = row.kind === "feature" ? "New feature idea" : "New improvement";
  const meta = [
    row.platform,
    row.app_version ? `v${row.app_version}` : null,
    row.user_id ? "signed in" : "signed out",
  ].filter(Boolean).join(" · ");

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: Deno.env.get("FEEDBACK_FROM") ?? "Kindose <onboarding@resend.dev>",
      to: [to],
      subject: `Kindose · ${label}`,
      text: `${row.message}\n\n${meta}\n${row.created_at}`,
      html:
        `<p style="font-size:16px;white-space:pre-wrap">${escape(row.message)}</p>` +
        `<p style="color:#6B6A76;font-size:13px">${escape(meta)}<br>${escape(String(row.created_at))}</p>`,
    }),
  });

  if (!res.ok) {
    console.error("send failed", res.status, await res.text());
    // Give the row back so a later call can try again.
    await admin.from("feedback").update({ notified_at: null }).eq("id", id);
    return json({ error: "send_failed" }, 502);
  }
  return json({ ok: true });
});
