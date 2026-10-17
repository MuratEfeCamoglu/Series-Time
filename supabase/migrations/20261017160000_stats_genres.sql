-- Aşama 4: profil istatistikleri (F8) ve öneriler için türler (F18) — ISKELET.md §3.2, §3.3.

alter table public.shows add column genre_ids integer[] not null default '{}';

-- TMDB dizi türleri, Türkçe adlarıyla. Yalnızca tmdb-proxy yazar (30 gün önbellek).
create table public.genres (
  id integer primary key,
  name text not null,
  last_synced_at timestamptz not null default now()
);

alter table public.genres enable row level security;

create policy "genres_select_all" on public.genres for select to anon, authenticated using (true);

-- F8(d): izlenen bölüm sayısı ve toplam süre. Süre: bölümün runtime'ı, yoksa dizinin
-- varsayılan süresi, o da yoksa 45 dk (V15). Sezon 0 istatistiğe girmez.
create function public.get_user_stats(user_id uuid)
returns table (watched_episodes integer, watch_minutes bigint)
language sql
stable
security invoker
set search_path = ''
as $$
  select count(*)::integer,
         coalesce(sum(coalesce(e.runtime, s.default_runtime, 45)), 0)::bigint
  from public.watched_episodes w
  join public.episodes e on e.id = w.episode_id
  join public.shows s on s.id = w.show_id
  where w.user_id = get_user_stats.user_id
    and e.season_number > 0;
$$;

-- F18(c): oturum sahibinin listesindeki dizilerde en sık geçen tür kimlikleri.
-- Eşitlikte küçük kimlik önce gelir; sonuç her çağrıda aynı olsun.
create function public.get_top_genres(lim integer default 3)
returns setof integer
language sql
stable
security invoker
set search_path = ''
as $$
  select g.genre_id
  from public.user_shows us
  join public.shows s on s.id = us.show_id
  cross join lateral unnest(s.genre_ids) as g(genre_id)
  where us.user_id = auth.uid()
  group by g.genre_id
  order by count(*) desc, g.genre_id
  limit get_top_genres.lim;
$$;

revoke execute on function public.get_user_stats(uuid) from public, anon;
revoke execute on function public.get_top_genres(integer) from public, anon;
grant execute on function public.get_user_stats(uuid) to authenticated;
grant execute on function public.get_top_genres(integer) to authenticated;
