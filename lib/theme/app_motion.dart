/// F22 animasyon süreleri. Sistemde "animasyonları azalt" açıksa kullanılmaz.
abstract final class AppMotion {
  /// Açılışta simgenin büyüyüp solması (≤ 800 ms).
  static const launch = Duration(milliseconds: 700);

  /// Düğme durum değişimi (işaretleme, favori).
  static const toggle = Duration(milliseconds: 220);

  /// Açılış simgesinin büyüme oranı ve boyutu.
  static const launchIconScale = 1.35;
  static const double launchIconSize = 160;

  /// Basılı afiş/kartın küçülmesi.
  static const press = Duration(milliseconds: 120);
  static const pressScale = 0.95;

  /// Liste/ızgara öğelerinin sırayla girişi; ilk [staggeredItems] öğe kademeli gelir.
  static const entrance = Duration(milliseconds: 320);
  static const stagger = Duration(milliseconds: 35);
  static const staggeredItems = 12;
  static const entranceOffset = 0.08;

  /// İlerleme çubuğunun dolması, sayıların sayması ve puan sütunlarının yükselmesi.
  static const progress = Duration(milliseconds: 700);
  static const countUp = Duration(milliseconds: 800);

  /// Seçilen tepki/yıldız/oyun kısa zıplaması.
  static const bounce = Duration(milliseconds: 260);
  static const bounceScale = 1.18;
}
