// Kindose · delete-account
//
// Deletes the signed-in user's account. Their backup row goes with it
// (backups.user_id has "on delete cascade").
//
// The app calls it with the user's session, so the platform checks the
// token before this code runs (verify_jwt stays on). We then look the user
// up again with the secret key, so a user can only ever delete themselves.
//
// Deploy:  supabase functions deploy delete-account

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

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "unauthorized" }, 401);

  const admin = createClient(url, secretKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) return json({ error: "unauthorized" }, 401);

  const { error: deleteError } = await admin.auth.admin.deleteUser(data.user.id);
  if (deleteError) {
    console.error("delete failed", deleteError.message);
    return json({ error: "delete_failed" }, 500);
  }
  return json({ ok: true });
});
