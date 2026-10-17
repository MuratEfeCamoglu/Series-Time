import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Keşfet'in en üstündeki "Sana Özel Öneriler" kartı (F18a, V24).
class SuggestCard extends StatelessWidget {
  const SuggestCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: AppColors.surfaceAlt,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: ListTile(
        key: const Key('discover.suggestCard'),
        leading: const Icon(Icons.auto_awesome, color: AppColors.accent),
        title: Text(l10n.suggestCardTitle, style: AppTextStyles.body),
        subtitle: Text(l10n.suggestCardBody, style: AppTextStyles.caption),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.suggest),
      ),
    );
  }
}
