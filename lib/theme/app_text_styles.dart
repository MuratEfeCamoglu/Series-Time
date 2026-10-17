import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Yazı stilleri. `fontFamily` verilmez: sistem yazı tipi kullanılır (iOS SF Pro, Android Roboto).
abstract final class AppTextStyles {
  static const title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(fontSize: 15, color: AppColors.textPrimary);
  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  static const navLabel = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
}
