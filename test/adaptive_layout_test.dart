import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/widgets/adaptive_layout.dart';

void main() {
  test('navigation switches to rail at the medium breakpoint', () {
    expect(AdaptiveLayout.usesNavigationRail(599), isFalse);
    expect(AdaptiveLayout.usesNavigationRail(600), isTrue);
  });

  test('page padding scales by available width', () {
    expect(AdaptiveLayout.horizontalPaddingForWidth(320), 16);
    expect(AdaptiveLayout.horizontalPaddingForWidth(390), 20);
    expect(AdaptiveLayout.horizontalPaddingForWidth(720), 24);
    expect(AdaptiveLayout.horizontalPaddingForWidth(900), 32);
  });

  testWidgets('button group stacks on very narrow widths', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: AdaptiveButtonGroup(children: [Text('First'), Text('Second')]),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(AdaptiveButtonGroup),
        matching: find.byType(Column),
      ),
      findsOneWidget,
    );
  });

  testWidgets('button group stays horizontal with enough width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(480, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: AdaptiveButtonGroup(children: [Text('First'), Text('Second')]),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(AdaptiveButtonGroup),
        matching: find.byType(Row),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sheet frame stays flush with the bottom edge', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const sheetKey = Key('sheet');

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(bottom: 34),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.expand(
            child: AdaptiveSheetFrame(
              child: SizedBox(key: sheetKey, height: 100, width: 400),
            ),
          ),
        ),
      ),
    );

    expect(tester.getBottomLeft(find.byKey(sheetKey)).dy, 800);
  });
}
