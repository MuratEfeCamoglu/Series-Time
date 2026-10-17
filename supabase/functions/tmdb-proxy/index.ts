// TMDB API v3 vekili (ISKELET.md §3.5). API anahtarı yalnızca burada, Edge Function sırrı olarak bulunur.
// Eylemler: search, trending, show, season, episode_credits, genres, discover, recommendations,
// on_the_air, popular, show_credits.
// Ortak TMDB kodu: ../_shared/tmdb.ts.
import { z } from "npm:zod@3";
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import {
  cachedEpisodes,
  env,
  isFresh,
  syncSeason,
  syncShow,
  tmdb,
  TmdbError,
  type TmdbJson,
  upsertSummaries,
} from "../_shared/tmdb.ts";

// F10(a): oylamada ilk 20 kişi gösterildiği için fazlası saklanmaz.
const MAX_CREDITS = 20;
const GENRES_TTL_MS = 30 * 24 * 60 * 60 * 1000;

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
  z.object({ action: z.literal("genres") }),
  z.object({
    action: z.literal("discover"),
    genreIds: z.array(tmdbId).min(1).max(3),
    page: z.number().int().min(1).max(500).default(1),
  }),
  z.object({ action: z.literal("recommendations"), showId: tmdbId }),
  z.object({ action: z.literal("on_the_air") }),
  z.object({ action: z.literal("popular") }),
  z.object({ action: z.literal("show_credits"), showId: tmdbId }),
]);

type CacheState = "hit" | "miss" | "stale";

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
      case "genres":
        return await genres(db);
      case "discover":
        return json(await discover(db, userData.user.id, body.genreIds, body.page));
      case "recommendations":
        return json(await recommendations(db, userData.user.id, body.showId));
      case "on_the_air":
        return json(await onTheAir(db));
      case "popular":
        return json(await popular(db));
      case "show_credits":
        return json(await showCredits(body.showId));
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

// F6(i): yeni bölümü yayında olan diziler; kullanıcının listesindekiler de gösterilir.
// F3(d): en ünlü diziler — TMDB'de en çok oy alanlar (anlık popülerlik değil).
async function popular(db: SupabaseClient) {
  const data = await tmdb("/discover/tv", { sort_by: "vote_count.desc" });
  return { results: await upsertSummaries(db, data.results ?? []) };
}

// F4(a) Hakkında: dizinin tüm sezonlardaki oyuncuları, en çok bölümde oynayan önce
// (TMDB sırası). Önbelleğe yazılmaz; yalnızca görüntülenir.
async function showCredits(showId: number) {
  const data = await tmdb(`/tv/${showId}/aggregate_credits`);
  const cast = (data.cast ?? []).slice(0, MAX_CREDITS).map((p: TmdbJson) => ({
    person_id: p.id,
    name: p.name,
    character: p.roles?.[0]?.character || null,
    profile_path: p.profile_path ?? null,
  }));
  return { cast };
}

async function onTheAir(db: SupabaseClient) {
  const data = await tmdb("/tv/on_the_air");
  return { results: await upsertSummaries(db, data.results ?? []) };
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

async function genres(db: SupabaseClient) {
  const { data: cached, error } = await db.from("genres").select("id, name, last_synced_at");
  if (error) throw error;
  const toResponse = (rows: TmdbJson[]) =>
    rows
      .map(({ id, name }) => ({ id, name }))
      .sort((a, b) => a.name.localeCompare(b.name, "tr"));

  const oldest = Math.min(...cached.map((g) => new Date(g.last_synced_at).getTime()));
  if (cached.length > 0 && Date.now() - oldest < GENRES_TTL_MS) {
    return json({ genres: toResponse(cached) }, 200, "hit");
  }
  try {
    const data = await tmdb("/genre/tv/list");
    const syncedAt = new Date().toISOString();
    const rows = (data.genres ?? []).map((g: TmdbJson) => ({
      id: g.id,
      name: g.name,
      last_synced_at: syncedAt,
    }));
    if (rows.length > 0) {
      const { error: upsertError } = await db.from("genres").upsert(rows);
      if (upsertError) throw upsertError;
    }
    return json({ genres: toResponse(rows) }, 200, "miss");
  } catch (err) {
    if (err instanceof TmdbError && cached.length > 0) {
      return json({ genres: toResponse(cached) }, 200, "stale");
    }
    throw err;
  }
}

// F18(d): seçili türlerden en az biri ("|" = VEYA), en az 100 oy, popülerliğe göre.
async function discover(db: SupabaseClient, userId: string, genreIds: number[], page: number) {
  const data = await tmdb("/discover/tv", {
    with_genres: genreIds.join("|"),
    sort_by: "popularity.desc",
    "vote_count.gte": "100",
    page: String(page),
  });
  const results = await upsertSummaries(db, data.results ?? []);
  return {
    results: await withoutUserShows(db, userId, results),
    totalPages: data.total_pages ?? 0,
  };
}

// F18(f): yalnızca ilk sayfa (en fazla 20 dizi).
async function recommendations(db: SupabaseClient, userId: string, showId: number) {
  const data = await tmdb(`/tv/${showId}/recommendations`);
  const results = await upsertSummaries(db, data.results ?? []);
  return { results: await withoutUserShows(db, userId, results) };
}

// Öneriler çağıranın listesindeki dizileri içermez (§3.5).
async function withoutUserShows<T extends { id: number }>(
  db: SupabaseClient,
  userId: string,
  results: T[],
) {
  const { data, error } = await db.from("user_shows").select("show_id").eq("user_id", userId);
  if (error) throw error;
  const mine = new Set(data.map((row) => row.show_id));
  return results.filter((show) => !mine.has(show.id));
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

async function cachedCredits(db: SupabaseClient, episodeId: number) {
  const { data, error } = await db
    .from("episode_credits")
    .select()
    .eq("episode_id", episodeId)
    .order("order");
  if (error) throw error;
  return data;
}

function json(body: unknown, status = 200, cache?: CacheState) {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (cache) headers["x-cache"] = cache;
  return new Response(JSON.stringify(body), { status, headers });
}
