-- F14 genişlemesi: sezon/dizi rozetleri, tür rozetleri ve 6'lık vitrin.
begin;
create extension if not exists pgtap with schema extensions;

select plan(13);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local', '{"username": "ayse_1"}'),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local', '{"username": "burak"}');

select is((select count(*)::int from public.badges where code like 'genre_%'), 48, '48 tür rozeti');

-- Bitmiş dram dizisi: 2 sezon × 1 bölüm.
insert into public.shows (id, name, status, genre_ids, poster_path)
values (1, 'Bir', 'Ended', '{18}', '/dizi.jpg');
insert into public.seasons (id, show_id, season_number, episode_count, poster_path) values
  (101, 1, 1, 1, '/s1.jpg'), (102, 1, 2, 1, null);
insert into public.episodes (id, show_id, season_number, episode_number, air_date) values
  (11, 1, 1, 1, current_date - 30),
  (21, 1, 2, 1, current_date - 10);
insert into public.user_shows (user_id, show_id) values ('11111111-1111-1111-1111-111111111111', 1);

insert into public.watched_episodes (user_id, episode_id, show_id)
values ('11111111-1111-1111-1111-111111111111', 11, 1);
select ok(
  exists (select 1 from public.show_badges where show_id = 1 and season_number = 1),
  'sezon bitince sezon rozeti'
);
select ok(
  not exists (select 1 from public.show_badges where show_id = 1 and season_number = 0),
  'dizi bitmeden dizi rozeti yok'
);

insert into public.watched_episodes (user_id, episode_id, show_id)
values ('11111111-1111-1111-1111-111111111111', 21, 1);
select ok(
  exists (select 1 from public.show_badges where show_id = 1 and season_number = 0),
  'bitmiş dizinin tüm bölümleri izlenince dizi rozeti'
);
select ok(
  exists (select 1 from public.user_badges where badge_code = 'genre_18_1'),
  'Dram Meraklısı tür rozeti'
);
select ok(
  exists (select 1 from public.notifications where entity_id = 'show:1:0'),
  'dizi rozeti bildirimi'
);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
select is(
  (select show_name from public.get_notifications() where entity_id = 'show:1:0'),
  'Bir', 'bildirim dizi adıyla'
);
select is(
  (select string_agg(season_number || poster_path, ',' order by season_number)
   from public.get_show_badges('11111111-1111-1111-1111-111111111111')),
  '0/dizi.jpg,1/s1.jpg,2/dizi.jpg', 'sezon afişi, yoksa dizinin afişi'
);

select public.set_featured_badges(
  '[{"show_id": 1, "season_number": 0}, {"badge_code": "genre_18_1"}]'::jsonb
);
select is(
  (select string_agg(coalesce(badge_code, show_id || ':' || season_number), ',' order by position)
   from public.get_featured_badges('11111111-1111-1111-1111-111111111111')),
  '1:0,genre_18_1', 'vitrin sırası korunur'
);
select throws_ok(
  $$select public.set_featured_badges('[{"badge_code": "episodes_5000"}]'::jsonb)$$,
  '23503', null, 'kazanılmamış rozet vitrine konamaz'
);
select throws_ok(
  $$select public.set_featured_badges(
    '[{"badge_code":"a"},{"badge_code":"b"},{"badge_code":"c"},{"badge_code":"d"},{"badge_code":"e"},{"badge_code":"f"},{"badge_code":"g"}]'::jsonb)$$,
  '22023', null, 'en fazla 6 rozet'
);

-- Başkasının vitrinine yazılamaz.
select set_config('request.jwt.claims', '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);
delete from public.featured_badges where user_id = '11111111-1111-1111-1111-111111111111';
select is(
  (select count(*)::int from public.featured_badges where user_id = '11111111-1111-1111-1111-111111111111'),
  2, 'başkasının vitrini silinemez'
);
select throws_ok(
  $$insert into public.show_badges (user_id, show_id, season_number)
    values ('22222222-2222-2222-2222-222222222222', 1, 0)$$,
  '42501', null, 'istemci rozet veremez'
);
reset role;

select * from finish();

rollback;
