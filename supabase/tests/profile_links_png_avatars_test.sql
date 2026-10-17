-- F2/F8(i): sosyal kullanıcı adı biçimleri; avatars kovası PNG kabul eder.
begin;
create extension if not exists pgtap with schema extensions;

select plan(7);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local', '{"username": "ayse_1"}');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$update public.profiles set letterboxd_username = 'ayse_1', instagram_username = 'ayse.dizi_1'
    where id = '11111111-1111-1111-1111-111111111111'$$,
  'geçerli kullanıcı adları kaydedilir'
);
select throws_ok(
  $$update public.profiles set letterboxd_username = 'https://letterboxd.com/ayse'
    where id = '11111111-1111-1111-1111-111111111111'$$,
  '23514', null, 'Letterboxd: tam adres kabul edilmez'
);
select throws_ok(
  $$update public.profiles set letterboxd_username = 'a' where id = '11111111-1111-1111-1111-111111111111'$$,
  '23514', null, 'Letterboxd: en az 2 karakter'
);
select throws_ok(
  $$update public.profiles set instagram_username = '.ayse' where id = '11111111-1111-1111-1111-111111111111'$$,
  '23514', null, 'Instagram: nokta ile başlayamaz'
);
select throws_ok(
  $$update public.profiles set instagram_username = 'ay..se' where id = '11111111-1111-1111-1111-111111111111'$$,
  '23514', null, 'Instagram: art arda nokta olamaz'
);
select lives_ok(
  $$update public.profiles set letterboxd_username = null, instagram_username = null
    where id = '11111111-1111-1111-1111-111111111111'$$,
  'bağlantılar boşaltılabilir'
);
reset role;

select ok(
  (select 'image/png' = any(allowed_mime_types) from storage.buckets where id = 'avatars'),
  'avatars kovası PNG kabul eder'
);

select * from finish();

rollback;
