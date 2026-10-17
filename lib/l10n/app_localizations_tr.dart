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
  String get profileEdit => 'Düzenle';

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
  String get discoverTrendingTitle => 'Haftanın trend dizileri';

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
  String get tabWatchlist => 'İzleme Listesi';

  @override
  String get tabUpcoming => 'Yaklaşan';

  @override
  String get watchlistUpNext => 'Sıradaki';

  @override
  String get watchlistNotRecently => 'Bir süredir izlemediklerin';

  @override
  String get watchlistAllCaughtUp => 'İzleyecek yeni bölüm yok';

  @override
  String get watchlistShowGrid => 'Izgara görünümü';

  @override
  String get watchlistShowList => 'Liste görünümü';

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
  String get episodeFeedbackSoon =>
      'Tepkiler, bölümün yıldızı ve yorumlar burada olacak.';
}
