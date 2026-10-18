import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Keşfet'in en üstündeki kompakt "Sana Özel Öneriler" bandı (F18a, V24).
class SuggestCard extends StatelessWidget {
  const SuggestCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Material(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        child: InkWell(
          key: const Key('discover.suggestCard'),
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          onTap: () => context.push(AppRoutes.suggest),
          child: SizedBox(
            height: AppSpacing.suggestBandHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.suggestCardTitle,
                      style: AppTextStyles.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
