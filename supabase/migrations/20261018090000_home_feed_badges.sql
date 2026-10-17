-- F8(k): son etkinlik bölüm sahne görseliyle; F6(k): "Arkadaşların ne izliyor" akışı;
-- F14: rozet sayısı 15'e çıkar (kullanıcı kararları 2026-10-18).

-- Dönüş tipine sahne görseli ve arka plan eklendiği için yeniden oluşturulur.
drop function public.get_recent_activity(uuid, integer);

create function public.get_recent_activity(user_id uuid, lim integer default 20)
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
  select w.episode_id, e.show_id, s.name, s.poster_path, s.backdrop_path, e.still_path,
         e.season_number, e.episode_number, e.name, w.watched_at
  from public.watched_episodes w
  join public.episodes e on e.id = w.episode_id
  join public.shows s on s.id = e.show_id
  where w.user_id = get_recent_activity.user_id
  order by w.watched_at desc, e.season_number desc, e.episode_number desc
  limit least(greatest(lim, 1), 50);
$$;
revoke execute on function public.get_recent_activity(uuid, integer) from public, anon;
grant execute on function public.get_recent_activity(uuid, integer) to authenticated;

-- Takip edilen her kişinin en son izlediği bölüm ve varsa verdiği puan; engellenenler hariç.
-- Yorum metni içermez (R7).
create function public.get_friends_activity(lim integer default 20)
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
      s.poster_path, e.still_path, e.season_number, e.episode_number, r.rating, w.watched_at
    from public.follows f
    join public.watched_episodes w on w.user_id = f.followee_id
    join public.profiles p on p.id = w.user_id
    join public.episodes e on e.id = w.episode_id
    join public.shows s on s.id = e.show_id
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
revoke execute on function public.get_friends_activity(integer) from public, anon;
grant execute on function public.get_friends_activity(integer) to authenticated;

insert into public.badges (code, name, description, icon) values
  ('episodes_10', 'Isınma Turu', '10 bölüm izle.', 'badge_episodes_10'),
  ('episodes_50', 'Alışkanlık', '50 bölüm izle.', 'badge_episodes_50'),
  ('episodes_500', 'Ekran Bağımlısı', '500 bölüm izle.', 'badge_episodes_500'),
  ('episodes_5000', 'Efsane İzleyici', '5.000 bölüm izle.', 'badge_episodes_5000'),
  ('shows_25', 'Arşivci', 'Listene 25 dizi ekle.', 'badge_shows_25'),
  ('shows_50', 'Kütüphaneci', 'Listene 50 dizi ekle.', 'badge_shows_50'),
  ('first_finished', 'Final Sahnesi', 'Bitmiş bir dizinin tüm bölümlerini izle.', 'badge_first_finished'),
  ('finished_5', 'Bitirici', 'Bitmiş 5 dizinin tüm bölümlerini izle.', 'badge_finished_5'),
  ('comments_10', 'Sohbetçi', '10 yorum yaz.', 'badge_comments_10'),
  ('comments_50', 'Eleştirmen', '50 yorum yaz.', 'badge_comments_50');

-- Bitmiş (Ended/Canceled) dizinin yayınlanmış tüm bölümleri izlendi mi (sezon 0 hariç).
create function public.is_show_finished(target_user uuid, target_show integer)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select s.status in ('Ended', 'Canceled') from public.shows s where s.id = target_show),
    false
  )
  and exists (
    select 1 from public.episodes e
    where e.show_id = target_show and e.season_number > 0 and e.air_date <= public.utc_today()
  )
  and not exists (
    select 1 from public.episodes e
    where e.show_id = target_show and e.season_number > 0 and e.air_date <= public.utc_today()
      and not exists (
        select 1 from public.watched_episodes w
        where w.user_id = target_user and w.episode_id = e.id
      )
  );
$$;
revoke execute on function public.is_show_finished(uuid, integer) from public, anon, authenticated;

create or replace function public.after_watched_episode_badges()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  watched integer;
begin
  select count(*) into watched from public.watched_episodes w where w.user_id = new.user_id;
  if watched >= 1 then perform public.award_badge(new.user_id, 'first_episode'); end if;
  if watched >= 10 then perform public.award_badge(new.user_id, 'episodes_10'); end if;
  if watched >= 50 then perform public.award_badge(new.user_id, 'episodes_50'); end if;
  if watched >= 100 then perform public.award_badge(new.user_id, 'episodes_100'); end if;
  if watched >= 500 then perform public.award_badge(new.user_id, 'episodes_500'); end if;
  if watched >= 1000 then perform public.award_badge(new.user_id, 'episodes_1000'); end if;
  if watched >= 5000 then perform public.award_badge(new.user_id, 'episodes_5000'); end if;
  -- Bitirme yalnızca bu bölüm diziyi tamamladıysa sayılır; böylece her işaretlemede tüm liste taranmaz.
  if public.is_show_finished(new.user_id, new.show_id) then
    perform public.award_badge(new.user_id, 'first_finished');
    if (
      select count(*) from public.user_shows us
      where us.user_id = new.user_id and public.is_show_finished(us.user_id, us.show_id)
    ) >= 5 then
      perform public.award_badge(new.user_id, 'finished_5');
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.after_user_show_badges()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  total integer;
begin
  select count(*) into total from public.user_shows us where us.user_id = new.user_id;
  if total >= 10 then perform public.award_badge(new.user_id, 'shows_10'); end if;
  if total >= 25 then perform public.award_badge(new.user_id, 'shows_25'); end if;
  if total >= 50 then perform public.award_badge(new.user_id, 'shows_50'); end if;
  return new;
end;
$$;

create or replace function public.after_comment_badges()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  total integer;
begin
  perform public.award_badge(new.user_id, 'first_comment');
  select count(*) into total from public.comments c where c.user_id = new.user_id;
  if total >= 10 then perform public.award_badge(new.user_id, 'comments_10'); end if;
  if total >= 50 then perform public.award_badge(new.user_id, 'comments_50'); end if;
  return new;
end;
$$;
