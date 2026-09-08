import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/pages/main.dart';

void main() {
  testWidgets('Floating navigation bar displays pill and contextual circle button', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'toDoList': jsonEncode([]),
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 1. Initial State: MainPage (Tasks)
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);

    // On Tasks page, the circle button should have the add icon / 'New Task' tooltip
    expect(find.byTooltip('New Task'), findsOneWidget);

    // 2. Switch to Today tab
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    // On Today page, the circle button should have 'Go to Today' tooltip
    expect(find.byTooltip('Go to Today'), findsOneWidget);

    // 3. Switch to Calendar tab
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    // On Calendar page, the circle button should have 'Add to Calendar' tooltip
    expect(find.byTooltip('Add to Calendar'), findsOneWidget);

    // 4. Switch back to Tasks tab
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('New Task'), findsOneWidget);
  });
}
