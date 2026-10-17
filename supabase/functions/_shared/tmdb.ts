// tmdb-proxy ve tmdb-sync'in ortak TMDB erişimi ve önbellek yazımı (ISKELET.md §3.5).
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";

const TMDB_BASE_URL = "https://api.themoviedb.org/3";
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;

export class TmdbError extends Error {}

// deno-lint-ignore no-explicit-any
export type TmdbJson = Record<string, any>;

export async function syncShow(db: SupabaseClient, showId: number) {
  const data = await tmdb(`/tv/${showId}`);
  const syncedAt = new Date().toISOString();
  const showRow = {
    ...summaryRow(data),
    status: data.status ?? null,
    number_of_seasons: data.number_of_seasons ?? null,
    number_of_episodes: data.number_of_episodes ?? null,
    default_runtime: data.episode_run_time?.[0] ?? null,
    // Detayda türler `genres[].id`, liste sonuçlarında `genre_ids` olarak gelir (§3.5).
    genre_ids: (data.genres ?? []).map((g: TmdbJson) => g.id),
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

export async function syncSeason(db: SupabaseClient, showId: number, seasonNumber: number) {
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

// Arama/trend sonuçları: yalnızca özet kolonlar yazılır, detay kolonları ve last_synced_at korunur.
/// İstemci dili (F21b). Önbellekteki metinler Türkçedir; İngilizce yanıtlar yalnızca gösterilir.
export type Lang = "tr" | "en";

export function langParams(lang: Lang): Record<string, string> {
  return lang === "en" ? { language: "en-US" } : {};
}

/// [lang] İngilizceyse mevcut Türkçe satırlar değiştirilmez, yalnızca eksik diziler eklenir
/// (listeye eklemek için satırın var olması gerekir; ilk `show` senkronu Türkçeleştirir).
export async function upsertSummaries(db: SupabaseClient, results: TmdbJson[], lang: Lang = "tr") {
  const rows = results.filter((r) => r.id && r.name).map(summaryRow);
  if (rows.length === 0) return [];
  const { error } = await db
    .from("shows")
    .upsert(rows, lang === "en" ? { onConflict: "id", ignoreDuplicates: true } : undefined);
  if (error) throw error;
  return rows;
}

export function summaryRow(r: TmdbJson) {
  return {
    id: r.id,
    name: r.name,
    original_name: r.original_name ?? null,
    overview: r.overview ?? "",
    poster_path: r.poster_path ?? null,
    backdrop_path: r.backdrop_path ?? null,
    first_air_date: r.first_air_date || null,
    genre_ids: r.genre_ids ?? [],
  };
}

export async function cachedEpisodes(db: SupabaseClient, showId: number, seasonNumber: number) {
  const { data, error } = await db
    .from("episodes")
    .select()
    .eq("show_id", showId)
    .eq("season_number", seasonNumber)
    .order("episode_number");
  if (error) throw error;
  return data;
}

export async function tmdb(path: string, params: Record<string, string> = {}): Promise<TmdbJson> {
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

export function isFresh(syncedAt: string | null | undefined) {
  return !!syncedAt && Date.now() - new Date(syncedAt).getTime() < CACHE_TTL_MS;
}

export function env(name: string) {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`${name} tanımlı değil`);
  return value;
}
