-- Aşama 3: izlenen bölümler, işaretleme RPC'leri, İzleme Listesi ve Yaklaşan (ISKELET.md §3.2–3.4, F5–F7).

create table public.watched_episodes (
  user_id uuid not null references auth.users on delete cascade,
  episode_id integer not null references public.episodes on delete cascade,
  -- Sorgu hızı için; değeri tetikleyici bölümden alır, istemcinin gönderdiğine güvenilmez.
  show_id integer not null references public.shows on delete cascade,
  watched_at timestamptz not null default now(),
  primary key (user_id, episode_id)
);

create index watched_episodes_user_show_idx on public.watched_episodes (user_id, show_id);

alter table public.watched_episodes enable row level security;

create policy "watched_episodes_select_authenticated"
  on public.watched_episodes for select
  to authenticated
  using (true);

create policy "watched_episodes_insert_own"
  on public.watched_episodes for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "watched_episodes_delete_own"
  on public.watched_episodes for delete
  to authenticated
  using (auth.uid() = user_id);

-- Bugünün tarihi (UTC); "yayınlanmış bölüm" kuralı bu tarihle karşılaştırır.
create function public.utc_today()
returns date
language sql
stable
set search_path = ''
as $$
  select (now() at time zone 'utc')::date;
$$;

-- F5(d): yayın tarihi gelecekte (veya belirsiz) olan bölüm işaretlenemez.
create function public.before_watched_episode_insert()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  episode_air_date date;
begin
  select e.show_id, e.air_date into new.show_id, episode_air_date
  from public.episodes e
  where e.id = new.episode_id;

  if episode_air_date is null or episode_air_date > public.utc_today() then
    raise exception 'episode_not_aired' using errcode = 'P0001', hint = 'F5d';
  end if;
  return new;
end;
$$;

create trigger watched_episodes_before_insert
  before insert on public.watched_episodes
  for each row execute function public.before_watched_episode_insert();

-- Listede olmayan bir dizinin bölümü işaretlenince dizi listeye girer; son izleme tarihi
-- İzleme Listesi sıralaması (F6g) ve 30 gün ayrımı (F6e) için güncel tutulur.
-- user_shows istemciye güncelleme izni vermediği için security definer.
create function public.after_watched_episodes_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.user_shows (user_id, show_id, last_watched_at)
    values (new.user_id, new.show_id, new.watched_at)
    on conflict (user_id, show_id) do update
      set last_watched_at = greatest(public.user_shows.last_watched_at, excluded.last_watched_at);
    return new;
  end if;

  update public.user_shows us
  set last_watched_at = (
    select max(w.watched_at) from public.watched_episodes w
    where w.user_id = old.user_id and w.show_id = old.show_id
  )
  where us.user_id = old.user_id and us.show_id = old.show_id;
  return old;
end;
$$;

create trigger watched_episodes_after_insert
  after insert on public.watched_episodes
  for each row execute function public.after_watched_episodes_change();

create trigger watched_episodes_after_delete
  after delete on public.watched_episodes
  for each row execute function public.after_watched_episodes_change();

-- F4(c): dizi listeden çıkarılınca o diziye ait izleme kayıtları da silinir.
create function public.after_user_show_delete()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.watched_episodes w
  where w.user_id = old.user_id and w.show_id = old.show_id;
  return old;
end;
$$;

create trigger user_shows_after_delete
  after delete on public.user_shows
  for each row execute function public.after_user_show_delete();

-- F5(c) "Buraya kadar izledim": seçilen bölüm ve aynı dizinin önceki tüm yayınlanmış
-- bölümleri. Özel bölüm (sezon 0) seçilirse yalnızca kendisi. Dönen: yeni işaretlenen sayısı.
create function public.mark_episodes_until(episode_id integer)
returns integer
language sql
security invoker
set search_path = ''
as $$
  with target as (
    select e.show_id, e.season_number, e.episode_number
    from public.episodes e
    where e.id = mark_episodes_until.episode_id
  ),
  inserted as (
    insert into public.watched_episodes (user_id, episode_id, show_id)
    select auth.uid(), e.id, e.show_id
    from public.episodes e, target t
    where e.show_id = t.show_id
      and e.air_date <= public.utc_today()
      and (
        e.id = mark_episodes_until.episode_id
        or (
          t.season_number > 0 and e.season_number > 0
          and (e.season_number, e.episode_number) <= (t.season_number, t.episode_number)
        )
      )
    on conflict do nothing
    returning 1
  )
  select count(*)::integer from inserted;
$$;

-- F5(b) "Sezonun tamamını izledim": sezonun yayınlanmış bölümleri.
create function public.mark_season(show_id integer, season_number integer)
returns integer
language sql
security invoker
set search_path = ''
as $$
  with inserted as (
    insert into public.watched_episodes (user_id, episode_id, show_id)
    select auth.uid(), e.id, e.show_id
    from public.episodes e
    where e.show_id = mark_season.show_id
      and e.season_number = mark_season.season_number
      and e.air_date <= public.utc_today()
    on conflict do nothing
    returning 1
  )
  select count(*)::integer from inserted;
$$;

-- F6: sıradaki bölümü olan diziler, ilerleme sayıları ile (sezon 0 hariç). 30 gün ayrımı
-- istemcide (tracking/logic.dart) yapılır.
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
    select e.id, e.show_id, e.season_number, e.episode_number, (w.episode_id is not null) as watched
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
    select distinct on (a.show_id) a.show_id, a.id, a.season_number, a.episode_number
    from aired a
    where not a.watched
    order by a.show_id, a.season_number, a.episode_number
  )
  select m.show_id, s.name, s.poster_path, m.added_at, m.last_watched_at,
         n.id, n.season_number, n.episode_number, c.aired_count, c.watched_count
  from mine m
  join public.shows s on s.id = m.show_id
  join next_episode n on n.show_id = m.show_id
  join counts c on c.show_id = m.show_id
  -- F6(g): hiç izlenmemişler en üstte (eklenme tarihine göre), sonra son izleme azalan.
  order by (m.last_watched_at is null) desc, m.last_watched_at desc, m.added_at desc;
$$;

-- F7: listedeki dizilerin bugünden itibaren [days] gün içinde yayınlanacak bölümleri.
create function public.get_upcoming(days integer default 90)
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
  select e.id, e.show_id, s.name, s.poster_path, e.season_number, e.episode_number, e.name, e.air_date
  from public.user_shows us
  join public.shows s on s.id = us.show_id
  join public.episodes e on e.show_id = us.show_id
  where us.user_id = auth.uid()
    and e.season_number > 0
    and e.air_date between public.utc_today() and public.utc_today() + get_upcoming.days
  order by e.air_date, s.name, e.season_number, e.episode_number;
$$;

revoke execute on function public.mark_episodes_until(integer) from public, anon;
revoke execute on function public.mark_season(integer, integer) from public, anon;
revoke execute on function public.get_watchlist() from public, anon;
revoke execute on function public.get_upcoming(integer) from public, anon;
grant execute on function public.mark_episodes_until(integer) to authenticated;
grant execute on function public.mark_season(integer, integer) to authenticated;
grant execute on function public.get_watchlist() to authenticated;
grant execute on function public.get_upcoming(integer) to authenticated;
