import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driver_schedule/tickets_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Tickets Screen UI test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TicketsScreen())));
    await tester.pump(const Duration(seconds: 2));

    // Check for the Dropdown filter
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    
    // Check default filter text
    expect(find.text('Month'), findsOneWidget);

    // Initially it shows a CircularProgressIndicator while fetching from DB
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
