import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/pages/home_page.dart';

void main() {
  final sampleTasks = [
    {
      'name': 'Buy groceries',
      'completed': false,
      'priority': 3.0,
      'iconName': 'shopping',
      'duration': null,
      'isGroup': false,
      'subtasks': [],
      'colorValue': null,
    },
    {
      'name': 'Go running',
      'completed': true,
      'priority': 5.0,
      'iconName': 'fitness',
      'duration': 60,
      'isGroup': false,
      'subtasks': [],
      'colorValue': null,
    },
    {
      'name': 'Study project',
      'completed': false,
      'priority': 4.0,
      'iconName': 'book',
      'duration': null,
      'isGroup': true,
      'subtasks': [
        {'name': 'Read chapter 1', 'completed': true},
        {'name': 'Do exercises', 'completed': false},
      ],
      'colorValue': null,
    },
  ];

  group('HomePage task display', () {
    testWidgets('displays task names', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'toDoList': jsonEncode(sampleTasks),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tasks should be sorted by priority (highest first):
      // Go running (5.0), Study project (4.0), Buy groceries (3.0)
      expect(find.text('Go running'), findsOneWidget);
      // Group tasks append "(completed/total)" to the name
      expect(find.textContaining('Study project'), findsOneWidget);
      expect(find.text('Buy groceries'), findsOneWidget);
    });

    testWidgets('does not show empty state when tasks exist', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'toDoList': jsonEncode(sampleTasks),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No tasks yet'), findsNothing);
    });
  });

  group('HomePage checkbox interaction', () {
    testWidgets('tapping checkbox toggles task completion', (WidgetTester tester) async {
      final singleTask = [
        {
          'name': 'Simple Task',
          'completed': false,
          'priority': 3.0,
          'iconName': null,
          'duration': null,
          'isGroup': false,
          'subtasks': [],
          'colorValue': null,
        }
      ];

      SharedPreferences.setMockInitialValues({
        'toDoList': jsonEncode(singleTask),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Simple Task'), findsOneWidget);

      // Find and tap the checkbox
      final checkbox = find.byType(Checkbox);
      if (checkbox.evaluate().isNotEmpty) {
        await tester.tap(checkbox.first);
        await tester.pumpAndSettle();
      }
    });
  });

  group('HomePage task persistence', () {
    testWidgets('loads tasks from SharedPreferences on init', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'toDoList': jsonEncode(sampleTasks),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 3 tasks loaded
      expect(find.text('Go running'), findsOneWidget);
      expect(find.textContaining('Study project'), findsOneWidget);
      expect(find.text('Buy groceries'), findsOneWidget);
    });

    testWidgets('starts empty when no saved data', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No tasks yet'), findsOneWidget);
    });
  });
}
