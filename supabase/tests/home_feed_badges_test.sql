-- F14: 15 rozet, bölüm/dizi/bitirme/yorum eşikleri; F6(k): arkadaş akışı; F8(k): sahne görseli.
begin;
create extension if not exists pgtap with schema extensions;

select plan(10);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local', '{"username": "ayse_1"}'),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local', '{"username": "burak"}'),
  ('33333333-3333-3333-3333-333333333333', 'authenticated', 'authenticated', 'c@test.local', '{"username": "cem"}'),
  ('44444444-4444-4444-4444-444444444444', 'authenticated', 'authenticated', 'd@test.local', '{"username": "deniz"}');

select is((select count(*)::int from public.badges), 15, '15 rozet tanımlı');

-- 1: bitmiş dizi (2 bölüm + sezon 0 + gelecek bölüm), 2: 12 bölümlü yayını süren dizi
insert into public.shows (id, name, status) values (1, 'Bitti', 'Ended'), (2, 'Sürüyor', 'Returning Series');
insert into public.episodes (id, show_id, season_number, episode_number, air_date, still_path) values
  (11, 1, 1, 1, current_date - 10, '/s11.jpg'),
  (12, 1, 1, 2, current_date - 9, '/s12.jpg'),
  (10, 1, 0, 1, current_date - 20, null),
  (13, 1, 2, 1, current_date + 30, null);
insert into public.episodes (id, show_id, season_number, episode_number, air_date)
select 200 + n, 2, 1, n, current_date - 5 from generate_series(1, 12) n;
insert into public.user_shows (user_id, show_id) values
  ('11111111-1111-1111-1111-111111111111', 1),
  ('11111111-1111-1111-1111-111111111111', 2);

insert into public.watched_episodes (user_id, episode_id, show_id)
values ('11111111-1111-1111-1111-111111111111', 11, 1);
select ok(
  not exists (select 1 from public.user_badges where user_id = '11111111-1111-1111-1111-111111111111' and badge_code = 'first_finished'),
  'yarım kalan dizi bitirme rozeti vermez'
);
insert into public.watched_episodes (user_id, episode_id, show_id)
values ('11111111-1111-1111-1111-111111111111', 12, 1);
select ok(
  exists (select 1 from public.user_badges where user_id = '11111111-1111-1111-1111-111111111111' and badge_code = 'first_finished'),
  'bitmiş dizinin yayınlanmış tüm bölümleri izlenince Final Sahnesi (sezon 0 ve gelecek bölüm sayılmaz)'
);

insert into public.watched_episodes (user_id, episode_id, show_id)
select '11111111-1111-1111-1111-111111111111', 200 + n, 2 from generate_series(1, 8) n;
select ok(
  exists (select 1 from public.user_badges where user_id = '11111111-1111-1111-1111-111111111111' and badge_code = 'episodes_10'),
  '10 bölümde Isınma Turu'
);
select ok(
  not exists (select 1 from public.user_badges where user_id = '11111111-1111-1111-1111-111111111111' and badge_code = 'episodes_50'),
  '50 bölüm eşiği aşılmadan verilmez'
);

-- 25 dizi
insert into public.shows (id, name) select 1000 + n, 'D' || n from generate_series(1, 23) n;
insert into public.user_shows (user_id, show_id)
select '11111111-1111-1111-1111-111111111111', 1000 + n from generate_series(1, 23) n;
select ok(
  exists (select 1 from public.user_badges where user_id = '11111111-1111-1111-1111-111111111111' and badge_code = 'shows_25'),
  '25 dizide Arşivci'
);

-- Arkadaş akışı: 1, 2'yi ve 3'ü takip eder, 3'ü engeller; 4'ü takip etmez.
insert into public.follows (follower_id, followee_id) values
  ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222'),
  ('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333');
insert into public.blocks (blocker_id, blocked_id)
values ('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333');
insert into public.watched_episodes (user_id, episode_id, show_id, watched_at) values
  ('22222222-2222-2222-2222-222222222222', 11, 1, now() - interval '2 hours'),
  ('22222222-2222-2222-2222-222222222222', 12, 1, now() - interval '1 hour'),
  ('33333333-3333-3333-3333-333333333333', 11, 1, now()),
  ('44444444-4444-4444-4444-444444444444', 11, 1, now());
insert into public.episode_ratings (user_id, episode_id, rating)
values ('22222222-2222-2222-2222-222222222222', 12, 4.5);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
select is(
  (select count(*)::int from public.get_friends_activity()),
  1, 'yalnızca takip edilen ve engellenmemiş kişiler, kişi başına bir satır'
);
select is(
  (select episode_id || ' ' || username || ' ' || rating from public.get_friends_activity()),
  '12 burak 4.5', 'kişinin en son izlediği bölüm ve verdiği puan'
);
select is(
  (select still_path from public.get_recent_activity('11111111-1111-1111-1111-111111111111') where episode_id = 12),
  '/s12.jpg', 'son etkinlik bölümün sahne görselini döner'
);
select throws_ok(
  $$select public.is_show_finished('11111111-1111-1111-1111-111111111111', 1)$$,
  '42501', null, 'bitirme yardımcısı istemciden çağrılamaz'
);
reset role;

select * from finish();

rollback;
