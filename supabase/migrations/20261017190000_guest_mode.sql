-- F19 misafir modu: anonim oturum (Supabase `is_anonymous`) yalnızca okur; hiçbir kullanıcı
-- tablosuna ve avatars kovasına yazamaz. Mevcut izin politikalarına dokunmadan, hepsiyle
-- VE'lenen kısıtlayıcı (restrictive) politikalar eklenir.

create function public.is_registered_user()
returns boolean
language sql
stable
set search_path = ''
as $$
  select coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false;
$$;

do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles', 'user_shows', 'watched_episodes', 'reactions', 'star_votes', 'comments',
    'comment_likes', 'follows', 'blocks', 'reports', 'notifications'
  ] loop
    execute format(
      'create policy %I on public.%I as restrictive for insert to authenticated with check (public.is_registered_user())',
      t || '_registered_insert', t);
    execute format(
      'create policy %I on public.%I as restrictive for update to authenticated using (public.is_registered_user())',
      t || '_registered_update', t);
    execute format(
      'create policy %I on public.%I as restrictive for delete to authenticated using (public.is_registered_user())',
      t || '_registered_delete', t);
  end loop;
end;
$$;

-- Diğer kovaları etkilememek için koşul yalnızca avatars kovasına uygulanır.
create policy "avatars_registered_insert" on storage.objects as restrictive for insert to authenticated
  with check (bucket_id <> 'avatars' or public.is_registered_user());
create policy "avatars_registered_update" on storage.objects as restrictive for update to authenticated
  using (bucket_id <> 'avatars' or public.is_registered_user());
create policy "avatars_registered_delete" on storage.objects as restrictive for delete to authenticated
  using (bucket_id <> 'avatars' or public.is_registered_user());

-- Anonim kayıtta kullanıcı adı yoktur; profil oluşturmaya çalışmak (kısıt hatası) misafir
-- girişini engellerdi. Misafir için profil satırı oluşmaz (F19d).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_username text := lower(trim(new.raw_user_meta_data ->> 'username'));
begin
  if new.is_anonymous then
    return new;
  end if;
  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    new_username,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), new_username)
  );
  return new;
end;
$$;
