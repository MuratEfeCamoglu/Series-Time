import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/data/models.dart';
import '../shows/data/models.dart';
import '../shows/providers.dart';
import '../social/providers.dart';

/// Arama kutusu boşken gösterilen en ünlü diziler (F3d).
final popularShowsProvider = FutureProvider.autoDispose<List<Show>>(
  (ref) => ref.watch(showsRepositoryProvider).popularShows(),
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
