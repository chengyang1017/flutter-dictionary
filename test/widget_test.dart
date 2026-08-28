import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets(
    'app boots into a Material application',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MyApp(),
      );

      expect(
        find.byType(MaterialApp),
        findsOneWidget,
      );
    },
  );
}
