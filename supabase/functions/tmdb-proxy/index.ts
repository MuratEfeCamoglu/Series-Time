// TMDB API v3 vekili (ISKELET.md §3.5). API anahtarı yalnızca burada, Edge Function sırrı olarak bulunur.
// Aşama 2 eylemleri: search, trending, show, season, episode_credits.
// genres, discover ve recommendations Aşama 4'te (F18, shows.genre_ids ile birlikte) eklenir.
import { z } from "npm:zod@3";
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

const TMDB_BASE_URL = "https://api.themoviedb.org/3";
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;
// F10(a): oylamada ilk 20 kişi gösterildiği için fazlası saklanmaz.
const MAX_CREDITS = 20;

const tmdbId = z.number().int().positive();

const Body = z.discriminatedUnion("action", [
  z.object({
    action: z.literal("search"),
    query: z.string().trim().min(2).max(100),
    page: z.number().int().min(1).max(500).default(1),
  }),
  z.object({ action: z.literal("trending") }),
  z.object({ action: z.literal("show"), showId: tmdbId }),
  z.object({
    action: z.literal("season"),
    showId: tmdbId,
    seasonNumber: z.number().int().min(0),
  }),
  z.object({ action: z.literal("episode_credits"), episodeId: tmdbId }),
]);

type CacheState = "hit" | "miss" | "stale";

class TmdbError extends Error {}

// deno-lint-ignore no-explicit-any
type TmdbJson = Record<string, any>;

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  // Ağ geçidi JWT'yi doğrular, ama anon anahtarı da geçerli bir JWT'dir: gerçek kullanıcı şart.
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(env("SUPABASE_URL"), env("SUPABASE_ANON_KEY"), {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) return json({ error: "unauthorized" }, 401);

  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return json({ error: "invalid_body" }, 400);
  }
  const parsed = Body.safeParse(raw);
  if (!parsed.success) {
    return json({ error: "invalid_body", issues: parsed.error.issues }, 400);
  }

  const db = createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), {
    auth: { persistSession: false },
  });

  try {
    const body = parsed.data;
    switch (body.action) {
      case "search":
        return json(await search(db, body.query, body.page));
      case "trending":
        return json(await trending(db));
      case "show":
        return await show(db, body.showId);
      case "season":
        return await season(db, body.showId, body.seasonNumber);
      case "episode_credits":
        return await episodeCredits(db, body.episodeId);
    }
  } catch (error) {
    if (error instanceof TmdbError) {
      console.error(error.message);
      return json({ error: "tmdb_unavailable" }, 502);
    }
    console.error(error);
    return json({ error: "internal" }, 500);
  }
});

async function search(db: SupabaseClient, query: string, page: number) {
  const data = await tmdb("/search/tv", { query, page: String(page) });
  const results = await upsertSummaries(db, data.results ?? []);
  return { results, totalPages: data.total_pages ?? 0 };
}

async function trending(db: SupabaseClient) {
  const data = await tmdb("/trending/tv/week");
  return { results: await upsertSummaries(db, data.results ?? []) };
}

async function show(db: SupabaseClient, showId: number) {
  const cached = await cachedShow(db, showId);
  if (cached && isFresh(cached.show.last_synced_at)) return json(cached, 200, "hit");
  try {
    return json(await syncShow(db, showId), 200, "miss");
  } catch (error) {
    if (error instanceof TmdbError && cached?.show.last_synced_at) {
      return json(cached, 200, "stale");
    }
    throw error;
  }
}

async function season(db: SupabaseClient, showId: number, seasonNumber: number) {
  const { data: seasonRow, error } = await db
    .from("seasons")
    .select("last_synced_at")
    .eq("show_id", showId)
    .eq("season_number", seasonNumber)
    .maybeSingle();
  if (error) throw error;

  if (seasonRow && isFresh(seasonRow.last_synced_at)) {
    return json({ episodes: await cachedEpisodes(db, showId, seasonNumber) }, 200, "hit");
  }
  try {
    return json({ episodes: await syncSeason(db, showId, seasonNumber) }, 200, "miss");
  } catch (error) {
    if (error instanceof TmdbError && seasonRow?.last_synced_at) {
      return json({ episodes: await cachedEpisodes(db, showId, seasonNumber) }, 200, "stale");
    }
    throw error;
  }
}

async function episodeCredits(db: SupabaseClient, episodeId: number) {
  const { data: episode, error } = await db
    .from("episodes")
    .select("show_id, season_number, episode_number")
    .eq("id", episodeId)
    .maybeSingle();
  if (error) throw error;
  // Bölüm satırı `season` eylemiyle oluşur; istemci bölümü hep oradan tanır.
  if (!episode) return json({ error: "episode_not_found" }, 404);

  const cached = await cachedCredits(db, episodeId);
  // Kadrosu boş bölümler satır bırakmadığı için her seferinde TMDB'ye sorulur (F10d).
  if (cached.length > 0 && isFresh(cached[0].last_synced_at)) {
    return json({ credits: cached }, 200, "hit");
  }
  try {
    const data = await tmdb(
      `/tv/${episode.show_id}/season/${episode.season_number}/episode/${episode.episode_number}/credits`,
    );
    const seen = new Set<number>();
    const syncedAt = new Date().toISOString();
    const rows = [...(data.cast ?? []), ...(data.guest_stars ?? [])]
      .filter((person: TmdbJson) => !seen.has(person.id) && seen.add(person.id))
      .slice(0, MAX_CREDITS)
      .map((person: TmdbJson, index: number) => ({
        episode_id: episodeId,
        person_id: person.id,
        name: person.name,
        character: person.character || null,
        profile_path: person.profile_path ?? null,
        order: index,
        last_synced_at: syncedAt,
      }));

    // Kadrodan çıkan kişiler kalmasın diye önce silinir.
    const del = await db.from("episode_credits").delete().eq("episode_id", episodeId);
    if (del.error) throw del.error;
    if (rows.length > 0) {
      const ins = await db.from("episode_credits").insert(rows);
      if (ins.error) throw ins.error;
    }
    return json({ credits: rows }, 200, "miss");
  } catch (error) {
    if (error instanceof TmdbError && cached.length > 0) {
      return json({ credits: cached }, 200, "stale");
    }
    throw error;
  }
}

async function syncShow(db: SupabaseClient, showId: number) {
  const data = await tmdb(`/tv/${showId}`);
  const syncedAt = new Date().toISOString();
  const showRow = {
    ...summaryRow(data),
    status: data.status ?? null,
    number_of_seasons: data.number_of_seasons ?? null,
    number_of_episodes: data.number_of_episodes ?? null,
    default_runtime: data.episode_run_time?.[0] ?? null,
    last_synced_at: syncedAt,
  };
  const { data: savedShow, error: showError } = await db
    .from("shows")
    .upsert(showRow)
    .select()
    .single();
  if (showError) throw showError;

  // Sezonun `last_synced_at` değeri bölüm senkronuna aittir; burada değiştirilmez.
  const seasonRows = (data.seasons ?? []).map((s: TmdbJson) => ({
    id: s.id,
    show_id: showId,
    season_number: s.season_number,
    name: s.name ?? null,
    poster_path: s.poster_path ?? null,
    air_date: s.air_date || null,
    episode_count: s.episode_count ?? null,
  }));
  if (seasonRows.length > 0) {
    const { error } = await db.from("seasons").upsert(seasonRows);
    if (error) throw error;
  }
  const { data: seasons, error: seasonsError } = await db
    .from("seasons")
    .select()
    .eq("show_id", showId)
    .order("season_number");
  if (seasonsError) throw seasonsError;
  return { show: savedShow, seasons };
}

async function syncSeason(db: SupabaseClient, showId: number, seasonNumber: number) {
  // Bölümler shows/seasons satırına bağlıdır; detayı hiç açılmamış dizide önce o çekilir.
  const { data: showRow, error } = await db
    .from("shows")
    .select("last_synced_at")
    .eq("id", showId)
    .maybeSingle();
  if (error) throw error;
  if (!showRow?.last_synced_at) await syncShow(db, showId);

  const data = await tmdb(`/tv/${showId}/season/${seasonNumber}`);
  const episodeRows = (data.episodes ?? []).map((e: TmdbJson) => ({
    id: e.id,
    show_id: showId,
    season_number: seasonNumber,
    episode_number: e.episode_number,
    name: e.name ?? null,
    overview: e.overview ?? "",
    air_date: e.air_date || null,
    runtime: e.runtime ?? null,
    still_path: e.still_path ?? null,
  }));
  if (episodeRows.length > 0) {
    const { error: upsertError } = await db.from("episodes").upsert(episodeRows);
    if (upsertError) throw upsertError;
  }
  const { error: seasonError } = await db.from("seasons").upsert({
    id: data.id,
    show_id: showId,
    season_number: seasonNumber,
    name: data.name ?? null,
    poster_path: data.poster_path ?? null,
    air_date: data.air_date || null,
    episode_count: episodeRows.length,
    last_synced_at: new Date().toISOString(),
  });
  if (seasonError) throw seasonError;
  return await cachedEpisodes(db, showId, seasonNumber);
}

/// Arama/trend sonuçları: yalnızca özet kolonlar yazılır, detay kolonları ve last_synced_at korunur.
async function upsertSummaries(db: SupabaseClient, results: TmdbJson[]) {
  const rows = results.filter((r) => r.id && r.name).map(summaryRow);
  if (rows.length === 0) return [];
  const { error } = await db.from("shows").upsert(rows);
  if (error) throw error;
  return rows;
}

function summaryRow(r: TmdbJson) {
  return {
    id: r.id,
    name: r.name,
    original_name: r.original_name ?? null,
    overview: r.overview ?? "",
    poster_path: r.poster_path ?? null,
    backdrop_path: r.backdrop_path ?? null,
    first_air_date: r.first_air_date || null,
  };
}

async function cachedShow(db: SupabaseClient, showId: number) {
  const { data: showRow, error } = await db.from("shows").select().eq("id", showId).maybeSingle();
  if (error) throw error;
  if (!showRow) return null;
  const { data: seasons, error: seasonsError } = await db
    .from("seasons")
    .select()
    .eq("show_id", showId)
    .order("season_number");
  if (seasonsError) throw seasonsError;
  return { show: showRow, seasons };
}

async function cachedEpisodes(db: SupabaseClient, showId: number, seasonNumber: number) {
  const { data, error } = await db
    .from("episodes")
    .select()
    .eq("show_id", showId)
    .eq("season_number", seasonNumber)
    .order("episode_number");
  if (error) throw error;
  return data;
}

async function cachedCredits(db: SupabaseClient, episodeId: number) {
  const { data, error } = await db
    .from("episode_credits")
    .select()
    .eq("episode_id", episodeId)
    .order("order");
  if (error) throw error;
  return data;
}

async function tmdb(path: string, params: Record<string, string> = {}): Promise<TmdbJson> {
  const url = new URL(TMDB_BASE_URL + path);
  url.searchParams.set("language", "tr-TR");
  for (const [key, value] of Object.entries(params)) url.searchParams.set(key, value);

  let response: Response;
  try {
    response = await fetch(url, {
      headers: { Authorization: `Bearer ${env("TMDB_API_KEY")}`, Accept: "application/json" },
    });
  } catch (error) {
    throw new TmdbError(`TMDB erişilemedi: ${error}`);
  }
  if (!response.ok) throw new TmdbError(`TMDB ${response.status}: ${path}`);
  return await response.json();
}

function isFresh(syncedAt: string | null | undefined) {
  return !!syncedAt && Date.now() - new Date(syncedAt).getTime() < CACHE_TTL_MS;
}

function json(body: unknown, status = 200, cache?: CacheState) {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (cache) headers["x-cache"] = cache;
  return new Response(JSON.stringify(body), { status, headers });
}

function env(name: string) {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`${name} tanımlı değil`);
  return value;
}
