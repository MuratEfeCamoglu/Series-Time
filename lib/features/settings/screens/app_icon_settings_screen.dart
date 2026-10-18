import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_palettes.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../providers.dart';
import 'color_settings_screen.dart';

/// Ayarlar › Uygulama simgesi (F22): renk paletleriyle aynı 6 renkte ana ekran simgesi.
class AppIconSettingsScreen extends ConsumerWidget {
  const AppIconSettingsScreen({super.key});

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    AppPalette icon,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(appIconProvider.notifier).select(icon);
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.appIconFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAppIcon)),
      body: ref
          .watch(appIconProvider)
          .when(
            data: (selected) => ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.settingsAppIconHint,
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
                for (final icon in AppPalette.values)
                  ListTile(
                    key: Key('appIcon.${icon.name}'),
                    leading: AppIconPreview(color: icon.accent),
                    title: Text(paletteName(l10n, icon)),
                    selected: icon == selected,
                    trailing: icon == selected
                        ? Icon(Icons.check, color: AppColors.accent)
                        : null,
                    onTap: icon == selected
                        ? null
                        : () => _select(context, ref, icon),
                  ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(appIconProvider),
            ),
          ),
    );
  }
}

/// Simgenin önizlemesi: siyah yuvarlak kare üstünde, simgenin ön planı seçilen renkte.
class AppIconPreview extends StatelessWidget {
  const AppIconPreview({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.appIconPreviewRadius),
      child: ColoredBox(
        color: AppColors.onAccent,
        child: SizedBox.square(
          dimension: AppSpacing.appIconPreviewSize,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: Image.asset('assets/icon/app_icon_foreground.png'),
          ),
        ),
      ),
    );
  }
}
