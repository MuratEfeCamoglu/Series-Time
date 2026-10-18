-- F1, F2: profiles tablosu, kayıt tetikleyicisi ve RLS.
begin;
create extension if not exists pgtap with schema extensions;

select plan(15);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local',
   '{"username": "ayse_1"}'),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'b@test.local',
   '{"username": "Burak", "display_name": "Burak B."}');

select is(
  (select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),
  true,
  'profiles tablosunda RLS açık'
);

select is(
  (select username || '|' || display_name from public.profiles
   where id = '11111111-1111-1111-1111-111111111111'),
  'ayse_1|ayse_1',
  'kayıt tetikleyicisi profili oluşturur; görünen ad yoksa kullanıcı adı kullanılır'
);

select is(
  (select username || '|' || display_name from public.profiles
   where id = '22222222-2222-2222-2222-222222222222'),
  'burak|Burak B.',
  'kullanıcı adı küçük harfe çevrilir, görünen ad meta veriden alınır'
);

select throws_ok(
  $$insert into auth.users (id, aud, role, email, raw_user_meta_data)
    values ('33333333-3333-3333-3333-333333333333', 'authenticated', 'authenticated',
            'c@test.local', '{"username": "ayse_1"}')$$,
  '23505',
  null,
  'aynı kullanıcı adı ikinci kez alınamaz (F1a)'
);

select throws_ok(
  $$insert into auth.users (id, aud, role, email, raw_user_meta_data)
    values ('44444444-4444-4444-4444-444444444444', 'authenticated', 'authenticated',
            'd@test.local', '{"username": "ab"}')$$,
  '23514',
  null,
  'kurala uymayan kullanıcı adı reddedilir (F1a)'
);

select is(
  (select count(*)::int from auth.users where email in ('c@test.local', 'd@test.local')),
  0,
  'profil oluşturulamazsa hesap da oluşmaz'
);

select is(public.is_username_available('AYSE_1'), false, 'alınmış ad müsait değil');
select is(public.is_username_available('yeni_ad'), true, 'boş ad müsait');

-- Anonim kullanıcı
set local role anon;
select is_empty('select * from public.profiles', 'anonim kullanıcı profilleri okuyamaz');
select is(public.is_username_available('ayse_1'), false, 'anonim kullanıcı ad müsaitliğini sorabilir');
reset role;

-- Oturum açmış kullanıcı A
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

-- seed.sql'deki test hesapları da bulunabilir; yalnızca bu testin kullanıcıları sayılır.
select is(
  (select count(*)::int from public.profiles
   where id in ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222')),
  2,
  'oturum açmış kullanıcı başkasının profilini de okur'
);

update public.profiles set bio = 'merhaba' where id = '11111111-1111-1111-1111-111111111111';
select is(
  (select bio from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'merhaba',
  'kullanıcı kendi profilini günceller'
);

update public.profiles set bio = 'ele geçirildi' where id = '22222222-2222-2222-2222-222222222222';
select is(
  (select bio from public.profiles where id = '22222222-2222-2222-2222-222222222222'),
  '',
  'kullanıcı başkasının profilini güncelleyemez'
);

select throws_ok(
  $$insert into public.profiles (id, username, display_name)
    values ('55555555-5555-5555-5555-555555555555', 'sahte', 'Sahte')$$,
  '42501',
  null,
  'istemci profil satırı ekleyemez'
);

select throws_ok(
  $$update public.profiles set bio = repeat('x', 161)
    where id = '11111111-1111-1111-1111-111111111111'$$,
  '23514',
  null,
  'biyografi 160 karakteri aşamaz (F2)'
);

reset role;
select * from finish();

rollback;
