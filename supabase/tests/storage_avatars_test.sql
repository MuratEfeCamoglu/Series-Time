-- F2: avatars kovası; kullanıcı yalnızca avatars/<kendi uid>/ yoluna yazar ve siler.
begin;
create extension if not exists pgtap with schema extensions;

select plan(6);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local',
   '{"username": "ayse_1"}'),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local',
   '{"username": "burak"}');

select is(
  (select public::text || '|' || file_size_limit::text from storage.buckets where id = 'avatars'),
  'true|2097152',
  'avatars kovası herkese açık ve 2 MB sınırlı'
);

-- Yeni Storage sürümleri tablodan doğrudan silmeyi engeller; test için izin verilir.
select set_config('storage.allow_delete_query', 'true', true);

-- B'nin dosyası (service rolüyle)
insert into storage.objects (bucket_id, name, owner)
values ('avatars', '22222222-2222-2222-2222-222222222222/b.jpg', '22222222-2222-2222-2222-222222222222');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$insert into storage.objects (bucket_id, name, owner)
    values ('avatars', '11111111-1111-1111-1111-111111111111/a.jpg', '11111111-1111-1111-1111-111111111111')$$,
  'kullanıcı kendi klasörüne yükler'
);

select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner)
    values ('avatars', '22222222-2222-2222-2222-222222222222/x.jpg', '11111111-1111-1111-1111-111111111111')$$,
  '42501',
  null,
  'kullanıcı başkasının klasörüne yükleyemez'
);

delete from storage.objects where name = '22222222-2222-2222-2222-222222222222/b.jpg';
reset role;
select is(
  (select count(*)::int from storage.objects where name = '22222222-2222-2222-2222-222222222222/b.jpg'),
  1,
  'kullanıcı başkasının avatarını silemez'
);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
delete from storage.objects where name = '11111111-1111-1111-1111-111111111111/a.jpg';
reset role;
select is(
  (select count(*)::int from storage.objects where name = '11111111-1111-1111-1111-111111111111/a.jpg'),
  0,
  'kullanıcı kendi avatarını siler'
);

set local role anon;
select is(
  (select count(*)::int from storage.objects where bucket_id = 'avatars'),
  1,
  'avatarlar anonim olarak okunabilir'
);
reset role;

select * from finish();

rollback;
