import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_palettes.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../providers.dart';

String paletteName(AppLocalizations l10n, AppPalette palette) =>
    switch (palette) {
      AppPalette.yellow => l10n.paletteYellow,
      AppPalette.purple => l10n.palettePurple,
      AppPalette.blue => l10n.paletteBlue,
      AppPalette.green => l10n.paletteGreen,
      AppPalette.red => l10n.paletteRed,
      AppPalette.orange => l10n.paletteOrange,
    };

/// Ayarlar › Renk (F21a): hazır koyu paletler; seçim tüm uygulamaya hemen uygulanır.
class ColorSettingsScreen extends ConsumerWidget {
  const ColorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(paletteProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsColors)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.settingsColorsHint,
              style: AppTextStyles.bodySecondary,
            ),
          ),
          for (final palette in AppPalette.values)
            ListTile(
              key: Key('palette.${palette.name}'),
              leading: _Swatch(palette: palette),
              title: Text(paletteName(l10n, palette)),
              selected: palette == selected,
              trailing: palette == selected
                  ? Icon(Icons.check, color: AppColors.accent)
                  : null,
              onTap: () => ref.read(paletteProvider.notifier).select(palette),
            ),
        ],
      ),
    );
  }
}

/// Paletin vurgu rengi, zemin üstünde.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.minTapTarget,
      height: AppSpacing.minTapTarget,
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        shape: BoxShape.circle,
        border: Border.all(color: palette.border),
      ),
      alignment: Alignment.center,
      child: Container(
        width: AppSpacing.lg,
        height: AppSpacing.lg,
        decoration: BoxDecoration(
          color: palette.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
