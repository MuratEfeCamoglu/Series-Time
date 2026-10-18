-- F14 genişlemesi (kullanıcı kararları 2026-10-18):
-- (a) Diziye özel rozetler: her sezon bitince sezon rozeti, bitmiş dizinin tüm bölümleri
--     izlenince dizi rozeti; simgesi dizinin/sezonun afişi (istemci çizer).
-- (b) Tür rozetleri: 16 TMDB türü × 3 kademe (bitmiş 1, 5, 10 dizi) = 48 yeni genel rozet.
-- (c) Rozet vitrini: kullanıcı kazandığı rozetlerden en fazla 6'sını profilinde gösterir.

-- (a) season_number 0 = dizinin tamamı. Sezon 0 (özel bölümler) hiçbir zaman rozet vermez,
-- bu yüzden 0 değeri çakışmaz.
create table public.show_badges (
  user_id uuid not null references auth.users on delete cascade,
  show_id integer not null references public.shows on delete cascade,
  season_number integer not null check (season_number >= 0),
  earned_at timestamptz not null default now(),
  primary key (user_id, show_id, season_number)
);
create index show_badges_user_earned_idx on public.show_badges (user_id, earned_at desc);

alter table public.show_badges enable row level security;
-- Rozetler herkese açık profillerde görünür (V10); yalnızca tetikleyiciler yazar.
create policy "show_badges_select_authenticated" on public.show_badges
  for select to authenticated using (true);

-- (c) Vitrin: her satır ya genel rozet (badge_code) ya dizi/sezon rozetidir. Yabancı anahtarlar
-- yalnızca kazanılmış rozetin seçilebilmesini sağlar; rozet silinirse vitrinden de düşer.
create table public.featured_badges (
  user_id uuid not null references auth.users on delete cascade,
  position smallint not null check (position between 1 and 6),
  badge_code text,
  show_id integer,
  season_number integer,
  primary key (user_id, position),
  constraint featured_badges_one_kind check ((badge_code is null) <> (show_id is null)),
  constraint featured_badges_show_season check ((show_id is null) = (season_number is null)),
  unique (user_id, badge_code),
  unique (user_id, show_id, season_number),
  foreign key (user_id, badge_code)
    references public.user_badges (user_id, badge_code) on delete cascade,
  foreign key (user_id, show_id, season_number)
    references public.show_badges (user_id, show_id, season_number) on delete cascade
);

alter table public.featured_badges enable row level security;
create policy "featured_badges_select_authenticated" on public.featured_badges
  for select to authenticated using (true);
create policy "featured_badges_insert_own" on public.featured_badges
  for insert to authenticated with check (auth.uid() = user_id);
create policy "featured_badges_update_own" on public.featured_badges
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "featured_badges_delete_own" on public.featured_badges
  for delete to authenticated using (auth.uid() = user_id);
-- F19: misafir yazamaz.
create policy "featured_badges_registered_insert" on public.featured_badges
  as restrictive for insert to authenticated with check (public.is_registered_user());
create policy "featured_badges_registered_update" on public.featured_badges
  as restrictive for update to authenticated using (public.is_registered_user());
create policy "featured_badges_registered_delete" on public.featured_badges
  as restrictive for delete to authenticated using (public.is_registered_user());

-- (b) Tür rozetleri. `icon` = 'genre': istemci türe uygun simgeyi kademe rengiyle çizer.
insert into public.badges (code, name, description, icon)
select 'genre_' || g.id || '_' || t.n,
       g.name || ' ' || t.title,
       g.name || ' türünde bitmiş ' || t.n || ' dizinin tüm bölümlerini izle.',
       'genre'
from (values
  (10759, 'Aksiyon & Macera'), (16, 'Animasyon'), (35, 'Komedi'), (80, 'Suç'),
  (99, 'Belgesel'), (18, 'Dram'), (10751, 'Aile'), (10762, 'Çocuk'), (9648, 'Gizem'),
  (10763, 'Haber'), (10764, 'Gerçeklik'), (10765, 'Bilim Kurgu & Fantastik'),
  (10766, 'Pembe Dizi'), (10767, 'Talk Show'), (10768, 'Savaş & Politika'), (37, 'Western')
) as g(id, name)
cross join (values (1, 'Meraklısı'), (5, 'Tutkunu'), (10, 'Ustası')) as t(n, title);

-- Sezonun yayınlanmış tüm bölümleri izlendi mi. Sezon tamamen yayınlanmış olmalı (tarihsiz veya
-- gelecek bölüm yok) ve önbellekteki bölüm sayısı TMDB'nin sezon bölüm sayısına ulaşmış olmalı;
-- yoksa yarım çekilmiş bir sezon "bitti" sayılırdı.
create function public.is_season_finished(target_user uuid, target_show integer, season integer)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select season > 0
  and exists (
    select 1 from public.episodes e
    where e.show_id = target_show and e.season_number = season
  )
  and not exists (
    select 1 from public.episodes e
    where e.show_id = target_show and e.season_number = season
      and (e.air_date is null or e.air_date > public.utc_today())
  )
  and (
    select count(*) from public.episodes e
    where e.show_id = target_show and e.season_number = season
  ) >= coalesce(
    (select se.episode_count from public.seasons se
     where se.show_id = target_show and se.season_number = season),
    0
  )
  and not exists (
    select 1 from public.episodes e
    where e.show_id = target_show and e.season_number = season
      and not exists (
        select 1 from public.watched_episodes w
        where w.user_id = target_user and w.episode_id = e.id
      )
  );
$$;
revoke execute on function public.is_season_finished(uuid, integer, integer) from public, anon, authenticated;

-- Bildirimin entity_id'si 'show:<dizi>:<sezon>' (0 = dizinin tamamı); istemci dizi adıyla yazar.
create function public.award_show_badge(target_user uuid, target_show integer, season integer)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.show_badges (user_id, show_id, season_number)
  values (target_user, target_show, season)
  on conflict do nothing;
  if found then
    insert into public.notifications (user_id, type, entity_id)
    values (target_user, 'badge_earned', 'show:' || target_show || ':' || season);
  end if;
end;
$$;
revoke execute on function public.award_show_badge(uuid, integer, integer) from public, anon, authenticated;

-- Bitirilen dizinin her türü için o türde bitirilmiş dizi sayısına göre kademe rozetleri.
create function public.award_genre_badges(target_user uuid, target_show integer)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  g integer;
  total integer;
  tier integer;
begin
  for g in select unnest(s.genre_ids) from public.shows s where s.id = target_show loop
    select count(*) into total
    from public.user_shows us
    join public.shows s2 on s2.id = us.show_id
    where us.user_id = target_user
      and s2.genre_ids @> array[g]
      and public.is_show_finished(target_user, us.show_id);
    foreach tier in array array[1, 5, 10] loop
      if total >= tier
         and exists (select 1 from public.badges b where b.code = 'genre_' || g || '_' || tier) then
        perform public.award_badge(target_user, 'genre_' || g || '_' || tier);
      end if;
    end loop;
  end loop;
end;
$$;
revoke execute on function public.award_genre_badges(uuid, integer) from public, anon, authenticated;

create function public.after_watched_episode_show_badges()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  season integer;
begin
  select e.season_number into season from public.episodes e where e.id = new.episode_id;
  if public.is_season_finished(new.user_id, new.show_id, season) then
    perform public.award_show_badge(new.user_id, new.show_id, season);
  end if;
  if public.is_show_finished(new.user_id, new.show_id) then
    perform public.award_show_badge(new.user_id, new.show_id, 0);
    perform public.award_genre_badges(new.user_id, new.show_id);
  end if;
  return new;
end;
$$;

create trigger watched_episodes_show_badges
  after insert on public.watched_episodes
  for each row execute function public.after_watched_episode_show_badges();

-- Geriye dönük: şimdiye kadar bitirilenler sessizce (bildirimsiz) verilir.
insert into public.show_badges (user_id, show_id, season_number)
select distinct w.user_id, e.show_id, e.season_number
from public.watched_episodes w
join public.episodes e on e.id = w.episode_id
where e.season_number > 0
  and public.is_season_finished(w.user_id, e.show_id, e.season_number)
on conflict do nothing;

insert into public.show_badges (user_id, show_id, season_number)
select us.user_id, us.show_id, 0
from public.user_shows us
where public.is_show_finished(us.user_id, us.show_id)
on conflict do nothing;

with finished as (
  select us.user_id, g
  from public.user_shows us
  join public.shows s on s.id = us.show_id
  cross join lateral unnest(s.genre_ids) as g
  where public.is_show_finished(us.user_id, us.show_id)
),
counts as (
  select f.user_id, f.g, count(*) as total from finished f group by f.user_id, f.g
)
insert into public.user_badges (user_id, badge_code)
select c.user_id, b.code
from counts c
cross join (values (1), (5), (10)) as t(n)
join public.badges b on b.code = 'genre_' || c.g || '_' || t.n
where c.total >= t.n
on conflict do nothing;

-- Dizi ve sezon rozetleri, en yeni önce. Sezon rozetinin görseli sezon afişi (yoksa dizinin).
create function public.get_show_badges(user_id uuid)
returns table (
  show_id integer,
  season_number integer,
  show_name text,
  poster_path text,
  earned_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select sb.show_id, sb.season_number, s.name,
         coalesce(case when sb.season_number > 0 then se.poster_path end, s.poster_path),
         sb.earned_at
  from public.show_badges sb
  join public.shows s on s.id = sb.show_id
  left join public.seasons se on se.show_id = sb.show_id and se.season_number = sb.season_number
  where sb.user_id = get_show_badges.user_id
  order by sb.earned_at desc, sb.show_id, sb.season_number desc;
$$;

-- Vitrin sırasıyla; dizi rozetleri için ad ve görsel eklenir.
create function public.get_featured_badges(user_id uuid)
returns table (
  "position" smallint,
  badge_code text,
  show_id integer,
  season_number integer,
  show_name text,
  poster_path text
)
language sql
stable
security invoker
set search_path = ''
as $$
  select f.position, f.badge_code, f.show_id, f.season_number, s.name,
         coalesce(case when f.season_number > 0 then se.poster_path end, s.poster_path)
  from public.featured_badges f
  left join public.shows s on s.id = f.show_id
  left join public.seasons se on se.show_id = f.show_id and se.season_number = f.season_number
  where f.user_id = get_featured_badges.user_id
  order by f.position;
$$;

-- Vitrini tek seferde ve atomik değiştirir; dizideki sıra vitrin sırasıdır. Öğe:
-- {"badge_code": "..."} veya {"show_id": 1, "season_number": 0}. RLS sahibini ve misafiri denetler.
create function public.set_featured_badges(items jsonb)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if jsonb_array_length(items) > 6 then
    raise exception 'too_many_featured_badges' using errcode = '22023';
  end if;
  delete from public.featured_badges where user_id = auth.uid();
  insert into public.featured_badges (user_id, position, badge_code, show_id, season_number)
  select auth.uid(), t.ord::smallint, t.item ->> 'badge_code',
         (t.item ->> 'show_id')::integer, (t.item ->> 'season_number')::integer
  from jsonb_array_elements(items) with ordinality as t(item, ord);
end;
$$;

-- Profildeki rozet sayısı dizi/sezon rozetlerini de sayar.
create or replace function public.get_profile_counts(user_id uuid)
returns table (followers integer, following integer, badges integer)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    (select count(*)::integer from public.follows f where f.followee_id = get_profile_counts.user_id),
    (select count(*)::integer from public.follows f where f.follower_id = get_profile_counts.user_id),
    (select count(*)::integer from public.user_badges b where b.user_id = get_profile_counts.user_id)
      + (select count(*)::integer from public.show_badges b where b.user_id = get_profile_counts.user_id);
$$;

-- Dizi rozeti bildirimi dizi adıyla yazılır; dönüş tipi değiştiği için yeniden kurulur.
drop function public.get_notifications();
create function public.get_notifications()
returns table (
  id uuid,
  type public.notification_type,
  actor_id uuid,
  actor_username text,
  actor_display_name text,
  actor_avatar_path text,
  entity_id text,
  badge_name text,
  episode_id integer,
  read_at timestamptz,
  created_at timestamptz,
  show_name text
)
language sql
stable
security invoker
set search_path = ''
as $$
  select n.id, n.type, n.actor_id, p.username, p.display_name, p.avatar_path, n.entity_id,
         b.name, c.episode_id, n.read_at, n.created_at, s.name
  from public.notifications n
  left join public.profiles p on p.id = n.actor_id
  left join public.badges b on n.type = 'badge_earned' and b.code = n.entity_id
  left join public.comments c on n.type = 'comment_liked' and c.id::text = n.entity_id
  left join public.shows s
    on n.type = 'badge_earned' and n.entity_id like 'show:%'
   -- Metin karşılaştırması: diğer rozet kodlarında tamsayıya çevirme hatası olmasın.
   and s.id::text = split_part(n.entity_id, ':', 2)
  where n.user_id = auth.uid()
    and n.created_at > now() - interval '90 days'
  order by n.created_at desc
  limit 200;
$$;

revoke execute on function public.get_show_badges(uuid) from public, anon;
revoke execute on function public.get_featured_badges(uuid) from public, anon;
revoke execute on function public.set_featured_badges(jsonb) from public, anon;
revoke execute on function public.get_notifications() from public, anon;
grant execute on function public.get_show_badges(uuid) to authenticated;
grant execute on function public.get_featured_badges(uuid) to authenticated;
grant execute on function public.set_featured_badges(jsonb) to authenticated;
grant execute on function public.get_notifications() to authenticated;
