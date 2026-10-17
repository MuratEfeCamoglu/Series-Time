/// Boşluk ve boyut sabitleri (ISKELET.md §3.7).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double posterRadius = 6;
  static const double posterAspectRatio = 2 / 3;
  static const double progressBarHeight = 3;
  static const double minTapTarget = 44;
  static const double buttonHeight = 48;
  static const double progressIndicatorSize = 20;
  static const double progressIndicatorStroke = 2;
  static const double formMaxWidth = 420;
  static const double avatarLarge = 96;
  static const double sheetHeightFactor = 0.75;

  static const int posterGridColumns = 3;
  static const double posterThumbWidth = 46;
  static const double detailPosterWidth = 110;
  static const double detailBackdropHeight = 220;
  static const double emptyStateIconSize = 48;

  /// İzleme Listesi ızgara hücresi: 2:3 afiş + ilerleme çubuğu + bölüm kodu satırı.
  static const double watchlistGridAspectRatio = 0.58;

  /// Profil kapağı (F8a); avatar kapağın alt kenarına taşar.
  static const double profileCoverHeight = 220;
  static const double badgeMinSize = 16;
  static const double posterRowHeight = 150;
  static const double coverThumbAspectRatio = 16 / 9;
  static const int coverGridColumns = 2;

  /// Listenin sonuna bu kadar kala sonraki sayfa istenir.
  static const double loadMoreThreshold = 400;
}
