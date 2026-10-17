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
  static const double progressBarOutline = 1;
  static const double statusDotSize = 10;
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

  /// Dizilerim/Tümü ızgara hücresi: 2:3 afiş + renkli ilerleme çubuğu.
  static const double progressGridAspectRatio = 0.62;

  /// Profil kapağı (F8a); avatar kapağın alt kenarına taşar.
  /// Profil başlığı (F8a, F8c): üst çubuk + avatar satırı; arkasında soluk kapak.
  static const double profileHeaderHeight = 190;

  /// Afiş görünümü (F6k): üst görsel ve yatay satır afiş genişliği.
  static const double homeHeroHeight = 240;
  static const double homePosterWidth = 120;
  static const double friendStarSize = 14;

  /// Afiş görünümünde çiplerle uzak bölüme kaydırabilmek için önceden çizilen ekran sayısı.
  static const double homeCacheViewports = 6;

  /// Puanlar grafiği (F8l).
  static const double ratingChartHeight = 96;
  static const double ratingBarGap = 3;

  /// Son etkinlik kartı (F8k): 16:9 sahne görseli.
  static const double recentStillWidth = 200;
  static const double profileNameMaxTextScale = 1.3;
  static const double avatarRing = 3;
  static const double badgeMinSize = 16;
  static const double posterRowHeight = 150;
  static const double coverThumbAspectRatio = 16 / 9;
  static const int coverGridColumns = 2;

  /// Listenin sonuna bu kadar kala sonraki sayfa istenir.
  static const double loadMoreThreshold = 400;

  /// Spoiler yorumun bulanıklığı (F11b).
  static const double spoilerBlurSigma = 6;
  static const double castPhotoSize = 64;
  static const double castCardWidth = 88;
  static const double castRowHeight = 150;
  static const double reactionEmojiSize = 28;
  static const double avatarSmall = 36;
  static const double reactionTileAspectRatio = 0.85;
  static const int reactionGridColumns = 4;

  /// TMDB atıf logosu (F17); uygulama ikonundan küçük kalmalı.
  static const double tmdbLogoHeight = 20;

  /// Bölüm sahne görseli (TMDB still, 16:9).
  static const double stillThumbWidth = 112;
  static const double stillAspectRatio = 16 / 9;

  /// İzleme Listesi satırı (F6b): afiş ve büyük yuvarlak onay düğmesi.
  static const double watchlistPosterWidth = 56;
  static const double checkButtonSize = 48;
  static const double checkButtonBorder = 2;
  static const double episodeHeaderHeight = 240;
  static const double watchlistImageWidth = 128;
  static const double pillRadius = 24;
  static const double nextEpisodeBannerHeight = 120;
  static const double bannerCheckScale = 1.4;
  static const double ratingStarSize = 40;
  static const double characterAvatarSize = 76;
  static const double characterTileAspectRatio = 0.62;
}
