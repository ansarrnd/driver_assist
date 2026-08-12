import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driver_schedule/features/drive/presentation/pages/add_drive_entry_page.dart';

import '../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await configureTestEnvironment();
  });

  testWidgets('AddDriveEntryPage golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpTestWidget(tester, const AddDriveEntryPage());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AddDriveEntryPage),
      matchesGoldenFile('add_drive_entry_trip.png'),
    );
  });
}
