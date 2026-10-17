import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../providers.dart';

/// Ayarlar › Dil (F21b): Telefonun dili, Türkçe veya English; seçim hemen uygulanır.
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(languageProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsLanguage)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.settingsLanguageHint,
              style: AppTextStyles.bodySecondary,
            ),
          ),
          for (final (language, label) in [
            (AppLanguage.system, l10n.languageSystem),
            (AppLanguage.tr, l10n.languageTurkish),
            (AppLanguage.en, l10n.languageEnglish),
          ])
            ListTile(
              key: Key('language.${language.name}'),
              title: Text(label),
              selected: language == selected,
              trailing: language == selected
                  ? Icon(Icons.check, color: AppColors.accent)
                  : null,
              onTap: () => ref.read(languageProvider.notifier).select(language),
            ),
        ],
      ),
    );
  }
}
