-- F8(j): en fazla 4 favori dizi; F8(k): profilde son izlenen bölümler (kullanıcı kararları 2026-10-17).

alter table public.user_shows
  add column is_favorite boolean not null default false;

-- Sahibi grup seçimine ek olarak yalnızca favori işaretini günceller.
grant update (is_favorite) on public.user_shows to authenticated;

create function public.enforce_favorite_limit()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.is_favorite and (tg_op = 'INSERT' or not old.is_favorite) then
    if (
      select count(*) from public.user_shows us
      where us.user_id = new.user_id and us.is_favorite and us.show_id <> new.show_id
    ) >= 4 then
      raise exception 'too_many_favorites' using errcode = '23514';
    end if;
  end if;
  return new;
end;
$$;

create trigger user_shows_favorite_limit
  before insert or update of is_favorite on public.user_shows
  for each row execute function public.enforce_favorite_limit();

-- Dönüş tipine is_favorite eklendiği için yeniden oluşturulur.
drop function public.get_user_show_progress(uuid);

create function public.get_user_show_progress(user_id uuid)
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
    select us.show_id, us.added_at, us.last_watched_at, us.manual_status, us.is_favorite
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
  select m.show_id, s.name, s.poster_path, s.backdrop_path, s.status, m.added_at,
         m.last_watched_at, m.manual_status, m.is_favorite,
         coalesce(c.aired_count, 0), coalesce(c.watched_count, 0)
  from mine m
  join public.shows s on s.id = m.show_id
  left join counts c on c.show_id = m.show_id
  order by m.last_watched_at desc nulls last, m.added_at desc;
$$;
revoke execute on function public.get_user_show_progress(uuid) from public, anon;
grant execute on function public.get_user_show_progress(uuid) to authenticated;

create index watched_episodes_user_watched_at_idx
  on public.watched_episodes (user_id, watched_at desc);

-- Son izlenen bölümler, yeniden eskiye; izleme listeleri herkese açık (V10).
create function public.get_recent_activity(user_id uuid, lim integer default 20)
returns table (
  episode_id integer,
  show_id integer,
  show_name text,
  poster_path text,
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
  select w.episode_id, e.show_id, s.name, s.poster_path, e.season_number, e.episode_number,
         e.name, w.watched_at
  from public.watched_episodes w
  join public.episodes e on e.id = w.episode_id
  join public.shows s on s.id = e.show_id
  where w.user_id = get_recent_activity.user_id
  order by w.watched_at desc, e.season_number desc, e.episode_number desc
  limit least(greatest(lim, 1), 50);
$$;
revoke execute on function public.get_recent_activity(uuid, integer) from public, anon;
grant execute on function public.get_recent_activity(uuid, integer) to authenticated;
