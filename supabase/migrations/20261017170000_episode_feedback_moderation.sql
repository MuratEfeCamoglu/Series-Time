-- Aşama 5: bölüm sonrası (F9 tepki, F10 bölümün yıldızı, F11 yorum) ve moderasyon (F15).
-- ISKELET.md §3.3; follows tablosu Aşama 6'da gelir, engellemenin takip etkisi orada eklenir.

create type public.reaction_emoji as enum ('funny', 'love', 'shocked', 'sad', 'angry', 'bored');
create type public.report_target as enum ('comment', 'profile');
create type public.report_reason as enum ('spam', 'harassment', 'spoiler', 'inappropriate', 'other');
create type public.report_status as enum ('open', 'resolved');

-- F9: bölüm başına kullanıcı başına tek tepki.
create table public.reactions (
  user_id uuid not null references auth.users on delete cascade,
  episode_id integer not null references public.episodes on delete cascade,
  emoji public.reaction_emoji not null,
  created_at timestamptz not null default now(),
  primary key (user_id, episode_id)
);

-- F10: bölüm başına kullanıcı başına tek oy. Kadro satırları yenilenirken silinip yeniden
-- yazıldığı için episode_credits'e yabancı anahtar verilmez; oylar kaybolmasın.
create table public.star_votes (
  user_id uuid not null references auth.users on delete cascade,
  episode_id integer not null references public.episodes on delete cascade,
  person_id integer not null,
  created_at timestamptz not null default now(),
  primary key (user_id, episode_id)
);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  episode_id integer not null references public.episodes on delete cascade,
  body text not null
    constraint comments_body_length check (char_length(btrim(body)) between 1 and 500),
  is_spoiler boolean not null default false,
  -- Yönetici panelden doldurur (F15e); dolu yorum kimseye gösterilmez.
  hidden_at timestamptz,
  created_at timestamptz not null default now()
);

create index comments_episode_created_idx on public.comments (episode_id, created_at desc);
create index comments_user_created_idx on public.comments (user_id, created_at desc);

create table public.comment_likes (
  user_id uuid not null references auth.users on delete cascade,
  comment_id uuid not null references public.comments on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, comment_id)
);

create table public.blocks (
  blocker_id uuid not null references auth.users on delete cascade,
  blocked_id uuid not null references auth.users on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_not_self check (blocker_id <> blocked_id)
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users on delete cascade,
  target_type public.report_target not null,
  target_id text not null,
  reason public.report_reason not null,
  note text constraint reports_note_length check (char_length(note) <= 300),
  status public.report_status not null default 'open',
  created_at timestamptz not null default now(),
  -- Aynı içeriği ikinci kez şikayet etmek yeni satır açmaz.
  unique (reporter_id, target_type, target_id)
);

create table public.banned_words (
  word text primary key
);

alter table public.reactions enable row level security;
alter table public.star_votes enable row level security;
alter table public.comments enable row level security;
alter table public.comment_likes enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;
-- banned_words: istemci erişimi yok (politika yazılmaz).
alter table public.banned_words enable row level security;

-- Oturum sahibine bu yorum gösterilmez mi? Engellediği kişinin yorumu (F15b) veya kendi
-- şikayet ettiği yorum (F15a). reports istemciye kapalı olduğu için security definer.
create function public.is_comment_hidden_for_viewer(comment_id uuid, author_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
      select 1 from public.blocks b
      where b.blocker_id = auth.uid() and b.blocked_id = author_id
    )
    or exists (
      select 1 from public.reports r
      where r.reporter_id = auth.uid()
        and r.target_type = 'comment'
        and r.target_id = comment_id::text
    );
$$;

create policy "reactions_select_authenticated" on public.reactions for select to authenticated using (true);
create policy "reactions_insert_own" on public.reactions for insert to authenticated with check (auth.uid() = user_id);
create policy "reactions_update_own" on public.reactions for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "reactions_delete_own" on public.reactions for delete to authenticated using (auth.uid() = user_id);

create policy "star_votes_select_authenticated" on public.star_votes for select to authenticated using (true);
create policy "star_votes_insert_own" on public.star_votes for insert to authenticated with check (auth.uid() = user_id);
create policy "star_votes_update_own" on public.star_votes for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "star_votes_delete_own" on public.star_votes for delete to authenticated using (auth.uid() = user_id);

create policy "comments_select_visible" on public.comments for select to authenticated
  using (hidden_at is null and not public.is_comment_hidden_for_viewer(id, user_id));
create policy "comments_insert_own" on public.comments for insert to authenticated
  with check (auth.uid() = user_id and hidden_at is null);
create policy "comments_delete_own" on public.comments for delete to authenticated using (auth.uid() = user_id);

create policy "comment_likes_select_authenticated" on public.comment_likes for select to authenticated using (true);
-- F11(e): yalnızca başkalarının yorumu beğenilir.
create policy "comment_likes_insert_own" on public.comment_likes for insert to authenticated
  with check (
    auth.uid() = user_id
    and not exists (select 1 from public.comments c where c.id = comment_id and c.user_id = auth.uid())
  );
create policy "comment_likes_delete_own" on public.comment_likes for delete to authenticated using (auth.uid() = user_id);

create policy "blocks_select_own" on public.blocks for select to authenticated using (auth.uid() = blocker_id);
create policy "blocks_insert_own" on public.blocks for insert to authenticated with check (auth.uid() = blocker_id);
create policy "blocks_delete_own" on public.blocks for delete to authenticated using (auth.uid() = blocker_id);

create policy "reports_insert_own" on public.reports for insert to authenticated
  with check (auth.uid() = reporter_id and status = 'open');

-- F15(d): büyük/küçük harf duyarsız, Türkçe karakterler ASCII'ye indirgenmiş metin.
-- `lower()` 'İ' harfini sunucu yereline göre farklı çevirebildiği için önce elle eşlenir.
create function public.normalize_text(input text)
returns text
language sql
immutable
set search_path = ''
as $$
  select translate(lower(translate(input, 'İIÇĞÖŞÜÂÎÛ', 'iıçğöşüâîû')), 'çğıöşüâîû', 'cgiosuaiu');
$$;

-- F11(f) hız sınırı ve F15(d) kelime filtresi. banned_words istemciye kapalı: security definer.
create function public.before_comment_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized text := public.normalize_text(new.body);
begin
  if (
    select count(*) from public.comments c
    where c.user_id = new.user_id and c.created_at > now() - interval '1 minute'
  ) >= 5 then
    raise exception 'comment_rate_limited' using errcode = 'P0001', hint = 'F11f';
  end if;

  -- Kelime sınırıyla eşleşir: "ama" yasaklıysa "amaç" reddedilmez.
  if exists (
    select 1 from public.banned_words w
    where normalized ~ ('\m' || w.word || '\M')
  ) then
    raise exception 'comment_banned_word' using errcode = 'P0001', hint = 'F15d';
  end if;

  new.body := btrim(new.body);
  return new;
end;
$$;

create trigger comments_before_insert
  before insert on public.comments
  for each row execute function public.before_comment_insert();

-- Yasaklı kelimeler de aynı biçimde saklanır.
create function public.before_banned_word_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.word := public.normalize_text(btrim(new.word));
  return new;
end;
$$;

create trigger banned_words_normalize
  before insert or update on public.banned_words
  for each row execute function public.before_banned_word_write();

-- F9(c): tepki dağılımı (yüzdeler istemcide, toplam 100'e yuvarlanarak).
create function public.get_episode_reaction_stats(episode_id integer)
returns table (emoji public.reaction_emoji, count integer)
language sql
stable
security invoker
set search_path = ''
as $$
  select r.emoji, count(*)::integer
  from public.reactions r
  where r.episode_id = get_episode_reaction_stats.episode_id
  group by r.emoji;
$$;

-- F10(c): en çok oy alan 5 kişi ve toplam oy.
create function public.get_episode_star_stats(episode_id integer)
returns table (person_id integer, name text, "character" text, profile_path text, votes integer, total_votes integer)
language sql
stable
security invoker
set search_path = ''
as $$
  with tally as (
    select v.person_id, count(*)::integer as votes
    from public.star_votes v
    where v.episode_id = get_episode_star_stats.episode_id
    group by v.person_id
  )
  select t.person_id, c.name, c.character, c.profile_path, t.votes,
         (select coalesce(sum(t2.votes), 0)::integer from tally t2)
  from tally t
  left join public.episode_credits c
    on c.episode_id = get_episode_star_stats.episode_id and c.person_id = t.person_id
  order by t.votes desc, c."order" nulls last
  limit 5;
$$;

-- F11(d): en yeniden eskiye, [before] öncesindeki [lim] yorum. RLS (gizli, engellenen,
-- şikayet edilen) security invoker ile uygulanır.
create function public.get_episode_comments(
  episode_id integer,
  before timestamptz default null,
  lim integer default 20
)
returns table (
  id uuid,
  user_id uuid,
  username text,
  display_name text,
  avatar_path text,
  body text,
  is_spoiler boolean,
  created_at timestamptz,
  like_count integer,
  liked_by_me boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  select c.id, c.user_id, p.username, p.display_name, p.avatar_path, c.body, c.is_spoiler,
         c.created_at,
         (select count(*)::integer from public.comment_likes l where l.comment_id = c.id),
         exists (select 1 from public.comment_likes l where l.comment_id = c.id and l.user_id = auth.uid())
  from public.comments c
  join public.profiles p on p.id = c.user_id
  where c.episode_id = get_episode_comments.episode_id
    and (get_episode_comments.before is null or c.created_at < get_episode_comments.before)
  order by c.created_at desc
  limit least(get_episode_comments.lim, 50);
$$;

revoke execute on function public.get_episode_reaction_stats(integer) from public, anon;
revoke execute on function public.get_episode_star_stats(integer) from public, anon;
revoke execute on function public.get_episode_comments(integer, timestamptz, integer) from public, anon;
revoke execute on function public.is_comment_hidden_for_viewer(uuid, uuid) from public, anon;
grant execute on function public.get_episode_reaction_stats(integer) to authenticated;
grant execute on function public.get_episode_star_stats(integer) to authenticated;
grant execute on function public.get_episode_comments(integer, timestamptz, integer) to authenticated;
grant execute on function public.is_comment_hidden_for_viewer(uuid, uuid) to authenticated;

-- Başlangıç listesi; yönetici Supabase panelinden genişletir (V17). Değerler tetikleyiciyle
-- normalize edilir.
insert into public.banned_words (word) values
  ('amk'), ('aq'), ('orospu'), ('piç'), ('siktir'), ('sikerim'), ('yarrak'), ('ibne'),
  ('pezevenk'), ('kahpe'), ('amcık'), ('götveren');
