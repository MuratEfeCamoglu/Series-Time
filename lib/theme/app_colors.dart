import 'package:flutter/painting.dart';

import 'app_palettes.dart';

/// ISKELET.md §3.7 renk paleti. Widget'larda yalnızca bu değerler kullanılır.
abstract final class AppColors {
  static AppPalette _palette = AppPalette.yellow;

  /// F21(a): seçilen paleti uygular; uygulama ağacı ardından yeniden çizilir.
  static void apply(AppPalette palette) => _palette = palette;

  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get surfaceAlt => _palette.surfaceAlt;
  static Color get border => _palette.border;
  static Color get accent => _palette.accent;
  static const onAccent = Color(0xFF000000);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA0A0A0);
  static const danger = Color(0xFFFF453A);

  /// F6(j) durum grubu renkleri; çubuk ve çiplerde, grup adıyla birlikte kullanılır.
  static const statusFinished = Color(0xFFB388FF);
  static const statusUpToDate = Color(0xFF34C759);
  static const statusWatching = Color(0xFFFFCC00);
  static const statusPaused = Color(0xFF64B5F6);
  static const statusDropped = Color(0xFFFF453A);
  static const statusWatchlist = Color(0xFFFFFFFF);

  /// Görsel üstündeki başlığın okunması için koyu geçiş (yalnızca üst kısım ve şeffaf).
  static const scrimTop = Color(0x99000000);
  static const scrimClear = Color(0x00000000);

  /// Profil başlığındaki kapağı soluklaştıran üst ton (F8a).
  static const coverScrim = Color(0xB3000000);
}
