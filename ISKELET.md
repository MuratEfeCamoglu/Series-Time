# Sezonluk — Proje İskeleti ve Sınırları

> "Sezonluk" geçici çalışma adıdır (bkz. V2). Bu dosya projenin tek doğruluk kaynağıdır; CLAUDE.md ve AGENT.md buraya dayanır.
> Bölüm numaraları (§) ve özellik kodları (F1…F19) diğer dosyalarda bu adlarla anılır.

## 1. Amaç ve Hedef Kullanıcı

- **Sorun:** TV Time kapandı. Kullanıcılar izledikleri dizileri, sıradaki bölümü ve yaklaşan yayınları tek yerden takip edebilecekleri, TV Time'a alışık oldukları arayüze benzeyen bir uygulamaya ihtiyaç duyuyor.
- **Ürün:** Yalnızca **dizi** takip eden, iOS ve Android mağazalarında herkese açık bir mobil uygulama. Görünüm ve akış TV Time'a olabildiğince yakın; ancak TV Time adı, logosu, ikonları ve görselleri **kullanılmaz** (marka hakları).
- **Hedef kullanıcı:** Haftada en az bir dizi bölümü izleyen, eski TV Time kullanıcıları ve dizi takibi yapan 16+ yaş Türkçe konuşan kullanıcılar.
- **Başlangıç ölçeği:** İlk 6 ayda ≤ 1.000 kayıtlı kullanıcı, ≤ 200 günlük aktif kullanıcı (bkz. V6). Gelir modeli yok.
- **Başarı ölçütleri (MVP yayından 60 gün sonra ölçülür):**
  - Yeni kullanıcı kayıt + ilk dizi ekleme + ilk bölüm işaretlemeyi **≤ 2 dakikada** tamamlayabilir (5 kişilik kullanılabilirlik testinde en az 4 kişi).
  - Bir bölümü işaretleme, Diziler sekmesinden **tek dokunuşla** yapılabilir.
  - Mağaza puanı ≥ 4.0 (en az 20 değerlendirme varsa).
  - Çökme oranı: çökmesiz oturum oranı ≥ %99 (App Store Connect ve Play Console verisi).

## 2. Kapsam

### 2.1 Kapsam İçi (MVP)

Tüm özellikler "Zorunlu"dur; kullanıcı ilk sürümde hepsini istemiştir. "Aşama" sütunu, özelliğin §6'daki hangi aşamada inşa edildiğini gösterir. Bir özelliğin başka aşamaya bağlı alt maddesi varsa §6 tablosunda belirtilmiştir.

| # | Özellik | Aşama | Kabul Kriteri (hepsi sağlanmalı) |
|---|---|---|---|
| F1 | **Hesap**: e-posta+şifre ile kayıt, e-posta doğrulama, giriş, çıkış, şifre sıfırlama | 1 | (a) Kayıtta kullanıcı adı `^[a-z0-9_]{3,20}$` kuralına uyar ve benzersizdir; aynı ad ikinci kez alınamaz. (b) Şifre ≥ 8 karakter. (c) Doğrulanmamış e-posta ile giriş yapılamaz, "e-postanı doğrula" mesajı görünür. (d) Uygulama kapatılıp açıldığında oturum korunur. (e) Şifre sıfırlama e-postası ≤ 60 sn içinde gelir (geliştirme projesinde gerçek gelen kutusuna); e-postadaki bağlantı `sezonluk://reset-password` ekranını açar ve yeni şifre orada belirlenir. (f) Kayıt ekranında Kullanım Şartları ve Gizlilik Politikası onay kutusu işaretlenmeden "Kayıt ol" düğmesi pasiftir; bağlantılar `lib/core/config.dart` içindeki `legalPrivacyUrl` ve `legalTermsUrl` adreslerini `url_launcher` ile açar (metinler `docs/` altında, bkz. F17). |
| F2 | **Profil düzenleme** ("Düzenle" düğmesi) | 1 | Kullanıcı görünen ad (1–40 karakter), kullanıcı adı, ülke (ISO-3166 listesinden; bayrak emoji olarak gösterilir), biyografi (≤ 160 karakter), avatar ve kapak görselini değiştirebilir. Avatar: galeriden ya da herhangi bir dizinin (listeden veya aramayla) TMDB arka plan ve afiş görsellerinden seçilir, kare kırpma ekranında yakınlaştırılıp kaydırılarak kırpılır ve 512×512 PNG (≤ 2 MB) olarak Storage'a yüklenir (oyuncu portresi seçeneği yok; daha önce seçilmiş `tmdb:<yol>` avatarlar gösterilmeye devam eder). Kapak: herhangi bir dizinin (listeden veya aramayla) TMDB arka plan görsellerinden biri seçilir (`profiles.cover_path`, `tmdb-proxy` `show_images`; yükleme yok, bkz. V9; kullanıcı kararı 2026-10-17). İsteğe bağlı Letterboxd ve Instagram profil bağlantıları: alan tam bağlantı olarak girilir ve gösterilir (`https://letterboxd.com/<ad>/`, `https://www.instagram.com/<ad>/`; kullanıcı adı veya `@ad` da kabul edilir); veritabanında yalnızca bağlantıdan ayıklanan kullanıcı adı saklanır — Letterboxd `^[a-z0-9_]{2,15}$`, Instagram 1–30 karakter (harf, rakam, `.`, `_`; nokta ile başlayıp bitmez, art arda nokta yok); kısa bağlantılar (`boxd.it/…`) kabul edilmez (kullanıcı kararı 2026-10-18). Kaydet sonrası değişiklik profil ekranında yenileme gerekmeden görünür. (Kullanıcı kararları 2026-10-17.) |
| F3 | **Keşfet**: dizi arama, kullanıcı arama, trend listesi | 2 | (a) "Diziler / Kullanıcılar" segmenti vardır. (b) Dizi araması en az 2 karakterle başlar, yazma durduktan 300 ms sonra istek atar, sonuçlar afiş+ad+yıl ile listelenir. (c) Kullanıcı araması kullanıcı adında önek eşleşmesiyle en fazla 20 sonuç döner. (d) Arama kutusu boşken TMDB'de en çok oy almış "En ünlü diziler" 3'lü afiş ızgarasında gösterilir (`tmdb-proxy` `popular`; kullanıcı kararı 2026-10-17). (e) Sonuç yoksa "Sonuç bulunamadı" boş durumu görünür. (f) Kullanıcı aramasında oturum sahibinin engellediği kişiler listelenmez. (g) Arama kutusu boşken "Sana Özel Öneriler" kartının altında, "En ünlü diziler"in üstünde "Şu an yayında" yatay satırı: TMDB'de yeni bölümü yayında olan diziler (`tmdb-proxy` `on_the_air`), kullanıcının listesinde olsa da; afişe dokununca dizi detayı açılır; misafirde de görünür (Diziler sekmesinden taşındı, kullanıcı kararı 2026-10-17). |
| F4 | **Dizi detayı** ve listeye ekleme/çıkarma | 2 | (a) Detay: arka plan görseli, afiş, ad, yıl, durum (devam ediyor/bitti), özet, sezon listesi; "Hakkında" (özet ve oyuncular: fotoğraf, ad, rol — `tmdb-proxy` `show_credits`) ve "Bölümler" sekmeleri, açılışta Bölümler: "Sıradaki" bölüm bandı (hepsi izlendiyse "Hepsini izledin!") ve izlenen/yayınlanan sayılı, ilerleme çizgili, sezonu işaretleme düğmeli sezon kartları; sezona dokununca bölümler kartın altında açılır/kapanır (yeni sayfa açılmaz), her bölüm geniş bant olarak (TMDB sahne görseli `still_path` kapak olarak — izlenmemiş bölümde de net, kullanıcı kararı —, no, ad, yayın tarihi, izlendi işareti); Bölüm Sonrası ekranının üstünde de aynı görsel. (b) "Ekle" ile dizi kullanıcının listesine girer ve ≤ 1 sn içinde Diziler sekmesinde görünür; listedeki dizinin durum grubu (F6j) detayda görünür ve dokununca açılan menüden değiştirilir; kalp düğmesi diziyi favorilere ekler/çıkarır (F8j). (c) "Listeden çıkar" onay ister; onaylanınca dizi ve o diziye ait izleme kayıtları silinir. (d) Sezon 0 (özel bölümler) ayrı "Özel Bölümler" başlığıyla gösterilir ve ilerleme/istatistiğe dahil edilmez. (e) Bölüm satırındaki onay kutusu işaretleme yapar (F5); satırın geri kalanına dokunmak Bölüm Sonrası ekranını (`/episode/:id` rotası) açar. |
| F5 | **Bölüm işaretleme** | 3 | (a) Tek bölüm işaretleme/geri alma. (b) "Sezonun tamamını izledim". (c) "Buraya kadar izledim" (seçilen bölüm ve önceki tüm yayınlanmış bölümler). (d) Yayın tarihi gelecekte olan bölüm işaretlenemez (düğme pasif). (e) İşaretleme arayüzde iyimser güncellenir: dokunuştan sonra ≤ 100 ms içinde görsel değişir; sunucu hatasında geri alınır ve "Kaydedilemedi, tekrar dene" mesajı gösterilir. (f) İşaretleme düğmeleri yalnızca işaretler, Bölüm Sonrası ekranına geçmez (kullanıcı kararı 2026-10-17); ekran banda/satıra dokununca açılır. |
| F6 | **Diziler** sekmesi: Son izlenenler ve Sıradaki | 3 | Diziler sekmesi alt sekmesiz tek kaydırılan sayfadır; yukarıdan aşağı: **Son izlenen diziler** (son izlemeye göre yatay afiş satırı, en fazla 20, grup renkli çubuklu; hiç izleme yoksa gösterilmez), **Sıradaki** bölümler (a–g) ve **Yaklaşan** (F7). Dizilerim ızgarası profildedir (F8e) (kullanıcı kararları 2026-10-17). (a) **İzlemeye devam et** bölümü: sıradaki bölümü olan ve son izleme ≤ 30 gün önce olan diziler; hiç izlenmemişler ayrı **Henüz başlamadıkların** bölümünde; durumu Durduruldu veya Dönülmez (j) olan diziler Sıradaki sekmesinde görünmez. (b) Liste kartı: solda sıradaki bölümün sahne görseli (yoksa dizinin arka planı), çerçeveli dizi adı etiketi, sıradakinden sonra kalan bölüm sayısı (+N), sezonun ilk bölümünde "Sezon başı" etiketi, dizi adı, "S01 \| B05" biçiminde sıradaki bölüm ve bölüm adı, sağda büyük yuvarlak onay düğmesi, altında dizinin durum grubu (j) renginde ilerleme çubuğu (= izlenen yayınlanmış bölüm / toplam yayınlanmış bölüm, sezon 0 hariç; İzleme Listesi grubunda boş ve beyaz konturlu); renk tek başına bilgi taşımaz, ekran okuyucu etiketinde grup adı vardır. Aynı çubuk ızgarada, Son izlenenlerde, profil satırlarında, Dizilerim ızgarasında ve Tümü ekranında kullanılır. (c) Üç görünüm: **Liste** (varsayılan), **Izgara** (3 sütun) ve **Afiş** (k); üst çubuktaki görünüm menüsünden seçilir ve tercih cihazda (`shared_preferences`) saklanır (kullanıcı kararları 2026-10-17, 2026-10-18). (d) Afişteki onay düğmesine dokunmak sıradaki bölümü işaretler (F5 kuralları geçerli). (e) **Bir süredir izlemediklerin**: sıradaki bölümü olan ve son izleme > 30 gün önce olan diziler, ayrı bölümde. (f) Tüm yayınlanmış bölümleri izlenmiş diziler bu sekmede görünmez. Listede hiç dizi yoksa "Henüz dizi eklemedin" boş durumu ve Keşfet'e giden düğme görünür. (g) Sıralama: son izleme tarihi azalan; hiç izlenmemişler ekleme tarihine göre azalan, en üstte. (i) — ("Şu an yayında" Keşfet'e taşındı, bkz. F3g.) (j) **Durum grupları**: listedeki her dizi tek bir gruptadır — **Bitti** (mor; TMDB durumu Ended/Canceled ve yayınlanmış tüm bölümler izlendi), **Güncel** (yeşil; yayın sürüyor veya durum bilinmiyor ve yayınlanmış tüm bölümler izlendi), **Devam ediyor** (sarı; en az bir bölüm izlendi, hepsi değil), **Durduruldu** (mavi; elle), **Dönülmez** (kırmızı; elle), **İzleme Listesi** (beyaz; hiç izlenmemiş veya yayınlanmış bölümü yok — otomatik, ya da elle). Otomatik grup `tracking/logic.dart`'ta saf fonksiyondur; elle seçilen grup (`user_shows.manual_status`) otomatiğin önüne geçer ve "Otomatik"e dönülebilir; Durduruldu veya İzleme Listesi'ndeki dizide bölüm işaretlenince elle seçim kalkar (veritabanı tetikleyicisi), Dönülmez'de kalkmaz. Grup, dizi detayından ve Sıradaki kartına uzun basınca açılan menüden değiştirilir. Profildeki **Dizilerim** bölümü ve "Tümü" ekranı listedeki tüm dizileri renkli çubuklu ızgarada gösterir ve gruplara göre çiplerle filtrelenir. (k) **Afiş görünümü**: üstte büyük görsel (İzlemeye devam et'teki ilk dizinin, yoksa son izlenen dizinin arka planı; dokununca dizi detayı), altında bölümlere kaydıran çipler; yatay afiş satırları: **Yaklaşan** (afiş, köşede bölüm etiketi, altında tarih), **İzlemeye devam et** (afiş, sıradaki bölüm etiketi, köşede tek dokunuşla işaretleyen onay düğmesi, F5 kuralları; uzun basınca durum menüsü), **Henüz başlamadıkların**, **Bir süredir izlemediklerin**, **Son izlenen diziler** ve **Arkadaşların ne izliyor** (takip edilen her kişinin son izlediği bölüm: afiş, bölüm etiketi, avatar, kullanıcı adı ve o bölüme verdiği puan yıldızları; dokununca Bölüm Sonrası ekranı; engellenenler hariç; takip edilen yoksa veya kimse izlemediyse gizli; `get_friends_activity`). Boş satırlar gösterilmez. (h) 100 dizilik listede kaydırma takılmaz: ızgara tembel oluşturulan `SliverGrid`/`GridView.builder` ile çizilir; `flutter run --profile` ile DevTools Performance görünümünde 10 sn kaydırmada karelerin ≥ %95'i 16 ms altındadır. |
| F7 | **Diziler › Yaklaşan** bölümü | 3 | Diziler sayfasının altında; ilk 5 bölüm görünür, "Tümünü göster" hepsini aynı sayfada açar. Listedeki dizilerin bugünden itibaren 90 gün içinde yayınlanacak bölümleri tarih başlıklarına ("Bugün", "Yarın", sonra "17 Ekim Cuma" biçimi) göre gruplu, artan tarih sırasıyla listelenir. Her satır: afiş küçük görseli, dizi adı, S/B numarası, bölüm adı. Boşsa "Yaklaşan bölüm yok" görünür. |
| F8 | **Profil ekranı** ve istatistikler | 4 | (a) Sabitlenen üst çubuk (`SliverAppBar`); başlığın arkasında seçilen kapak (V9) karartılmış ve aşağı doğru siyaha geçen soluk arka plan olarak durur, aşağı kaydırıldıkça paralaks ile kayar (kullanıcı kararı 2026-10-17). (b) Üst çubukta sağda sarı bildirim zili; okunmamış bildirim varsa sayı rozeti (F13). (c) Solda yuvarlak avatar; sağında görünen ad ve ülke bayrağı, kullanıcı adı, "<tarih>'ten beri" (kayıt tarihi) ve takipçi sayısı (dokununca takipçi listesi); paylaş ikonu ve "Düzenle" (başkasının profilinde "Takip et") üst çubukta. (d) İki istatistik kartı: **dizi izleme süresi** "X ay Y gün Z saat" (1 ay = 30 gün; süre = izlenen bölümlerin `runtime` toplamı, yoksa dizinin varsayılan süresi, o da yoksa 45 dk) ve **izlenen bölüm sayısı**. (e) Bölüm sırası (kullanıcı kararı 2026-10-18): biyografi ve bağlantılar (i) → istatistik kartları (d) ve sayılar (f) → **Favori diziler** (j) → **Şu an izlediklerim** (Devam ediyor grubundaki diziler, son izlenene göre yatay afiş satırı; "Tümü" → Tümü ekranı bu grupla süzülü açılır) → **Son etkinlik** (k) → **Puanlar** (l) → **Dizilerim** (tüm diziler, grup çipleriyle süzülen renkli çubuklu 3'lü ızgara, F6j). (f) Takipçi, takip edilen ve rozet sayıları; dokununca ilgili liste açılır. (g) Paylaş ikonu, `share_plus` ile işletim sisteminin paylaşım menüsünü `sezonluk://user/<kullanıcıadı>` bağlantısı ve kısa bir metinle açar. (h) İstatistikler, bir bölüm işaretlendikten sonra profil açıldığında güncel değeri gösterir (eski önbellek yok). (i) Dolu Letterboxd ve Instagram bağlantıları (F2) kendi ve başkalarının profilinde genel bağlantı ikonu + bağlantı metni (`letterboxd.com/<ad>`, `instagram.com/<ad>`) olarak görünür (marka logosu yok); dokununca `url_launcher` ile `https://letterboxd.com/<ad>/`, `https://www.instagram.com/<ad>/` açılır. (j) **Favori diziler**: en fazla 4 dizi, 4 eşit sütunlu afiş satırı; dizi detayındaki kalp düğmesiyle eklenir/çıkarılır (yalnızca listedeki dizi); 5. favoride "En fazla 4 favori seçebilirsin" mesajı çıkar (veritabanı tetikleyicisi de reddeder); kendi profilinde favori yoksa ipucu metni görünür, başkasının profilinde bölüm gizlenir; listeden çıkarılan dizi favorilerden de çıkar. (k) **Son etkinlik**: son izlenen 20 bölüm (`get_recent_activity`), yatay satır: bölümün sahne görseli (yoksa dizinin arka planı, o da yoksa afişi), "S01 \| B05" ve dizi adı (kullanıcı kararı 2026-10-18); dokununca Bölüm Sonrası ekranı açılır; hiç izleme yoksa bölüm gösterilmez. (l) **Puanlar**: kullanıcının bölümlere verdiği puanların dağılımı 0,5–5 arası 10 sütunlu çubuk grafikte (sütun yüksekliği = o puanı verdiği bölüm sayısı, en yüksek sütun tam boy), üstünde toplam puan sayısı ve ortalama (bir ondalık); her sütunun ekran okuyucu etiketinde puan ve sayı vardır; bölüm puanı değişince yenilenir; hiç puan yoksa kendi profilinde ipucu, başkasında bölüm gizli (`get_rating_distribution`; kullanıcı kararı 2026-10-18). |
| F9 | **Bölüm sonrası ekranı — emoji tepkileri** | 5 | (a) 12 sabit tepki: 😂 Komik, 😍 Bayıldım, 😮 Şok oldum, 😢 Hüzünlendim, 😡 Sinirlendim, 😴 Sıkıldım, 🤯 Kafam yandı, 😱 Korktum, 🔥 Efsane, 🤔 Düşündürdü, 🥰 Duygulandım, 😬 Gerildim (kullanıcı kararı 2026-10-17; ilk 6'sı MVP). (b) Kullanıcı bölüm başına tek tepki verir, değiştirebilir veya kaldırabilir. (c) Tepki verdikten sonra her tepkinin yüzdesi gösterilir (toplam %100 ± yuvarlama). |
| F10 | **Bölümün yıldızı oylaması** | 5 | (a) Adaylar: TMDB bölüm oyuncu kadrosu + konuk oyuncular, TMDB sırasına göre ilk 20 kişi; fotoğraf, oyuncu adı, karakter adı. (b) Bölüm başına kullanıcı başına tek oy; değiştirilebilir. (c) Oy verdikten sonra en çok oy alan 5 kişi yüzdeleriyle gösterilir. (d) Kadro bilgisi yoksa bölüm "Bu bölüm için oyuncu bilgisi yok" mesajıyla gizlenir. |
| F11 | **Yorumlar ve spoiler gizleme** | 5 | (a) Yorum 1–500 karakter; "Spoiler içeriyor" anahtarı vardır. (b) Spoiler işaretli yorumlar herkes için bulanık/gizli görünür, dokununca açılır. (c) Kullanıcı bölümü izlenmiş işaretlememişse o bölümün **tüm** yorumları gizlidir; "Bu bölümü izlemedin, yorumlar spoiler içerebilir — Yine de göster" uyarısı çıkar. (d) Yorumlar en yeniden eskiye, 20'şerli sayfalarla yüklenir. (e) Kullanıcı kendi yorumunu silebilir; başkalarının yorumunu beğenebilir/beğeniyi geri alabilir; beğeni sayısı görünür. (f) Bir kullanıcı dakikada en fazla 5 yorum gönderebilir; aşımda "Çok hızlı yorum yapıyorsun" hatası (veritabanı tetikleyicisi). (g) Yasaklı kelime listesindeki bir kelimeyi içeren yorum reddedilir (F15). |
| F12 | **Takip sistemi** ve diğer kullanıcı profili | 6 | (a) Başka kullanıcının profili F8 ile aynı düzendedir; "Düzenle" yerine "Takip et / Takip ediliyor" düğmesi. (b) Takip/bırakma ≤ 1 sn içinde sayılara yansır. (c) Takipçi ve takip edilen listeleri sayfalı (30'ar). (d) Kullanıcı kendini takip edemez (veritabanı kısıtı). (e) Tüm profiller herkese açıktır (bkz. V10). |
| F13 | **Uygulama içi bildirimler** (zil) | 6 | (a) Türler: yeni takipçi, yorumun beğenildi, rozet kazanıldı. (b) Bildirimler veritabanı tetikleyicileriyle oluşturulur. (c) Zil ekranı açıldığında hepsi okundu işaretlenir ve zil sayacı sıfırlanır. (d) Liste en yeniden eskiye, son 90 gün. (e) Push bildirimi yoktur (bkz. §2.2). |
| F14 | **Rozetler** | 6 | 15 rozet (kullanıcı kararı 2026-10-18), veritabanı tetikleyicisiyle otomatik verilir: `first_episode` (1 bölüm), `episodes_10`, `episodes_50`, `episodes_100`, `episodes_500`, `episodes_1000`, `episodes_5000` (bölüm sayısı), `shows_10`, `shows_25`, `shows_50` (listedeki dizi), `first_finished` ve `finished_5` (bitmiş — Ended/Canceled — dizinin yayınlanmış tüm bölümleri izlendi; 1 ve 5 dizi), `first_comment`, `comments_10`, `comments_50` (yorum sayısı). Rozet ekranı kazanılanları renkli, kazanılmayanları gri ve koşuluyla gösterir. Rozet bir kez verilir; koşul sonradan bozulsa da geri alınmaz. |
| F15 | **Moderasyon**: şikayet, engelleme, kelime filtresi | 5 | (a) Her yorumda ve profilde "Şikayet et" (nedenler: spam, taciz, spoiler, uygunsuz içerik, diğer). Şikayet edilen içerik şikayet edene hemen gizlenir. (b) "Engelle": engellenen kişinin yorumları engelleyene gösterilmez, iki yönlü takip ilişkisi silinir, engellenen engelleyeni takip edemez. (c) Ayarlar'da engellenenler listesi ve engeli kaldırma. (d) `banned_words` tablosundaki kelimeleri (büyük/küçük harf duyarsız, Türkçe karakter normalize) içeren yorum reddedilir. (e) Yönetici şikayetleri Supabase panelinden inceler ve `comments.hidden_at` alanını doldurarak yorumu herkesten gizler (bkz. §5.4). |
| F16 | **Hesap silme** | 7 | Ayarlar › Hesabı sil → kullanıcı adını yazarak onay → `delete-account` Edge Function kullanıcıyı, tüm satırlarını (cascade) ve Storage'daki avatarını siler; işlem ≤ 10 sn sürer ve kullanıcı giriş ekranına döner. Silinen hesapla tekrar giriş yapılamaz. (Apple Guideline 5.1.1(v) zorunluluğu.) |
| F17 | **Yasal ve atıf ekranları** | 7 | Ayarlar › Hakkında: TMDB logosu ve "This product uses the TMDB API but is not endorsed or certified by TMDB." metni; Gizlilik Politikası ve Kullanım Şartları bağlantıları (yayında erişilebilir URL); uygulama sürümü. `docs/privacy.md` ve `docs/terms.md` GitHub Pages'te yayında ve bağlantılar HTTP 200 döner. Kullanım Şartları yorumlar için sıfır tolerans maddesi içerir. |
| F18 | **Öneriler sayfası** (`/suggest`): kategoriye göre kişisel dizi önerisi | 4 | (a) Keşfet ekranının en üstünde "Sana Özel Öneriler" kartı vardır; dokununca `/suggest` açılır. (b) Kategori çipleri: TMDB dizi türleri Türkçe adlarıyla (`genres` tablosu); aynı anda 1–3 kategori seçilebilir, 4. seçimde "En fazla 3 kategori seçebilirsin" mesajı çıkar ve seçim eklenmez. (c) Varsayılan seçim: cihazda saklanan son seçim (`shared_preferences`); yoksa kullanıcının listesindeki dizilerde en sık geçen 3 tür (`get_top_genres()`); listesi boşsa hiçbir tür seçili değildir ve "Öneri almak için en az bir kategori seç" mesajı görünür. (d) Sonuçlar: seçili türlerden en az birine sahip, TMDB oy sayısı ≥ 100 olan diziler, popülerliğe göre azalan; kullanıcının listesindeki diziler **hariç**; 3'lü afiş ızgarası, 20'şerli sayfa, aşağı kaydırınca sonraki sayfa yüklenir. Seçim değişince sonuçlar ≤ 2 sn içinde yenilenir (geliştirme projesinde, `tmdb-proxy` logundan ölçülür). (e) Her afişte "+" kısayolu diziyi listeye ekler (F4(b) kuralı); eklenen dizi öneri ızgarasından hemen kalkar. Afişe dokunmak dizi detayını açar. (f) "İzlediklerine benzer" bölümü: en son izlenen dizi için TMDB önerileri, en fazla 20 dizi, listedekiler hariç, başlık "<Dizi adı> izlediğin için"; kullanıcı hiç bölüm izlememişse bölüm gösterilmez. (g) Sonuç yoksa "Bu kategorilerde yeni öneri kalmadı" boş durumu görünür. |
| F20 | **Bölüm puanı ve beğenisi** | 5 | (a) Bölüm Sonrası ekranında 5 yıldız üzerinden 0,5 adımlı puan (yıldızın sol yarısı buçuk); aynı puana tekrar dokunmak puanı kaldırır; ortalama puan (bir ondalık) ve puan sayısı görünür. (b) Kalp düğmesiyle bölüm beğenilir/beğeni geri alınır; beğeni sayısı görünür. (c) İkisi de iyimser güncellenir, hatada geri alınır. (d) Misafir puan veremez, beğenemez (F19). Kullanıcı kararı 2026-10-17. |
| F19 | **Misafir modu**: hesap açmadan uygulamayı gezme | 7 | (a) Giriş ekranında "Misafir olarak devam et" düğmesi vardır; e-posta/şifre istemeden Supabase anonim girişiyle oturum açar (panelde "Allow anonymous sign-ins" açık). (b) Misafir Keşfet'i (dizi arama, trendler, Sana Özel Öneriler — benzer bölümü yok), dizi detayını ve sezon bölüm listelerini kullanabilir. (c) Listeye ekleme, bölüm işaretleme, Bölüm Sonrası ekranı (tepki, oy, yorum), kullanıcı profilleri, takip ve kendi profili hesap ister: misafir bunları denediğinde "Bu özellik için hesap oluştur" iletisi ile Kayıt ol / Giriş yap düğmeleri çıkar; Diziler ve Profil sekmeleri aynı çağrıyı gösterir. (d) Misafirin tüm yazma işlemleri veritabanında da reddedilir (kısıtlayıcı RLS politikası, JWT `is_anonymous`); misafir için profil satırı oluşmaz. (e) Misafir yazma yapamadığı için hesap açınca taşınacak veri yoktur; Kayıt ol/Giriş yap misafir oturumunu kapatıp normal akışa geçer. |

### 2.2 Sonraki Sürümler (MVP sonrası, öncelik sırasıyla)

1. TV Time / Trakt dışa aktarım dosyasından içe aktarma (kapanan TV Time kullanıcılarını çekmek için en değerli özellik).
2. Push bildirimleri (yeni bölüm yayınlandı, yeni takipçi).
3. İngilizce arayüz (i18n altyapısı MVP'de hazır).
4. Yorumlara yanıt (tek seviye).
5. "Nerede izlenir" (TMDB watch providers).
6. Önerilerde "İlgilenmiyorum" ile diziyi gizleme ve bu geri bildirime göre sıralama.
7. Reklam veya premium (önce TMDB ticari lisansı, bkz. R1).
8. Sosyal giriş (Apple, Google) — eklenirse Apple ile Giriş zorunlu olur.
9. Açık tema, tablet düzeni.

### 2.3 Kapsam Dışı (bu projede yapılmayacak)

- **Filmler** ve film takibi — ürün yalnızca dizi takip eder; alt menüde Filmler sekmesi yoktur.
- **TV Time adı, logosu, ikonları, maskotu, ekran görüntüleri veya görselleri** — marka ve telif ihlali, mağaza reddi riski.
- Web uygulaması / web profil sayfası — tek geliştiriciyle iki istemciyi sürdürmek MVP'yi geciktirir.
- Özel mesajlaşma (DM), gruplar, gizli profil — moderasyon yükü çok artar.
- Video, GIF veya görsel içeren yorum — moderasyon ve depolama maliyeti.
- Ayrı yönetici paneli — Supabase Dashboard yeterli.
- Çevrimdışı işaretleme / senkronizasyon — çakışma çözümü karmaşık; çevrimdışıyken işaretleme hata mesajı verir, önceden yüklenmiş listeler okunabilir.
- Dizi izletme, yayın akışı, torrent veya korsan bağlantı.
- Kendi öneri algoritması / makine öğrenmesi modeli — F18 önerileri yalnızca TMDB `discover` ve `recommendations` uç noktalarına ve kullanıcının kendi listesine dayanır; model eğitmek ve barındırmak ücretsiz katmana ve MVP süresine sığmaz.

## 3. Mimari

### 3.1 Genel Yaklaşım

İstemci–BaaS mimarisi. Tek bir Flutter uygulaması doğrudan Supabase'e konuşur (`supabase_flutter`); iş kuralları mümkün olduğunca **Postgres içinde** (RLS politikaları, kısıtlar, tetikleyiciler, SQL fonksiyonları) uygulanır. Kendi sunucumuz yoktur. TMDB'ye yalnızca Supabase Edge Function üzerinden erişilir (API anahtarı istemcide bulunmaz).

```
[Flutter uygulaması (iOS/Android)]
      │ supabase_flutter (Auth, PostgREST, Storage, RPC)
      ▼
[Supabase]
  ├─ Auth (e-posta+şifre)
  ├─ Postgres (tablolar + RLS + tetikleyiciler + RPC)
  ├─ Storage (avatars kovası)
  └─ Edge Functions
       ├─ tmdb-proxy  ──HTTPS──► [TMDB API v3]
       ├─ tmdb-sync (zamanlanmış, günlük)
       └─ delete-account
```

### 3.2 Ana Bileşenler

| Bileşen | Sorumluluk |
|---|---|
| `lib/app/` | `go_router` rotaları, oturum yönlendirmesi, alt menü kabuğu (`StatefulShellRoute`). Alt menü: **Diziler · Keşfet · Profil**. |
| `lib/features/*` | Özellik başına: `data/` (repository + modeller), `logic.dart` (saf iş mantığı), `providers.dart` (Riverpod), `screens/`, `widgets/`. |
| `lib/shared/widgets` | Ortak widget'lar (PosterCard, ProgressBar, PrimaryButton, EmptyState…). |
| `lib/theme` | Renk, boşluk, yazı tipi değerleri ve `ThemeData` (§3.7). Widget'larda sabit renk kodu yazılmaz. |
| `tmdb-proxy` | TMDB isteklerini yapar, sonucu `shows/seasons/episodes/episode_credits` tablolarına yazar (upsert) ve döner. Aynı kayıt 24 saatten yeniyse TMDB'ye gitmeden veritabanından döner. |
| `tmdb-sync` | pg_cron ile günde 1 kez (03:00 UTC) çalışır; en az bir kullanıcının listesinde olan ve durumu "Returning Series"/"In Production" olan dizileri yeniler (çalışma başına en fazla 500 dizi). |
| `delete-account` | Service role ile kullanıcıyı ve dosyalarını siler (F16). |
| Postgres tetikleyicileri | Rozet verme (F14), bildirim üretme (F13), yorum hız sınırı ve kelime filtresi (F11, F15), `user_shows.last_watched_at` güncelleme. |
| SQL fonksiyonları (RPC) | `get_watchlist()`, `get_upcoming(days int)`, `get_user_stats(user_id uuid)`, `mark_episodes_until(episode_id)`, `mark_season(show_id, season_number)`, `get_episode_reaction_stats(episode_id)`, `get_episode_star_stats(episode_id)`, `get_top_genres(lim int default 3)` (F18: kullanıcının listesindeki dizilerde en sık geçen tür kimlikleri), `get_user_show_progress(user_id uuid)` (F6j: her dizi için yayınlanmış/izlenmiş bölüm sayısı, TMDB durumu, elle seçilen grup ve favori işareti), `get_recent_activity(user_id uuid, lim int default 20)` (F8k: son izlenen bölümler, sahne görseliyle), `get_friends_activity(lim int default 20)` (F6k: takip edilenlerin son izlediği bölümler), `get_rating_distribution(user_id uuid)` (F8l: puan başına bölüm sayısı). Ağır hesaplar istemcide değil burada yapılır. |

### 3.3 Veri Modeli

Tüm kullanıcı tablolarında `user_id uuid references auth.users on delete cascade`. Zaman alanları `timestamptz default now()`. TMDB kimlikleri `integer` olarak birincil anahtar kullanılır.

**TMDB önbellek tabloları** (istemci yalnızca okur; yazma sadece Edge Function / service role):

| Tablo | Alanlar |
|---|---|
| `shows` | `id` (TMDB id, PK), `name`, `original_name`, `overview`, `poster_path`, `backdrop_path`, `status`, `first_air_date date`, `number_of_seasons`, `number_of_episodes`, `default_runtime int` (dk), `genre_ids int[]` default `'{}'` (F18), `last_synced_at` |
| `seasons` | `id` (TMDB id, PK), `show_id → shows`, `season_number`, `name`, `poster_path`, `air_date`, `episode_count`; UNIQUE(`show_id`,`season_number`) |
| `episodes` | `id` (TMDB id, PK), `show_id → shows`, `season_number`, `episode_number`, `name`, `overview`, `air_date date`, `runtime int`, `still_path`; UNIQUE(`show_id`,`season_number`,`episode_number`) |
| `episode_credits` | `episode_id → episodes`, `person_id`, `name`, `character`, `profile_path`, `order`; PK(`episode_id`,`person_id`) |
| `genres` | `id` (TMDB tür id, PK), `name` (Türkçe ad), `last_synced_at` — F18 kategori çipleri |

**Kullanıcı tabloları:**

| Tablo | Alanlar ve kısıtlar |
|---|---|
| `profiles` | `id` (PK = auth.users.id), `username` UNIQUE CHECK `^[a-z0-9_]{3,20}$`, `display_name` (1–40), `bio` (≤160), `country_code char(2)` null, `avatar_path` null (Storage yolu veya `tmdb:<yol>`), `cover_show_id → shows` null, `cover_path` null (TMDB arka plan yolu), `letterboxd_username` null, `instagram_username` null (F2), `created_at`. Kayıtta tetikleyiciyle oluşturulur. |
| `user_shows` | PK(`user_id`,`show_id`), `added_at`, `last_watched_at` null, `manual_status` enum(`paused`,`dropped`,`planned`) null (F6j), `is_favorite bool` default false (F8j; kullanıcı başına en fazla 4, tetikleyici); sahibi yalnızca bu iki kolonu günceller |
| `watched_episodes` | PK(`user_id`,`episode_id`), `show_id` (sorgu hızı için), `watched_at` |
| `reactions` | PK(`user_id`,`episode_id`), `emoji` enum(`funny`,`love`,`shocked`,`sad`,`angry`,`bored`,`mindblown`,`scared`,`epic`,`thoughtful`,`touched`,`tense`), `created_at` |
| `star_votes` | PK(`user_id`,`episode_id`), `person_id`, `created_at` |
| `comments` | `id uuid` PK, `user_id`, `episode_id`, `body` CHECK 1–500, `is_spoiler bool`, `hidden_at` null (yönetici), `created_at`; INDEX(`episode_id`,`created_at desc`) |
| `comment_likes` | PK(`user_id`,`comment_id → comments on delete cascade`) |
| `follows` | PK(`follower_id`,`followee_id`), CHECK `follower_id <> followee_id`, `created_at` |
| `blocks` | PK(`blocker_id`,`blocked_id`), CHECK farklı kişiler |
| `reports` | `id`, `reporter_id`, `target_type` enum(`comment`,`profile`), `target_id text`, `reason` enum(`spam`,`harassment`,`spoiler`,`inappropriate`,`other`), `note` (≤300) null, `status` enum(`open`,`resolved`) default `open`, `created_at` |
| `badges` | `code` PK, `name`, `description`, `icon` (yerel varlık adı) — migration ile 15 satır |
| `user_badges` | PK(`user_id`,`badge_code`), `earned_at` |
| `notifications` | `id`, `user_id` (alıcı), `type` enum(`new_follower`,`comment_liked`,`badge_earned`), `actor_id` null, `entity_id text` null, `read_at` null, `created_at` |
| `episode_ratings` | PK(`user_id`,`episode_id`), `rating numeric(2,1)` CHECK 0,5–5 ve 0,5 adım, `created_at` (F20) |
| `episode_likes` | PK(`user_id`,`episode_id`), `created_at` (F20) |
| `banned_words` | `word` PK (normalize edilmiş küçük harf) — seed ile başlangıç listesi |

**İlişkiler:** Kullanıcı N–N dizi (`user_shows`); kullanıcı N–N bölüm (`watched_episodes`, `reactions`, `star_votes`); bölüm 1–N yorum; kullanıcı N–N kullanıcı (`follows`, `blocks`).

**Storage:** `avatars` kovası herkese okunur, JPEG ve PNG kabul eder (kırpılmış avatar PNG, F2); kullanıcı yalnızca `avatars/<kendi uid>/` yoluna yazar/siler (Storage RLS politikası).

**RLS özeti:** Misafir (anonim) oturumlar hiçbir kullanıcı tablosuna ve `avatars` kovasına yazamaz (F19, kısıtlayıcı politika). TMDB tabloları (`genres` dahil) ve `badges`: herkese okuma, istemciye yazma yok. `profiles`, `user_shows`, `watched_episodes`, `user_badges`, `follows`, `reactions`, `star_votes`, `comments`(hidden_at null olanlar), `comment_likes`: oturum açmış herkes okur, yalnızca sahibi (`auth.uid() = user_id`) ekler/siler/günceller. `notifications`, `blocks`: yalnızca sahibi okur/yazar. `reports`: sahibi ekler, kimse istemciden okuyamaz. `banned_words`: istemci erişimi yok.

### 3.4 Önemli İş Kuralları

- **Yayınlanmış bölüm:** `air_date` dolu ve `air_date <= bugünün tarihi (UTC)` ve `season_number > 0`.
- **Sıradaki bölüm:** Kullanıcının izlemediği yayınlanmış bölümler arasında (`season_number`, `episode_number`) sırasına göre ilki.
- **İlerleme:** izlenen yayınlanmış bölüm sayısı / yayınlanmış bölüm sayısı.
- **Spoiler kapısı (F11c):** `watched_episodes` içinde (kullanıcı, bölüm) yoksa yorumlar gizli başlar.
- **Engelleme filtresi:** Yorum ve kullanıcı listelerinde, `blocks` tablosunda oturum sahibinin engellediği kişiler sorguda hariç tutulur.

### 3.5 `tmdb-proxy` Sözleşmesi

İstemci `supabase.functions.invoke('tmdb-proxy', body: {...})` ile çağırır; yalnızca oturum açmış kullanıcı (JWT doğrulanır). Edge Function gövdeyi `zod` (`npm:zod`) ile doğrular; geçersizse HTTP 400. Dönen JSON istemcide `lib/features/*/data/models.dart` içindeki `fromJson` fabrikalarıyla ayrıştırılır. Tüm TMDB isteklerinde `language=tr-TR` kullanılır.

| `action` | Diğer alanlar | TMDB uç noktası | Yazdığı tablo | Dönen |
|---|---|---|---|---|
| `search` | `query` (≥ 2 karakter), `page` | `/search/tv` | `shows` (özet alanlar) | `{ results: Show[], totalPages }` |
| `trending` | — | `/trending/tv/week` | `shows` | `{ results: Show[] }` |
| `show` | `showId` | `/tv/{id}` | `shows`, `seasons` | `{ show, seasons }` |
| `season` | `showId`, `seasonNumber` | `/tv/{id}/season/{n}` | `episodes` | `{ episodes }` |
| `episode_credits` | `episodeId` | `/tv/{id}/season/{n}/episode/{e}/credits` (cast + guest_stars) | `episode_credits` | `{ credits }` |
| `genres` | — | `/genre/tv/list` | `genres` | `{ genres }` |
| `discover` | `genreIds` (1–3 tamsayı), `page` | `/discover/tv?with_genres=<id1>\|<id2>&sort_by=popularity.desc&vote_count.gte=100` | `shows` (özet alanlar) | `{ results: Show[], totalPages }` — çağıranın `user_shows` dizileri çıkarılmış |
| `recommendations` | `showId` | `/tv/{id}/recommendations` (yalnızca 1. sayfa) | `shows` (özet alanlar) | `{ results: Show[] }` — çağıranın `user_shows` dizileri çıkarılmış |
| `on_the_air` | — | `/tv/on_the_air` (yalnızca 1. sayfa) | `shows` (özet alanlar) | `{ results: Show[] }` — F6(i); kullanıcının dizileri çıkarılmaz |
| `show_images` | `showId` | `/tv/{id}/images` (en fazla 30 arka plan ve 30 afiş) | — (önbelleğe yazılmaz) | `{ backdrops: string[], posters: string[] }` — F2 kapak ve avatar |
| `popular` | — | `/discover/tv?sort_by=vote_count.desc` (yalnızca 1. sayfa) | `shows` (özet alanlar) | `{ results: Show[] }` — F3(d) |
| `show_credits` | `showId` | `/tv/{id}/aggregate_credits` (ilk 20 kişi) | — (önbelleğe yazılmaz) | `{ cast: [{ person_id, name, character, profile_path }] }` — F4(a) |

Önbellek kuralı: `genres` 30 gün önbelleklenir. `show`, `season`, `episode_credits` için kayıt `last_synced_at` 24 saatten yeniyse TMDB'ye gidilmez ve yanıt başlığı `x-cache: hit` olur; aksi halde `x-cache: miss`. `search`, `trending`, `discover`, `recommendations`, `on_the_air`, `popular` ve `show_credits` önbelleklenmez. `search`, `trending`, `discover` ve `recommendations` sonuçlarındaki `genre_ids` alanı `shows.genre_ids` kolonuna yazılır; `show` eyleminde TMDB'nin döndürdüğü `genres[].id` değerleri aynı kolona yazılır. TMDB hata verirse HTTP 502 ve `{ error: "tmdb_unavailable" }` döner; önbellekte eski kayıt varsa o döner (`x-cache: stale`).
`seasons` ve `episode_credits` tablolarına da `last_synced_at` kolonu eklenir.

### 3.6 Dış Bağımlılıklar

| Servis | Kullanım | Not |
|---|---|---|
| TMDB API v3 | Dizi, sezon, bölüm, kadro, arama, trend; görseller `image.tmdb.org` | Ticari olmayan kullanım + atıf zorunlu (F17). Para kazanmaya başlamadan önce ticari lisans gerekir (R1). |
| Supabase (Free plan) | Auth, Postgres, Storage, Edge Functions, pg_cron | Ücretsiz katman limitleri ve 7 gün hareketsizlikte proje duraklatma (R3). |
| Codemagic | iOS build'i (Windows'ta Mac olmadığı için) ve TestFlight/Play'e yükleme | Ücretsiz katmanda aylık sınırlı macOS build dakikası (R8, V22). Android build yerelde de alınabilir. |
| Apple Developer / Google Play Console | Mağaza yayını | 99 USD/yıl, 25 USD tek seferlik. |

### 3.7 Görsel Dil

- Yalnızca koyu tema (`ThemeData.dark` tabanlı, `useMaterial3: true`). Renkler `lib/theme/app_colors.dart`:
  `background #000000`, `surface #141414`, `surfaceAlt #1F1F1F`, `border #2A2A2A`, `accent #FFCC00` (sarı vurgu, ilerleme çubuğu, zil, birincil düğme), `onAccent #000000`, `textPrimary #FFFFFF`, `textSecondary #A0A0A0`, `danger #FF453A`. Durum grubu renkleri (F6j): `statusFinished #B388FF` (mor), `statusUpToDate #34C759` (yeşil), `statusWatching #FFCC00` (sarı), `statusPaused #64B5F6` (mavi), `statusDropped #FF453A` (kırmızı), `statusWatchlist #FFFFFF` (beyaz); hepsi siyah zeminde ≥ 4.5:1.
- Yazı tipi: sistem yazı tipi (iOS SF Pro, Android Roboto).
- Afiş oranı 2:3, köşe yarıçapı 6 pt; ilerleme çubuğu 3 pt yüksek, afişin hemen altında.
- Dokunma hedefleri ≥ 44×44 pt; metin/zemin kontrastı ≥ 4.5:1.
- Arayüz metinleri yalnızca `lib/l10n/app_tr.arb` içinde (Flutter `gen-l10n`); widget'larda düz metin yazılmaz.

## 4. Klasör Yapısı

```
Series-Time/                      # depo kökü
├── lib/
│   ├── main.dart                 # Supabase.initialize, ProviderScope, MaterialApp.router
│   ├── app/
│   │   ├── router.dart           # go_router rotaları + oturum yönlendirmesi + derin bağlantılar
│   │   └── shell.dart            # alt menü: Diziler · Keşfet · Profil
│   ├── features/
│   │   ├── auth/                 # F1: sign_in, sign_up, forgot_password, reset_password ekranları
│   │   ├── profile/              # F2, F8: profil, düzenle, "Tümü"
│   │   ├── discover/             # F3
│   │   ├── suggest/              # F18: kategoriye göre öneriler, "İzlediklerine benzer"
│   │   ├── shows/                # F4: dizi detayı, sezon, ekleme/çıkarma
│   │   ├── tracking/             # F5–F7: işaretleme, sıradaki, ilerleme, yaklaşan
│   │   ├── episode_feedback/     # F9–F11: tepki, yıldız, yorum
│   │   ├── social/               # F12: takip, takipçi listeleri, kullanıcı arama
│   │   ├── notifications/        # F13
│   │   ├── badges/               # F14
│   │   ├── moderation/           # F15: şikayet, engelleme, engellenenler
│   │   └── settings/             # F16, F17: ayarlar, hesap silme, hakkında
│   │       # her özellik klasöründe: data/ (repository.dart, models.dart), logic.dart,
│   │       # providers.dart, screens/, widgets/ — gerekmeyen alt klasör açılmaz
│   ├── shared/widgets/           # PosterCard, ProgressBar, PrimaryButton, EmptyState, ErrorView
│   ├── core/                     # config.dart, supabase_client.dart, tmdb_image.dart, format.dart, failures.dart
│   ├── theme/                    # app_colors.dart, app_spacing.dart, app_text_styles.dart, app_theme.dart
│   └── l10n/                     # app_tr.arb (+ gen-l10n çıktısı, elle düzenlenmez)
├── test/                         # lib/ yapısını aynalar: test/features/<özellik>/logic_test.dart, *_widget_test.dart
├── supabase/
│   ├── config.toml
│   ├── migrations/               # YYYYMMDDHHMMSS_aciklama.sql
│   ├── functions/
│   │   ├── tmdb-proxy/index.ts
│   │   ├── tmdb-sync/index.ts
│   │   └── delete-account/index.ts
│   ├── tests/                    # pgTAP: *_test.sql
│   └── seed.sql                  # 2 test kullanıcısı (yalnızca CI'daki yerel yığın; badges/banned_words migration ile)
├── android/                      # flutter create çıktısı (applicationId, URL şeması)
├── ios/                          # flutter create çıktısı (bundle id, URL şeması)
├── assets/                       # uygulama ikonu, açılış görseli, rozet ikonları (özgün)
├── env/
│   ├── example.json              # değişken adları, değer yok (commit edilir)
│   ├── dev.json                  # geliştirme projesi (sezonluk-dev) adresi/anon anahtarı (commit edilmez)
│   └── prod.json                 # canlı Supabase adresi/anon anahtarı (commit edilmez)
├── tool/verify.dart              # analyze + format kontrolü + test'i sırayla çalıştırır
├── docs/                         # privacy.md, terms.md (GitHub Pages ile yayınlanır, F1/F17)
├── e2e/                          # Maestro akışları (*.yaml)
├── .github/workflows/ci.yml
├── analysis_options.yaml
├── l10n.yaml
├── pubspec.yaml
├── codemagic.yaml
├── CLAUDE.md
├── AGENT.md
└── ISKELET.md
```

## 5. Kısıtlar

### 5.1 Teknik
- Teknoloji yığını CLAUDE.md'de listelenendir; listede olmayan bağımlılık onay gerektirir (AGENT.md).
- Hedef platformlar: iOS 15+ ve Android 8 (API 26)+, yalnızca dikey yön, yalnızca telefon. Web/masaüstü Flutter hedefleri oluşturulmaz.
- Arayüz dili: Türkçe. Tarih biçimi `tr-TR`.
- Kendi sunucu yok; tüm arka uç Supabase'tir.

### 5.2 Performans (test cihazı: orta segment Android, ör. Samsung Galaxy A54 veya eşdeğeri; release build)
- Soğuk açılıştan Diziler sekmesinin içerikle görünmesine: ≤ 3 sn (oturum açık, 20 dizi).
- Bölüm işaretleme görsel geri bildirimi: ≤ 100 ms (iyimser güncelleme).
- `tmdb-proxy` yanıt süresi: önbellekten ≤ 400 ms, TMDB'den ≤ 2 sn (p95, Supabase function logs).
- RPC `get_watchlist()` 100 dizi / 5.000 izlenmiş bölümle ≤ 300 ms (`explain analyze`, geliştirme projesi).
- Görseller `cached_network_image` ile disk önbellekli; afiş listesinde TMDB `w342`, detayda `w780` boyutu kullanılır.

### 5.3 Güvenlik ve Gizlilik
- Tüm tablolarda RLS açık; her tablo için en az bir pgTAP testi "başka kullanıcının satırına yazamaz" durumunu doğrular.
- TMDB API anahtarı ve Supabase service role anahtarı yalnızca Edge Function sırlarında; istemciye yalnızca `SUPABASE_URL` ve `SUPABASE_ANON_KEY` `--dart-define-from-file` ile verilir (bu değerler uygulama ikilisine gömülür, bu yüzden gizli sayılmaz).
- Oturum belirteci `supabase_flutter` varsayılanıyla (`shared_preferences`) saklanır.
- Kişisel veri: e-posta, kullanıcı adı, ülke, avatar, izleme geçmişi. Üçüncü taraf analiz/reklam SDK'sı yoktur. Gizlilik politikası KVKK ve GDPR temel maddelerini (veri türleri, amaç, silme hakkı, iletişim e-postası) içerir. İletişim için uygulamaya özel bir e-posta adresi açılır (V21); geliştiricinin kişisel adresi yazılmaz.
- Yaş sınırı: 16+ (Kullanım Şartları'nda; mağaza yaş derecelendirmesi kullanıcı içeriği nedeniyle 12+/Teen).

### 5.4 Operasyon
- Şikayetler uygulama sahibi tarafından **en geç 24 saat içinde** Supabase panelinden incelenir (Apple Guideline 1.2 gereği).
- Supabase projesi haftada en az bir kez kullanım aldığı için duraklamaz; yine de R3 önlemi uygulanır.

### 5.5 Zaman ve Bütçe
- Geliştirici: 1 kişi + AI agent, haftada ~15 saat (bkz. V5). Hedef: 7 aşama, ~12 hafta.
- Aylık altyapı bütçesi: 0 TL (ücretsiz katmanlar). Sabit maliyet: Apple 99 USD/yıl, Google 25 USD tek seferlik.

## 6. Geliştirme Aşamaları

Her aşama, kendinden öncekiler bitmeden başlamaz. Her aşamanın sonunda CLAUDE.md'deki tüm doğrulama komutları geçmelidir.

| Aşama | İçerik | Bitti Kriteri |
|---|---|---|
| 0 — Kurulum | `flutter create` ile Android+iOS projesi, `analysis_options.yaml` (flutter_lints), `tool/verify.dart`, `go_router` + Riverpod iskeleti, Supabase yerel (`supabase init`), tema, `gen-l10n`, `env/` dosyaları, boş 3 sekmeli alt menü, GitHub Actions CI (`subosito/flutter-action` stable + `supabase/setup-cli`; her push'ta: `flutter pub get`, `dart run tool/verify.dart`, `supabase start`, `supabase test db`) | `dart run tool/verify.dart` geçer; `supabase start` çalışır; uygulama Android emülatörde 3 boş sekmeyle açılır; CI yeşil. |
| 1 — Hesap ve profil temeli | F1, F2 (kapak seçimi hariç — 4. aşamada tamamlanır); `profiles` tablosu, kayıt tetikleyicisi, `avatars` kovası ve RLS; `docs/privacy.md` ve `docs/terms.md` taslakları | F1 kabul kriterleri; F2 avatar/ad/ülke/biyografi; `profiles` ve Storage pgTAP testleri geçer. |
| 2 — TMDB ve keşif | `tmdb-proxy` (§3.5), TMDB tabloları, F3, F4, `user_shows` | F3, F4 kabul kriterleri; aynı `show` isteği art arda iki kez yapıldığında ilki `x-cache: miss`, ikincisi `x-cache: hit` döner (`curl -i` çıktısı rapora eklenir); `git grep -n TMDB_API_KEY -- lib env android ios` boş döner. |
| 3 — Takip çekirdeği | `watched_episodes`, işaretleme RPC'leri, F5, F6, F7, `tmdb-sync` | F5–F7 kabul kriterleri (F5(f) Bölüm Sonrası ekranına yönlendirme 5. aşamada bağlanır; bu aşamada boş `/episode/:id` ekranı açılır); sıradaki bölüm/ilerleme mantığı için birim testleri (sezon 0, gelecek bölüm, boş dizi durumları). |
| 4 — Profil, istatistik ve öneriler | F8, `get_user_stats`, kapak seçimi (F2 tamamlanır), "Tümü" ekranı; F18 (`genres` tablosu, `shows.genre_ids`, `get_top_genres`, `tmdb-proxy` `genres`/`discover`/`recommendations` eylemleri) | F8 kabul kriterleri (F8(b) zil sayacı ve F8(f) takipçi/takip/rozet sayıları bu aşamada 0 gösteren yer tutucu widget'larla durur, 6. aşamada gerçek veriye bağlanır); izleme süresi biçimlendirmesi birim testli (0 dk, 59 dk, 1 gün, 31 gün); F18 kabul kriterleri; kategori seçimi (en fazla 3, varsayılan seçim önceliği) birim testli; `discover` yanıtında kullanıcının listesindeki bir dizinin bulunmadığı `curl` ile doğrulanır. |
| 5 — Bölüm sonrası ve moderasyon | F9, F10, F11, F15 | F9–F11, F15 kabul kriterleri; hız sınırı ve kelime filtresi pgTAP testli. |
| 6 — Sosyal | F12, F13, F14; F8(b) ve F8(f)'nin gerçek veriye bağlanması | F12–F14 ve F8(b), F8(f) kabul kriterleri; rozet ve bildirim tetikleyicileri pgTAP testli. |
| 7 — Yayın hazırlığı | F16, F17, `docs/` metinlerinin son hali ve GitHub Pages yayını, uygulama ikonu ve adı, mağaza açıklamaları, Maestro duman testleri (kayıt → dizi ekle → bölüm işaretle), `codemagic.yaml` içinde `android-release` ve `ios-release` iş akışları, Codemagic ile release build (Android `appbundle`, iOS `ipa`), TestFlight ve Play iç test | Maestro akışı geçer; §5.2 performans hedefleri ölçülüp rapora yazılır; her iki mağazanın iç test kanalına build yüklenir. |

## 7. Riskler

| # | Risk | Etki | Önlem |
|---|---|---|---|
| R1 | TMDB şartları ticari kullanımı lisansa bağlar; reklam/premium eklenince ihlal oluşur | Yüksek — API erişimi kesilebilir | MVP gelirsiz; F17 atfı eksiksiz; para kazanmadan önce TMDB ticari lisansı alınır veya alternatif veri kaynağı (TVmaze vb.) değerlendirilir. Yayından önce güncel TMDB kullanım şartları okunur ve sonuç README'ye not edilir. |
| R2 | TV Time'a "fazla benzer" arayüz nedeniyle marka/ticari takdim şikayeti veya mağaza reddi | Yüksek | Ad, logo, ikon, renk tonu, maskot ve görseller özgün; düzen benzerliği serbest, birebir kopya varlık kullanılmaz; mağaza metninde TV Time adı geçmez. |
| R3 | Supabase ücretsiz katman limitleri (veritabanı ~500 MB, Storage ~1 GB) veya hareketsizlikte duraklatma | Orta — hizmet kesintisi | `tmdb-sync` cron'u günlük istek üretir; aylık kullanım panelden kontrol edilir; %80 dolulukta Pro plana geçiş kararı verilir. Limitler kurulum günü Supabase sayfasından teyit edilir. |
| R4 | Kullanıcı içeriği (yorum, avatar) nedeniyle App Store reddi (Guideline 1.2) | Yüksek | F15 (şikayet, engelleme, filtre), 24 saat inceleme taahhüdü (§5.4), Kullanım Şartları'nda sıfır tolerans maddesi. |
| R5 | MVP kapsamı tek geliştirici için geniş (18 özellik) | Orta — gecikme | Aşamalar sıralı ve her biri kendi başına çalışır; 12 haftada 5. aşama bitmezse F14, F13 ve F18(f) "Sonraki Sürümler"e taşınır (kullanıcı onayıyla). |
| R6 | TMDB'de eksik bölüm süresi, yayın tarihi veya kadro bilgisi | Düşük | Süre için 45 dk varsayılan; tarihsiz bölüm "yayınlanmamış" sayılır; kadrosuz bölümde F10 gizlenir. |
| R8 | Windows'ta iOS derlenemez ve iOS simülatörü yoktur; Codemagic ücretsiz dakikaları biterse iOS build alınamaz | Orta — iOS testi gecikir | Günlük geliştirme Android emülatörde yapılır; iOS build'i yalnızca aşama sonlarında alınır; iOS kontrolü TestFlight ile gerçek cihazda yapılır; dakika biterse ücretli plana veya kiralık Mac'e geçiş kararı kullanıcıya bırakılır. |
| R7 | Spoiler sızıntısı (bildirimde, önizlemede yorum metni) | Orta — kullanıcı memnuniyeti | Bildirimler yorum metni içermez; yorum önizlemesi hiçbir listede gösterilmez. |

## 8. Varsayımlar

Kullanıcı tarafından onaylanmamış, sonradan değiştirilebilir kararlar. Etkisi büyükten küçüğe sıralıdır.

- **V1:** Dizi verisi (afiş, bölüm listesi, yayın tarihi, kadro) **TMDB API v3**'ten gelir; ticari olmayan ücretsiz kullanım şartlarıyla başlanır (R1).
- **V2:** Uygulamanın geçici adı **Sezonluk**; uygulama kimliği `com.sezonluk.app`, derin bağlantı şeması `sezonluk://`. Mağazaya göndermeden önce ad için marka araştırması yapılır; ad değişirse yalnızca Android `android:label`, iOS `CFBundleDisplayName`, `app_tr.arb` ve mağaza metinleri güncellenir. `applicationId`/bundle id `flutter create` sonrası elle `com.sezonluk.app` yapılır.
- **V3:** İstemci **Flutter (stable kanal) + Dart 3**; tek kod tabanından iOS ve Android. Durum yönetimi Riverpod (kod üretimi olmadan), gezinme `go_router`. Modeller elle yazılmış `fromJson`/`toJson` ile; `freezed`/`json_serializable` kod üretimi kullanılmaz (V23).
- **V4:** Arka uç **Supabase Free plan**; kendi sunucu yok.
- **V5:** Tek geliştirici + AI agent, haftada ~15 saat, ~12 hafta.
- **V6:** İlk 6 ayda ≤ 1.000 kullanıcı; ücretsiz katman yeterli.
- **V7:** Kimlik doğrulama e-posta+şifre; ayrıca hesapsız gezinme için Supabase anonim girişi (F19, kullanıcı kararı 2026-10-17). Sosyal giriş yok (bu yüzden Apple ile Giriş zorunlu değil).
- **V8:** Arayüz yalnızca Türkçe; metinler i18n dosyasında, İngilizce sonraki sürümde.
- **V9:** Kapak görseli kullanıcı yüklemesi değil, kullanıcının listesindeki bir dizinin TMDB arka planıdır (moderasyon ve depolama yükünü azaltır). Kapak seçilmemişse en son izlenen dizinin arka planı, o da yoksa düz `surface` rengi kullanılır.
- **V10:** Tüm profiller ve izleme listeleri herkese açık; gizli profil yok.
- **V11:** Bildirimler yalnızca uygulama içi; push bildirimi sonraki sürüm.
- **V12:** "Bölümün yıldızı" bölümdeki oyunculardan seçilir (karakter adıyla birlikte).
- **V13:** Bölüm başına kullanıcı başına tek emoji tepkisi; 12 sabit tepki (F9a).
- **V14:** "Bir süredir izlemediklerin" eşiği 30 gün; Yaklaşan ufku 90 gün.
- **V15:** İzleme süresi hesabında 1 ay = 30 gün; süresi bilinmeyen bölüm 45 dk.
- **V16:** Rozet seti 15 adet (F14); rozet ikonları özgün olarak çizilir (sarı halka, koyu zemin, eşik yazısı).
- **V17:** Yönetim (şikayet inceleme, yorum gizleme) Supabase Dashboard'dan elle yapılır; ayrı admin paneli yok.
- **V18:** Geliştirme makinesi Windows; gerekli araçlar: Flutter SDK (stable), Android Studio + emülatör, Docker Desktop, Supabase CLI (Scoop ile), Maestro CLI (Aşama 7). Node.js gerekmez.
- **V19:** Uygulama yalnızca telefon, dikey yön, koyu tema.
- **V20:** Reklam/premium eklenebilmesi için ekran düzeninde yer ayrılmaz; eklenirken ayrı bir tasarım turu yapılır (önce R1 çözülmeli).
- **V22:** iOS build'i ve mağaza yüklemeleri Codemagic (ücretsiz katman) ile yapılır; `codemagic.yaml` depoda tutulur, imza sertifikaları Codemagic panelinde saklanır.
- **V23:** Supabase'in Dart için resmi tip üretici aracı olmadığından tablo modelleri elle yazılır; her modelin `fromJson` ayrıştırması birim testiyle doğrulanır.
- **V24:** Öneriler sayfası (F18) alt menüde ayrı sekme değildir; alt menü 3 sekme (Diziler · Keşfet · Profil) kalsın diye Keşfet'in üstündeki karttan açılır.
- **V25:** "Kategori" = TMDB dizi türü (Dram, Komedi, Suç, Bilim Kurgu & Fantastik vb.); öneriler TMDB `discover` ve `recommendations` sonuçlarıdır, kişiselleştirme kullanıcının listesindeki türler ve son izlediği diziyle sınırlıdır.
- **V26:** Geliştirme, disk ve Docker yükünü azaltmak için yerel Supabase yığını yerine Supabase bulutundaki ayrı bir
  geliştirme projesinde (`sezonluk-dev`, Frankfurt) yapılır; migration'lar `supabase db push`, testler
  `supabase test db --linked` ile çalışır. CI (GitHub Actions) yerel yığını GitHub sunucusunda kurmaya devam eder.
  Ücretsiz planda 2 aktif proje sınırı olduğundan yayın projesinin nasıl açılacağı Aşama 7'den önce kararlaştırılır.
  Kullanıcı kararıyla geliştirme projesinin açılması ve bağlanması en sona ertelenmiştir: o zamana kadar migration ve
  pgTAP testleri yazılır ama uygulanmaz/çalıştırılmaz; aşama raporlarında "veritabanı doğrulaması ertelendi" yazılır.
- **V27:** Durum grubu renkleri §3.7'deki tonlardır; Durduruldu ve Dönülmez yalnızca elle seçilir, otomatik hesap bu ikisini hiç üretmez (kullanıcı kararı 2026-10-17).
- **V28:** Profil düzeni bir dizi takip uygulamasının profil ekran görüntüsüne göre kuruldu (favoriler, şu an izlediklerim, son etkinlik); Dizilerim sekmesi Diziler'den profile taşındı, Diziler sekmesi tek sayfa oldu (kullanıcı kararları 2026-10-17).
- **V29:** Diziler ana ekranının Afiş görünümü bir dizi takip uygulamasının ana ekran görüntüsüne göre kuruldu; düzen benzer, görseller ve renkler özgündür (R2) (kullanıcı kararı 2026-10-18).
- **V21:** Gizlilik/destek iletişimi için uygulamaya özel bir e-posta adresi (ör. ücretsiz bir posta hizmetinde) yayından önce açılır; yasal metinler GitHub Pages ile bu depodan yayınlanır.
