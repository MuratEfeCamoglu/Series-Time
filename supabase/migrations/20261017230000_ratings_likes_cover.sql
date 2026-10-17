-- F20 bölüm puanı (5 üzerinden, buçuklu) ve bölüm beğenisi; F2 kapak için seçilen arka plan
-- görselinin yolu (kullanıcı kararları 2026-10-17).

create table public.episode_ratings (
  user_id uuid not null references auth.users on delete cascade,
  episode_id integer not null references public.episodes on delete cascade,
  rating numeric(2, 1) not null
    constraint episode_ratings_half_steps check (rating between 0.5 and 5 and rating * 2 = floor(rating * 2)),
  created_at timestamptz not null default now(),
  primary key (user_id, episode_id)
);

create table public.episode_likes (
  user_id uuid not null references auth.users on delete cascade,
  episode_id integer not null references public.episodes on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, episode_id)
);

create index episode_ratings_episode_idx on public.episode_ratings (episode_id);
create index episode_likes_episode_idx on public.episode_likes (episode_id);

alter table public.episode_ratings enable row level security;
alter table public.episode_likes enable row level security;

create policy "episode_ratings_select_authenticated" on public.episode_ratings for select to authenticated using (true);
create policy "episode_ratings_insert_own" on public.episode_ratings for insert to authenticated with check (auth.uid() = user_id);
create policy "episode_ratings_update_own" on public.episode_ratings for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "episode_ratings_delete_own" on public.episode_ratings for delete to authenticated using (auth.uid() = user_id);

create policy "episode_likes_select_authenticated" on public.episode_likes for select to authenticated using (true);
create policy "episode_likes_insert_own" on public.episode_likes for insert to authenticated with check (auth.uid() = user_id);
create policy "episode_likes_delete_own" on public.episode_likes for delete to authenticated using (auth.uid() = user_id);

-- F19: misafir puan veremez, beğenemez (diğer kullanıcı tablolarıyla aynı kısıtlayıcı kural).
do $$
declare
  t text;
begin
  foreach t in array array['episode_ratings', 'episode_likes'] loop
    execute format(
      'create policy %I on public.%I as restrictive for insert to authenticated with check (public.is_registered_user())',
      t || '_registered_insert', t);
    execute format(
      'create policy %I on public.%I as restrictive for update to authenticated using (public.is_registered_user())',
      t || '_registered_update', t);
    execute format(
      'create policy %I on public.%I as restrictive for delete to authenticated using (public.is_registered_user())',
      t || '_registered_delete', t);
  end loop;
end;
$$;

-- F20: ortalama puan, puan sayısı ve beğeni sayısı.
create function public.get_episode_rating_stats(episode_id integer)
returns table (average numeric, rating_count integer, like_count integer)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    (select round(avg(r.rating), 1) from public.episode_ratings r where r.episode_id = get_episode_rating_stats.episode_id),
    (select count(*)::integer from public.episode_ratings r where r.episode_id = get_episode_rating_stats.episode_id),
    (select count(*)::integer from public.episode_likes l where l.episode_id = get_episode_rating_stats.episode_id);
$$;

revoke execute on function public.get_episode_rating_stats(integer) from public, anon;
grant execute on function public.get_episode_rating_stats(integer) to authenticated;

-- F2: kapak, seçilen dizinin herhangi bir TMDB arka plan görseli olabilir (yalnızca yol).
alter table public.profiles
  add column cover_path text
    constraint profiles_cover_path_format check (cover_path ~ '^/[A-Za-z0-9_.-]+$');

-- F2: avatar TMDB oyuncu/karakter fotoğrafı da olabilir; `avatar_path` o zaman "tmdb:" önekli
-- TMDB yoludur (yüklenen dosyalar `<uid>/...` biçiminde kalır).
alter table public.profiles
  add constraint profiles_avatar_path_format
    check (avatar_path is null or avatar_path ~ '^tmdb:/[A-Za-z0-9_.-]+$' or avatar_path !~ '^tmdb:');
