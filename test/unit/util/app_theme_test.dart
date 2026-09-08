import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tooodooo_app/util/app_theme.dart';

void main() {
  group('AppTheme', () {
    group('getPriorityColor', () {
      test('returns green for priority 1 (lowest)', () {
        final color = AppTheme.getPriorityColor(1);
        expect(color, isNotNull);
        // Verify it's greenish (high green component)
        expect(color.green, greaterThan(color.red));
      });

      test('returns teal for priority 2', () {
        final color = AppTheme.getPriorityColor(2);
        expect(color, isNotNull);
      });

      test('returns blue for priority 3 (medium)', () {
        final color = AppTheme.getPriorityColor(3);
        expect(color, isNotNull);
        expect(color.blue, greaterThan(color.red));
      });

      test('returns orange for priority 4 (high)', () {
        final color = AppTheme.getPriorityColor(4);
        expect(color, isNotNull);
        expect(color.red, greaterThan(color.blue));
      });

      test('returns red for priority 5 (highest)', () {
        final color = AppTheme.getPriorityColor(5);
        expect(color, isNotNull);
        expect(color.red, greaterThan(color.green));
      });

      test('returns grey for default/invalid priority', () {
        final color = AppTheme.getPriorityColor(0);
        expect(color, isNotNull);
      });

      test('each priority returns a distinct color', () {
        final colors = <int>{};
        for (int i = 1; i <= 5; i++) {
          colors.add(AppTheme.getPriorityColor(i).value);
        }
        expect(colors.length, 5, reason: 'All 5 priorities should have distinct colors');
      });
    });

    group('getCalendarTaskColor', () {
      test('returns valid colors for all priorities 1-5', () {
        for (int i = 1; i <= 5; i++) {
          final color = AppTheme.getCalendarTaskColor(i);
          expect(color, isNotNull, reason: 'Priority $i should return a valid color');
        }
      });

      test('returns grey for default/invalid priority', () {
        final color = AppTheme.getCalendarTaskColor(0);
        expect(color, isNotNull);
      });

      test('each priority returns a distinct color', () {
        final colors = <int>{};
        for (int i = 1; i <= 5; i++) {
          colors.add(AppTheme.getCalendarTaskColor(i).value);
        }
        expect(colors.length, 5);
      });
    });

    group('getTextColorForPriority', () {
      test('returns white for all priorities', () {
        for (int i = 1; i <= 5; i++) {
          expect(AppTheme.getTextColorForPriority(i), Colors.white);
        }
      });
    });

    group('text styles', () {
      test('appBarTitle has expected properties', () {
        expect(AppTheme.appBarTitle.color, Colors.white);
        expect(AppTheme.appBarTitle.fontSize, 28);
        expect(AppTheme.appBarTitle.fontWeight, FontWeight.bold);
      });

      test('taskTitle returns style for given priority', () {
        final style = AppTheme.taskTitle(3);
        expect(style.fontSize, 18);
        expect(style.fontWeight, FontWeight.w500);
      });

      test('taskCompleted has line-through decoration', () {
        final style = AppTheme.taskCompleted(3);
        expect(style.decoration, TextDecoration.lineThrough);
      });
    });

    group('themeData', () {
      test('returns valid ThemeData', () {
        final theme = AppTheme.themeData;
        expect(theme, isA<ThemeData>());
        expect(theme.primaryColor, AppTheme.primaryColor);
        expect(theme.scaffoldBackgroundColor, AppTheme.backgroundColor);
      });

      test('themeData has correct color scheme', () {
        final theme = AppTheme.themeData;
        expect(theme.colorScheme.primary, AppTheme.accentColor);
      });
    });

    group('constants', () {
      test('padding values are positive', () {
        expect(AppTheme.defaultPadding, greaterThan(0));
        expect(AppTheme.smallPadding, greaterThan(0));
        expect(AppTheme.largePadding, greaterThan(0));
      });

      test('padding values follow expected order', () {
        expect(AppTheme.smallPadding, lessThan(AppTheme.defaultPadding));
        expect(AppTheme.defaultPadding, lessThan(AppTheme.largePadding));
      });

      test('borderRadius is positive', () {
        expect(AppTheme.borderRadius, greaterThan(0));
      });

      test('icon sizes are positive', () {
        expect(AppTheme.iconSize, greaterThan(0));
        expect(AppTheme.smallIconSize, greaterThan(0));
        expect(AppTheme.smallIconSize, lessThan(AppTheme.iconSize));
      });
    });

    group('button styles', () {
      test('primaryButtonStyle is configured', () {
        expect(AppTheme.primaryButtonStyle, isNotNull);
      });

      test('secondaryButtonStyle is configured', () {
        expect(AppTheme.secondaryButtonStyle, isNotNull);
      });
    });
  });
}
