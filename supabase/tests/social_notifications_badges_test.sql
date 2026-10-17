-- Aşama 6: takip, engelleme etkisi, bildirim ve rozet tetikleyicileri.
begin;
create extension if not exists pgtap with schema extensions;

select plan(25);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local',
   '{"username": "ayse_1"}'),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local',
   '{"username": "burak"}'),
  ('33333333-3333-3333-3333-333333333333', 'authenticated', 'authenticated', 'c@test.local',
   '{"username": "cem"}');

insert into public.shows (id, name) select g, 'Dizi ' || g from generate_series(1, 10) g;
insert into public.episodes (id, show_id, season_number, episode_number, air_date)
select 1000 + g, 1, 1, g, current_date - 1 from generate_series(1, 100) g;

select is(
  (select bool_and(relrowsecurity) from pg_class where oid in (
    'public.follows'::regclass, 'public.badges'::regclass,
    'public.user_badges'::regclass, 'public.notifications'::regclass)),
  true, 'Aşama 6 tablolarında RLS açık'
);
select is((select count(*)::int from public.badges), 5, '5 rozet tanımlı (F14)');

-- Kullanıcı A
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select throws_ok(
  $$insert into public.follows (follower_id, followee_id) values ('11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111')$$,
  '23514', null, 'kişi kendini takip edemez (F12d)'
);
select throws_ok(
  $$insert into public.follows (follower_id, followee_id) values ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333')$$,
  '42501', null, 'başkası adına takip edilemez'
);
insert into public.follows (follower_id, followee_id) values ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
select is(
  (select followers || '/' || following from public.get_profile_counts('22222222-2222-2222-2222-222222222222')),
  '1/0', 'takipçi sayısı (F12b)'
);
select is_empty(
  $$select * from public.notifications where user_id = '22222222-2222-2222-2222-222222222222'$$,
  'başkasının bildirimleri okunamaz'
);
reset role;

select is(
  (select type::text || ':' || actor_id from public.notifications where user_id = '22222222-2222-2222-2222-222222222222'),
  'new_follower:11111111-1111-1111-1111-111111111111',
  'yeni takipçi bildirimi oluşur (F13a)'
);

-- C de B'yi takip eder; A takip listesini görür
insert into public.follows (follower_id, followee_id, created_at)
values ('33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', now() + interval '1 second');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
select is(
  (select array_agg(username) from public.get_follow_list('22222222-2222-2222-2222-222222222222', 'followers')),
  array['cem', 'ayse_1'], 'takipçi listesi en yeni önce (F12c)'
);
select is(
  (select array_agg(username) from public.get_follow_list('11111111-1111-1111-1111-111111111111', 'following')),
  array['burak'], 'takip edilenler listesi'
);
select is(
  (select count(*)::int from public.get_follow_list('22222222-2222-2222-2222-222222222222', 'followers', 30)),
  0, 'sayfa ofseti'
);

-- F15(b): A, B'yi engeller → iki yönlü takip silinir, B A'yı takip edemez
insert into public.blocks (blocker_id, blocked_id) values ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
select is(
  (select count(*)::int from public.follows where follower_id = '11111111-1111-1111-1111-111111111111' and followee_id = '22222222-2222-2222-2222-222222222222'),
  0, 'engelleyince takip silinir (F15b)'
);
select is(
  (select count(*)::int from public.get_follow_list('33333333-3333-3333-3333-333333333333', 'following')
   where username = 'burak'),
  0, 'engellenen kişi kullanıcı listelerinde görünmez'
);
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);
select throws_ok(
  $$insert into public.follows (follower_id, followee_id) values ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111')$$,
  '42501', null, 'engellenen engelleyeni takip edemez (F15b)'
);

-- F13(c): okundu işareti
select is((select count(*)::int from public.notifications where read_at is null), 2, 'B''nin okunmamış bildirimleri (A ve C takip etti)');
select public.mark_notifications_read();
select is((select count(*)::int from public.notifications where read_at is null), 0, 'zil açılınca hepsi okundu (F13c)');
select throws_ok(
  $$update public.notifications set type = 'badge_earned'$$,
  '42501', null, 'bildirimin yalnızca okundu alanı değişebilir'
);
reset role;

-- F14 rozetleri ve F13 rozet bildirimi
insert into public.watched_episodes (user_id, episode_id, show_id)
values ('33333333-3333-3333-3333-333333333333', 1001, 1);
select is(
  (select array_agg(badge_code) from public.user_badges where user_id = '33333333-3333-3333-3333-333333333333'),
  array['first_episode'], 'ilk bölüm rozeti (F14)'
);
select is(
  (select count(*)::int from public.notifications
   where user_id = '33333333-3333-3333-3333-333333333333' and type = 'badge_earned' and entity_id = 'first_episode'),
  1, 'rozet kazanıldı bildirimi (F13a)'
);

insert into public.watched_episodes (user_id, episode_id, show_id)
select '33333333-3333-3333-3333-333333333333', 1000 + g, 1 from generate_series(2, 100) g;
select is(
  (select count(*)::int from public.user_badges where user_id = '33333333-3333-3333-3333-333333333333' and badge_code = 'episodes_100'),
  1, '100 bölüm rozeti'
);
select is(
  (select count(*)::int from public.notifications where user_id = '33333333-3333-3333-3333-333333333333' and entity_id = 'first_episode'),
  1, 'rozet ve bildirimi bir kez verilir'
);

delete from public.watched_episodes where user_id = '33333333-3333-3333-3333-333333333333';
select is(
  (select count(*)::int from public.user_badges where user_id = '33333333-3333-3333-3333-333333333333'),
  2, 'koşul bozulsa da rozet geri alınmaz (F14)'
);

insert into public.user_shows (user_id, show_id)
select '11111111-1111-1111-1111-111111111111', g from generate_series(1, 10) g;
select is(
  (select count(*)::int from public.user_badges where user_id = '11111111-1111-1111-1111-111111111111' and badge_code = 'shows_10'),
  1, '10 dizi rozeti'
);

-- F13: yorum beğenildi bildirimi, yorum metni içermez
insert into public.comments (id, user_id, episode_id, body)
values ('aaaaaaaa-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', 1001, 'Gizli spoiler metni');
select is(
  (select count(*)::int from public.user_badges where user_id = '33333333-3333-3333-3333-333333333333' and badge_code = 'first_comment'),
  1, 'ilk yorum rozeti'
);
insert into public.comment_likes (user_id, comment_id) values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000001');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}', true);
select is(
  (select actor_username || ':' || episode_id from public.get_notifications() where type = 'comment_liked'),
  'ayse_1:1001', 'beğeni bildirimi beğenen kişi ve bölümü verir'
);
select is(
  (select count(*)::int from public.notifications where entity_id like '%spoiler%'),
  0, 'bildirim yorum metni içermez (R7)'
);
reset role;

select * from finish();

rollback;
