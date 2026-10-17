-- F4(f): kullanıcının dizi için seçtiği afiş; F13(f): Bildirimler › Arkadaşlar akışı
-- (kullanıcı kararları 2026-10-18).

alter table public.user_shows
  add column poster_path text
    constraint user_shows_poster_path_format check (poster_path ~ '^/[A-Za-z0-9_.-]+$');

grant update (poster_path) on public.user_shows to authenticated;

-- Seçilen afiş, dizinin sahibinin listelerinde TMDB afişinin yerine geçer. Dönüş tipleri
-- değişmediği için gövdeler yerinde yenilenir.
create or replace function public.get_watchlist()
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
  next_still_path text,
  backdrop_path text,
  aired_count integer,
  watched_count integer,
  show_status text,
  manual_status public.manual_show_status
)
language sql
stable
security invoker
set search_path = ''
as $$
  with mine as (
    select us.show_id, us.added_at, us.last_watched_at, us.manual_status, us.poster_path
    from public.user_shows us
    where us.user_id = auth.uid()
      and (us.manual_status is null or us.manual_status not in ('paused', 'dropped'))
  ),
  aired as (
    select e.id, e.show_id, e.season_number, e.episode_number, e.name, e.still_path,
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
    select distinct on (a.show_id) a.show_id, a.id, a.season_number, a.episode_number, a.name, a.still_path
    from aired a
    where not a.watched
    order by a.show_id, a.season_number, a.episode_number
  )
  select m.show_id, s.name, coalesce(m.poster_path, s.poster_path), m.added_at, m.last_watched_at,
         n.id, n.season_number, n.episode_number, n.name, n.still_path, s.backdrop_path,
         c.aired_count, c.watched_count, s.status, m.manual_status
  from mine m
  join public.shows s on s.id = m.show_id
  join next_episode n on n.show_id = m.show_id
  join counts c on c.show_id = m.show_id
  order by (m.last_watched_at is null) desc, m.last_watched_at desc, m.added_at desc;
$$;

create or replace function public.get_upcoming(days integer default 90)
returns table (
  episode_id integer,
  show_id integer,
  show_name text,
  poster_path text,
  season_number integer,
  episode_number integer,
  episode_name text,
  air_date date
)
language sql
stable
security invoker
set search_path = ''
as $$
  select e.id, e.show_id, s.name, coalesce(us.poster_path, s.poster_path), e.season_number,
         e.episode_number, e.name, e.air_date
  from public.user_shows us
  join public.shows s on s.id = us.show_id
  join public.episodes e on e.show_id = us.show_id
  where us.user_id = auth.uid()
    and e.season_number > 0
    and e.air_date between public.utc_today() and public.utc_today() + get_upcoming.days
  order by e.air_date, s.name, e.season_number, e.episode_number;
$$;

create or replace function public.get_user_show_progress(user_id uuid)
returns table (
  show_id integer,
  name text,
  poster_path text,
  backdrop_path text,
  show_status text,
  added_at timestamptz,
  last_watched_at timestamptz,
  manual_status public.manual_show_status,
  is_favorite boolean,
  aired_count integer,
  watched_count integer
)
language sql
stable
security invoker
set search_path = ''
as $$
  with mine as (
    select us.show_id, us.added_at, us.last_watched_at, us.manual_status, us.is_favorite,
           us.poster_path
    from public.user_shows us
    where us.user_id = get_user_show_progress.user_id
  ),
  counts as (
    select e.show_id, count(*)::integer as aired_count,
           (count(*) filter (where w.episode_id is not null))::integer as watched_count
    from mine m
    join public.episodes e on e.show_id = m.show_id
    left join public.watched_episodes w
      on w.user_id = get_user_show_progress.user_id and w.episode_id = e.id
    where e.season_number > 0 and e.air_date <= public.utc_today()
    group by e.show_id
  )
  select m.show_id, s.name, coalesce(m.poster_path, s.poster_path), s.backdrop_path, s.status,
         m.added_at, m.last_watched_at, m.manual_status, m.is_favorite,
         coalesce(c.aired_count, 0), coalesce(c.watched_count, 0)
  from mine m
  join public.shows s on s.id = m.show_id
  left join counts c on c.show_id = m.show_id
  order by m.last_watched_at desc nulls last, m.added_at desc;
$$;

create or replace function public.get_recent_activity(user_id uuid, lim integer default 20)
returns table (
  episode_id integer,
  show_id integer,
  show_name text,
  poster_path text,
  backdrop_path text,
  still_path text,
  season_number integer,
  episode_number integer,
  episode_name text,
  watched_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select w.episode_id, e.show_id, s.name, coalesce(us.poster_path, s.poster_path), s.backdrop_path,
         e.still_path, e.season_number, e.episode_number, e.name, w.watched_at
  from public.watched_episodes w
  join public.episodes e on e.id = w.episode_id
  join public.shows s on s.id = e.show_id
  left join public.user_shows us on us.user_id = w.user_id and us.show_id = e.show_id
  where w.user_id = get_recent_activity.user_id
  order by w.watched_at desc, e.season_number desc, e.episode_number desc
  limit least(greatest(lim, 1), 50);
$$;

create or replace function public.get_friends_activity(lim integer default 20)
returns table (
  user_id uuid,
  username text,
  avatar_path text,
  episode_id integer,
  show_id integer,
  show_name text,
  poster_path text,
  still_path text,
  season_number integer,
  episode_number integer,
  rating numeric,
  watched_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select latest.*
  from (
    select distinct on (w.user_id)
      w.user_id, p.username, p.avatar_path, w.episode_id, e.show_id, s.name as show_name,
      coalesce(us.poster_path, s.poster_path) as poster_path, e.still_path, e.season_number,
      e.episode_number, r.rating, w.watched_at
    from public.follows f
    join public.watched_episodes w on w.user_id = f.followee_id
    join public.profiles p on p.id = w.user_id
    join public.episodes e on e.id = w.episode_id
    join public.shows s on s.id = e.show_id
    left join public.user_shows us on us.user_id = w.user_id and us.show_id = e.show_id
    left join public.episode_ratings r on r.user_id = w.user_id and r.episode_id = w.episode_id
    where f.follower_id = auth.uid()
      and not exists (
        select 1 from public.blocks b
        where b.blocker_id = auth.uid() and b.blocked_id = w.user_id
      )
    order by w.user_id, w.watched_at desc, e.season_number desc, e.episode_number desc
  ) latest
  order by latest.watched_at desc
  limit least(greatest(lim, 1), 50);
$$;

-- Bildirimler › Arkadaşlar: takip edilenlerin son 90 gündeki izlemeleri (aynı gün aynı dizideki
-- bölümler tek satırda), puanları ve rozetleri; engellenenler hariç, yorum metni yok (R7).
create function public.get_friends_feed(lim integer default 50)
returns table (
  kind text,
  user_id uuid,
  username text,
  avatar_path text,
  show_id integer,
  show_name text,
  poster_path text,
  episode_id integer,
  season_number integer,
  episode_number integer,
  episode_count integer,
  rating numeric,
  badge_code text,
  happened_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  with friends as (
    select f.followee_id as id
    from public.follows f
    where f.follower_id = auth.uid()
      and not exists (
        select 1 from public.blocks b
        where b.blocker_id = auth.uid() and b.blocked_id = f.followee_id
      )
  ),
  watched as (
    select w.user_id, e.show_id, count(*)::integer as episode_count,
           max(w.watched_at) as happened_at,
           (array_agg(e.id order by e.season_number desc, e.episode_number desc))[1] as episode_id
    from public.watched_episodes w
    join friends fr on fr.id = w.user_id
    join public.episodes e on e.id = w.episode_id
    where w.watched_at >= now() - interval '90 days'
    group by w.user_id, e.show_id, (w.watched_at at time zone 'utc')::date
  ),
  events as (
    select 'watched'::text as kind, wa.user_id, wa.show_id, wa.episode_id, wa.episode_count,
           null::numeric as rating, null::text as badge_code, wa.happened_at
    from watched wa
    union all
    select 'rated', r.user_id, e.show_id, r.episode_id, 1, r.rating, null, r.created_at
    from public.episode_ratings r
    join friends fr on fr.id = r.user_id
    join public.episodes e on e.id = r.episode_id
    where r.created_at >= now() - interval '90 days'
    union all
    select 'badge', ub.user_id, null, null, null, null, ub.badge_code, ub.earned_at
    from public.user_badges ub
    join friends fr on fr.id = ub.user_id
    where ub.earned_at >= now() - interval '90 days'
  )
  select ev.kind, ev.user_id, p.username, p.avatar_path, ev.show_id, s.name,
         coalesce(us.poster_path, s.poster_path), ev.episode_id, e.season_number, e.episode_number,
         ev.episode_count, ev.rating, ev.badge_code, ev.happened_at
  from events ev
  join public.profiles p on p.id = ev.user_id
  left join public.shows s on s.id = ev.show_id
  left join public.user_shows us on us.user_id = ev.user_id and us.show_id = ev.show_id
  left join public.episodes e on e.id = ev.episode_id
  order by ev.happened_at desc
  limit least(greatest(lim, 1), 100);
$$;
revoke execute on function public.get_friends_feed(integer) from public, anon;
grant execute on function public.get_friends_feed(integer) to authenticated;
