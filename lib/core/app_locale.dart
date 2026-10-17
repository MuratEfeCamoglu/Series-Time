import 'package:intl/intl.dart';

/// F21(b): uygulamanın etkin dili. Uygulama kökü çözülen dili [apply] ile bildirir; tarih
/// biçimleri, ondalık ayırıcı, bölüm kodu ve TMDB istek dili buradan okunur.
abstract final class AppLocale {
  static String _code = 'tr';

  /// "tr" veya "en".
  static String get code => _code;

  static bool get isEnglish => _code == 'en';

  static void apply(String languageCode) {
    _code = languageCode == 'en' ? 'en' : 'tr';
    Intl.defaultLocale = _code;
  }

  /// Bölüm kodundaki harf: "S01 | B05" / "S01 | E05".
  static String get episodeLetter => isEnglish ? 'E' : 'B';

  /// "4,5" / "4.5".
  static String decimal(double value, {int digits = 1}) {
    final text = value.toStringAsFixed(digits);
    return isEnglish ? text : text.replaceAll('.', ',');
  }
}
