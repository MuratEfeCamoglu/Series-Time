-- Aşama 2: TMDB önbellek tabloları (yalnızca tmdb-proxy yazar) ve user_shows (ISKELET.md §3.3, F3, F4).
-- shows.genre_ids ve genres tablosu Aşama 4'te (F18) eklenir.

-- `last_synced_at` yalnızca detay (`show` eylemi) senkronunda dolar. Arama/trend sonuçları
-- satırı özet alanlarla oluşturur; varsayılan now() olsaydı detayı hiç çekilmemiş bir dizi
-- önbellekte "taze" sayılırdı.
create table public.shows (
  id integer primary key,
  name text not null,
  original_name text,
  overview text not null default '',
  poster_path text,
  backdrop_path text,
  status text,
  first_air_date date,
  number_of_seasons integer,
  number_of_episodes integer,
  default_runtime integer,
  last_synced_at timestamptz
);

create table public.seasons (
  id integer primary key,
  show_id integer not null references public.shows on delete cascade,
  season_number integer not null,
  name text,
  poster_path text,
  air_date date,
  episode_count integer,
  last_synced_at timestamptz,
  unique (show_id, season_number)
);

create table public.episodes (
  id integer primary key,
  show_id integer not null references public.shows on delete cascade,
  season_number integer not null,
  episode_number integer not null,
  name text,
  overview text not null default '',
  air_date date,
  runtime integer,
  still_path text,
  unique (show_id, season_number, episode_number)
);

create table public.episode_credits (
  episode_id integer not null references public.episodes on delete cascade,
  person_id integer not null,
  name text not null,
  character text,
  profile_path text,
  "order" integer not null,
  last_synced_at timestamptz not null default now(),
  primary key (episode_id, person_id)
);

-- Herkese okuma; istemciye yazma politikası yok (yazma yalnızca service role ile).
alter table public.shows enable row level security;
alter table public.seasons enable row level security;
alter table public.episodes enable row level security;
alter table public.episode_credits enable row level security;

create policy "shows_select_all" on public.shows for select to anon, authenticated using (true);
create policy "seasons_select_all" on public.seasons for select to anon, authenticated using (true);
create policy "episodes_select_all" on public.episodes for select to anon, authenticated using (true);
create policy "episode_credits_select_all" on public.episode_credits for select to anon, authenticated using (true);

create table public.user_shows (
  user_id uuid not null references auth.users on delete cascade,
  show_id integer not null references public.shows on delete cascade,
  added_at timestamptz not null default now(),
  last_watched_at timestamptz,
  primary key (user_id, show_id)
);

-- tmdb-sync (Aşama 3) "en az bir kullanıcının listesindeki diziler"i bu kolonla bulur.
create index user_shows_show_id_idx on public.user_shows (show_id);

alter table public.user_shows enable row level security;

create policy "user_shows_select_authenticated"
  on public.user_shows for select
  to authenticated
  using (true);

create policy "user_shows_insert_own"
  on public.user_shows for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Güncelleme politikası yok: last_watched_at Aşama 3'te tetikleyiciyle güncellenir.
create policy "user_shows_delete_own"
  on public.user_shows for delete
  to authenticated
  using (auth.uid() = user_id);

-- profiles migration'ında bırakılan yabancı anahtar (kapak = listedeki bir dizinin arka planı, V9).
alter table public.profiles
  add constraint profiles_cover_show_id_fkey
  foreign key (cover_show_id) references public.shows on delete set null;
