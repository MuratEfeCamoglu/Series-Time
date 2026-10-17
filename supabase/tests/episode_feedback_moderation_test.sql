-- Aşama 5: tepkiler, yıldız oyu, yorumlar (hız sınırı, kelime filtresi), beğeni, engelleme, şikayet.
begin;
create extension if not exists pgtap with schema extensions;

select plan(31);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local',
   '{"username": "ayse_1"}'),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local',
   '{"username": "burak"}'),
  ('33333333-3333-3333-3333-333333333333', 'authenticated', 'authenticated', 'c@test.local',
   '{"username": "cem"}');

insert into public.shows (id, name) values (1, 'Bir');
insert into public.episodes (id, show_id, season_number, episode_number, air_date)
values (11, 1, 1, 1, current_date - 1), (12, 1, 1, 2, current_date - 1);
insert into public.episode_credits (episode_id, person_id, name, character, "order") values
  (11, 501, 'Oyuncu A', 'Karakter A', 0),
  (11, 502, 'Oyuncu B', 'Karakter B', 1);

select is(
  (select bool_and(relrowsecurity) from pg_class where oid in (
    'public.reactions'::regclass, 'public.star_votes'::regclass, 'public.comments'::regclass,
    'public.comment_likes'::regclass, 'public.blocks'::regclass, 'public.reports'::regclass,
    'public.banned_words'::regclass)),
  true,
  'Aşama 5 tablolarında RLS açık'
);

select is(public.normalize_text('İĞNE ışık ÇÖŞ Ü'), 'igne isik cos u', 'Türkçe karakterler normalize edilir');
select is((select count(*)::int from public.banned_words where word = 'pic'), 1, 'yasaklı kelimeler normalize saklanır');

-- Kullanıcı A
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

-- F9
insert into public.reactions (user_id, episode_id, emoji) values ('11111111-1111-1111-1111-111111111111', 11, 'love');
select throws_ok(
  $$insert into public.reactions (user_id, episode_id, emoji) values ('11111111-1111-1111-1111-111111111111', 11, 'sad')$$,
  '23505', null, 'bölüm başına tek tepki (F9b)'
);
update public.reactions set emoji = 'sad' where user_id = '11111111-1111-1111-1111-111111111111' and episode_id = 11;
select is(
  (select emoji::text from public.reactions where user_id = '11111111-1111-1111-1111-111111111111' and episode_id = 11),
  'sad', 'tepki değiştirilebilir (F9b)'
);
select throws_ok(
  $$insert into public.reactions (user_id, episode_id, emoji) values ('22222222-2222-2222-2222-222222222222', 11, 'love')$$,
  '42501', null, 'başkası adına tepki verilemez'
);

-- F10
insert into public.star_votes (user_id, episode_id, person_id) values ('11111111-1111-1111-1111-111111111111', 11, 501);
update public.star_votes set person_id = 502 where user_id = '11111111-1111-1111-1111-111111111111' and episode_id = 11;
select is(
  (select person_id from public.star_votes where user_id = '11111111-1111-1111-1111-111111111111'),
  502, 'oy değiştirilebilir (F10b)'
);

-- F11
select throws_ok(
  $$insert into public.comments (user_id, episode_id, body) values ('11111111-1111-1111-1111-111111111111', 11, '   ')$$,
  '23514', null, 'boş yorum reddedilir (F11a)'
);
select throws_ok(
  format($$insert into public.comments (user_id, episode_id, body) values ('11111111-1111-1111-1111-111111111111', 11, %L)$$, repeat('a', 501)),
  '23514', null, '500 karakteri aşan yorum reddedilir (F11a)'
);
select throws_ok(
  $$insert into public.comments (user_id, episode_id, body) values ('11111111-1111-1111-1111-111111111111', 11, 'Bu sahne PİÇ gibiydi')$$,
  'P0001', 'comment_banned_word', 'yasaklı kelime büyük harf ve Türkçe karakterle de yakalanır (F15d)'
);
select lives_ok(
  $$insert into public.comments (user_id, episode_id, body) values ('11111111-1111-1111-1111-111111111111', 11, 'Amaç belliydi')$$,
  'yasaklı kelime yalnızca tam kelime olarak eşleşir'
);
insert into public.comments (user_id, episode_id, body, is_spoiler) values
  ('11111111-1111-1111-1111-111111111111', 11, '  Harika bölüm  ', true),
  ('11111111-1111-1111-1111-111111111111', 11, 'Üçüncü', false),
  ('11111111-1111-1111-1111-111111111111', 12, 'Dördüncü', false),
  ('11111111-1111-1111-1111-111111111111', 12, 'Beşinci', false);
select is(
  (select count(*)::int from public.comments where body = 'Harika bölüm'),
  1, 'yorum baştaki ve sondaki boşluklardan arındırılır'
);
select throws_ok(
  $$insert into public.comments (user_id, episode_id, body) values ('11111111-1111-1111-1111-111111111111', 11, 'Altıncı')$$,
  'P0001', 'comment_rate_limited', 'dakikada 5 yorumdan fazlası reddedilir (F11f)'
);
select throws_ok(
  $$insert into public.comments (user_id, episode_id, body) values ('22222222-2222-2222-2222-222222222222', 11, 'Sahte')$$,
  '42501', null, 'başkası adına yorum yazılamaz'
);
select throws_ok(
  $$insert into public.comments (user_id, episode_id, body, hidden_at) values ('11111111-1111-1111-1111-111111111111', 12, 'x', now())$$,
  '42501', null, 'istemci gizli yorum oluşturamaz'
);
reset role;

-- B ve C de yorum yazar (yönetici bağlamında; hız sınırı kullanıcı başınadır)
insert into public.comments (id, user_id, episode_id, body, created_at) values
  ('aaaaaaaa-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 11, 'B yorumu', now() + interval '1 second'),
  ('aaaaaaaa-0000-0000-0000-000000000003', '33333333-3333-3333-3333-333333333333', 11, 'C yorumu', now() + interval '2 seconds'),
  ('aaaaaaaa-0000-0000-0000-000000000009', '33333333-3333-3333-3333-333333333333', 11, 'Gizli', now());
update public.comments set hidden_at = now() where id = 'aaaaaaaa-0000-0000-0000-000000000009';

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select is(
  (select array_agg(body) from public.get_episode_comments(11, null, 2)),
  array['C yorumu', 'B yorumu'],
  'yorumlar en yeniden eskiye, sayfa boyutu kadar (F11d)'
);
select is(
  (select count(*)::int from public.get_episode_comments(11)),
  5,
  'yönetici gizlediği yorum kimseye görünmez (F15e)'
);

-- F11(e) beğeni
insert into public.comment_likes (user_id, comment_id) values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000002');
select is(
  (select like_count || '/' || liked_by_me from public.get_episode_comments(11) where id = 'aaaaaaaa-0000-0000-0000-000000000002'),
  '1/true', 'beğeni sayısı ve benim beğenim'
);
select throws_ok(
  $$insert into public.comment_likes (user_id, comment_id)
    select '11111111-1111-1111-1111-111111111111', id from public.comments where body = 'Üçüncü'$$,
  '42501', null, 'kendi yorumunu beğenemez'
);

-- F11(e) silme
delete from public.comments where id = 'aaaaaaaa-0000-0000-0000-000000000002';
select is(
  (select count(*)::int from public.comments where id = 'aaaaaaaa-0000-0000-0000-000000000002'),
  1, 'başkasının yorumu silinemez'
);
delete from public.comments where body = 'Üçüncü';
select is((select count(*)::int from public.comments where body = 'Üçüncü'), 0, 'kendi yorumunu siler');

-- F15(a) şikayet
insert into public.reports (reporter_id, target_type, target_id, reason)
values ('11111111-1111-1111-1111-111111111111', 'comment', 'aaaaaaaa-0000-0000-0000-000000000002', 'spam');
select is(
  (select count(*)::int from public.get_episode_comments(11) where id = 'aaaaaaaa-0000-0000-0000-000000000002'),
  0, 'şikayet edilen yorum şikayet edene hemen gizlenir (F15a)'
);
select is_empty('select * from public.reports', 'şikayetler istemciden okunamaz');

-- F15(b) engelleme
insert into public.blocks (blocker_id, blocked_id) values ('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333');
select is(
  (select count(*)::int from public.get_episode_comments(11) where user_id = '33333333-3333-3333-3333-333333333333'),
  0, 'engellenen kişinin yorumları engelleyene gösterilmez (F15b)'
);
select throws_ok(
  $$insert into public.blocks (blocker_id, blocked_id) values ('11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111')$$,
  '23514', null, 'kişi kendini engelleyemez'
);
select is_empty('select 1 from public.banned_words', 'yasaklı kelime listesi istemciye kapalı');
reset role;

-- Kullanıcı B: A'nın şikayet ve engeli B'yi etkilemez
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);
select is(
  (select count(*)::int from public.get_episode_comments(11) where user_id in (
    '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333')),
  2, 'şikayet ve engel yalnızca sahibini etkiler'
);
select is_empty('select * from public.blocks', 'başkasının engelleri görünmez');

insert into public.reactions (user_id, episode_id, emoji) values ('22222222-2222-2222-2222-222222222222', 11, 'sad');
insert into public.star_votes (user_id, episode_id, person_id) values ('22222222-2222-2222-2222-222222222222', 11, 501);
select is(
  (select array_agg(emoji::text || ':' || count) from public.get_episode_reaction_stats(11)),
  array['sad:2'], 'tepki dağılımı (F9c)'
);
select is(
  (select array_agg(name || ':' || votes || '/' || total_votes order by name) from public.get_episode_star_stats(11)),
  array['Oyuncu A:1/2', 'Oyuncu B:1/2'], 'yıldız oyu dağılımı ve toplam (F10c)'
);
reset role;

set local role anon;
select throws_ok('select * from public.get_episode_comments(11)', '42501', null, 'anonim kullanıcı yorumları okuyamaz');
reset role;

select * from finish();

rollback;
