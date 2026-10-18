-- F13(f): Bildirimler › Ben listesinde oturum sahibinin kendi izlemeleri (kullanıcı kararı 2026-10-18).
-- Aynı gün (UTC) aynı dizide izlenen bölümler tek satırdır; okunmamış sayacına girmez, bu yüzden
-- `notifications` tablosuna yazılmaz, doğrudan `watched_episodes`'tan okunur.
create function public.get_my_watch_feed(lim integer default 50)
returns table (
  show_id integer,
  show_name text,
  poster_path text,
  backdrop_path text,
  still_path text,
  episode_id integer,
  season_number integer,
  episode_number integer,
  episode_count integer,
  happened_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  with watched as (
    select e.show_id, count(*)::integer as episode_count, max(w.watched_at) as happened_at,
           (array_agg(e.id order by e.season_number desc, e.episode_number desc))[1] as episode_id
    from public.watched_episodes w
    join public.episodes e on e.id = w.episode_id
    where w.user_id = auth.uid()
      and w.watched_at >= now() - interval '90 days'
    group by e.show_id, (w.watched_at at time zone 'utc')::date
  )
  select wa.show_id, s.name, coalesce(us.poster_path, s.poster_path), s.backdrop_path, e.still_path,
         wa.episode_id, e.season_number, e.episode_number, wa.episode_count, wa.happened_at
  from watched wa
  join public.shows s on s.id = wa.show_id
  join public.episodes e on e.id = wa.episode_id
  left join public.user_shows us on us.user_id = auth.uid() and us.show_id = wa.show_id
  order by wa.happened_at desc
  limit least(greatest(lim, 1), 100);
$$;
revoke execute on function public.get_my_watch_feed(integer) from public, anon;
grant execute on function public.get_my_watch_feed(integer) to authenticated;
