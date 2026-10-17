-- F8(l): puan dağılımı yalnızca istenen kullanıcının puanlarını sayar, puana göre sıralı ve herkese açıktır.
begin;
create extension if not exists pgtap with schema extensions;

select plan(3);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local', '{"username": "ayse_1"}'),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local', '{"username": "burak"}');

insert into public.shows (id, name) values (1, 'Bir');
insert into public.episodes (id, show_id, season_number, episode_number, air_date)
select n, 1, 1, n, current_date - 1 from generate_series(1, 4) n;
insert into public.episode_ratings (user_id, episode_id, rating) values
  ('11111111-1111-1111-1111-111111111111', 1, 4.5),
  ('11111111-1111-1111-1111-111111111111', 2, 4.5),
  ('11111111-1111-1111-1111-111111111111', 3, 2.0),
  ('22222222-2222-2222-2222-222222222222', 4, 1.0);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);

select is(
  (select array_agg(rating::text || 'x' || rating_count order by rating)
   from public.get_rating_distribution('11111111-1111-1111-1111-111111111111')),
  array['2.0x1', '4.5x2'],
  'puan başına sayı, puana göre sıralı'
);
select is(
  (select sum(rating_count)::int from public.get_rating_distribution('11111111-1111-1111-1111-111111111111')),
  3, 'başkasının puanları sayılmaz; başkasının dağılımı okunabilir (V10)'
);
select is(
  (select count(*)::int from public.get_rating_distribution('33333333-3333-3333-3333-333333333333')),
  0, 'puanı olmayan kullanıcı için boş'
);
reset role;

select * from finish();

rollback;
