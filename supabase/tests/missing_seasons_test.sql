-- Bölümleri önbellekte eksik sezonlar (F6 sıradaki bölüm).
begin;
create extension if not exists pgtap with schema extensions;

select plan(3);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local', '{"username": "ayse_1"}');

insert into public.shows (id, name) values (1, 'Bir');
insert into public.seasons (id, show_id, season_number, air_date, episode_count) values
  (101, 1, 1, current_date - 400, 2),
  (102, 1, 2, current_date - 30, 2),
  (103, 1, 3, current_date + 30, 2),
  (100, 1, 0, current_date - 400, 5);
insert into public.episodes (id, show_id, season_number, episode_number, air_date) values
  (11, 1, 1, 1, current_date - 400),
  (12, 1, 1, 2, current_date - 393);
insert into public.user_shows (user_id, show_id)
values ('11111111-1111-1111-1111-111111111111', 1);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
select is(
  (select array_agg(season_number) from public.get_missing_seasons()),
  array[2], 'yalnızca bölümleri eksik yayınlanmış sezon (özel ve gelecek sezon hariç)'
);
reset role;

insert into public.episodes (id, show_id, season_number, episode_number, air_date) values
  (21, 1, 2, 1, current_date - 30),
  (22, 1, 2, 2, current_date - 23);
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
select is(
  (select count(*)::integer from public.get_missing_seasons()), 0, 'tamamlanınca liste boş'
);
reset role;

set local role anon;
select throws_ok(
  'select * from public.get_missing_seasons()', '42501', null, 'anon rolü çağıramaz'
);
reset role;

select * from finish();

rollback;
