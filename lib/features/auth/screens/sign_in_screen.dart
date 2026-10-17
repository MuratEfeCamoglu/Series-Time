import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_spacing.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/auth_form_layout.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  Object? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Başarılı girişte yönlendirmeyi oturum durumu dinleyicisi yapar.
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
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
      title: l10n.signInTitle,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                key: const Key('signIn.email'),
                controller: _email,
                decoration: InputDecoration(labelText: l10n.fieldEmail),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: (value) => isValidEmail(value ?? '')
                    ? null
                    : l10n.validationEmailInvalid,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('signIn.password'),
                controller: _password,
                decoration: InputDecoration(labelText: l10n.fieldPassword),
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                validator: (value) => isValidPassword(value ?? '')
                    ? null
                    : l10n.validationPasswordShort,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(AppRoutes.forgotPassword),
            child: Text(l10n.signInForgotPassword),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_error != null) FormErrorText(failureMessage(l10n, _error!)),
        PrimaryButton(
          label: l10n.signInButton,
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () => context.go(AppRoutes.signUp),
          child: Text(l10n.signInToSignUp),
        ),
      ],
    );
  }
}
