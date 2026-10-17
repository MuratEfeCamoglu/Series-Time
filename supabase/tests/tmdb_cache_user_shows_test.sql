-- Aşama 2: TMDB önbellek tabloları ve user_shows RLS.
begin;
create extension if not exists pgtap with schema extensions;

select plan(14);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local',
   '{"username": "ayse_1"}'),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local',
   '{"username": "burak"}');

insert into public.shows (id, name) values (1399, 'Game of Thrones'), (1396, 'Breaking Bad');
insert into public.seasons (id, show_id, season_number) values (3624, 1399, 1);
insert into public.episodes (id, show_id, season_number, episode_number, air_date)
values (63056, 1399, 1, 1, '2011-04-17');
insert into public.episode_credits (episode_id, person_id, name, "order")
values (63056, 22970, 'Peter Dinklage', 0);
insert into public.user_shows (user_id, show_id)
values ('22222222-2222-2222-2222-222222222222', 1396);

select is(
  (select bool_and(relrowsecurity) from pg_class
   where oid in ('public.shows'::regclass, 'public.seasons'::regclass, 'public.episodes'::regclass,
                 'public.episode_credits'::regclass, 'public.user_shows'::regclass)),
  true,
  'TMDB tablolarında ve user_shows tablosunda RLS açık'
);

select is(
  (select last_synced_at from public.shows where id = 1399),
  null,
  'özet satırda last_synced_at boş kalır (önbellek taze sayılmaz)'
);

-- Anonim kullanıcı
set local role anon;
select is((select count(*)::int from public.shows), 2, 'anonim kullanıcı dizileri okur');
select is_empty('select * from public.user_shows', 'anonim kullanıcı user_shows okuyamaz');
reset role;

-- Oturum açmış kullanıcı A
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select is((select count(*)::int from public.episode_credits), 1, 'kullanıcı kadroyu okur');

select throws_ok(
  $$insert into public.shows (id, name) values (1, 'Sahte')$$,
  '42501', null, 'istemci shows tablosuna yazamaz'
);

select throws_ok(
  $$insert into public.episodes (id, show_id, season_number, episode_number) values (1, 1399, 1, 2)$$,
  '42501', null, 'istemci episodes tablosuna yazamaz'
);

update public.shows set name = 'Değişti' where id = 1399;
select is(
  (select name from public.shows where id = 1399),
  'Game of Thrones',
  'istemci shows satırını güncelleyemez'
);

select lives_ok(
  $$insert into public.user_shows (user_id, show_id)
    values ('11111111-1111-1111-1111-111111111111', 1399)$$,
  'kullanıcı kendi listesine dizi ekler (F4b)'
);

select throws_ok(
  $$insert into public.user_shows (user_id, show_id)
    values ('22222222-2222-2222-2222-222222222222', 1399)$$,
  '42501', null, 'kullanıcı başkasının listesine dizi ekleyemez'
);

select is(
  (select count(*)::int from public.user_shows),
  2,
  'oturum açmış kullanıcı tüm listeleri okur (V10)'
);

delete from public.user_shows where user_id = '22222222-2222-2222-2222-222222222222';
select is(
  (select count(*)::int from public.user_shows where user_id = '22222222-2222-2222-2222-222222222222'),
  1,
  'kullanıcı başkasının listesinden dizi silemez'
);

delete from public.user_shows where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 1399;
select is(
  (select count(*)::int from public.user_shows where user_id = '11111111-1111-1111-1111-111111111111'),
  0,
  'kullanıcı kendi listesinden dizi çıkarır (F4c)'
);

reset role;

select throws_ok(
  $$update public.profiles set cover_show_id = 999999
    where id = '11111111-1111-1111-1111-111111111111'$$,
  '23503', null, 'kapak yalnızca var olan bir diziye işaret eder'
);

select * from finish();

rollback;
