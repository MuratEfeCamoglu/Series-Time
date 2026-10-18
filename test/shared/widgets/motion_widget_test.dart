import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/shared/widgets/motion.dart';
import 'package:sezonluk/shared/widgets/progress_bar.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

double _opacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.descendant(
        of: find.byType(EntranceAnimation),
        matching: find.byType(FadeTransition),
      ),
    )
    .opacity
    .value;

void main() {
  testWidgets('öğe görünmezden solarak gelir; sonraki öğe gecikmeli (F22c)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const EntranceAnimation(index: 5, child: Text('a'))),
    );
    expect(_opacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 100));
    // 5. öğe kendi gecikmesi (5 × 35 ms) dolmadan başlamaz.
    expect(_opacity(tester), 0);

    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
  });

  testWidgets('animasyonları azalt açıksa öğe hemen tam görünür (F22c)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const EntranceAnimation(index: 3, child: Text('a')),
        reduceMotion: true,
      ),
    );
    expect(_opacity(tester), 1);
  });

  testWidgets('basılı tutulunca küçülür, bırakınca eski boyuna döner', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PressScale(
          child: SizedBox.square(
            dimension: 100,
            child: InkWell(onTap: () {}, child: const Text('afiş')),
          ),
        ),
      ),
    );
    double scale() =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
    expect(scale(), 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('afiş')),
    );
    await tester.pumpAndSettle();
    expect(scale(), lessThan(1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(scale(), 1);
  });

  testWidgets('seçilince kısa zıplar ve eski boyuna döner', (tester) async {
    Future<void> pump(bool active) => tester.pumpWidget(
      _app(SelectionBounce(active: active, child: const Text('😂'))),
    );
    double scale() => tester
        .widget<ScaleTransition>(
          find.descendant(
            of: find.byType(SelectionBounce),
            matching: find.byType(ScaleTransition),
          ),
        )
        .scale
        .value;

    await pump(false);
    await pump(true);
    await tester.pump(const Duration(milliseconds: 120));
    expect(scale(), greaterThan(1));

    await tester.pumpAndSettle();
    expect(scale(), 1);
  });

  testWidgets('sayı sıfırdan hedefe sayarak gelir', (tester) async {
    await tester.pumpWidget(
      _app(CountUp(value: 120, builder: (_, v) => Text('$v'))),
    );
    expect(find.text('0'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('120'), findsOneWidget);
  });

  testWidgets('ilerleme çubuğu boştan dolar', (tester) async {
    await tester.pumpWidget(
      _app(const SizedBox(width: 200, child: ProgressBar(value: 0.5))),
    );
    double value() => tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;
    expect(value(), 0);

    await tester.pumpAndSettle();
    expect(value(), 0.5);
  });
}
