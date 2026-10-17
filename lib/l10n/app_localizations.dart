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
