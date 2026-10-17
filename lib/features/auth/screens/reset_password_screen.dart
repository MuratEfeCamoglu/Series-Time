import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_spacing.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/auth_form_layout.dart';

/// `sezonluk://reset-password` bağlantısıyla açılır (F1e).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _loading = false;
  Object? _error;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).updatePassword(_password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).resetPasswordDone)),
      );
      // Durum değişince yönlendirici ana ekrana geçer.
      ref.read(authStatusProvider.notifier).passwordResetCompleted();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthFormLayout(
      title: l10n.resetPasswordTitle,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _password,
                decoration: InputDecoration(labelText: l10n.fieldNewPassword),
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => isValidPassword(value ?? '')
                    ? null
                    : l10n.validationPasswordShort,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _repeat,
                decoration: InputDecoration(
                  labelText: l10n.fieldPasswordRepeat,
                ),
                obscureText: true,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) => value == _password.text
                    ? null
                    : l10n.validationPasswordMismatch,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_error != null) FormErrorText(failureMessage(l10n, _error!)),
        PrimaryButton(
          label: l10n.resetPasswordButton,
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
