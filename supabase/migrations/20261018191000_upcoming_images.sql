-- F7: Yaklaşan satırları Sıradaki kartı gibi bölümün sahne görseliyle (yoksa dizinin arka
-- planıyla) gösterilir (kullanıcı kararı 2026-10-18). Dönüş tipi değiştiği için yeniden kurulur.
drop function public.get_upcoming(integer);

create function public.get_upcoming(days integer default 90)
returns table (
  episode_id integer,
  show_id integer,
  show_name text,
  poster_path text,
  season_number integer,
  episode_number integer,
  episode_name text,
  air_date date,
  still_path text,
  backdrop_path text
)
language sql
stable
security invoker
set search_path = ''
as $$
  select e.id, e.show_id, s.name, coalesce(us.poster_path, s.poster_path), e.season_number,
         e.episode_number, e.name, e.air_date, e.still_path, s.backdrop_path
  from public.user_shows us
  join public.shows s on s.id = us.show_id
  join public.episodes e on e.show_id = us.show_id
  where us.user_id = auth.uid()
    and e.season_number > 0
    and e.air_date between public.utc_today() and public.utc_today() + get_upcoming.days
  order by e.air_date, s.name, e.season_number, e.episode_number;
$$;
revoke execute on function public.get_upcoming(integer) from public, anon;
grant execute on function public.get_upcoming(integer) to authenticated;
