import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brikle/main.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
