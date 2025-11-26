// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:job_search_simulator/main.dart';

void main() {
  testWidgets('Setup view displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: JobSearchSimulatorApp()),
    );

    // Wait for animations and async operations to complete
    await tester.pumpAndSettle();

    // Verify that setup view is displayed
    expect(find.text('Karakter Oluştur'), findsOneWidget);
    expect(find.text('Cinsiyet'), findsOneWidget);
    expect(find.text('Bölüm'), findsOneWidget);
    expect(find.text('Simülasyona Başla'), findsOneWidget);
  });
}
