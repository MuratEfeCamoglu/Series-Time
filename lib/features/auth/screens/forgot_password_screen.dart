import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/auth_form_layout.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  Object? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
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
      title: l10n.forgotPasswordTitle,
      children: [
        Text(
          _sent ? l10n.forgotPasswordSent : l10n.forgotPasswordBody,
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!_sent) ...[
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: l10n.fieldEmail),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _submit(),
              validator: (value) => isValidEmail(value ?? '')
                  ? null
                  : l10n.validationEmailInvalid,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_error != null) FormErrorText(failureMessage(l10n, _error!)),
          PrimaryButton(
            label: l10n.forgotPasswordButton,
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ],
    );
  }
}
