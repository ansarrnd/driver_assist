import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driver_schedule/features/drive/presentation/pages/add_drive_entry_page.dart';

import '../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await configureTestEnvironment();
  });

  group('AddDriveEntryPage', () {
    testWidgets('shows validation errors when submitting empty form', (tester) async {
      await pumpTestWidget(tester, const AddDriveEntryPage());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Add Entry'));
      await tester.tap(find.text('Add Entry'));
      await tester.pump();

      expect(find.text('Please enter customer name'), findsOneWidget);
      expect(find.text('Please select a date'), findsOneWidget);
      expect(find.text('Please select a time'), findsOneWidget);
    });

    testWidgets('uses pickup/drop labels for trip mode', (tester) async {
      await pumpTestWidget(tester, const AddDriveEntryPage());
      await tester.pumpAndSettle();

      expect(find.text('Pickup'), findsOneWidget);
      expect(find.text('Drop'), findsOneWidget);
    });
  });
}
