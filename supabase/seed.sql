-- Yalnızca CI'daki yerel yığının test verisi; geliştirme projesine uygulanmaz. badges ve banned_words migration ile eklenir.
-- İki doğrulanmış test kullanıcısı; profilleri kayıt tetikleyicisiyle oluşur.
-- Bu hesapların bilgileri yalnızca bu dosyada tutulur (CLAUDE.md).
--   test1@sezonluk.local / sezonluk-test-n74YwSp26ABN  (kullanıcı adı: test_bir)
--   test2@sezonluk.local / sezonluk-test-n74YwSp26ABN  (kullanıcı adı: test_iki)

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  -- GoTrue bu metin kolonlarını NULL olarak okuyamaz; boş dize verilir.
  confirmation_token, recovery_token, email_change_token_new, email_change
)
values
  ('00000000-0000-0000-0000-000000000000', 'aaaaaaaa-0000-4000-8000-000000000001',
   'authenticated', 'authenticated', 'test1@sezonluk.local',
   extensions.crypt('sezonluk-test-n74YwSp26ABN', extensions.gen_salt('bf')), now(),
   '{"provider": "email", "providers": ["email"]}',
   '{"username": "test_bir", "display_name": "Test Bir"}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'aaaaaaaa-0000-4000-8000-000000000002',
   'authenticated', 'authenticated', 'test2@sezonluk.local',
   extensions.crypt('sezonluk-test-n74YwSp26ABN', extensions.gen_salt('bf')), now(),
   '{"provider": "email", "providers": ["email"]}',
   '{"username": "test_iki", "display_name": "Test İki"}', now(), now(), '', '', '', '');

insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), id, id::text, 'email',
       jsonb_build_object('sub', id::text, 'email', email, 'email_verified', true),
       now(), now(), now()
from auth.users
where email in ('test1@sezonluk.local', 'test2@sezonluk.local');
