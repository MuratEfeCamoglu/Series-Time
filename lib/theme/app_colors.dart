import 'package:flutter/painting.dart';

/// ISKELET.md §3.7 renk paleti. Widget'larda yalnızca bu sabitler kullanılır.
abstract final class AppColors {
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF141414);
  static const surfaceAlt = Color(0xFF1F1F1F);
  static const border = Color(0xFF2A2A2A);
  static const accent = Color(0xFFFFCC00);
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
