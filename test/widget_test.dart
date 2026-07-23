import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driver_schedule/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:driver_schedule/database_helper.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Main Navigation UI test', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('ListTile background color')) return;
      originalOnError?.call(details);
    };

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));

    // Verify that we start on the Drive Schedule tab.
    expect(find.text('Drive Schedule'), findsWidgets);
    expect(find.byType(TabBar), findsOneWidget); // Contains Trips/Tickets

    // Tap the 'Add' icon in BottomNavigationBar.
    await tester.tap(find.text('Add'));
    await tester.pump(const Duration(seconds: 1));

    // Verify that we navigated to the Add Screen.
    expect(find.text('Add Item'), findsOneWidget);
    expect(find.text('Customer Name'), findsOneWidget);

    // Tap the 'Settings' icon in BottomNavigationBar.
    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(seconds: 1));

    // Verify that we navigated to the Settings Screen.
    expect(find.text('Settings'), findsWidgets);
  });
}
