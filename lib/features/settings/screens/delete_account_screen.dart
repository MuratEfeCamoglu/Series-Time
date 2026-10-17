import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers.dart';
import '../../profile/providers.dart';
import '../logic.dart';

/// F16: Ayarlar › Hesabı sil. Kullanıcı adını yazmadan düğme pasiftir; başarılı silmeden
/// sonra oturum kapanır ve yönlendirici giriş ekranına döner.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirm = TextEditingController();
  bool _deleting = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _confirm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).deleteAccount(_confirm.text);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _deleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final username = ref.watch(myProfileProvider).value?.username;
    final matches =
        username != null && deleteConfirmationMatches(_confirm.text, username);
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccountTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Icon(
            Icons.warning_amber,
            color: AppColors.danger,
            size: AppSpacing.emptyStateIconSize,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.deleteAccountBody, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.lg),
          if (username != null)
            Text(
              l10n.deleteAccountPrompt(username),
              style: AppTextStyles.bodySecondary,
            ),
          TextField(
            key: const Key('deleteAccount.confirm'),
            controller: _confirm,
            enabled: !_deleting,
            autocorrect: false,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const Key('deleteAccount.submit'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
            ),
            onPressed: matches && !_deleting ? _delete : null,
            child: _deleting
                ? const SizedBox.square(
                    dimension: AppSpacing.progressIndicatorSize,
                    child: CircularProgressIndicator(
                      strokeWidth: AppSpacing.progressIndicatorStroke,
                    ),
                  )
                : Text(l10n.deleteAccountButton),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(failureMessage(l10n, error), style: AppTextStyles.error),
          ],
        ],
      ),
    );
  }
}
