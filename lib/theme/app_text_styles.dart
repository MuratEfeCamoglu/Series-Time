import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Yazı stilleri. `fontFamily` verilmez: sistem yazı tipi kullanılır (iOS SF Pro, Android Roboto).
abstract final class AppTextStyles {
  static const title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(fontSize: 15, color: AppColors.textPrimary);
  static const bodySecondary = TextStyle(
    fontSize: 15,
    color: AppColors.textSecondary,
  );
  static const error = TextStyle(fontSize: 14, color: AppColors.danger);
  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  /// Profil başlığındaki görünen ad (F8c).
  static const profileName = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// İstatistik kartındaki büyük sayı (F8d); rengi paletten verilir.
  static const statNumber = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );
  static const navLabel = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
}
