// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Sezonluk';

  @override
  String get tabShows => 'Diziler';

  @override
  String get tabDiscover => 'Keşfet';

  @override
  String get tabProfile => 'Profil';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get save => 'Kaydet';

  @override
  String get errorNetwork =>
      'İnternet bağlantısı yok. Bağlantını kontrol edip tekrar dene.';

  @override
  String get errorUnknown => 'Bir şeyler ters gitti.';

  @override
  String get errorInvalidCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get errorEmailNotConfirmed =>
      'E-postanı doğrula. Gelen kutundaki bağlantıya dokunduktan sonra giriş yapabilirsin.';

  @override
  String get errorUsernameTaken => 'Bu kullanıcı adı alınmış.';

  @override
  String get errorWeakPassword => 'Şifre en az 8 karakter olmalı.';

  @override
  String get errorSamePassword => 'Yeni şifre eskisiyle aynı olamaz.';

  @override
  String get errorRateLimited =>
      'Çok fazla deneme yaptın. Biraz bekleyip tekrar dene.';

  @override
  String get errorFileTooLarge => 'Görsel 2 MB\'tan büyük olamaz.';

  @override
  String get errorLinkOpen => 'Bağlantı açılamadı.';

  @override
  String get fieldEmail => 'E-posta';

  @override
  String get fieldPassword => 'Şifre';

  @override
  String get fieldNewPassword => 'Yeni şifre';

  @override
  String get fieldPasswordRepeat => 'Şifre (tekrar)';

  @override
  String get fieldUsername => 'Kullanıcı adı';

  @override
  String get fieldDisplayName => 'Görünen ad';

  @override
  String get fieldBio => 'Biyografi';

  @override
  String get fieldCountry => 'Ülke';

  @override
  String get validationEmailInvalid => 'Geçerli bir e-posta adresi gir.';

  @override
  String get validationPasswordShort => 'Şifre en az 8 karakter olmalı.';

  @override
  String get validationPasswordMismatch => 'Şifreler eşleşmiyor.';

  @override
  String get validationUsernameFormat =>
      '3–20 karakter; yalnızca küçük harf, rakam ve _ kullanılabilir.';

  @override
  String get validationDisplayNameLength => 'Görünen ad 1–40 karakter olmalı.';

  @override
  String get validationBioLength => 'Biyografi en fazla 160 karakter olabilir.';

  @override
  String get signInTitle => 'Giriş yap';

  @override
  String get signInButton => 'Giriş yap';

  @override
  String get signInToSignUp => 'Hesabın yok mu? Kayıt ol';

  @override
  String get signInForgotPassword => 'Şifremi unuttum';

  @override
  String get signUpTitle => 'Kayıt ol';

  @override
  String get signUpButton => 'Kayıt ol';

  @override
  String get signUpToSignIn => 'Zaten hesabın var mı? Giriş yap';

  @override
  String get signUpConsent =>
      'Kullanım Şartları\'nı ve Gizlilik Politikası\'nı okudum, kabul ediyorum.';

  @override
  String get termsOfUse => 'Kullanım Şartları';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get signUpCheckEmailTitle => 'E-postanı doğrula';

  @override
  String signUpCheckEmailBody(String email) {
    return '$email adresine bir doğrulama bağlantısı gönderdik. Bağlantıya dokunduktan sonra giriş yapabilirsin.';
  }

  @override
  String get backToSignIn => 'Girişe dön';

  @override
  String get forgotPasswordTitle => 'Şifremi unuttum';

  @override
  String get forgotPasswordBody =>
      'Hesabının e-posta adresini gir; şifreni sıfırlaman için bir bağlantı gönderelim.';

  @override
  String get forgotPasswordButton => 'Bağlantı gönder';

  @override
  String get forgotPasswordSent =>
      'E-posta gönderildi. Gelen kutundaki bağlantı uygulamada yeni şifre ekranını açar.';

  @override
  String get resetPasswordTitle => 'Yeni şifre belirle';

  @override
  String get resetPasswordButton => 'Şifreyi kaydet';

  @override
  String get resetPasswordDone => 'Şifren güncellendi.';

  @override
  String get editProfileTitle => 'Profili düzenle';

  @override
  String get changeAvatar => 'Avatarı değiştir';

  @override
  String get countryNone => 'Belirtilmemiş';

  @override
  String get countryPickerTitle => 'Ülke seç';

  @override
  String get countrySearchHint => 'Ülke kodu ara (ör. TR)';

  @override
  String get profileSaved => 'Profil kaydedildi.';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get errorTmdbUnavailable =>
      'Dizi bilgileri şu an alınamıyor. Biraz sonra tekrar dene.';

  @override
  String get saveFailed => 'Kaydedilemedi, tekrar dene.';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get noResults => 'Sonuç bulunamadı';

  @override
  String get discoverSegmentShows => 'Diziler';

  @override
  String get discoverSegmentUsers => 'Kullanıcılar';

  @override
  String get discoverSearchShowsHint => 'Dizi ara';

  @override
  String get discoverSearchUsersHint => 'Kullanıcı adı ara';

  @override
  String get discoverSearchMinChars => 'Aramak için en az 2 karakter yaz.';

  @override
  String get showStatusOngoing => 'Devam ediyor';

  @override
  String get showStatusEnded => 'Bitti';

  @override
  String get showAdd => 'Ekle';

  @override
  String get showRemove => 'Listeden çıkar';

  @override
  String get showRemoveConfirmTitle => 'Listeden çıkarılsın mı?';

  @override
  String showRemoveConfirmBody(String name) {
    return '$name listenden çıkarılacak ve bu diziye ait izleme kayıtların silinecek.';
  }

  @override
  String get showRemoveConfirmButton => 'Çıkar';

  @override
  String get showSeasons => 'Sezonlar';

  @override
  String get showSpecials => 'Özel Bölümler';

  @override
  String seasonTitle(int number) {
    return '$number. Sezon';
  }

  @override
  String seasonEpisodeCount(int count) {
    return '$count bölüm';
  }

  @override
  String get episodeNoAirDate => 'Yayın tarihi belli değil';

  @override
  String get seasonNoEpisodes => 'Bu sezonun bölüm bilgisi henüz yok.';

  @override
  String get showsEmpty => 'Henüz dizi eklemedin';

  @override
  String get showsGoToDiscover => 'Keşfet\'e git';

  @override
  String get tabWatchlist => 'Sıradaki';

  @override
  String get tabUpcoming => 'Yaklaşan';

  @override
  String get watchlistUpNext => 'İzlemeye devam et';

  @override
  String get watchlistNotRecently => 'Bir süredir izlemediklerin';

  @override
  String get watchlistAllCaughtUp => 'İzleyecek yeni bölüm yok';

  @override
  String markNextEpisode(String code) {
    return '$code bölümünü izledim';
  }

  @override
  String get upcomingEmpty => 'Yaklaşan bölüm yok';

  @override
  String get upcomingToday => 'Bugün';

  @override
  String get upcomingTomorrow => 'Yarın';

  @override
  String get seasonMarkAll => 'Sezonun tamamını izledim';

  @override
  String get episodeMarkUntil => 'Buraya kadar izledim';

  @override
  String get episodeMarkWatched => 'İzlendi';

  @override
  String get episodeTitle => 'Bölüm';

  @override
  String get profileNotifications => 'Bildirimler';

  @override
  String get profileShare => 'Profili paylaş';

  @override
  String profileShareText(String link) {
    return 'Sezonluk\'ta izlediğim dizilere göz at: $link';
  }

  @override
  String get statWatchTimeTitle => 'Dizi izleme süresi';

  @override
  String statWatchTimeValue(int months, int days, int hours) {
    return '$months ay $days gün $hours saat';
  }

  @override
  String get statEpisodesTitle => 'İzlenen bölüm';

  @override
  String get statFollowers => 'Takipçi';

  @override
  String get statFollowing => 'Takip';

  @override
  String get statBadges => 'Rozet';

  @override
  String get profileMyShows => 'Dizilerim';

  @override
  String get profileSeeAll => 'Tümü';

  @override
  String get profileNoShows => 'Henüz dizi eklenmemiş.';

  @override
  String get fieldCover => 'Kapak';

  @override
  String get coverNone => 'Otomatik';

  @override
  String get coverPickerTitle => 'Kapak seç';

  @override
  String get coverPickerHint =>
      'Bir dizi seç, sonra o dizinin arka plan görsellerinden birini kapak yap. Seçmezsen en son izlediğin dizi kullanılır.';

  @override
  String get suggestCardTitle => 'Sana Özel Öneriler';

  @override
  String get suggestTitle => 'Sana Özel Öneriler';

  @override
  String get suggestMaxGenres => 'En fazla 3 kategori seçebilirsin';

  @override
  String get suggestPickGenre => 'Öneri almak için en az bir kategori seç';

  @override
  String get suggestEmpty => 'Bu kategorilerde yeni öneri kalmadı';

  @override
  String get suggestByGenre => 'Seçtiğin kategorilerden';

  @override
  String suggestSimilarTitle(String name) {
    return '$name izlediğin için';
  }

  @override
  String suggestAddShow(String name) {
    return '$name listene ekle';
  }

  @override
  String get errorCommentRateLimited =>
      'Çok hızlı yorum yapıyorsun. Biraz bekleyip tekrar dene.';

  @override
  String get errorCommentBannedWord => 'Yorumun uygunsuz bir ifade içeriyor.';

  @override
  String get reactionsTitle => 'Ruh hâlin';

  @override
  String get reactionFunny => 'Komik';

  @override
  String get reactionLove => 'Bayıldım';

  @override
  String get reactionShocked => 'Şok oldum';

  @override
  String get reactionSad => 'Hüzünlendim';

  @override
  String get reactionAngry => 'Sinirlendim';

  @override
  String get reactionBored => 'Sıkıldım';

  @override
  String percent(int value) {
    return '%$value';
  }

  @override
  String get starTitle => 'Bölümün yıldızı';

  @override
  String get starNoCast => 'Bu bölüm için oyuncu bilgisi yok';

  @override
  String get starResultsTitle => 'En çok oy alanlar';

  @override
  String starVoteFor(String name) {
    return '$name için oy ver';
  }

  @override
  String get commentsTitle => 'Yorumlar';

  @override
  String get commentHint => 'Yorumunu yaz';

  @override
  String get commentSpoilerSwitch => 'Spoiler içeriyor';

  @override
  String get commentSend => 'Gönder';

  @override
  String get commentTooLong => 'Yorum 1–500 karakter olmalı.';

  @override
  String get commentsEmpty => 'Henüz yorum yok. İlk yorumu sen yaz.';

  @override
  String get commentsSpoilerGate =>
      'Bu bölümü izlemedin, yorumlar spoiler içerebilir';

  @override
  String get commentsShowAnyway => 'Yine de göster';

  @override
  String get commentSpoilerHidden => 'Spoiler içeriyor — görmek için dokun';

  @override
  String get commentsLoadMore => 'Daha fazla yorum';

  @override
  String get commentLike => 'Beğen';

  @override
  String get commentUnlike => 'Beğeniyi geri al';

  @override
  String get commentMenu => 'Yorum seçenekleri';

  @override
  String get commentDelete => 'Sil';

  @override
  String get commentDeleteConfirm => 'Yorumun silinsin mi?';

  @override
  String get report => 'Şikayet et';

  @override
  String get reportTitle => 'Şikayet nedeni';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Taciz';

  @override
  String get reportReasonSpoiler => 'Spoiler';

  @override
  String get reportReasonInappropriate => 'Uygunsuz içerik';

  @override
  String get reportReasonOther => 'Diğer';

  @override
  String get reportNoteHint => 'Not (isteğe bağlı)';

  @override
  String get reportSend => 'Gönder';

  @override
  String get reportSent => 'Şikayetin alındı. İnceleyeceğiz.';

  @override
  String get block => 'Engelle';

  @override
  String blockConfirmTitle(String name) {
    return '$name engellensin mi?';
  }

  @override
  String get blockConfirmBody =>
      'Yorumlarını görmeyeceksin ve seni takip edemeyecek.';

  @override
  String blockDone(String name) {
    return '$name engellendi.';
  }

  @override
  String get blockedUsersTitle => 'Engellenenler';

  @override
  String get blockedUsersEmpty => 'Kimseyi engellemedin.';

  @override
  String get unblock => 'Engeli kaldır';

  @override
  String get follow => 'Takip et';

  @override
  String get following => 'Takip ediliyor';

  @override
  String get profileMenu => 'Profil seçenekleri';

  @override
  String get followersTitle => 'Takipçiler';

  @override
  String get followingTitle => 'Takip edilenler';

  @override
  String get followersEmpty => 'Henüz takipçi yok.';

  @override
  String get followingEmpty => 'Henüz kimse takip edilmiyor.';

  @override
  String get userShowsTitle => 'Diziler';

  @override
  String get notificationsTitle => 'Bildirimler';

  @override
  String get notificationsEmpty => 'Son 90 günde bildirim yok.';

  @override
  String notificationNewFollower(String name) {
    return '$name seni takip etmeye başladı.';
  }

  @override
  String notificationCommentLiked(String name) {
    return '$name yorumunu beğendi.';
  }

  @override
  String notificationBadgeEarned(String badge) {
    return '\"$badge\" rozetini kazandın!';
  }

  @override
  String get notificationDeletedUser => 'Bir kullanıcı';

  @override
  String get badgesTitle => 'Rozetler';

  @override
  String badgeEarnedOn(String date) {
    return '$date tarihinde kazanıldı';
  }

  @override
  String get badgeLocked => 'Henüz kazanılmadı';

  @override
  String get errorUsernameMismatch => 'Kullanıcı adı eşleşmiyor.';

  @override
  String get deleteAccountTitle => 'Hesabı sil';

  @override
  String get deleteAccountBody =>
      'Hesabın, profilin, izleme geçmişin, yorumların, tepkilerin, takip ilişkilerin ve avatarın kalıcı olarak silinir. Bu işlem geri alınamaz.';

  @override
  String deleteAccountPrompt(String username) {
    return 'Onaylamak için kullanıcı adını yaz: $username';
  }

  @override
  String get deleteAccountButton => 'Hesabımı kalıcı olarak sil';

  @override
  String get aboutTitle => 'Hakkında';

  @override
  String get aboutTmdbAttribution =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  String get aboutTmdbLogo => 'TMDB logosu';

  @override
  String aboutVersion(String version) {
    return 'Sürüm $version';
  }

  @override
  String get guestContinue => 'Misafir olarak devam et';

  @override
  String get guestGateTitle => 'Bu özellik için hesap oluştur';

  @override
  String get guestGateBody =>
      'Dizilerini takip etmek, bölüm işaretlemek, yorum yapmak ve arkadaşlarını takip etmek için ücretsiz bir hesap aç.';

  @override
  String get guestHaveAccount => 'Hesabım var, giriş yap';

  @override
  String get reactionMindblown => 'Kafam yandı';

  @override
  String get reactionScared => 'Korktum';

  @override
  String get reactionEpic => 'Efsane';

  @override
  String get reactionThoughtful => 'Düşündürdü';

  @override
  String get reactionTouched => 'Duygulandım';

  @override
  String get reactionTense => 'Gerildim';

  @override
  String get onTheAirTitle => 'Şu an yayında';

  @override
  String episodeStill(String code) {
    return '$code sahnesi';
  }

  @override
  String get episodeWatched => 'İzlendi';

  @override
  String get episodeMarkAsWatched => 'İzledim olarak işaretle';

  @override
  String episodeRuntime(int minutes) {
    return '$minutes dk';
  }

  @override
  String get watchlistNotStarted => 'Henüz başlamadıkların';

  @override
  String get seasonPremiere => 'Sezon başı';

  @override
  String remainingEpisodes(int count) {
    return '+$count';
  }

  @override
  String get showTabAbout => 'Hakkında';

  @override
  String get showTabEpisodes => 'Bölümler';

  @override
  String get showNextEpisode => 'Sıradaki';

  @override
  String get showAllWatched => 'Hepsini izledin!';

  @override
  String get showAllEpisodes => 'Tüm bölümler';

  @override
  String seasonProgress(int watched, int total) {
    return '$watched/$total';
  }

  @override
  String get seasonCompleted => 'Sezon tamamlandı';

  @override
  String get discoverPopularTitle => 'En ünlü diziler';

  @override
  String get showCastTitle => 'Oyuncular';

  @override
  String get showCastEmpty => 'Oyuncu bilgisi yok.';

  @override
  String get seasonExpand => 'Bölümleri göster';

  @override
  String get seasonCollapse => 'Bölümleri gizle';

  @override
  String get ratingTitle => 'Puanın';

  @override
  String get ratingNone => 'Henüz puan verilmedi.';

  @override
  String ratingAverage(String average, int count) {
    return 'Ortalama $average · $count puan';
  }

  @override
  String ratingStar(int count) {
    return '$count yıldız';
  }

  @override
  String get episodeLike => 'Bölümü beğen';

  @override
  String get episodeUnlike => 'Beğeniyi geri al';

  @override
  String get coverNoImages => 'Bu dizinin arka plan görseli yok.';

  @override
  String get coverChosen => 'Seçili görsel';

  @override
  String get pickerMyShows => 'Listendeki diziler';

  @override
  String get pickerSearchResults => 'Arama sonuçları';

  @override
  String get pickerSearchHint => 'Bir dizi ara.';

  @override
  String get avatarFromGallery => 'Galeriden seç';

  @override
  String get statusFinished => 'Bitti';

  @override
  String get statusUpToDate => 'Güncel';

  @override
  String get statusWatching => 'Devam ediyor';

  @override
  String get statusPaused => 'Durduruldu';

  @override
  String get statusDropped => 'Dönülmez';

  @override
  String get statusWatchlist => 'İzleme Listesi';

  @override
  String statusAuto(String status) {
    return 'Otomatik ($status)';
  }

  @override
  String get statusMenuTitle => 'Dizi durumu';

  @override
  String get statusFilterAll => 'Tümü';

  @override
  String get statusFilterEmpty => 'Bu grupta dizi yok.';

  @override
  String statusProgressLabel(String status, int watched, int aired) {
    return '$status, $watched/$aired bölüm izlendi';
  }

  @override
  String get avatarFromShow => 'Dizi görsellerinden seç';

  @override
  String get avatarPickerTitle => 'Görsel seç';

  @override
  String get avatarNoImages => 'Bu dizinin görseli yok.';

  @override
  String get cropTitle => 'Kırp';

  @override
  String get cropHint => 'Sürükleyip yakınlaştırarak kareyi ayarla.';

  @override
  String get cropDone => 'Kullan';

  @override
  String get fieldLetterboxd => 'Letterboxd profil bağlantısı';

  @override
  String get fieldInstagram => 'Instagram profil bağlantısı';

  @override
  String get validationLetterboxd =>
      'Geçerli bir Letterboxd profil bağlantısı gir (letterboxd.com/kullaniciadi; kısa boxd.it bağlantıları olmaz).';

  @override
  String get validationInstagram =>
      'Geçerli bir Instagram profil bağlantısı gir (instagram.com/kullaniciadi).';

  @override
  String get recentShowsTitle => 'Son izlenen diziler';

  @override
  String get upcomingShowAll => 'Tümünü göster';

  @override
  String get upcomingShowLess => 'Daha az göster';

  @override
  String get profileFavorites => 'Favori diziler';

  @override
  String get profileFavoritesHint =>
      'Dizi detayındaki kalp düğmesiyle en fazla 4 favori seçebilirsin.';

  @override
  String get profileWatching => 'Şu an izlediklerim';

  @override
  String get profileWatchingEmpty => 'Şu an izlediğin dizi yok.';

  @override
  String get profileRecentActivity => 'Son etkinlik';

  @override
  String profileSince(String date) {
    return '$date tarihinden beri';
  }

  @override
  String get favoriteAdd => 'Favorilere ekle';

  @override
  String get favoriteRemove => 'Favorilerden çıkar';

  @override
  String get favoritesLimit => 'En fazla 4 favori seçebilirsin.';

  @override
  String get layoutMenu => 'Görünüm';

  @override
  String get layoutList => 'Liste';

  @override
  String get layoutGrid => 'Izgara';

  @override
  String get layoutPoster => 'Afiş';

  @override
  String get friendsActivityTitle => 'Arkadaşların ne izliyor';

  @override
  String friendRating(String rating) {
    return '$rating yıldız';
  }

  @override
  String profileSaveFailedHint(String reason) {
    return 'Profil kaydedilemedi: $reason';
  }

  @override
  String get validationFixFields => 'Kırmızı işaretli alanları düzelt.';

  @override
  String get hintLetterboxd => 'https://letterboxd.com/kullaniciadi/';

  @override
  String get hintInstagram => 'https://www.instagram.com/kullaniciadi/';

  @override
  String get profileRatings => 'Puanlar';

  @override
  String profileRatingsSummary(int count, String average) {
    return '$count puan · ortalama $average';
  }

  @override
  String get profileRatingsEmpty =>
      'Bölüm Sonrası ekranında verdiğin puanlar burada grafik olarak görünür.';

  @override
  String ratingBarLabel(String rating, int count) {
    return '$rating yıldız: $count bölüm';
  }

  @override
  String get posterPickerTitle => 'Afiş';

  @override
  String get posterPickerEmpty => 'Bu dizinin başka afişi yok.';

  @override
  String get posterDefault => 'Varsayılan';

  @override
  String get tabNotifications => 'Bildirimler';

  @override
  String get notificationsMe => 'Ben';

  @override
  String get notificationsFriends => 'Arkadaşlar';

  @override
  String get friendsFeedEmpty =>
      'Takip ettiğin kişilerin izlediği bölümler, puanları ve rozetleri burada görünür.';

  @override
  String feedWatchedOne(String user, String show, String code) {
    return '@$user izledi: $show · $code';
  }

  @override
  String feedWatchedMany(String user, int count, String show) {
    return '@$user $count bölüm izledi: $show';
  }

  @override
  String feedRated(String user, String show, String code, String rating) {
    return '@$user puan verdi: $show · $code · $rating ★';
  }

  @override
  String feedBadge(String user, String badge) {
    return '@$user \"$badge\" rozetini kazandı';
  }

  @override
  String unreadNotifications(int count) {
    return '$count okunmamış bildirim';
  }

  @override
  String get settingsColors => 'Renk';

  @override
  String get settingsColorsHint =>
      'Uygulamanın vurgu rengini ve zemin tonlarını seç. Seçim hemen uygulanır.';

  @override
  String get paletteYellow => 'Sarı';

  @override
  String get palettePurple => 'Mor';

  @override
  String get paletteBlue => 'Mavi';

  @override
  String get paletteGreen => 'Yeşil';

  @override
  String get paletteRed => 'Kırmızı';

  @override
  String get paletteOrange => 'Turuncu';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguageHint =>
      'Arayüz dili hemen değişir. Dizi ve bölüm adları ile özetler şimdilik Türkçe gösterilir.';

  @override
  String get languageSystem => 'Telefonun dili';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'English';

  @override
  String get badgeFirstEpisodeName => 'İlk Bölüm';

  @override
  String get badgeFirstEpisodeDesc => 'İlk bölümünü izlendi olarak işaretle.';

  @override
  String get badgeEpisodes10Name => 'Isınma Turu';

  @override
  String get badgeEpisodes10Desc => '10 bölüm izle.';

  @override
  String get badgeEpisodes50Name => 'Alışkanlık';

  @override
  String get badgeEpisodes50Desc => '50 bölüm izle.';

  @override
  String get badgeEpisodes100Name => 'Dizi Kurdu';

  @override
  String get badgeEpisodes100Desc => '100 bölüm izle.';

  @override
  String get badgeEpisodes500Name => 'Ekran Bağımlısı';

  @override
  String get badgeEpisodes500Desc => '500 bölüm izle.';

  @override
  String get badgeEpisodes1000Name => 'Maraton Ustası';

  @override
  String get badgeEpisodes1000Desc => '1.000 bölüm izle.';

  @override
  String get badgeEpisodes5000Name => 'Efsane İzleyici';

  @override
  String get badgeEpisodes5000Desc => '5.000 bölüm izle.';

  @override
  String get badgeShows10Name => 'Koleksiyoncu';

  @override
  String get badgeShows10Desc => 'Listene 10 dizi ekle.';

  @override
  String get badgeShows25Name => 'Arşivci';

  @override
  String get badgeShows25Desc => 'Listene 25 dizi ekle.';

  @override
  String get badgeShows50Name => 'Kütüphaneci';

  @override
  String get badgeShows50Desc => 'Listene 50 dizi ekle.';

  @override
  String get badgeFirstFinishedName => 'Final Sahnesi';

  @override
  String get badgeFirstFinishedDesc =>
      'Bitmiş bir dizinin tüm bölümlerini izle.';

  @override
  String get badgeFinished5Name => 'Bitirici';

  @override
  String get badgeFinished5Desc => 'Bitmiş 5 dizinin tüm bölümlerini izle.';

  @override
  String get badgeFirstCommentName => 'İlk Söz';

  @override
  String get badgeFirstCommentDesc => 'İlk yorumunu yaz.';

  @override
  String get badgeComments10Name => 'Sohbetçi';

  @override
  String get badgeComments10Desc => '10 yorum yaz.';

  @override
  String get badgeComments50Name => 'Eleştirmen';

  @override
  String get badgeComments50Desc => '50 yorum yaz.';

  @override
  String meWatchedOne(String show, String code) {
    return 'İzledin: $show · $code';
  }

  @override
  String meWatchedMany(int count, String show) {
    return '$count bölüm izledin: $show';
  }

  @override
  String get discoverSearchTooltip => 'Ara';

  @override
  String socialLetterboxdLabel(String name) {
    return 'Letterboxd: $name';
  }

  @override
  String socialInstagramLabel(String name) {
    return 'Instagram: $name';
  }
}
