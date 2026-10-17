import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('tr')];

  /// Uygulamanın görünen adı (geçici ad, ISKELET.md V2).
  ///
  /// In tr, this message translates to:
  /// **'Sezonluk'**
  String get appTitle;

  /// Alt menü: izleme listesi ve yaklaşan bölümler sekmesi.
  ///
  /// In tr, this message translates to:
  /// **'Diziler'**
  String get tabShows;

  /// Alt menü: dizi/kullanıcı arama ve trendler sekmesi.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get tabDiscover;

  /// Alt menü: kullanıcının kendi profili sekmesi.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @errorNetwork.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok. Bağlantını kontrol edip tekrar dene.'**
  String get errorNetwork;

  /// No description provided for @errorUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Bir şeyler ters gitti.'**
  String get errorUnknown;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya şifre hatalı.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailNotConfirmed.
  ///
  /// In tr, this message translates to:
  /// **'E-postanı doğrula. Gelen kutundaki bağlantıya dokunduktan sonra giriş yapabilirsin.'**
  String get errorEmailNotConfirmed;

  /// No description provided for @errorUsernameTaken.
  ///
  /// In tr, this message translates to:
  /// **'Bu kullanıcı adı alınmış.'**
  String get errorUsernameTaken;

  /// No description provided for @errorWeakPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 8 karakter olmalı.'**
  String get errorWeakPassword;

  /// No description provided for @errorSamePassword.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre eskisiyle aynı olamaz.'**
  String get errorSamePassword;

  /// No description provided for @errorRateLimited.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla deneme yaptın. Biraz bekleyip tekrar dene.'**
  String get errorRateLimited;

  /// No description provided for @errorFileTooLarge.
  ///
  /// In tr, this message translates to:
  /// **'Görsel 2 MB\'tan büyük olamaz.'**
  String get errorFileTooLarge;

  /// No description provided for @errorLinkOpen.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı açılamadı.'**
  String get errorLinkOpen;

  /// No description provided for @fieldEmail.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get fieldPassword;

  /// No description provided for @fieldNewPassword.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre'**
  String get fieldNewPassword;

  /// No description provided for @fieldPasswordRepeat.
  ///
  /// In tr, this message translates to:
  /// **'Şifre (tekrar)'**
  String get fieldPasswordRepeat;

  /// No description provided for @fieldUsername.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı'**
  String get fieldUsername;

  /// No description provided for @fieldDisplayName.
  ///
  /// In tr, this message translates to:
  /// **'Görünen ad'**
  String get fieldDisplayName;

  /// No description provided for @fieldBio.
  ///
  /// In tr, this message translates to:
  /// **'Biyografi'**
  String get fieldBio;

  /// No description provided for @fieldCountry.
  ///
  /// In tr, this message translates to:
  /// **'Ülke'**
  String get fieldCountry;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi gir.'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordShort.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 8 karakter olmalı.'**
  String get validationPasswordShort;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor.'**
  String get validationPasswordMismatch;

  /// No description provided for @validationUsernameFormat.
  ///
  /// In tr, this message translates to:
  /// **'3–20 karakter; yalnızca küçük harf, rakam ve _ kullanılabilir.'**
  String get validationUsernameFormat;

  /// No description provided for @validationDisplayNameLength.
  ///
  /// In tr, this message translates to:
  /// **'Görünen ad 1–40 karakter olmalı.'**
  String get validationDisplayNameLength;

  /// No description provided for @validationBioLength.
  ///
  /// In tr, this message translates to:
  /// **'Biyografi en fazla 160 karakter olabilir.'**
  String get validationBioLength;

  /// No description provided for @signInTitle.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get signInTitle;

  /// No description provided for @signInButton.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get signInButton;

  /// No description provided for @signInToSignUp.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu? Kayıt ol'**
  String get signInToSignUp;

  /// No description provided for @signInForgotPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi unuttum'**
  String get signInForgotPassword;

  /// No description provided for @signUpTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt ol'**
  String get signUpTitle;

  /// No description provided for @signUpButton.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt ol'**
  String get signUpButton;

  /// No description provided for @signUpToSignIn.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı? Giriş yap'**
  String get signUpToSignIn;

  /// No description provided for @signUpConsent.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Şartları\'nı ve Gizlilik Politikası\'nı okudum, kabul ediyorum.'**
  String get signUpConsent;

  /// No description provided for @termsOfUse.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Şartları'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicy;

  /// No description provided for @signUpCheckEmailTitle.
  ///
  /// In tr, this message translates to:
  /// **'E-postanı doğrula'**
  String get signUpCheckEmailTitle;

  /// No description provided for @signUpCheckEmailBody.
  ///
  /// In tr, this message translates to:
  /// **'{email} adresine bir doğrulama bağlantısı gönderdik. Bağlantıya dokunduktan sonra giriş yapabilirsin.'**
  String signUpCheckEmailBody(String email);

  /// No description provided for @backToSignIn.
  ///
  /// In tr, this message translates to:
  /// **'Girişe dön'**
  String get backToSignIn;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi unuttum'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordBody.
  ///
  /// In tr, this message translates to:
  /// **'Hesabının e-posta adresini gir; şifreni sıfırlaman için bir bağlantı gönderelim.'**
  String get forgotPasswordBody;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı gönder'**
  String get forgotPasswordButton;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In tr, this message translates to:
  /// **'E-posta gönderildi. Gelen kutundaki bağlantı uygulamada yeni şifre ekranını açar.'**
  String get forgotPasswordSent;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre belirle'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordButton.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi kaydet'**
  String get resetPasswordButton;

  /// No description provided for @resetPasswordDone.
  ///
  /// In tr, this message translates to:
  /// **'Şifren güncellendi.'**
  String get resetPasswordDone;

  /// No description provided for @profileEdit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get profileEdit;

  /// No description provided for @editProfileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profili düzenle'**
  String get editProfileTitle;

  /// No description provided for @changeAvatar.
  ///
  /// In tr, this message translates to:
  /// **'Avatarı değiştir'**
  String get changeAvatar;

  /// No description provided for @countryNone.
  ///
  /// In tr, this message translates to:
  /// **'Belirtilmemiş'**
  String get countryNone;

  /// No description provided for @countryPickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ülke seç'**
  String get countryPickerTitle;

  /// No description provided for @countrySearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Ülke kodu ara (ör. TR)'**
  String get countrySearchHint;

  /// No description provided for @profileSaved.
  ///
  /// In tr, this message translates to:
  /// **'Profil kaydedildi.'**
  String get profileSaved;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @signOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get signOut;

  /// No description provided for @errorTmdbUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Dizi bilgileri şu an alınamıyor. Biraz sonra tekrar dene.'**
  String get errorTmdbUnavailable;

  /// No description provided for @saveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilemedi, tekrar dene.'**
  String get saveFailed;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// No description provided for @noResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get noResults;

  /// No description provided for @discoverSegmentShows.
  ///
  /// In tr, this message translates to:
  /// **'Diziler'**
  String get discoverSegmentShows;

  /// No description provided for @discoverSegmentUsers.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcılar'**
  String get discoverSegmentUsers;

  /// No description provided for @discoverSearchShowsHint.
  ///
  /// In tr, this message translates to:
  /// **'Dizi ara'**
  String get discoverSearchShowsHint;

  /// No description provided for @discoverSearchUsersHint.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı ara'**
  String get discoverSearchUsersHint;

  /// No description provided for @discoverSearchMinChars.
  ///
  /// In tr, this message translates to:
  /// **'Aramak için en az 2 karakter yaz.'**
  String get discoverSearchMinChars;

  /// No description provided for @discoverTrendingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Haftanın trend dizileri'**
  String get discoverTrendingTitle;

  /// No description provided for @showStatusOngoing.
  ///
  /// In tr, this message translates to:
  /// **'Devam ediyor'**
  String get showStatusOngoing;

  /// No description provided for @showStatusEnded.
  ///
  /// In tr, this message translates to:
  /// **'Bitti'**
  String get showStatusEnded;

  /// No description provided for @showAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get showAdd;

  /// No description provided for @showRemove.
  ///
  /// In tr, this message translates to:
  /// **'Listeden çıkar'**
  String get showRemove;

  /// No description provided for @showRemoveConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Listeden çıkarılsın mı?'**
  String get showRemoveConfirmTitle;

  /// No description provided for @showRemoveConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'{name} listenden çıkarılacak ve bu diziye ait izleme kayıtların silinecek.'**
  String showRemoveConfirmBody(String name);

  /// No description provided for @showRemoveConfirmButton.
  ///
  /// In tr, this message translates to:
  /// **'Çıkar'**
  String get showRemoveConfirmButton;

  /// No description provided for @showSeasons.
  ///
  /// In tr, this message translates to:
  /// **'Sezonlar'**
  String get showSeasons;

  /// No description provided for @showSpecials.
  ///
  /// In tr, this message translates to:
  /// **'Özel Bölümler'**
  String get showSpecials;

  /// No description provided for @seasonTitle.
  ///
  /// In tr, this message translates to:
  /// **'{number}. Sezon'**
  String seasonTitle(int number);

  /// No description provided for @seasonEpisodeCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} bölüm'**
  String seasonEpisodeCount(int count);

  /// No description provided for @episodeNoAirDate.
  ///
  /// In tr, this message translates to:
  /// **'Yayın tarihi belli değil'**
  String get episodeNoAirDate;

  /// No description provided for @seasonNoEpisodes.
  ///
  /// In tr, this message translates to:
  /// **'Bu sezonun bölüm bilgisi henüz yok.'**
  String get seasonNoEpisodes;

  /// No description provided for @showsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz dizi eklemedin'**
  String get showsEmpty;

  /// No description provided for @showsGoToDiscover.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet\'e git'**
  String get showsGoToDiscover;

  /// No description provided for @tabWatchlist.
  ///
  /// In tr, this message translates to:
  /// **'İzleme Listesi'**
  String get tabWatchlist;

  /// No description provided for @tabUpcoming.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan'**
  String get tabUpcoming;

  /// No description provided for @watchlistUpNext.
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki'**
  String get watchlistUpNext;

  /// No description provided for @watchlistNotRecently.
  ///
  /// In tr, this message translates to:
  /// **'Bir süredir izlemediklerin'**
  String get watchlistNotRecently;

  /// No description provided for @watchlistAllCaughtUp.
  ///
  /// In tr, this message translates to:
  /// **'İzleyecek yeni bölüm yok'**
  String get watchlistAllCaughtUp;

  /// No description provided for @watchlistShowGrid.
  ///
  /// In tr, this message translates to:
  /// **'Izgara görünümü'**
  String get watchlistShowGrid;

  /// No description provided for @watchlistShowList.
  ///
  /// In tr, this message translates to:
  /// **'Liste görünümü'**
  String get watchlistShowList;

  /// No description provided for @markNextEpisode.
  ///
  /// In tr, this message translates to:
  /// **'{code} bölümünü izledim'**
  String markNextEpisode(String code);

  /// No description provided for @upcomingEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan bölüm yok'**
  String get upcomingEmpty;

  /// No description provided for @upcomingToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get upcomingToday;

  /// No description provided for @upcomingTomorrow.
  ///
  /// In tr, this message translates to:
  /// **'Yarın'**
  String get upcomingTomorrow;

  /// No description provided for @seasonMarkAll.
  ///
  /// In tr, this message translates to:
  /// **'Sezonun tamamını izledim'**
  String get seasonMarkAll;

  /// No description provided for @episodeMarkUntil.
  ///
  /// In tr, this message translates to:
  /// **'Buraya kadar izledim'**
  String get episodeMarkUntil;

  /// No description provided for @episodeMarkWatched.
  ///
  /// In tr, this message translates to:
  /// **'İzlendi'**
  String get episodeMarkWatched;

  /// No description provided for @episodeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm'**
  String get episodeTitle;

  /// No description provided for @profileNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get profileNotifications;

  /// No description provided for @profileShare.
  ///
  /// In tr, this message translates to:
  /// **'Profili paylaş'**
  String get profileShare;

  /// No description provided for @profileShareText.
  ///
  /// In tr, this message translates to:
  /// **'Sezonluk\'ta izlediğim dizilere göz at: {link}'**
  String profileShareText(String link);

  /// No description provided for @statWatchTimeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dizi izleme süresi'**
  String get statWatchTimeTitle;

  /// No description provided for @statWatchTimeValue.
  ///
  /// In tr, this message translates to:
  /// **'{months} ay {days} gün {hours} saat'**
  String statWatchTimeValue(int months, int days, int hours);

  /// No description provided for @statEpisodesTitle.
  ///
  /// In tr, this message translates to:
  /// **'İzlenen bölüm'**
  String get statEpisodesTitle;

  /// No description provided for @statFollowers.
  ///
  /// In tr, this message translates to:
  /// **'Takipçi'**
  String get statFollowers;

  /// No description provided for @statFollowing.
  ///
  /// In tr, this message translates to:
  /// **'Takip'**
  String get statFollowing;

  /// No description provided for @statBadges.
  ///
  /// In tr, this message translates to:
  /// **'Rozet'**
  String get statBadges;

  /// No description provided for @profileMyShows.
  ///
  /// In tr, this message translates to:
  /// **'Dizilerim'**
  String get profileMyShows;

  /// No description provided for @profileSeeAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get profileSeeAll;

  /// No description provided for @profileNoShows.
  ///
  /// In tr, this message translates to:
  /// **'Henüz dizi eklenmemiş.'**
  String get profileNoShows;

  /// No description provided for @fieldCover.
  ///
  /// In tr, this message translates to:
  /// **'Kapak'**
  String get fieldCover;

  /// No description provided for @coverNone.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik'**
  String get coverNone;

  /// No description provided for @coverPickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kapak seç'**
  String get coverPickerTitle;

  /// No description provided for @coverPickerHint.
  ///
  /// In tr, this message translates to:
  /// **'Kapak, listendeki bir dizinin arka plan görselidir. Seçmezsen en son izlediğin dizi kullanılır.'**
  String get coverPickerHint;

  /// No description provided for @coverPickerEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Kapak seçmek için önce listene dizi ekle.'**
  String get coverPickerEmpty;

  /// No description provided for @suggestCardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana Özel Öneriler'**
  String get suggestCardTitle;

  /// No description provided for @suggestCardBody.
  ///
  /// In tr, this message translates to:
  /// **'Sevdiğin kategorilere göre yeni diziler keşfet.'**
  String get suggestCardBody;

  /// No description provided for @suggestTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana Özel Öneriler'**
  String get suggestTitle;

  /// No description provided for @suggestMaxGenres.
  ///
  /// In tr, this message translates to:
  /// **'En fazla 3 kategori seçebilirsin'**
  String get suggestMaxGenres;

  /// No description provided for @suggestPickGenre.
  ///
  /// In tr, this message translates to:
  /// **'Öneri almak için en az bir kategori seç'**
  String get suggestPickGenre;

  /// No description provided for @suggestEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu kategorilerde yeni öneri kalmadı'**
  String get suggestEmpty;

  /// No description provided for @suggestByGenre.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğin kategorilerden'**
  String get suggestByGenre;

  /// No description provided for @suggestSimilarTitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} izlediğin için'**
  String suggestSimilarTitle(String name);

  /// No description provided for @suggestAddShow.
  ///
  /// In tr, this message translates to:
  /// **'{name} listene ekle'**
  String suggestAddShow(String name);

  /// No description provided for @errorCommentRateLimited.
  ///
  /// In tr, this message translates to:
  /// **'Çok hızlı yorum yapıyorsun. Biraz bekleyip tekrar dene.'**
  String get errorCommentRateLimited;

  /// No description provided for @errorCommentBannedWord.
  ///
  /// In tr, this message translates to:
  /// **'Yorumun uygunsuz bir ifade içeriyor.'**
  String get errorCommentBannedWord;

  /// No description provided for @reactionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm sana nasıl hissettirdi?'**
  String get reactionsTitle;

  /// No description provided for @reactionFunny.
  ///
  /// In tr, this message translates to:
  /// **'Komik'**
  String get reactionFunny;

  /// No description provided for @reactionLove.
  ///
  /// In tr, this message translates to:
  /// **'Bayıldım'**
  String get reactionLove;

  /// No description provided for @reactionShocked.
  ///
  /// In tr, this message translates to:
  /// **'Şok oldum'**
  String get reactionShocked;

  /// No description provided for @reactionSad.
  ///
  /// In tr, this message translates to:
  /// **'Hüzünlendim'**
  String get reactionSad;

  /// No description provided for @reactionAngry.
  ///
  /// In tr, this message translates to:
  /// **'Sinirlendim'**
  String get reactionAngry;

  /// No description provided for @reactionBored.
  ///
  /// In tr, this message translates to:
  /// **'Sıkıldım'**
  String get reactionBored;

  /// No description provided for @percent.
  ///
  /// In tr, this message translates to:
  /// **'%{value}'**
  String percent(int value);

  /// No description provided for @starTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bölümün yıldızı'**
  String get starTitle;

  /// No description provided for @starNoCast.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm için oyuncu bilgisi yok'**
  String get starNoCast;

  /// No description provided for @starResultsTitle.
  ///
  /// In tr, this message translates to:
  /// **'En çok oy alanlar'**
  String get starResultsTitle;

  /// No description provided for @starVoteFor.
  ///
  /// In tr, this message translates to:
  /// **'{name} için oy ver'**
  String starVoteFor(String name);

  /// No description provided for @commentsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar'**
  String get commentsTitle;

  /// No description provided for @commentHint.
  ///
  /// In tr, this message translates to:
  /// **'Yorumunu yaz'**
  String get commentHint;

  /// No description provided for @commentSpoilerSwitch.
  ///
  /// In tr, this message translates to:
  /// **'Spoiler içeriyor'**
  String get commentSpoilerSwitch;

  /// No description provided for @commentSend.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get commentSend;

  /// No description provided for @commentTooLong.
  ///
  /// In tr, this message translates to:
  /// **'Yorum 1–500 karakter olmalı.'**
  String get commentTooLong;

  /// No description provided for @commentsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yorum yok. İlk yorumu sen yaz.'**
  String get commentsEmpty;

  /// No description provided for @commentsSpoilerGate.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölümü izlemedin, yorumlar spoiler içerebilir'**
  String get commentsSpoilerGate;

  /// No description provided for @commentsShowAnyway.
  ///
  /// In tr, this message translates to:
  /// **'Yine de göster'**
  String get commentsShowAnyway;

  /// No description provided for @commentSpoilerHidden.
  ///
  /// In tr, this message translates to:
  /// **'Spoiler içeriyor — görmek için dokun'**
  String get commentSpoilerHidden;

  /// No description provided for @commentsLoadMore.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla yorum'**
  String get commentsLoadMore;

  /// No description provided for @commentLike.
  ///
  /// In tr, this message translates to:
  /// **'Beğen'**
  String get commentLike;

  /// No description provided for @commentUnlike.
  ///
  /// In tr, this message translates to:
  /// **'Beğeniyi geri al'**
  String get commentUnlike;

  /// No description provided for @commentMenu.
  ///
  /// In tr, this message translates to:
  /// **'Yorum seçenekleri'**
  String get commentMenu;

  /// No description provided for @commentDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get commentDelete;

  /// No description provided for @commentDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Yorumun silinsin mi?'**
  String get commentDeleteConfirm;

  /// No description provided for @report.
  ///
  /// In tr, this message translates to:
  /// **'Şikayet et'**
  String get report;

  /// No description provided for @reportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şikayet nedeni'**
  String get reportTitle;

  /// No description provided for @reportReasonSpam.
  ///
  /// In tr, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In tr, this message translates to:
  /// **'Taciz'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonSpoiler.
  ///
  /// In tr, this message translates to:
  /// **'Spoiler'**
  String get reportReasonSpoiler;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In tr, this message translates to:
  /// **'Uygunsuz içerik'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get reportReasonOther;

  /// No description provided for @reportNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Not (isteğe bağlı)'**
  String get reportNoteHint;

  /// No description provided for @reportSend.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get reportSend;

  /// No description provided for @reportSent.
  ///
  /// In tr, this message translates to:
  /// **'Şikayetin alındı. İnceleyeceğiz.'**
  String get reportSent;

  /// No description provided for @block.
  ///
  /// In tr, this message translates to:
  /// **'Engelle'**
  String get block;

  /// No description provided for @blockConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} engellensin mi?'**
  String blockConfirmTitle(String name);

  /// No description provided for @blockConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlarını görmeyeceksin ve seni takip edemeyecek.'**
  String get blockConfirmBody;

  /// No description provided for @blockDone.
  ///
  /// In tr, this message translates to:
  /// **'{name} engellendi.'**
  String blockDone(String name);

  /// No description provided for @blockedUsersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Engellenenler'**
  String get blockedUsersTitle;

  /// No description provided for @blockedUsersEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Kimseyi engellemedin.'**
  String get blockedUsersEmpty;

  /// No description provided for @unblock.
  ///
  /// In tr, this message translates to:
  /// **'Engeli kaldır'**
  String get unblock;

  /// No description provided for @follow.
  ///
  /// In tr, this message translates to:
  /// **'Takip et'**
  String get follow;

  /// No description provided for @following.
  ///
  /// In tr, this message translates to:
  /// **'Takip ediliyor'**
  String get following;

  /// No description provided for @profileMenu.
  ///
  /// In tr, this message translates to:
  /// **'Profil seçenekleri'**
  String get profileMenu;

  /// No description provided for @followersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Takipçiler'**
  String get followersTitle;

  /// No description provided for @followingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Takip edilenler'**
  String get followingTitle;

  /// No description provided for @followersEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz takipçi yok.'**
  String get followersEmpty;

  /// No description provided for @followingEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kimse takip edilmiyor.'**
  String get followingEmpty;

  /// No description provided for @userShowsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Diziler'**
  String get userShowsTitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Son 90 günde bildirim yok.'**
  String get notificationsEmpty;

  /// No description provided for @notificationNewFollower.
  ///
  /// In tr, this message translates to:
  /// **'{name} seni takip etmeye başladı.'**
  String notificationNewFollower(String name);

  /// No description provided for @notificationCommentLiked.
  ///
  /// In tr, this message translates to:
  /// **'{name} yorumunu beğendi.'**
  String notificationCommentLiked(String name);

  /// No description provided for @notificationBadgeEarned.
  ///
  /// In tr, this message translates to:
  /// **'\"{badge}\" rozetini kazandın!'**
  String notificationBadgeEarned(String badge);

  /// No description provided for @notificationDeletedUser.
  ///
  /// In tr, this message translates to:
  /// **'Bir kullanıcı'**
  String get notificationDeletedUser;

  /// No description provided for @badgesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rozetler'**
  String get badgesTitle;

  /// No description provided for @badgeEarnedOn.
  ///
  /// In tr, this message translates to:
  /// **'{date} tarihinde kazanıldı'**
  String badgeEarnedOn(String date);

  /// No description provided for @badgeLocked.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kazanılmadı'**
  String get badgeLocked;

  /// No description provided for @errorUsernameMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı eşleşmiyor.'**
  String get errorUsernameMismatch;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı sil'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın, profilin, izleme geçmişin, yorumların, tepkilerin, takip ilişkilerin ve avatarın kalıcı olarak silinir. Bu işlem geri alınamaz.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Onaylamak için kullanıcı adını yaz: {username}'**
  String deleteAccountPrompt(String username);

  /// No description provided for @deleteAccountButton.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı kalıcı olarak sil'**
  String get deleteAccountButton;

  /// No description provided for @aboutTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get aboutTitle;

  /// No description provided for @aboutTmdbAttribution.
  ///
  /// In tr, this message translates to:
  /// **'This product uses the TMDB API but is not endorsed or certified by TMDB.'**
  String get aboutTmdbAttribution;

  /// No description provided for @aboutTmdbLogo.
  ///
  /// In tr, this message translates to:
  /// **'TMDB logosu'**
  String get aboutTmdbLogo;

  /// No description provided for @aboutVersion.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm {version}'**
  String aboutVersion(String version);

  /// No description provided for @guestContinue.
  ///
  /// In tr, this message translates to:
  /// **'Misafir olarak devam et'**
  String get guestContinue;

  /// No description provided for @guestGateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu özellik için hesap oluştur'**
  String get guestGateTitle;

  /// No description provided for @guestGateBody.
  ///
  /// In tr, this message translates to:
  /// **'Dizilerini takip etmek, bölüm işaretlemek, yorum yapmak ve arkadaşlarını takip etmek için ücretsiz bir hesap aç.'**
  String get guestGateBody;

  /// No description provided for @guestHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabım var, giriş yap'**
  String get guestHaveAccount;

  /// No description provided for @reactionMindblown.
  ///
  /// In tr, this message translates to:
  /// **'Kafam yandı'**
  String get reactionMindblown;

  /// No description provided for @reactionScared.
  ///
  /// In tr, this message translates to:
  /// **'Korktum'**
  String get reactionScared;

  /// No description provided for @reactionEpic.
  ///
  /// In tr, this message translates to:
  /// **'Efsane'**
  String get reactionEpic;

  /// No description provided for @reactionThoughtful.
  ///
  /// In tr, this message translates to:
  /// **'Düşündürdü'**
  String get reactionThoughtful;

  /// No description provided for @reactionTouched.
  ///
  /// In tr, this message translates to:
  /// **'Duygulandım'**
  String get reactionTouched;

  /// No description provided for @reactionTense.
  ///
  /// In tr, this message translates to:
  /// **'Gerildim'**
  String get reactionTense;

  /// No description provided for @onTheAirTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şu an yayında'**
  String get onTheAirTitle;

  /// No description provided for @episodeStill.
  ///
  /// In tr, this message translates to:
  /// **'{code} sahnesi'**
  String episodeStill(String code);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
