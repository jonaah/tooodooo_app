import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/pages/home_page.dart';

void main() {
  testWidgets('AppBar dissolves when scrolling down and reappears when scrolling up', (WidgetTester tester) async {
    // Generate 20 test tasks so the list is scrollable
    final tasksData = List.generate(20, (i) => {
      'name': 'Task $i',
      'completed': false,
      'priority': 3.0,
      'iconName': null,
      'duration': null,
      'isGroup': false,
      'subtasks': [],
      'colorValue': null,
    });

    SharedPreferences.setMockInitialValues({
      'toDoList': jsonEncode(tasksData),
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );

    // Initial pump and wait for SharedPreferences loading
    await tester.pumpAndSettle();

    // Verify task tiles are loaded
    expect(find.text('Task 0'), findsOneWidget);
    expect(find.text('TO DO'), findsOneWidget);

    // Verify initial opacity is 1.0
    final animatedOpacityFinder = find.byWidgetPredicate(
      (widget) => widget is Opacity && widget.child is IgnorePointer,
    );
    expect(animatedOpacityFinder, findsOneWidget);
    Opacity initialOpacityWidget = tester.widget(animatedOpacityFinder);
    expect(initialOpacityWidget.opacity, equals(1.0));

    // Scroll down: drag the ListView up by 300 pixels
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    // Pump animation frames
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify opacity has dissolved to 0.0
    Opacity dissolvedOpacityWidget = tester.widget(animatedOpacityFinder);
    expect(dissolvedOpacityWidget.opacity, equals(0.0));

    // Scroll up: drag the ListView down by 150 pixels
    await tester.drag(find.byType(ListView), const Offset(0, 150));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify opacity has reappeared back to 1.0
    Opacity reappearedOpacityWidget = tester.widget(animatedOpacityFinder);
    expect(reappearedOpacityWidget.opacity, equals(1.0));

    // Scroll down again
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    dissolvedOpacityWidget = tester.widget(animatedOpacityFinder);
    expect(dissolvedOpacityWidget.opacity, equals(0.0));

    // Scroll back all the way to top (overscroll)
    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    reappearedOpacityWidget = tester.widget(animatedOpacityFinder);
    expect(reappearedOpacityWidget.opacity, equals(1.0));
  });

  testWidgets('AppBar is visible and remains visible when task list is empty', (WidgetTester tester) async {
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

    final animatedOpacityFinder = find.byWidgetPredicate(
      (widget) => widget is Opacity && widget.child is IgnorePointer,
    );
    expect(animatedOpacityFinder, findsOneWidget);
    Opacity opacityWidget = tester.widget(animatedOpacityFinder);
    expect(opacityWidget.opacity, equals(1.0));
  });
}
