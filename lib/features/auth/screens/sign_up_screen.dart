import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';
import '../../../core/config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/auth_form_layout.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _accepted = false;
  bool _loading = false;
  Object? _error;
  String? _sentToEmail;

  @override
  void dispose() {
    _username.dispose();
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
      await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _email.text,
            password: _password.text,
            username: normalizeUsername(_username.text),
          );
      if (mounted) setState(() => _sentToEmail = _email.text.trim());
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLegal(String url) async {
    final uri = Uri.tryParse(url);
    final opened =
        uri != null &&
        uri.hasScheme &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorLinkOpen)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sentTo = _sentToEmail;
    if (sentTo != null) {
      return AuthFormLayout(
        title: l10n.signUpCheckEmailTitle,
        children: [
          Text(l10n.signUpCheckEmailBody(sentTo), style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: l10n.backToSignIn,
            onPressed: () => context.go(AppRoutes.signIn),
          ),
        ],
      );
    }

    return AuthFormLayout(
      title: l10n.signUpTitle,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                key: const Key('signUp.username'),
                controller: _username,
                decoration: InputDecoration(labelText: l10n.fieldUsername),
                autocorrect: false,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    isValidUsername(normalizeUsername(value ?? ''))
                    ? null
                    : l10n.validationUsernameFormat,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('signUp.email'),
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
                key: const Key('signUp.password'),
                controller: _password,
                decoration: InputDecoration(labelText: l10n.fieldPassword),
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => isValidPassword(value ?? '')
                    ? null
                    : l10n.validationPasswordShort,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CheckboxListTile(
          key: const Key('signUp.consent'),
          value: _accepted,
          onChanged: (value) => setState(() => _accepted = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.signUpConsent, style: AppTextStyles.body),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            TextButton(
              onPressed: () => _openLegal(legalTermsUrl),
              child: Text(l10n.termsOfUse),
            ),
            TextButton(
              onPressed: () => _openLegal(legalPrivacyUrl),
              child: Text(l10n.privacyPolicy),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_error != null) FormErrorText(failureMessage(l10n, _error!)),
        PrimaryButton(
          key: const Key('signUp.submit'),
          label: l10n.signUpButton,
          loading: _loading,
          // F1(f): onay kutusu işaretlenmeden düğme pasiftir.
          onPressed: _accepted ? _submit : null,
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () => context.go(AppRoutes.signIn),
          child: Text(l10n.signUpToSignIn),
        ),
      ],
    );
  }
}
