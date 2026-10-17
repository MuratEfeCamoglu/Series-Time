# Sezonluk

## Proje
Yalnızca dizi takip eden, TV Time arayüzüne benzeyen iOS/Android uygulaması: dizi ekleme, bölüm işaretleme,
istatistikler, kategoriye göre dizi önerileri, bölüm sonrası tepki/oylama/yorum ve takipçi sistemi. "Sezonluk" geçici addır.
TV Time adı, logosu, ikonları ve görselleri hiçbir yerde kullanılmaz.

- Kapsam, kabul kriterleri (F1–F18), veri modeli, `tmdb-proxy` sözleşmesi (§3.5), aşamalar: @ISKELET.md
- Agent rolü, yetkiler, yasaklar, "bitti" tanımı: @AGENT.md

## Teknoloji Yığını
- İstemci: Flutter (stable kanal) + Dart 3, null safety, yalnızca Android ve iOS hedefleri.
- Durum: `flutter_riverpod` (Notifier/AsyncNotifier, kod üretimi yok). Gezinme: `go_router`.
- Arka uç: Supabase — Auth, Postgres (RLS), Storage, Edge Functions (Deno/TypeScript), pg_cron. İstemci: `supabase_flutter`.
- Dış veri: TMDB API v3, yalnızca `supabase/functions/tmdb-proxy` üzerinden.
- Onaysız kullanılabilecek paketler (`flutter pub add`): flutter_riverpod, go_router, supabase_flutter,
  cached_network_image, image_picker, shared_preferences, share_plus, url_launcher, intl, flutter_localizations (sdk);
  dev: flutter_test (sdk), flutter_lints, mocktail. Edge Function'larda: `npm:zod`, `jsr:@supabase/supabase-js`.
  Bunların dışındaki her paket onay gerektirir (AGENT.md).
- Test: `flutter test` (birim + widget), pgTAP (`supabase test db`), Maestro (e2e, Aşama 7).
- Lint/format: `flutter analyze` (flutter_lints) + `dart format`.
- Build/dağıtım: Android yerelde `flutter build appbundle`; iOS ve mağaza yüklemeleri Codemagic (`codemagic.yaml`).

## Gerekli Araçlar (kullanıcı kurar)
Flutter SDK (stable), Android Studio + Android emülatörü, Docker Desktop, Supabase CLI (`scoop install supabase`),
Maestro CLI (yalnızca Aşama 7). Node.js gerekmez.

## Komutlar
| Amaç | Komut |
|---|---|
| Bağımlılıkları kur | `flutter pub get` |
| Yerel Supabase başlat (Docker açık olmalı) | `supabase start` |
| Şema + seed'i sıfırdan uygula | `supabase db reset` |
| Edge Function'ları yerelde çalıştır | `supabase functions serve --env-file supabase/.env.local` |
| Uygulamayı çalıştır | `flutter run --dart-define-from-file=env/dev.json` |
| Performans ölçümü | `flutter run --profile --dart-define-from-file=env/dev.json` |
| Yerelleştirme dosyalarını üret | `flutter gen-l10n` (`flutter pub get`/`run` sırasında da otomatik) |
| Lint | `flutter analyze` |
| Format | `dart format .` |
| Birim + widget testleri | `flutter test` |
| Veritabanı testleri (önce `supabase start`) | `supabase test db` |
| **Tüm doğrulama** | `dart run tool/verify.dart` (= `flutter analyze` → `dart format --output=none --set-exit-if-changed .` → `flutter test`; ilk hatada durur) |
| Anahtar sızıntısı kontrolü | `git grep -n TMDB_API_KEY -- lib env android ios` (boş dönmeli) |
| Android release build | `flutter build appbundle --release --dart-define-from-file=env/prod.json` |
| iOS build + TestFlight | Codemagic `ios-release` iş akışı (yalnızca onayla, AGENT.md) |
| E2E duman testi | `maestro test e2e/` |

`tool/verify.dart` Aşama 0'da yazılır; PowerShell 5.1 `&&` desteklemediği için zincirleme komut yerine bu betik kullanılır.

## Ortam Değişkenleri
- `env/dev.json` ve `env/prod.json` (commit edilmez; şablon `env/example.json`): `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
  `LEGAL_PRIVACY_URL`, `LEGAL_TERMS_URL`. Kodda yalnızca `lib/core/config.dart` içinden `String.fromEnvironment` ile okunur.
- `--dart-define` değerleri uygulama ikilisine gömülür: buraya asla gizli anahtar konmaz.
- `supabase/.env.local` (yerel fonksiyonlar, commit edilmez): `TMDB_API_KEY` (TMDB v3 "API Read Access Token").
- Uzak ortamda sırlar `supabase secrets set` ile girilir — yalnızca kullanıcı onayıyla ve değeri kullanıcı yazar.
- Android emülatörden yerel Supabase'e `http://10.0.2.2:54321` ile erişilir (`localhost` değil); `env/dev.json` buna göre yazılır.

## Kod Kuralları
- Klasör yapısı ISKELET.md §4 ile birebir aynıdır. §4'te olmayan üst düzey klasör veya `lib/` altında yeni ana klasör
  açılmaz (özellik klasörlerinin içindeki `data/`, `screens/`, `widgets/` serbesttir).
- Özellik klasörü düzeni: `data/repository.dart` (Supabase çağrıları), `data/models.dart` (elle yazılmış
  `fromJson`/`toJson`), `logic.dart` (saf fonksiyonlar), `providers.dart` (Riverpod), `screens/`, `widgets/`.
- `logic.dart` Flutter, Riverpod veya Supabase import etmez; her `logic.dart` için `test/features/<özellik>/logic_test.dart` vardır.
- Her `models.dart` sınıfının `fromJson`'u, ISKELET.md §3.3 kolon adlarıyla örnek JSON üzerinden test edilir.
- Widget testlerinde repository'ler `mocktail` ile taklit edilir ve provider'lar `ProviderScope(overrides: ...)` ile
  değiştirilir; testler gerçek ağa veya Supabase'e bağlanmaz.
- İsimlendirme: dosyalar `snake_case.dart`, sınıflar `PascalCase`, provider'lar `camelCaseProvider`,
  ekranlar `XxxScreen`, SQL tablo/kolon `snake_case`, migration `YYYYMMDDHHMMSS_kisa_aciklama.sql`.
- Veritabanı adları ISKELET.md §3.3 ile aynıdır; özellik kodları (F1…) commit ve PR başlıklarında kullanılır.
- Rotalar yalnızca `lib/app/router.dart` içinde tanımlanır; yollar: `/shows`, `/discover`, `/profile`, `/show/:id`,
  `/show/:id/season/:season`, `/episode/:id`, `/user/:username` (+ `/followers`, `/following`, `/shows`),
  `/suggest`, `/badges`, `/notifications`, `/settings/...`, `/sign-in`, `/sign-up`, `/forgot-password`, `/reset-password`.
- Renk, boşluk, yazı stili yalnızca `lib/theme/*` üzerinden; widget'ta `Color(0x...)` veya sabit sayı stil yazılmaz.
- Kullanıcıya görünen her metin `lib/l10n/app_tr.arb` içinde, `AppLocalizations.of(context)` ile kullanılır.
- `dynamic` yalnızca `fromJson`'a gelen `Map<String, dynamic>` için kabul edilir; başka yerde kullanılmaz.
- Hata yönetimi: repository Supabase/ağ hatasını `AppFailure` (`lib/core/failures.dart`) olarak fırlatır; ekranlar
  `AsyncValue.when` ile `ErrorView` + "Tekrar dene" gösterir. Hatalar sessizce yutulmaz.
- Mutasyonlar (işaretleme, takip, beğeni, tepki) iyimser güncellenir; hata olursa önceki state'e dönülür ve SnackBar gösterilir.
- Uzun listeler `ListView.builder`/`GridView.builder`/sliver'larla; görseller `CachedNetworkImage` + `lib/core/tmdb_image.dart`.
- Mümkün olan her widget `const`; `build` içinde ağ çağrısı yapılmaz.
- Yorumlar yalnızca "neden"i açıklamak için yazılır.
- Veritabanı şeması yalnızca yeni migration ile değişir; uygulanmış migration düzenlenmez.
- Her yeni tabloda aynı migration içinde RLS açılır ve politikaları yazılır; `supabase/tests/` altına pgTAP testi eklenir.
- Edge Function'lar TypeScript (Deno); gövde `zod` ile doğrulanır; sırlar `Deno.env.get` ile okunur.

## Çalışma Kuralları
- Göreve başlamadan ilgili F-kodunun kabul kriterini ISKELET.md §2.1'den oku.
- Her değişiklikten sonra `dart run tool/verify.dart`; SQL değiştiyse ayrıca `supabase db reset` ve `supabase test db`.
- Kapsam dışı (ISKELET.md §2.3) veya "Sonraki Sürümler" (§2.2) maddesi gerekiyor gibi görünürse uygulama, rapora yaz.
- Dal: `feat/F<no>-kisa-ad`, `fix/kisa-ad`. Commit: Conventional Commits, ör. `feat(F5): buraya kadar izledim`.
- ISKELET.md ile çelişen bir karar gerekiyorsa önce ISKELET.md'nin güncellenmesi için onay iste (AGENT.md).

## Önemli Notlar
- Aşama 0 kurulumu depo kökünde: `flutter create --org com.sezonluk --project-name sezonluk --platforms android,ios .`
  Ardından örnek sayaç kodu silinir; Android `applicationId` ve iOS bundle id `com.sezonluk.app` yapılır.
- Derin bağlantı şeması `sezonluk://`: Android `AndroidManifest.xml` intent-filter ve iOS `Info.plist` `CFBundleURLTypes`
  içine eklenir; Supabase Auth "Redirect URLs" listesine `sezonluk://reset-password` eklenir
  (yerelde `supabase/config.toml` → `additional_redirect_urls`). `supabase_flutter` auth bağlantılarını kendisi yakalar.
- `pubspec.yaml` içinde `flutter: generate: true`; `l10n.yaml`: `arb-dir: lib/l10n`, `template-arb-file: app_tr.arb`,
  `output-localization-file: app_localizations.dart`.
- Yayınlanmış bölüm = `air_date <= bugün (UTC)` ve `season_number > 0`. Sezon 0 ilerleme/istatistiğe girmez.
- TMDB görsel URL'si: `https://image.tmdb.org/t/p/<boyut><path>`; listede `w342`, detayda `w780`. TMDB atfı F17'de zorunlu.
- Spoiler kuralı: izlenmemiş bölümün yorumları gizli başlar; bildirimlerde ve listelerde yorum metni gösterilmez.
- Yerel e-postalar (doğrulama, şifre sıfırlama) Supabase'in yerel posta arayüzünde görünür (`supabase status` adresi verir).
- `seed.sql` iki test kullanıcısı içerir; bu hesapların bilgileri yalnızca seed dosyasındadır, başka yere yazılmaz.
- `.gitignore` en az: `build/`, `.dart_tool/`, `env/dev.json`, `env/prod.json`, `supabase/.env.local`, `*.jks`, `key.properties`.
- Geliştirme Windows'ta: iOS yerelde derlenemez ve simülatör yoktur; günlük test Android emülatörde, iOS kontrolü
  aşama sonlarında Codemagic + TestFlight ile yapılır (ISKELET.md R8).
