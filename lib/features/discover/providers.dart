import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/data/models.dart';
import '../shows/data/models.dart';
import '../shows/providers.dart';
import '../social/providers.dart';

/// Arama kutusu boşken gösterilen haftanın trend dizileri (F3d).
final trendingShowsProvider = FutureProvider.autoDispose<List<Show>>(
  (ref) => ref.watch(showsRepositoryProvider).trendingShows(),
);

final showSearchProvider = FutureProvider.autoDispose
    .family<List<Show>, String>(
      (ref, query) async =>
          (await ref.watch(showsRepositoryProvider).searchShows(query)).results,
    );

final userSearchProvider = FutureProvider.autoDispose
    .family<List<Profile>, String>(
      (ref, query) => ref.watch(socialRepositoryProvider).searchUsers(query),
    );
