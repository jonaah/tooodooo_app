import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/pages/home_page.dart';

void main() {
  group('HomePage empty state', () {
    testWidgets('shows empty state message when no tasks exist', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'toDoList': jsonEncode([]),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No tasks yet'), findsOneWidget);
      expect(find.text('Tap + to add a new task'), findsOneWidget);
    });

    testWidgets('shows empty state icon', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'toDoList': jsonEncode([]),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    });

    testWidgets('shows settings icon', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'toDoList': jsonEncode([]),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('shows TO DO title in AppBar', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'toDoList': jsonEncode([]),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TO DO'), findsOneWidget);
    });
  });
}
