-- F1, F2: profiles tablosu, kayıt tetikleyicisi, avatars kovası ve RLS (ISKELET.md §3.3).

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  username text not null unique
    constraint profiles_username_format check (username ~ '^[a-z0-9_]{3,20}$'),
  display_name text not null
    constraint profiles_display_name_length check (char_length(display_name) between 1 and 40),
  bio text not null default ''
    constraint profiles_bio_length check (char_length(bio) <= 160),
  country_code char(2)
    constraint profiles_country_code_format check (country_code ~ '^[A-Z]{2}$'),
  avatar_path text,
  -- `shows` tablosu Aşama 2'de gelir; yabancı anahtar o migration'da eklenir.
  cover_show_id integer,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_authenticated"
  on public.profiles for select
  to authenticated
  using (true);

-- Satır kayıt tetikleyicisiyle oluşur, hesapla birlikte (cascade) silinir; istemci yalnızca günceller.
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Kullanıcı adı ve görünen ad kayıtta `raw_user_meta_data` ile gelir. Kural ihlalinde
-- kısıt hatası kaydı da geri alır; böylece profilsiz hesap oluşmaz.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_username text := lower(trim(new.raw_user_meta_data ->> 'username'));
begin
  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    new_username,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), new_username)
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Kayıt ekranı oturum açılmadan önce adın boş olup olmadığını sorar; profiles tablosu
-- anonim kullanıcıya kapalı olduğu için yalnızca evet/hayır döndüren fonksiyon açılır.
create function public.is_username_available(name text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not exists (select 1 from public.profiles where username = lower(trim(name)));
$$;

revoke execute on function public.is_username_available(text) from public;
grant execute on function public.is_username_available(text) to anon, authenticated;

-- Avatarlar: herkese okunur, kullanıcı yalnızca avatars/<kendi uid>/ altına yazar (F2: ≤ 2 MB JPEG).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg']);

create policy "avatars_select_public"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "avatars_insert_own_folder"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars_update_own_folder"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars_delete_own_folder"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
