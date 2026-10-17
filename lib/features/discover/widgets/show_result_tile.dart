import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../shows/data/models.dart';

/// Dizi arama sonucu satırı: afiş, ad, yıl (F3b).
class ShowResultTile extends StatelessWidget {
  const ShowResultTile({super.key, required this.show});

  final Show show;

  @override
  Widget build(BuildContext context) {
    final year = show.firstAirDate?.year;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: SizedBox(
        width: AppSpacing.posterThumbWidth,
        child: PosterCard(title: show.name, posterPath: show.posterPath),
      ),
      title: Text(show.name, style: AppTextStyles.body),
      subtitle: year == null
          ? null
          : Text('$year', style: AppTextStyles.bodySecondary),
      onTap: () => context.push(AppRoutes.showDetail(show.id)),
    );
  }
}
