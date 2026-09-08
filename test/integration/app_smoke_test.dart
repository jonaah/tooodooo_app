import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/pages/main.dart';

void main() {
  group('App Smoke Test', () {
    testWidgets('app starts and shows MainNavigator with Tasks tab selected', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'toDoList': jsonEncode([]),
        'calendar_appointments': jsonEncode([]),
      });

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // MainNavigator should be visible
      expect(find.byType(MainNavigator), findsOneWidget);

      // Navigation tabs should be visible
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);

      // Tasks page should be initially active (AppBar title)
      expect(find.text('TO DO'), findsOneWidget);
    });

    testWidgets('navigating to Today tab loads correctly', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'toDoList': jsonEncode([]),
        'calendar_appointments': jsonEncode([]),
      });

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Switch to Today tab
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Today page action button should appear
      expect(find.byTooltip('Go to Today'), findsOneWidget);
    });

    testWidgets('navigating to Calendar tab loads correctly', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'toDoList': jsonEncode([]),
        'calendar_appointments': jsonEncode([]),
      });

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Switch to Calendar tab
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      // Calendar page action button should appear
      expect(find.byTooltip('Add to Calendar'), findsOneWidget);
    });

    testWidgets('switching back to Tasks tab preserves state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'toDoList': jsonEncode([]),
        'calendar_appointments': jsonEncode([]),
      });

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate away and back
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      // Tasks page should still be showing
      expect(find.byTooltip('New Task'), findsOneWidget);
      expect(find.text('TO DO'), findsOneWidget);
    });
  });
}
