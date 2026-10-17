import 'package:flutter/material.dart';

import '../../core/failures.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Hata nesnesini kullanıcıya gösterilecek metne çevirir.
String failureMessage(AppLocalizations l10n, Object error) {
  final type = error is AppFailure ? error.type : AppFailureType.unknown;
  return switch (type) {
    AppFailureType.network => l10n.errorNetwork,
    AppFailureType.invalidCredentials => l10n.errorInvalidCredentials,
    AppFailureType.emailNotConfirmed => l10n.errorEmailNotConfirmed,
    AppFailureType.usernameTaken => l10n.errorUsernameTaken,
    AppFailureType.weakPassword => l10n.errorWeakPassword,
    AppFailureType.samePassword => l10n.errorSamePassword,
    AppFailureType.rateLimited => l10n.errorRateLimited,
    AppFailureType.fileTooLarge => l10n.errorFileTooLarge,
    AppFailureType.tmdbUnavailable => l10n.errorTmdbUnavailable,
    AppFailureType.unknown => l10n.errorUnknown,
  };
}

/// `AsyncValue.when(error: ...)` için ortak hata görünümü.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              failureMessage(l10n, error),
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}
