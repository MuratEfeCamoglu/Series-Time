-- F13(f): Bildirimler › Ben listesindeki kendi izlemeler.
begin;
create extension if not exists pgtap with schema extensions;

select plan(4);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local', '{"username": "ayse_1"}'),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local', '{"username": "burak"}');

insert into public.shows (id, name, poster_path) values (1, 'Bir', '/tmdb.jpg');
insert into public.episodes (id, show_id, season_number, episode_number, air_date, still_path) values
  (11, 1, 1, 1, current_date - 3, '/s11.jpg'),
  (12, 1, 1, 2, current_date - 2, '/s12.jpg');
insert into public.user_shows (user_id, show_id, poster_path)
values ('11111111-1111-1111-1111-111111111111', 1, '/secilen.jpg');
insert into public.watched_episodes (user_id, episode_id, show_id, watched_at) values
  ('11111111-1111-1111-1111-111111111111', 11, 1, (date_trunc('day', now() at time zone 'utc') + interval '1 minute') at time zone 'utc'),
  ('11111111-1111-1111-1111-111111111111', 12, 1, (date_trunc('day', now() at time zone 'utc') + interval '2 minutes') at time zone 'utc'),
  ('22222222-2222-2222-2222-222222222222', 11, 1, now());

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
select is(
  (select count(*)::integer from public.get_my_watch_feed()),
  1, 'aynı gün aynı dizideki bölümler tek satır'
);
select is(
  (select episode_count || ' ' || episode_id || ' ' || still_path || ' ' || poster_path
   from public.get_my_watch_feed()),
  '2 12 /s12.jpg /secilen.jpg', 'bölüm sayısı, son bölüm, sahne görseli ve kişisel afiş'
);

select set_config('request.jwt.claims', '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);
select is(
  (select episode_count from public.get_my_watch_feed()),
  1, 'yalnızca oturum sahibinin izlemeleri döner'
);
reset role;

set local role anon;
select throws_ok(
  'select * from public.get_my_watch_feed()', '42501', null, 'anon rolü çağıramaz'
);
reset role;

select * from finish();

rollback;
