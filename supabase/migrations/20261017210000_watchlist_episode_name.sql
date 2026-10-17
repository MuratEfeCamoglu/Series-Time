-- F6(b) görsel düzen: İzleme Listesi satırı sıradaki bölümün adını da gösterir.
-- Dönüş tipi değiştiği için fonksiyon yeniden oluşturulur (gövde aynı + next_episode_name).
drop function public.get_watchlist();

create function public.get_watchlist()
returns table (
  show_id integer,
  name text,
  poster_path text,
  added_at timestamptz,
  last_watched_at timestamptz,
  next_episode_id integer,
  next_season_number integer,
  next_episode_number integer,
  next_episode_name text,
  aired_count integer,
  watched_count integer
)
language sql
stable
security invoker
set search_path = ''
as $$
  with mine as (
    select us.show_id, us.added_at, us.last_watched_at
    from public.user_shows us
    where us.user_id = auth.uid()
  ),
  aired as (
    select e.id, e.show_id, e.season_number, e.episode_number, e.name,
           (w.episode_id is not null) as watched
    from mine m
    join public.episodes e on e.show_id = m.show_id
    left join public.watched_episodes w on w.user_id = auth.uid() and w.episode_id = e.id
    where e.season_number > 0 and e.air_date <= public.utc_today()
  ),
  counts as (
    select a.show_id, count(*)::integer as aired_count,
           (count(*) filter (where a.watched))::integer as watched_count
    from aired a
    group by a.show_id
  ),
  next_episode as (
    select distinct on (a.show_id) a.show_id, a.id, a.season_number, a.episode_number, a.name
    from aired a
    where not a.watched
    order by a.show_id, a.season_number, a.episode_number
  )
  select m.show_id, s.name, s.poster_path, m.added_at, m.last_watched_at,
         n.id, n.season_number, n.episode_number, n.name, c.aired_count, c.watched_count
  from mine m
  join public.shows s on s.id = m.show_id
  join next_episode n on n.show_id = m.show_id
  join counts c on c.show_id = m.show_id
  order by (m.last_watched_at is null) desc, m.last_watched_at desc, m.added_at desc;
$$;

revoke execute on function public.get_watchlist() from public, anon;
grant execute on function public.get_watchlist() to authenticated;
