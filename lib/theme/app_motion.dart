/// F22 animasyon süreleri. Sistemde "animasyonları azalt" açıksa kullanılmaz.
abstract final class AppMotion {
  /// Açılışta simgenin büyüyüp solması (≤ 800 ms).
  static const launch = Duration(milliseconds: 700);

  /// Düğme durum değişimi (işaretleme, favori).
  static const toggle = Duration(milliseconds: 220);

  /// Açılış simgesinin büyüme oranı ve boyutu.
  static const launchIconScale = 1.35;
  static const double launchIconSize = 160;
}
