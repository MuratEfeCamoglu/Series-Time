-- F4(f): kişisel afiş yalnızca sahibinin listelerinde; F13(f): arkadaş akışı.
begin;
create extension if not exists pgtap with schema extensions;

select plan(9);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local', '{"username": "ayse_1"}'),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local', '{"username": "burak"}'),
  ('33333333-3333-3333-3333-333333333333', 'authenticated', 'authenticated', 'c@test.local', '{"username": "cem"}');

insert into public.shows (id, name, poster_path) values (1, 'Bir', '/tmdb.jpg');
insert into public.episodes (id, show_id, season_number, episode_number, air_date) values
  (11, 1, 1, 1, current_date - 3),
  (12, 1, 1, 2, current_date - 2),
  (13, 1, 1, 3, current_date + 2);
insert into public.user_shows (user_id, show_id) values
  ('11111111-1111-1111-1111-111111111111', 1),
  ('22222222-2222-2222-2222-222222222222', 1);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select throws_ok(
  $$update public.user_shows set poster_path = 'https://kotu.example/x.jpg'
    where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 1$$,
  '23514', null, 'afiş yalnızca TMDB yolu olabilir'
);
update public.user_shows set poster_path = '/secilen.jpg'
where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 1;
select is(
  (select poster_path from public.get_watchlist() where show_id = 1),
  '/secilen.jpg', 'Sıradaki seçilen afişi döner'
);
select is(
  (select poster_path from public.get_upcoming(90) where episode_id = 13),
  '/secilen.jpg', 'Yaklaşan seçilen afişi döner'
);
select is(
  (select poster_path from public.get_user_show_progress('22222222-2222-2222-2222-222222222222') where show_id = 1),
  '/tmdb.jpg', 'başkasının listesi kendi seçimini (yoksa TMDB afişini) gösterir'
);

update public.user_shows set poster_path = '/baskasi.jpg'
where user_id = '22222222-2222-2222-2222-222222222222' and show_id = 1;
reset role;
select is(
  (select poster_path from public.user_shows where user_id = '22222222-2222-2222-2222-222222222222' and show_id = 1),
  null, 'başkasının afişini değiştiremez'
);

-- Arkadaş akışı: 1, 2'yi ve 3'ü takip eder; 3 engelli. 2 kendi afişini seçmiştir.
update public.user_shows set poster_path = '/baskasi.jpg'
where user_id = '22222222-2222-2222-2222-222222222222' and show_id = 1;
insert into public.follows (follower_id, followee_id) values
  ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222'),
  ('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333');
insert into public.blocks (blocker_id, blocked_id)
values ('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333');
insert into public.watched_episodes (user_id, episode_id, show_id, watched_at) values
  ('22222222-2222-2222-2222-222222222222', 11, 1, (date_trunc('day', now() at time zone 'utc') + interval '1 minute') at time zone 'utc'),
  ('22222222-2222-2222-2222-222222222222', 12, 1, (date_trunc('day', now() at time zone 'utc') + interval '2 minutes') at time zone 'utc'),
  ('33333333-3333-3333-3333-333333333333', 11, 1, now());
insert into public.episode_ratings (user_id, episode_id, rating, created_at)
values ('22222222-2222-2222-2222-222222222222', 12, 4.0, now() - interval '30 minutes');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
select ok(
  not exists (select 1 from public.get_friends_feed() where username = 'cem'),
  'engellenen kişinin etkinliği görünmez'
);
select is(
  (select episode_count || ' ' || episode_id || ' ' || poster_path
   from public.get_friends_feed() where kind = 'watched'),
  '2 12 /baskasi.jpg', 'aynı gün aynı dizi tek satır: bölüm sayısı, son bölüm, arkadaşın afişi'
);
select is(
  (select rating from public.get_friends_feed() where kind = 'rated'),
  4.0, 'puan olayı'
);
select ok(
  exists (select 1 from public.get_friends_feed() where kind = 'badge' and badge_code = 'first_episode'),
  'arkadaşın kazandığı rozet akışta görünür'
);
reset role;

select * from finish();

rollback;
