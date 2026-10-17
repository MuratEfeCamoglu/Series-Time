import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../shows/providers.dart';

/// F6(i): Diziler sekmesinin en üstünde, TMDB'de yeni bölümü yayında olan diziler —
/// kullanıcının listesinde olmasalar da.
class OnTheAirRow extends ConsumerWidget {
  const OnTheAirRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shows = ref.watch(onTheAirProvider);
    return Column(
      key: const Key('onTheAir'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text(l10n.onTheAirTitle, style: AppTextStyles.title),
        ),
        SizedBox(
          height: AppSpacing.posterRowHeight,
          child: shows.when(
            data: (shows) => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: shows.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final show = shows[index];
                return PosterCard(
                  title: show.name,
                  posterPath: show.posterPath,
                  onTap: () => context.push(AppRoutes.showDetail(show.id)),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(onTheAirProvider),
            ),
          ),
        ),
      ],
    );
  }
}
