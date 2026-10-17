-- F6(b): get_watchlist sıradaki bölümün sahne görselini ve dizinin arka planını döner.
begin;
create extension if not exists pgtap with schema extensions;

select plan(2);

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'a@test.local',
        '{"username": "ayse_1"}');
insert into public.shows (id, name, backdrop_path) values (1, 'Bir', '/arka.jpg');
insert into public.episodes (id, show_id, season_number, episode_number, name, air_date, still_path)
values (11, 1, 1, 1, 'Pilot', current_date - 1, '/sahne.jpg');
insert into public.user_shows (user_id, show_id) values ('11111111-1111-1111-1111-111111111111', 1);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
select is((select next_still_path from public.get_watchlist()), '/sahne.jpg', 'sıradaki bölümün sahne görseli');
select is((select backdrop_path from public.get_watchlist()), '/arka.jpg', 'dizinin arka planı');
reset role;

select * from finish();

rollback;
