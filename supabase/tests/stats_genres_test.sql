-- Aşama 4: genres RLS, get_user_stats, get_top_genres.
begin;
create extension if not exists pgtap with schema extensions;

select plan(9);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local',
   '{"username": "ayse_1"}'),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local',
   '{"username": "burak"}');

insert into public.genres (id, name) values (18, 'Dram'), (35, 'Komedi'), (80, 'Suç');
insert into public.shows (id, name, default_runtime, genre_ids) values
  (1, 'Bir', 50, '{18,80}'),
  (2, 'İki', null, '{18,35}'),
  (3, 'Üç', null, '{35}');
insert into public.episodes (id, show_id, season_number, episode_number, air_date, runtime) values
  (11, 1, 1, 1, current_date - 3, 60),   -- kendi süresi
  (12, 1, 1, 2, current_date - 2, null), -- dizinin varsayılanı: 50
  (21, 2, 1, 1, current_date - 1, null), -- ikisi de yok: 45
  (10, 1, 0, 1, current_date - 9, 30);   -- sezon 0: sayılmaz
insert into public.user_shows (user_id, show_id) values
  ('11111111-1111-1111-1111-111111111111', 1),
  ('11111111-1111-1111-1111-111111111111', 2),
  ('22222222-2222-2222-2222-222222222222', 3);

select is(
  (select genre_ids from public.shows where id = 1),
  '{18,80}'::integer[],
  'shows.genre_ids türleri saklar'
);

insert into public.shows (id, name) values (4, 'Dört');
select is((select genre_ids from public.shows where id = 4), '{}'::integer[], 'genre_ids varsayılanı boş dizi');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select is(
  (select watched_episodes || '/' || watch_minutes from public.get_user_stats('11111111-1111-1111-1111-111111111111')),
  '0/0',
  'hiç izleme yoksa 0 bölüm, 0 dakika'
);

insert into public.watched_episodes (user_id, episode_id, show_id) values
  ('11111111-1111-1111-1111-111111111111', 11, 1),
  ('11111111-1111-1111-1111-111111111111', 12, 1),
  ('11111111-1111-1111-1111-111111111111', 21, 2),
  ('11111111-1111-1111-1111-111111111111', 10, 1);

select is(
  (select watched_episodes || '/' || watch_minutes from public.get_user_stats('11111111-1111-1111-1111-111111111111')),
  '3/155',
  'süre: bölüm süresi → dizi varsayılanı → 45 dk; sezon 0 hariç (F8d)'
);

select is(
  (select watched_episodes from public.get_user_stats('22222222-2222-2222-2222-222222222222')),
  0,
  'başka kullanıcının istatistiği okunabilir (V10)'
);

select is(
  (select array_agg(g) from public.get_top_genres() g),
  array[18, 35, 80],
  'en sık tür önce; eşitlikte küçük kimlik (F18c)'
);

select is(
  (select array_agg(g) from public.get_top_genres(1) g),
  array[18],
  'lim sonuç sayısını sınırlar'
);

select throws_ok(
  $$insert into public.genres (id, name) values (99, 'Sahte')$$,
  '42501', null, 'istemci genres tablosuna yazamaz'
);

reset role;

set local role anon;
select is((select count(*)::int from public.genres), 3, 'anonim kullanıcı türleri okur');
reset role;

select * from finish();

rollback;
