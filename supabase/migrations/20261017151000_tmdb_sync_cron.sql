-- tmdb-sync'i her gün 03:00 UTC'de çağırır (ISKELET.md §3.2).
-- Proje adresi ve service role anahtarı migration'a yazılmaz; Vault'tan okunur. İki sır
-- (`project_url`, `service_role_key`) proje açıldıktan sonra panelden elle eklenir
-- (Database → Vault). Sırlar yokken iş çalışır ama isteği gönderemez.
create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;

select cron.schedule(
  'tmdb-sync-daily',
  '0 3 * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
      || '/functions/v1/tmdb-sync',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 150000
  )
  where exists (select 1 from vault.decrypted_secrets where name = 'project_url');
  $$
);
