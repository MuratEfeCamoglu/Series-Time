-- F8(j): favori işareti, 4 favori sınırı, başkasının favorisi değiştirilemez; F8(k): son etkinlik sırası.
begin;
create extension if not exists pgtap with schema extensions;

select plan(7);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local', '{"username": "ayse_1"}'),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local', '{"username": "burak"}');

insert into public.shows (id, name) values (1, 'Bir'), (2, 'İki'), (3, 'Üç'), (4, 'Dört'), (5, 'Beş');
insert into public.episodes (id, show_id, season_number, episode_number, name, air_date) values
  (11, 1, 1, 1, 'Pilot', current_date - 10),
  (21, 2, 1, 1, 'Başlangıç', current_date - 9);
insert into public.user_shows (user_id, show_id)
select '11111111-1111-1111-1111-111111111111', id from public.shows;
insert into public.user_shows (user_id, show_id) values ('22222222-2222-2222-2222-222222222222', 1);
insert into public.watched_episodes (user_id, episode_id, show_id, watched_at) values
  ('11111111-1111-1111-1111-111111111111', 11, 1, now() - interval '2 days'),
  ('11111111-1111-1111-1111-111111111111', 21, 2, now() - interval '1 hour');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$update public.user_shows set is_favorite = true
    where user_id = '11111111-1111-1111-1111-111111111111' and show_id in (1, 2, 3, 4)$$,
  '4 favori seçilebilir'
);
select throws_ok(
  $$update public.user_shows set is_favorite = true
    where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 5$$,
  '23514', 'too_many_favorites', '5. favori reddedilir'
);
select is(
  (select count(*)::int from public.get_user_show_progress('11111111-1111-1111-1111-111111111111') where is_favorite),
  4, 'get_user_show_progress favori işaretini döner'
);
select lives_ok(
  $$update public.user_shows set is_favorite = false
    where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 1$$,
  'favoriden çıkarılabilir'
);

update public.user_shows set is_favorite = true
where user_id = '22222222-2222-2222-2222-222222222222' and show_id = 1;
reset role;
select is(
  (select is_favorite from public.user_shows where user_id = '22222222-2222-2222-2222-222222222222' and show_id = 1),
  false, 'başkasının favorisini değiştiremez'
);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);
select is(
  (select array_agg(episode_id) from public.get_recent_activity('11111111-1111-1111-1111-111111111111')),
  array[21, 11], 'son etkinlik yeniden eskiye ve herkese açık (V10)'
);
select is(
  (select show_name || ' ' || episode_name from public.get_recent_activity('11111111-1111-1111-1111-111111111111', 1)),
  'İki Başlangıç', 'sınır uygulanır, dizi ve bölüm adı döner'
);
reset role;

select * from finish();

rollback;
