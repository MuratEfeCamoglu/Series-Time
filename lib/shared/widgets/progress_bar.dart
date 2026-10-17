import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Afişin altındaki 3 pt sarı ilerleme çubuğu (ISKELET.md §3.7). [value] 0–1.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.progressBarHeight),
      child: LinearProgressIndicator(
        value: value,
        minHeight: AppSpacing.progressBarHeight,
        color: AppColors.accent,
        backgroundColor: AppColors.border,
      ),
    );
  }
}
