// Günlük TMDB senkronu (ISKELET.md §3.2): en az bir kullanıcının listesindeki, yayını süren
// dizilerin detayını ve son iki sezonunun bölümlerini yeniler. pg_cron her gün 03:00 UTC'de çağırır.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { env, syncSeason, syncShow, TmdbError } from "../_shared/tmdb.ts";

// AGENT.md: çalışma başına en fazla 500 dizi (TMDB kullanım şartları ve hız sınırı).
const MAX_SHOWS_PER_RUN = 500;
const ONGOING_STATUSES = ["Returning Series", "In Production"];
// Yeni bölümler son sezona eklenir; sezon sınırında yayın süren dizi için bir önceki de alınır.
const RECENT_SEASONS = 2;

Deno.serve(async (req) => {
  // Kullanıcı değil yalnızca zamanlanmış iş çağırır; ağ geçidi JWT denetimi kapalıdır (config.toml).
  if (req.headers.get("Authorization") !== `Bearer ${env("SUPABASE_SERVICE_ROLE_KEY")}`) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
  }

  const db = createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), {
    auth: { persistSession: false },
  });

  // En uzun süredir senkronlanmayanlar önce: limit dolarsa kalanlar ertesi gün gelir.
  const { data: shows, error } = await db
    .from("shows")
    .select("id, user_shows!inner(show_id)")
    .in("status", ONGOING_STATUSES)
    .order("last_synced_at", { ascending: true, nullsFirst: true })
    .limit(MAX_SHOWS_PER_RUN);
  if (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: "internal" }), { status: 500 });
  }

  const showIds = [...new Set(shows.map((row) => row.id as number))];
  let synced = 0;
  let failed = 0;
  for (const showId of showIds) {
    try {
      const { show } = await syncShow(db, showId);
      const lastSeason = show.number_of_seasons ?? 0;
      for (let n = Math.max(1, lastSeason - RECENT_SEASONS + 1); n <= lastSeason; n++) {
        await syncSeason(db, showId, n);
      }
      synced++;
    } catch (err) {
      // Bir dizinin hatası diğerlerini durdurmaz; TMDB tamamen düştüyse erken çıkılır.
      failed++;
      console.error(`tmdb-sync ${showId}:`, err);
      if (err instanceof TmdbError && synced === 0 && failed >= 5) break;
    }
  }

  return new Response(JSON.stringify({ synced, failed, total: showIds.length }), {
    headers: { "Content-Type": "application/json" },
  });
});
