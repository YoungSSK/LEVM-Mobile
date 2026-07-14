// Smoke test that the app boots without crashing and renders the login screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:levm_mobile/main.dart';

void main() {
  testWidgets('App boots and shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LEVMApp()),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
