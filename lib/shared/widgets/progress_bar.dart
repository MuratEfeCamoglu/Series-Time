import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Afişin altındaki 3 pt ilerleme çubuğu (ISKELET.md §3.7). [value] 0–1.
/// [outlined] boş, yalnızca kontur çizilen çubuktur (F6j İzleme Listesi).
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.outlined = false,
    this.semanticsLabel,
  });

  final double value;

  /// null: paletin vurgu rengi (F21a).
  final Color? color;
  final bool outlined;

  /// Renk tek başına bilgi taşımasın diye grup adı burada okunur.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? AppColors.accent;
    final radius = BorderRadius.circular(AppSpacing.progressBarHeight);
    if (outlined) {
      return Semantics(
        label: semanticsLabel,
        child: Container(
          height: AppSpacing.progressBarHeight,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: color,
              width: AppSpacing.progressBarOutline,
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: LinearProgressIndicator(
        value: value,
        minHeight: AppSpacing.progressBarHeight,
        color: color,
        backgroundColor: AppColors.border,
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}
