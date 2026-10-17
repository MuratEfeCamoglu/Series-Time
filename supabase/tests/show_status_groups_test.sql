-- F6(j): elle seçilen grup, otomatiğe dönüş, yalnızca manual_status güncellenebilir, ilerleme sayıları,
-- Sıradaki'den Durduruldu/Dönülmez çıkarılır.
begin;
create extension if not exists pgtap with schema extensions;

select plan(12);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local', '{"username": "ayse_1"}'),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local', '{"username": "burak"}');

insert into public.shows (id, name, status) values (1, 'Bir', 'Ended'), (2, 'İki', 'Returning Series'), (3, 'Üç', null);
insert into public.episodes (id, show_id, season_number, episode_number, air_date) values
  (11, 1, 1, 1, current_date - 10),
  (12, 1, 1, 2, current_date - 9),
  (10, 1, 0, 1, current_date - 20),
  (13, 1, 1, 3, current_date + 5),
  (21, 2, 1, 1, current_date - 3),
  (22, 2, 1, 2, current_date - 2);
insert into public.user_shows (user_id, show_id, manual_status) values
  ('11111111-1111-1111-1111-111111111111', 1, 'paused'),
  ('11111111-1111-1111-1111-111111111111', 2, 'dropped'),
  ('11111111-1111-1111-1111-111111111111', 3, 'planned'),
  ('22222222-2222-2222-2222-222222222222', 2, null);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select is(
  (select aired_count || '/' || watched_count || '/' || show_status from public.get_user_show_progress('11111111-1111-1111-1111-111111111111') where show_id = 1),
  '2/0/Ended',
  'ilerleme sayıları sezon 0 ve gelecek bölümü saymaz'
);
select is(
  (select aired_count || '/' || watched_count from public.get_user_show_progress('11111111-1111-1111-1111-111111111111') where show_id = 3),
  '0/0',
  'yayınlanmış bölümü olmayan dizi 0/0 ile listelenir'
);
select is(
  (select count(*)::int from public.get_watchlist()),
  0,
  'Durduruldu ve Dönülmez diziler Sıradaki''de görünmez'
);

-- Elle seçim değiştirilebilir, otomatiğe dönülebilir
update public.user_shows set manual_status = null
where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 1;
select is(
  (select manual_status from public.user_shows where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 1),
  null, 'kullanıcı Otomatik''e dönebilir'
);
select is(
  (select count(*)::int from public.get_watchlist() where show_id = 1),
  1, 'otomatiğe dönen dizi Sıradaki''de yeniden görünür'
);
select is(
  (select manual_status::text from public.get_watchlist() where show_id = 1),
  null, 'get_watchlist elle seçimi döner'
);

select throws_ok(
  $$update public.user_shows set added_at = now() - interval '1 year'
    where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 1$$,
  '42501', null, 'yalnızca manual_status güncellenebilir'
);

update public.user_shows set manual_status = 'paused'
where user_id = '22222222-2222-2222-2222-222222222222' and show_id = 2;
reset role;
select is(
  (select manual_status from public.user_shows where user_id = '22222222-2222-2222-2222-222222222222' and show_id = 2),
  null, 'başkasının grubunu değiştiremez'
);

-- Otomatiğe dönüş tetikleyicisi
update public.user_shows set manual_status = 'paused'
where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 1;
insert into public.watched_episodes (user_id, episode_id, show_id)
values ('11111111-1111-1111-1111-111111111111', 11, 1);
select is(
  (select manual_status from public.user_shows where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 1),
  null, 'Durduruldu dizide bölüm işaretlenince otomatiğe döner'
);

insert into public.watched_episodes (user_id, episode_id, show_id)
values ('11111111-1111-1111-1111-111111111111', 21, 2);
select is(
  (select manual_status::text from public.user_shows where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 2),
  'dropped', 'Dönülmez dizide bölüm işaretlense de korunur'
);

-- İzleme Listesi elle seçimi de işaretleyince kalkar (yeni dizi + bölüm)
insert into public.episodes (id, show_id, season_number, episode_number, air_date) values (31, 3, 1, 1, current_date - 1);
insert into public.watched_episodes (user_id, episode_id, show_id)
values ('11111111-1111-1111-1111-111111111111', 31, 3);
select is(
  (select manual_status from public.user_shows where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 3),
  null, 'İzleme Listesi dizide bölüm işaretlenince otomatiğe döner'
);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);
select is(
  (select watched_count from public.get_user_show_progress('11111111-1111-1111-1111-111111111111') where show_id = 1),
  1, 'başkasının ilerlemesi okunabilir (V10)'
);
reset role;

select * from finish();

rollback;
