import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/discover/screens/discover_screen.dart';
import 'package:sezonluk/features/profile/screens/profile_screen.dart';
import 'package:sezonluk/features/tracking/screens/shows_screen.dart';
import 'package:sezonluk/main.dart';

Finder _navLabel(String text) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(text));

void main() {
  testWidgets(
    'uygulama açılınca 3 sekme etiketi görünür ve Diziler seçilidir',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SezonlukApp()));
      await tester.pumpAndSettle();

      expect(_navLabel('Diziler'), findsOneWidget);
      expect(_navLabel('Keşfet'), findsOneWidget);
      expect(_navLabel('Profil'), findsOneWidget);
      expect(find.byType(ShowsScreen), findsOneWidget);
    },
  );

  testWidgets('sekmeye dokununca ilgili ekran açılır', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SezonlukApp()));
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('Keşfet'));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoverScreen), findsOneWidget);

    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}
