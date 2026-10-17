-- F20 bölüm puanı ve beğenisi, F2 kapak yolu ve TMDB avatarı.
begin;
create extension if not exists pgtap with schema extensions;

select plan(11);

insert into auth.users (id, aud, role, email, raw_user_meta_data, is_anonymous)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local', '{"username": "ayse_1"}', false),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local', '{"username": "burak"}', false),
  ('99999999-9999-9999-9999-999999999999', 'authenticated', 'authenticated', null, '{}', true);
insert into public.shows (id, name) values (1, 'Bir');
insert into public.episodes (id, show_id, season_number, episode_number, air_date) values (11, 1, 1, 1, current_date - 1);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$insert into public.episode_ratings (user_id, episode_id, rating) values ('11111111-1111-1111-1111-111111111111', 11, 4.5)$$,
  'buçuklu puan verilir'
);
select throws_ok(
  $$update public.episode_ratings set rating = 4.3 where user_id = '11111111-1111-1111-1111-111111111111'$$,
  '23514', null, 'yalnızca 0,5 adımlar'
);
select throws_ok(
  $$update public.episode_ratings set rating = 5.5 where user_id = '11111111-1111-1111-1111-111111111111'$$,
  '23514', null, 'en fazla 5'
);
select throws_ok(
  $$insert into public.episode_ratings (user_id, episode_id, rating) values ('22222222-2222-2222-2222-222222222222', 11, 3)$$,
  '42501', null, 'başkası adına puan verilemez'
);
insert into public.episode_likes (user_id, episode_id) values ('11111111-1111-1111-1111-111111111111', 11);
update public.profiles set cover_path = '/abc123.jpg', avatar_path = 'tmdb:/kisi.jpg'
where id = '11111111-1111-1111-1111-111111111111';
select is(
  (select cover_path || ' ' || avatar_path from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  '/abc123.jpg tmdb:/kisi.jpg', 'kapak yolu ve TMDB avatarı saklanır'
);
select throws_ok(
  $$update public.profiles set cover_path = 'https://kotu.example/x.jpg' where id = '11111111-1111-1111-1111-111111111111'$$,
  '23514', null, 'kapak yalnızca TMDB görsel yolu olabilir'
);
select throws_ok(
  $$update public.profiles set avatar_path = 'tmdb:https://kotu.example/x.jpg' where id = '11111111-1111-1111-1111-111111111111'$$,
  '23514', null, 'TMDB avatarı yalnızca TMDB görsel yolu olabilir'
);
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);
insert into public.episode_ratings (user_id, episode_id, rating) values ('22222222-2222-2222-2222-222222222222', 11, 3);
select is(
  (select average || '/' || rating_count || '/' || like_count from public.get_episode_rating_stats(11)),
  '3.8/2/1', 'ortalama (4,5 ve 3 → 3,8), puan ve beğeni sayısı'
);
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "99999999-9999-9999-9999-999999999999", "role": "authenticated", "is_anonymous": true}', true);
select throws_ok(
  $$insert into public.episode_ratings (user_id, episode_id, rating) values ('99999999-9999-9999-9999-999999999999', 11, 5)$$,
  '42501', null, 'misafir puan veremez (F19)'
);
select throws_ok(
  $$insert into public.episode_likes (user_id, episode_id) values ('99999999-9999-9999-9999-999999999999', 11)$$,
  '42501', null, 'misafir beğenemez (F19)'
);
reset role;

select is(
  (select bool_and(relrowsecurity) from pg_class where oid in ('public.episode_ratings'::regclass, 'public.episode_likes'::regclass)),
  true, 'RLS açık'
);

select * from finish();

rollback;
