-- F6(b): get_watchlist sıradaki bölümün adını döner.
begin;
create extension if not exists pgtap with schema extensions;

select plan(1);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local',
        '{"username": "ayse_1"}');
insert into public.shows (id, name) values (1, 'Bir');
insert into public.episodes (id, show_id, season_number, episode_number, name, air_date)
values (11, 1, 1, 1, 'Pilot', current_date - 1);
insert into public.user_shows (user_id, show_id) values ('11111111-1111-1111-1111-111111111111', 1);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
select is((select next_episode_name from public.get_watchlist()), 'Pilot', 'sıradaki bölümün adı');
reset role;

select * from finish();

rollback;
