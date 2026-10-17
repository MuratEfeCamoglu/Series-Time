import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/features/moderation/data/models.dart';
import 'package:sezonluk/features/moderation/screens/blocked_users_screen.dart';
import 'package:sezonluk/features/tracking/screens/shows_screen.dart';

import '../../helpers.dart';

void main() {
  testWidgets('Ayarlar › Engellenenler listeler ve engel kaldırılır (F15c)', (
    tester,
  ) async {
    final backend = TestBackend();
    when(() => backend.moderation.fetchBlockedUsers()).thenAnswer(
      (_) async => const [
        BlockedUser(userId: 'u2', username: 'burak', displayName: 'Burak'),
      ],
    );
    when(() => backend.moderation.unblock('u2')).thenAnswer((_) async {});
    await backend.pumpApp(tester);
    GoRouter.of(tester.element(find.byType(ShowsScreen))).push('/settings');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings.blocked')));
    await tester.pumpAndSettle();
    expect(find.byType(BlockedUsersScreen), findsOneWidget);
    expect(find.text('@burak'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unblock.u2')));
    await tester.pumpAndSettle();

    verify(() => backend.moderation.unblock('u2')).called(1);
    expect(find.text('Kimseyi engellemedin.'), findsOneWidget);
  });
}
