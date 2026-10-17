-- F9(a): 12 tepki.
begin;
create extension if not exists pgtap with schema extensions;

select plan(2);

select is(
  (select count(*)::int from unnest(enum_range(null::public.reaction_emoji))),
  12, 'reaction_emoji 12 değer içerir'
);
select is(
  (enum_range(null::public.reaction_emoji))[7:12]::text[],
  array['mindblown', 'scared', 'epic', 'thoughtful', 'touched', 'tense'],
  'yeni tepkiler eski 6 değerin ardından gelir'
);

select * from finish();

rollback;
