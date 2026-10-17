-- F6(j) dizi durum grupları: elle seçilen grup, otomatiğe dönüş tetikleyicisi, ilerleme sayıları
-- ve Sıradaki sekmesinden Durduruldu/Dönülmez dizilerin çıkarılması (kullanıcı kararı 2026-10-17).
-- Otomatik grup (Bitti/Güncel/Devam ediyor/İzleme Listesi) istemcide hesaplanır (tracking/logic.dart).

create type public.manual_show_status as enum ('paused', 'dropped', 'planned');

alter table public.user_shows add column manual_status public.manual_show_status;

-- Sahibi yalnızca elle seçilen grubu değiştirebilir; last_watched_at tetikleyicilerle güncellenir.
create policy "user_shows_update_own"
  on public.user_shows for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

revoke update on public.user_shows from authenticated;
grant update (manual_status) on public.user_shows to authenticated;

-- Durduruldu veya İzleme Listesi'ndeki bir dizide bölüm işaretlenince elle seçim kalkar ve grup
-- otomatiğe döner; Dönülmez kullanıcının bilinçli kararıdır, korunur.
create function public.after_watched_episode_reset_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.user_shows us
  set manual_status = null
  where us.user_id = new.user_id
    and us.show_id = new.show_id
    and us.manual_status in ('paused', 'planned');
  return new;
end;
$$;

create trigger watched_episodes_reset_status
  after insert on public.watched_episodes
  for each row execute function public.after_watched_episode_reset_status();

-- F6(j): kullanıcının tüm dizileri, yayınlanmış/izlenmiş bölüm sayıları (sezon 0 ve gelecek
-- bölümler hariç), TMDB durumu ve elle seçilen grupla. Başkasının profilinde de kullanılır (V10).
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
  aired_count integer,
  watched_count integer
)
language sql
stable
security invoker
set search_path = ''
as $$
  with mine as (
    select us.show_id, us.added_at, us.last_watched_at, us.manual_status
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
         m.last_watched_at, m.manual_status,
         coalesce(c.aired_count, 0), coalesce(c.watched_count, 0)
  from mine m
  join public.shows s on s.id = m.show_id
  left join counts c on c.show_id = m.show_id
  order by m.last_watched_at desc nulls last, m.added_at desc;
$$;

revoke execute on function public.get_user_show_progress(uuid) from public, anon;
grant execute on function public.get_user_show_progress(uuid) to authenticated;

-- Sıradaki: Durduruldu ve Dönülmez diziler çıkarılır; kart rengi için TMDB durumu ve elle seçilen
-- grup da döner. Dönüş tipi değiştiği için yeniden oluşturulur.
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
    select us.show_id, us.added_at, us.last_watched_at, us.manual_status
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
  select m.show_id, s.name, s.poster_path, m.added_at, m.last_watched_at,
         n.id, n.season_number, n.episode_number, n.name, n.still_path, s.backdrop_path,
         c.aired_count, c.watched_count, s.status, m.manual_status
  from mine m
  join public.shows s on s.id = m.show_id
  join next_episode n on n.show_id = m.show_id
  join counts c on c.show_id = m.show_id
  order by (m.last_watched_at is null) desc, m.last_watched_at desc, m.added_at desc;
$$;

revoke execute on function public.get_watchlist() from public, anon;
grant execute on function public.get_watchlist() to authenticated;
