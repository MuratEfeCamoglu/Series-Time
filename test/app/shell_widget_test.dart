import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sezonluk/features/discover/screens/discover_screen.dart';
import 'package:sezonluk/features/profile/screens/profile_screen.dart';
import 'package:sezonluk/features/tracking/screens/shows_screen.dart';

import '../helpers.dart';

Finder _navLabel(String text) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(text));

void main() {
  testWidgets(
    'uygulama açılınca 4 sekme etiketi görünür ve Diziler seçilidir',
    (tester) async {
      await TestBackend().pumpApp(tester);

      expect(_navLabel('Diziler'), findsOneWidget);
      expect(_navLabel('Keşfet'), findsOneWidget);
      expect(_navLabel('Bildirimler'), findsOneWidget);
      expect(_navLabel('Profil'), findsOneWidget);
      // Bildirimler, Keşfet ile Profil arasında (F13f).
      expect(
        tester.getCenter(_navLabel('Bildirimler')).dx,
        allOf(
          greaterThan(tester.getCenter(_navLabel('Keşfet')).dx),
          lessThan(tester.getCenter(_navLabel('Profil')).dx),
        ),
      );
      expect(find.byType(ShowsScreen), findsOneWidget);
    },
  );

  testWidgets('sekmeye dokununca ilgili ekran açılır', (tester) async {
    await TestBackend().pumpApp(tester);

    await tester.tap(_navLabel('Keşfet'));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoverScreen), findsOneWidget);

    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('açılışta simge katmanı solarak kalkar (F22c)', (tester) async {
    final backend = TestBackend();
    SharedPreferences.setMockInitialValues({'app.locale': 'tr'});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(backend.scope(preferences));
    await tester.pump();
    expect(find.byKey(const Key('launch.overlay')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('launch.overlay')), findsNothing);
    expect(find.byType(ShowsScreen), findsOneWidget);
  });

  testWidgets('animasyonları azalt açıksa açılış katmanı gösterilmez (F22c)', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final backend = TestBackend();
    SharedPreferences.setMockInitialValues({'app.locale': 'tr'});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(backend.scope(preferences));
    await tester.pump();
    expect(find.byKey(const Key('launch.overlay')), findsNothing);
  });
}
