import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../discover/logic.dart';
import '../../discover/providers.dart';
import '../../shows/data/models.dart';
import '../../shows/providers.dart';

/// Kapak ve karakter avatarı seçiminin ilk adımı: listedeki diziler veya aramayla
/// herhangi bir dizi (F2).
class ShowChooser extends ConsumerStatefulWidget {
  const ShowChooser({super.key, required this.onSelected});

  final ValueChanged<Show> onSelected;

  @override
  ConsumerState<ShowChooser> createState() => _ShowChooserState();
}

class _ShowChooserState extends ConsumerState<ShowChooser> {
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      searchDebounce,
      () => setState(() => _query = value.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final myShows = [
      for (final entry
          in ref.watch(myShowsProvider).value ?? const <UserShow>[])
        entry.show,
    ];
    final searching = canSearch(_query);
    final shows = searching
        ? ref.watch(showSearchProvider(_query)).value ?? const <Show>[]
        : myShows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            key: const Key('showChooser.search'),
            onChanged: _onChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.discoverSearchShowsHint,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            searching ? l10n.pickerSearchResults : l10n.pickerMyShows,
            style: AppTextStyles.caption,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: shows.isEmpty
              ? Center(
                  child: Text(
                    searching ? l10n.noResults : l10n.pickerSearchHint,
                    style: AppTextStyles.bodySecondary,
                    textAlign: TextAlign.center,
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: AppSpacing.posterGridColumns,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: AppSpacing.posterAspectRatio,
                  ),
                  itemCount: shows.length,
                  itemBuilder: (context, index) => PosterCard(
                    key: Key('showChooser.${shows[index].id}'),
                    title: shows[index].name,
                    posterPath: shows[index].posterPath,
                    onTap: () => widget.onSelected(shows[index]),
                  ),
                ),
        ),
      ],
    );
  }
}
