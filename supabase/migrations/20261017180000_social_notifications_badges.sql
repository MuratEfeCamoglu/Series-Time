-- Aşama 6: takip (F12), uygulama içi bildirimler (F13), rozetler (F14) ve engellemenin
-- takibe etkisi (F15b) — ISKELET.md §3.3.

create type public.notification_type as enum ('new_follower', 'comment_liked', 'badge_earned');

create table public.follows (
  follower_id uuid not null references auth.users on delete cascade,
  followee_id uuid not null references auth.users on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id),
  -- F12(d): kişi kendini takip edemez.
  constraint follows_not_self check (follower_id <> followee_id)
);

create index follows_followee_idx on public.follows (followee_id, created_at desc);

create table public.badges (
  code text primary key,
  name text not null,
  description text not null,
  -- Uygulamadaki yerel varlık adı (V16: özgün çizim).
  icon text not null
);

create table public.user_badges (
  user_id uuid not null references auth.users on delete cascade,
  badge_code text not null references public.badges on delete cascade,
  earned_at timestamptz not null default now(),
  primary key (user_id, badge_code)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  type public.notification_type not null,
  actor_id uuid references auth.users on delete cascade,
  entity_id text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_user_created_idx on public.notifications (user_id, created_at desc);

alter table public.follows enable row level security;
alter table public.badges enable row level security;
alter table public.user_badges enable row level security;
alter table public.notifications enable row level security;

-- İki kişi arasında herhangi bir yönde engel var mı? blocks yalnızca sahibine açık olduğu
-- için karşı yönü görmek security definer gerektirir.
create function public.is_blocked_between(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.blocks
    where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a)
  );
$$;

revoke execute on function public.is_blocked_between(uuid, uuid) from public, anon;
grant execute on function public.is_blocked_between(uuid, uuid) to authenticated;

create policy "follows_select_authenticated" on public.follows for select to authenticated using (true);
-- F15(b): engellenen engelleyeni (ve engelleyen engelleneni) takip edemez.
create policy "follows_insert_own" on public.follows for insert to authenticated
  with check (auth.uid() = follower_id and not public.is_blocked_between(follower_id, followee_id));
create policy "follows_delete_own" on public.follows for delete to authenticated using (auth.uid() = follower_id);

create policy "badges_select_all" on public.badges for select to anon, authenticated using (true);
create policy "user_badges_select_authenticated" on public.user_badges for select to authenticated using (true);

create policy "notifications_select_own" on public.notifications for select to authenticated
  using (auth.uid() = user_id);
-- Yalnızca okundu işareti (kolon yetkisi read_at ile sınırlı).
create policy "notifications_update_own" on public.notifications for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
revoke update on public.notifications from authenticated;
grant update (read_at) on public.notifications to authenticated;

-- F15(b): engelleyince iki yönlü takip ilişkisi silinir.
create function public.after_block_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.follows f
  where (f.follower_id = new.blocker_id and f.followee_id = new.blocked_id)
     or (f.follower_id = new.blocked_id and f.followee_id = new.blocker_id);
  return new;
end;
$$;

create trigger blocks_after_insert
  after insert on public.blocks
  for each row execute function public.after_block_insert();

-- F13(a, b): yeni takipçi bildirimi.
create function public.after_follow_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.notifications (user_id, type, actor_id)
  values (new.followee_id, 'new_follower', new.follower_id);
  return new;
end;
$$;

create trigger follows_after_insert
  after insert on public.follows
  for each row execute function public.after_follow_insert();

-- F13(a, b): yorum beğenildi bildirimi. Yorum metni bildirime yazılmaz (R7); yalnızca kimliği.
create function public.after_comment_like_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  author uuid;
begin
  select c.user_id into author from public.comments c where c.id = new.comment_id;
  if author is not null and author <> new.user_id then
    insert into public.notifications (user_id, type, actor_id, entity_id)
    values (author, 'comment_liked', new.user_id, new.comment_id::text);
  end if;
  return new;
end;
$$;

create trigger comment_likes_after_insert
  after insert on public.comment_likes
  for each row execute function public.after_comment_like_insert();

-- F14: rozet bir kez verilir; koşul sonradan bozulsa da geri alınmaz. Yeni verilen rozet
-- için bildirim (F13a).
create function public.award_badge(target_user uuid, badge text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.user_badges (user_id, badge_code)
  values (target_user, badge)
  on conflict do nothing;
  if found then
    insert into public.notifications (user_id, type, entity_id)
    values (target_user, 'badge_earned', badge);
  end if;
end;
$$;

-- İstemci rozet veremez; yalnızca tetikleyiciler çağırır.
revoke execute on function public.award_badge(uuid, text) from public, anon, authenticated;

create function public.after_watched_episode_badges()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  watched integer;
begin
  select count(*) into watched from public.watched_episodes w where w.user_id = new.user_id;
  if watched >= 1 then perform public.award_badge(new.user_id, 'first_episode'); end if;
  if watched >= 100 then perform public.award_badge(new.user_id, 'episodes_100'); end if;
  if watched >= 1000 then perform public.award_badge(new.user_id, 'episodes_1000'); end if;
  return new;
end;
$$;

create trigger watched_episodes_badges
  after insert on public.watched_episodes
  for each row execute function public.after_watched_episode_badges();

create function public.after_user_show_badges()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select count(*) from public.user_shows us where us.user_id = new.user_id) >= 10 then
    perform public.award_badge(new.user_id, 'shows_10');
  end if;
  return new;
end;
$$;

create trigger user_shows_badges
  after insert on public.user_shows
  for each row execute function public.after_user_show_badges();

create function public.after_comment_badges()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.award_badge(new.user_id, 'first_comment');
  return new;
end;
$$;

create trigger comments_badges
  after insert on public.comments
  for each row execute function public.after_comment_badges();

-- F8(f): takipçi, takip edilen ve rozet sayıları.
create function public.get_profile_counts(user_id uuid)
returns table (followers integer, following integer, badges integer)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    (select count(*)::integer from public.follows f where f.followee_id = get_profile_counts.user_id),
    (select count(*)::integer from public.follows f where f.follower_id = get_profile_counts.user_id),
    (select count(*)::integer from public.user_badges b where b.user_id = get_profile_counts.user_id);
$$;

-- F12(c): takipçi / takip edilen listeleri, 30'arlı sayfalar, en yeni takip önce.
-- Oturum sahibinin engellediği kişiler listelenmez (§3.4).
create function public.get_follow_list(user_id uuid, list text, page_offset integer default 0)
returns table (id uuid, username text, display_name text, avatar_path text, followed_at timestamptz)
language sql
stable
security invoker
set search_path = ''
as $$
  select p.id, p.username, p.display_name, p.avatar_path, f.created_at
  from public.follows f
  join public.profiles p
    on p.id = case when get_follow_list.list = 'followers' then f.follower_id else f.followee_id end
  where case when get_follow_list.list = 'followers' then f.followee_id else f.follower_id end
        = get_follow_list.user_id
    and not exists (
      select 1 from public.blocks b where b.blocker_id = auth.uid() and b.blocked_id = p.id
    )
  order by f.created_at desc, p.username
  limit 30 offset greatest(get_follow_list.page_offset, 0);
$$;

-- F13(d): son 90 gün, en yeniden eskiye; ad, rozet adı ve beğenilen yorumun bölümü eklenir.
create function public.get_notifications()
returns table (
  id uuid,
  type public.notification_type,
  actor_id uuid,
  actor_username text,
  actor_display_name text,
  actor_avatar_path text,
  entity_id text,
  badge_name text,
  episode_id integer,
  read_at timestamptz,
  created_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select n.id, n.type, n.actor_id, p.username, p.display_name, p.avatar_path, n.entity_id,
         b.name, c.episode_id, n.read_at, n.created_at
  from public.notifications n
  left join public.profiles p on p.id = n.actor_id
  left join public.badges b on n.type = 'badge_earned' and b.code = n.entity_id
  left join public.comments c on n.type = 'comment_liked' and c.id::text = n.entity_id
  where n.user_id = auth.uid()
    and n.created_at > now() - interval '90 days'
  order by n.created_at desc
  limit 200;
$$;

-- F13(c): zil ekranı açılınca hepsi okundu.
create function public.mark_notifications_read()
returns void
language sql
security invoker
set search_path = ''
as $$
  update public.notifications set read_at = now()
  where user_id = auth.uid() and read_at is null;
$$;

revoke execute on function public.get_profile_counts(uuid) from public, anon;
revoke execute on function public.get_follow_list(uuid, text, integer) from public, anon;
revoke execute on function public.get_notifications() from public, anon;
revoke execute on function public.mark_notifications_read() from public, anon;
grant execute on function public.get_profile_counts(uuid) to authenticated;
grant execute on function public.get_follow_list(uuid, text, integer) to authenticated;
grant execute on function public.get_notifications() to authenticated;
grant execute on function public.mark_notifications_read() to authenticated;

-- F14: 5 rozet (V16).
insert into public.badges (code, name, description, icon) values
  ('first_episode', 'İlk Bölüm', 'İlk bölümünü izlendi olarak işaretle.', 'badge_first_episode'),
  ('episodes_100', 'Dizi Kurdu', '100 bölüm izle.', 'badge_episodes_100'),
  ('episodes_1000', 'Maraton Ustası', '1.000 bölüm izle.', 'badge_episodes_1000'),
  ('shows_10', 'Koleksiyoncu', 'Listene 10 dizi ekle.', 'badge_shows_10'),
  ('first_comment', 'İlk Söz', 'İlk yorumunu yaz.', 'badge_first_comment');
