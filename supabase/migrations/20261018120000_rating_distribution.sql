-- F8(l): profildeki Puanlar grafiği — kullanıcının bölümlere verdiği puanların dağılımı
-- (kullanıcı kararı 2026-10-18). Puanlar herkese açıktır (V10).
create function public.get_rating_distribution(user_id uuid)
returns table (rating numeric, rating_count integer)
language sql
stable
security invoker
set search_path = ''
as $$
  select r.rating, count(*)::integer
  from public.episode_ratings r
  where r.user_id = get_rating_distribution.user_id
  group by r.rating
  order by r.rating;
$$;
revoke execute on function public.get_rating_distribution(uuid) from public, anon;
grant execute on function public.get_rating_distribution(uuid) to authenticated;
