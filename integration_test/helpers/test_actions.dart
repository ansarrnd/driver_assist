import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> fillAddDriveForm(
  WidgetTester tester, {
  required String customerName,
  required String source,
  required String destination,
}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Customer Name'), customerName);
  await tester.enterText(find.widgetWithText(TextFormField, 'Pickup'), source);
  await tester.enterText(find.widgetWithText(TextFormField, 'Drop'), destination);

  await tester.tap(find.byIcon(Icons.calendar_today));
  await tester.pumpAndSettle();

  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final dayFinder = find.text('${tomorrow.day}');
  if (dayFinder.evaluate().isNotEmpty) {
    await tester.tap(dayFinder.last);
  } else {
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${tomorrow.day}').last);
  }
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.access_time));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> swipeToDeleteEntry(WidgetTester tester, String customerName) async {
  await tester.drag(find.text(customerName), const Offset(-500, 0));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();
}

Future<void> completeOnboarding(WidgetTester tester) async {
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();
}
