import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../logic.dart';

/// Alt sayfanın sonucu; [code] null ise "Belirtilmemiş" seçilmiştir.
/// (Sayfa kapatılınca `null` döndüğü için seçim ayrı bir nesneyle taşınır.)
class CountrySelection {
  const CountrySelection(this.code);

  final String? code;
}

class CountryPickerSheet extends StatefulWidget {
  const CountryPickerSheet({super.key, required this.selected});

  final String? selected;

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final codes = filterCountryCodes(_query);
    return SafeArea(
      child: SizedBox(
        height:
            MediaQuery.sizeOf(context).height * AppSpacing.sheetHeightFactor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(l10n.countryPickerTitle, style: AppTextStyles.title),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.countrySearchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: codes.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      title: Text(l10n.countryNone),
                      trailing: widget.selected == null
                          ? Icon(Icons.check, color: AppColors.accent)
                          : null,
                      onTap: () =>
                          Navigator.pop(context, const CountrySelection(null)),
                    );
                  }
                  final code = codes[index - 1];
                  return ListTile(
                    leading: Text(
                      countryFlag(code),
                      style: AppTextStyles.title,
                    ),
                    title: Text(code),
                    trailing: code == widget.selected
                        ? Icon(Icons.check, color: AppColors.accent)
                        : null,
                    onTap: () => Navigator.pop(context, CountrySelection(code)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
