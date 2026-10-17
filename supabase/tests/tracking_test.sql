-- Aşama 3: watched_episodes RLS ve tetikleyicileri, işaretleme RPC'leri, get_watchlist, get_upcoming.
begin;
create extension if not exists pgtap with schema extensions;

select plan(24);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local',
   '{"username": "ayse_1"}'),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local',
   '{"username": "burak"}');

-- Dizi 1: S1 3 bölüm yayınlandı, S2B1 yayınlandı, S2B2 gelecekte; S0 bir özel bölüm.
-- Dizi 2: tüm bölümleri yayınlandı. Dizi 3: yalnızca gelecekte bölümleri var.
insert into public.shows (id, name) values (1, 'Bir'), (2, 'İki'), (3, 'Üç');
insert into public.episodes (id, show_id, season_number, episode_number, air_date) values
  (101, 1, 1, 1, current_date - 30),
  (102, 1, 1, 2, current_date - 20),
  (103, 1, 1, 3, current_date - 10),
  (104, 1, 2, 1, current_date - 1),
  (105, 1, 2, 2, current_date + 7),
  (100, 1, 0, 1, current_date - 40),
  (106, 1, 2, 3, null),
  (201, 2, 1, 1, current_date - 5),
  (301, 3, 1, 1, current_date + 1),
  (302, 3, 1, 2, current_date + 91);

insert into public.user_shows (user_id, show_id, added_at) values
  ('11111111-1111-1111-1111-111111111111', 1, now() - interval '3 days'),
  ('11111111-1111-1111-1111-111111111111', 3, now() - interval '1 day'),
  ('22222222-2222-2222-2222-222222222222', 2, now());

select is(
  (select relrowsecurity from pg_class where oid = 'public.watched_episodes'::regclass),
  true,
  'watched_episodes tablosunda RLS açık'
);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

-- F5(a): tek bölüm işaretleme
insert into public.watched_episodes (user_id, episode_id, show_id)
values ('11111111-1111-1111-1111-111111111111', 101, 999);
select is(
  (select show_id from public.watched_episodes where episode_id = 101),
  1,
  'show_id istemciden değil bölümden alınır'
);
select isnt(
  (select last_watched_at from public.user_shows
   where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 1),
  null,
  'işaretleme son izleme tarihini günceller'
);

select throws_ok(
  $$insert into public.watched_episodes (user_id, episode_id, show_id)
    values ('11111111-1111-1111-1111-111111111111', 105, 1)$$,
  'P0001', 'episode_not_aired', 'gelecekteki bölüm işaretlenemez (F5d)'
);

select throws_ok(
  $$insert into public.watched_episodes (user_id, episode_id, show_id)
    values ('11111111-1111-1111-1111-111111111111', 106, 1)$$,
  'P0001', 'episode_not_aired', 'tarihsiz bölüm işaretlenemez (R6)'
);

select throws_ok(
  $$insert into public.watched_episodes (user_id, episode_id, show_id)
    values ('22222222-2222-2222-2222-222222222222', 201, 2)$$,
  '42501', null, 'başkası adına bölüm işaretlenemez'
);

-- F6: get_watchlist
select is(
  (select next_episode_id from public.get_watchlist() where show_id = 1),
  102,
  'sıradaki bölüm ilk izlenmemiş yayınlanmış bölümdür'
);
select is(
  (select aired_count || '/' || watched_count from public.get_watchlist() where show_id = 1),
  '4/1',
  'ilerleme sayıları sezon 0 ve gelecekteki bölümleri saymaz'
);
select is(
  (select count(*)::int from public.get_watchlist() where show_id = 3),
  0,
  'yayınlanmış bölümü olmayan dizinin sıradaki bölümü yoktur'
);

-- F5(c): buraya kadar izledim
select is(public.mark_episodes_until(104), 3, 'buraya kadar: önceki yayınlanmış bölümler işaretlenir');
select is(
  (select array_agg(episode_id order by episode_id) from public.watched_episodes
   where user_id = '11111111-1111-1111-1111-111111111111'),
  array[101, 102, 103, 104],
  'buraya kadar sezon 0 ve gelecekteki bölümleri işaretlemez'
);
select is(public.mark_episodes_until(104), 0, 'buraya kadar ikinci kez çağrılınca bir şey eklemez');
select is(public.mark_episodes_until(100), 1, 'özel bölümde buraya kadar yalnızca o bölümü işaretler');

-- F6(f): tüm yayınlanmış bölümleri izlenen dizi listede görünmez
select is(
  (select count(*)::int from public.get_watchlist() where show_id = 1),
  0,
  'tüm yayınlanmış bölümleri izlenen dizi İzleme Listesi''nde yok'
);

-- F5(a) geri alma
delete from public.watched_episodes
where user_id = '11111111-1111-1111-1111-111111111111' and episode_id = 104;
select is(
  (select next_episode_id from public.get_watchlist() where show_id = 1),
  104,
  'işaret geri alınınca bölüm yeniden sıradaki olur'
);

-- F5(b): sezonun tamamı
delete from public.watched_episodes
where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 1;
select is(
  (select last_watched_at from public.user_shows
   where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 1),
  null,
  'tüm işaretler silinince son izleme tarihi boşalır'
);
select is(public.mark_season(1, 2), 1, 'sezonun tamamı: yalnızca yayınlanmış bölümler');

-- Listede olmayan dizinin bölümü işaretlenince dizi listeye girer
insert into public.watched_episodes (user_id, episode_id, show_id)
values ('11111111-1111-1111-1111-111111111111', 201, 2);
select is(
  (select count(*)::int from public.user_shows
   where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 2),
  1,
  'işaretlenen bölümün dizisi listeye eklenir'
);

-- F6(g): sıralama
insert into public.shows (id, name) values (4, 'Dört');
insert into public.episodes (id, show_id, season_number, episode_number, air_date)
values (401, 4, 1, 1, current_date - 3), (402, 4, 1, 2, current_date - 2);
insert into public.user_shows (user_id, show_id) values ('11111111-1111-1111-1111-111111111111', 4);
select is(
  (select array_agg(show_id) from public.get_watchlist()),
  array[4, 1],
  'hiç izlenmemiş dizi en üstte, sonra son izlenen'
);

-- F7: get_upcoming
select is(
  (select array_agg(episode_id) from public.get_upcoming(90)),
  array[301, 105],
  'yaklaşan: 90 gün içindekiler, artan tarih sırasıyla'
);
select is(
  (select count(*)::int from public.get_upcoming(90) where episode_id = 302),
  0,
  '90 günden sonraki bölüm yaklaşanlarda yok'
);

-- F4(c): listeden çıkarınca izleme kayıtları silinir
delete from public.user_shows
where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 1;
select is(
  (select count(*)::int from public.watched_episodes
   where user_id = '11111111-1111-1111-1111-111111111111' and show_id = 1),
  0,
  'listeden çıkarılan dizinin izleme kayıtları silinir (F4c)'
);

reset role;

-- Kullanıcı B, A'nın kaydını silemez
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);
delete from public.watched_episodes where user_id = '11111111-1111-1111-1111-111111111111';
reset role;
select is(
  (select count(*)::int from public.watched_episodes
   where user_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'başkasının izleme kaydı silinemez'
);

set local role anon;
select throws_ok(
  'select * from public.get_watchlist()',
  '42501', null, 'anonim kullanıcı get_watchlist çağıramaz'
);
reset role;

select * from finish();

rollback;
