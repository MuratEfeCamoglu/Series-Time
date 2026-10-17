import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'primary_button.dart';

/// F19(c): misafirin hesap gerektiren bir yere geldiğinde gördüğü çağrı.
class GuestGate extends StatelessWidget {
  const GuestGate({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
          child: Column(
            key: const Key('guestGate'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: AppSpacing.emptyStateIconSize,
                color: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.guestGateTitle,
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.guestGateBody,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                key: const Key('guestGate.signUp'),
                label: l10n.signUpButton,
                onPressed: () => context.go(AppRoutes.signUp),
              ),
              TextButton(
                key: const Key('guestGate.signIn'),
                onPressed: () => context.go(AppRoutes.signIn),
                child: Text(l10n.guestHaveAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bir düğmeye basan misafire aynı çağrıyı alttan açılan sayfada gösterir.
Future<void> showGuestGate(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  builder: (_) => const SafeArea(child: GuestGate()),
);
