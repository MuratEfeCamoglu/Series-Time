-- Aşama 0 duman testi: pgTAP altyapısının ve public şemanın çalıştığını doğrular.
-- Gerçek tablo/RLS testleri Aşama 1'den itibaren eklenir.
begin;
create extension if not exists pgtap with schema extensions;

select plan(1);
select has_schema('public', 'public şeması mevcut');
select * from finish();

rollback;
