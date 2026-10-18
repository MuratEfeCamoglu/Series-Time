-- Sıradaki bölüm (F6) ve ilerleme yalnızca önbellekteki bölümlerden hesaplanır. Bölümleri
-- hiç çekilmemiş yayınlanmış sezonlar diziyi "bitti" gösterir; istemci bu listeyi alıp
-- eksik sezonları `tmdb-proxy` `season` ile tamamlar.
create function public.get_missing_seasons(lim integer default 20)
returns table (show_id integer, season_number integer)
language sql
stable
security invoker
set search_path = ''
as $$
  select se.show_id, se.season_number
  from public.user_shows us
  join public.seasons se on se.show_id = us.show_id
  where us.user_id = auth.uid()
    and se.season_number > 0
    and se.air_date <= public.utc_today()
    and coalesce(se.episode_count, 0) > (
      select count(*) from public.episodes e
      where e.show_id = se.show_id and e.season_number = se.season_number
    )
  order by us.last_watched_at desc nulls last, se.show_id, se.season_number
  limit least(greatest(lim, 1), 50);
$$;
revoke execute on function public.get_missing_seasons(integer) from public, anon;
grant execute on function public.get_missing_seasons(integer) to authenticated;
