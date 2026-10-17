// F16 hesap silme (Apple Guideline 5.1.1(v)). Kullanıcının tüm satırları auth.users'a bağlı
// `on delete cascade` ile silinir; Storage'daki avatarları ayrıca silinir.
import { z } from "npm:zod@3";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { env } from "../_shared/tmdb.ts";

// Ekranda kullanıcı adını yazarak onaylanır; sunucu da aynı adı ister (yanlışlıkla silmeye karşı).
const Body = z.object({ confirmUsername: z.string().trim().min(1).max(40) });

const AVATAR_BUCKET = "avatars";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const userClient = createClient(env("SUPABASE_URL"), env("SUPABASE_ANON_KEY"), {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) return json({ error: "unauthorized" }, 401);
  const userId = userData.user.id;

  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return json({ error: "invalid_body" }, 400);
  }
  const parsed = Body.safeParse(raw);
  if (!parsed.success) return json({ error: "invalid_body" }, 400);

  const admin = createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), {
    auth: { persistSession: false },
  });

  const { data: profile, error: profileError } = await admin
    .from("profiles")
    .select("username")
    .eq("id", userId)
    .single();
  if (profileError) {
    console.error(profileError);
    return json({ error: "internal" }, 500);
  }
  if (profile.username !== parsed.data.confirmUsername.toLowerCase()) {
    return json({ error: "username_mismatch" }, 400);
  }

  // Önce dosyalar: hesap silindikten sonra klasörün sahibi kalmaz.
  const avatars = admin.storage.from(AVATAR_BUCKET);
  const { data: files, error: listError } = await avatars.list(userId, { limit: 1000 });
  if (listError) {
    console.error(listError);
    return json({ error: "internal" }, 500);
  }
  if (files.length > 0) {
    const { error: removeError } = await avatars.remove(files.map((f) => `${userId}/${f.name}`));
    if (removeError) {
      console.error(removeError);
      return json({ error: "internal" }, 500);
    }
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
  if (deleteError) {
    console.error(deleteError);
    return json({ error: "internal" }, 500);
  }
  return json({ deleted: true });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
