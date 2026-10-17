import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../tracking/data/models.dart';
import '../../tracking/logic.dart';
import '../../tracking/providers.dart';
import '../../tracking/widgets/show_progress_grid.dart';
import '../providers.dart';

/// "Tümü" (F8e, F6j): kullanıcının tüm dizileri, son izlenene göre, grup renginde çubuklu
/// 3'lü ızgarada; gruplara göre filtrelenir.
class UserShowsScreen extends ConsumerStatefulWidget {
  const UserShowsScreen({
    super.key,
    required this.username,
    this.initialStatus,
  });

  final String username;

  /// `ShowStatus` adı ("watching"…); bilinmiyorsa filtre yok.
  final String? initialStatus;

  @override
  ConsumerState<UserShowsScreen> createState() => _UserShowsScreenState();
}

class _UserShowsScreenState extends ConsumerState<UserShowsScreen> {
  late ShowStatus? _filter = ShowStatus.values
      .asNameMap()[widget.initialStatus];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final username = widget.username;
    final AsyncValue<List<ShowProgress>> shows = switch (ref.watch(
      profileByUsernameProvider(username),
    )) {
      AsyncData(:final value) => ref.watch(showProgressProvider(value.id)),
      AsyncError(:final error, :final stackTrace) => AsyncError(
        error,
        stackTrace,
      ),
      _ => const AsyncLoading(),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileMyShows)),
      body: shows.when(
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              message: l10n.profileNoShows,
              icon: Icons.live_tv_outlined,
            );
          }
          final filtered = filterByStatus(entries, _filter);
          return Column(
            children: [
              StatusFilterChips(
                selected: _filter,
                onSelected: (status) => setState(() => _filter = status),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        message: l10n.statusFilterEmpty,
                        icon: Icons.filter_list_off,
                      )
                    : ShowProgressGrid(shows: filtered),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(profileByUsernameProvider(username)),
        ),
      ),
    );
  }
}
