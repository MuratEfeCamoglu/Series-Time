-- F2/F8(i): Letterboxd ve Instagram kullanıcı adları; F2: kırpılmış avatarlar PNG olarak yüklenir
-- (kullanıcı kararları 2026-10-17).

alter table public.profiles
  add column letterboxd_username text
    constraint profiles_letterboxd_format check (letterboxd_username ~ '^[a-z0-9_]{2,15}$'),
  add column instagram_username text
    constraint profiles_instagram_format check (
      instagram_username ~ '^[a-z0-9._]{1,30}$'
      and instagram_username !~ '^\.'
      and instagram_username !~ '\.$'
      and instagram_username !~ '\.\.'
    );

-- Uygulama içi kırpma dart:ui ile PNG üretir; boyut sınırı (2 MB) değişmez.
update storage.buckets
set allowed_mime_types = array['image/jpeg', 'image/png']
where id = 'avatars';
