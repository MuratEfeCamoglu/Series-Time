-- F19: misafir (anonim) oturum okur ama yazamaz; profil oluşmaz.
begin;
create extension if not exists pgtap with schema extensions;

select plan(8);

insert into auth.users (id, aud, role, email, raw_user_meta_data, is_anonymous)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local',
   '{"username": "ayse_1"}', false),
  ('99999999-9999-9999-9999-999999999999', 'authenticated', 'authenticated', null, '{}', true);

insert into public.shows (id, name) values (1, 'Bir');
insert into public.episodes (id, show_id, season_number, episode_number, air_date)
values (11, 1, 1, 1, current_date - 1);

select is(
  (select count(*)::int from public.profiles where id = '99999999-9999-9999-9999-999999999999'),
  0, 'misafir için profil oluşmaz, anonim giriş engellenmez (F19d)'
);
select is(
  (select count(*)::int from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  1, 'normal kayıtta profil oluşmaya devam eder'
);

-- Misafir
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "99999999-9999-9999-9999-999999999999", "role": "authenticated", "is_anonymous": true}', true);

select is((select count(*)::int from public.shows), 1, 'misafir dizileri okur (F19b)');
select throws_ok(
  $$insert into public.user_shows (user_id, show_id) values ('99999999-9999-9999-9999-999999999999', 1)$$,
  '42501', null, 'misafir listeye dizi ekleyemez (F19c, F19d)'
);
select throws_ok(
  $$insert into public.watched_episodes (user_id, episode_id, show_id) values ('99999999-9999-9999-9999-999999999999', 11, 1)$$,
  '42501', null, 'misafir bölüm işaretleyemez'
);
select throws_ok(
  $$insert into public.comments (user_id, episode_id, body) values ('99999999-9999-9999-9999-999999999999', 11, 'merhaba')$$,
  '42501', null, 'misafir yorum yazamaz'
);
select throws_ok(
  $$insert into public.follows (follower_id, followee_id) values ('99999999-9999-9999-9999-999999999999', '11111111-1111-1111-1111-111111111111')$$,
  '42501', null, 'misafir takip edemez'
);
reset role;

-- Kayıtlı kullanıcı etkilenmez
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated", "is_anonymous": false}', true);
select lives_ok(
  $$insert into public.user_shows (user_id, show_id) values ('11111111-1111-1111-1111-111111111111', 1)$$,
  'kayıtlı kullanıcı yazmaya devam eder'
);
reset role;

select * from finish();

rollback;
