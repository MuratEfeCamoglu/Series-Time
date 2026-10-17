import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// F17: TMDB logosu ve atıf metni, yasal bağlantılar, uygulama sürümü.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).errorLinkOpen;
    final uri = Uri.tryParse(url);
    final opened =
        uri != null &&
        url.isNotEmpty &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(l10n.appTitle, style: AppTextStyles.headline),
          Text(
            l10n.aboutVersion(appVersion),
            key: const Key('about.version'),
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.xl),
          // TMDB atıf kuralı: logo değiştirilmeden, uygulamanın kendi logosundan küçük.
          Align(
            alignment: Alignment.centerLeft,
            child: Image.asset(
              'assets/images/tmdb_logo.png',
              height: AppSpacing.tmdbLogoHeight,
              semanticLabel: l10n.aboutTmdbLogo,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.aboutTmdbAttribution, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xl),
          ListTile(
            key: const Key('about.privacy'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _open(context, legalPrivacyUrl),
          ),
          ListTile(
            key: const Key('about.terms'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.termsOfUse),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _open(context, legalTermsUrl),
          ),
        ],
      ),
    );
  }
}
