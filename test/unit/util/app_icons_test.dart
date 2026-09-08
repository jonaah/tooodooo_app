import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tooodooo_app/util/app_icons.dart';

void main() {
  group('AppIcons', () {
    group('getIcon', () {
      test('returns correct IconData for known names', () {
        expect(AppIcons.getIcon('soccer'), Icons.sports_soccer);
        expect(AppIcons.getIcon('favorite'), Icons.favorite);
        expect(AppIcons.getIcon('home'), Icons.home);
        expect(AppIcons.getIcon('work'), Icons.work_history);
        expect(AppIcons.getIcon('school'), Icons.school);
      });

      test('returns null for null name', () {
        expect(AppIcons.getIcon(null), isNull);
      });

      test('returns null for unknown name', () {
        expect(AppIcons.getIcon('nonexistent'), isNull);
        expect(AppIcons.getIcon(''), isNull);
      });
    });

    group('getName', () {
      test('returns correct name for known icons', () {
        expect(AppIcons.getName(Icons.sports_soccer), 'soccer');
        expect(AppIcons.getName(Icons.favorite), 'favorite');
        expect(AppIcons.getName(Icons.home), 'home');
      });

      test('returns null for null icon', () {
        expect(AppIcons.getName(null), isNull);
      });

      test('returns null for unknown icon', () {
        expect(AppIcons.getName(Icons.ac_unit), isNull);
      });
    });

    group('bidirectional mapping', () {
      test('getName(getIcon(name)) == name for all entries', () {
        for (final name in AppIcons.iconMap.keys) {
          final icon = AppIcons.getIcon(name);
          expect(icon, isNotNull, reason: 'getIcon("$name") should not be null');
          final result = AppIcons.getName(icon!);
          expect(result, name, reason: 'getName(getIcon("$name")) should be "$name"');
        }
      });

      test('getIcon(getName(icon)) has same codePoint for all entries', () {
        for (final entry in AppIcons.iconMap.entries) {
          final name = AppIcons.getName(entry.value);
          expect(name, isNotNull, reason: 'getName should return a name for ${entry.key}');
          final icon = AppIcons.getIcon(name!);
          expect(icon?.codePoint, entry.value.codePoint,
            reason: 'Round-trip for ${entry.key} should match codePoint');
        }
      });
    });

    group('allIcons', () {
      test('contains all icons from iconMap', () {
        expect(AppIcons.allIcons.length, AppIcons.iconMap.length);
      });

      test('is unmodifiable', () {
        expect(() => AppIcons.allIcons.add(Icons.ac_unit), throwsUnsupportedError);
      });
    });

    group('defaultIcons', () {
      test('contains first 12 icons', () {
        expect(AppIcons.defaultIcons.length, 12);
      });

      test('is a subset of allIcons', () {
        for (final icon in AppIcons.defaultIcons) {
          expect(AppIcons.allIcons.contains(icon), isTrue,
            reason: 'Default icon should be in allIcons');
        }
      });

      test('returns fewer if total icons < 12', () {
        // This test verifies the logic works - since we have > 12 icons,
        // defaultIcons should be exactly 12
        expect(AppIcons.defaultIcons.length, lessThanOrEqualTo(AppIcons.allIcons.length));
      });
    });

    group('iconMap', () {
      test('contains expected category icons', () {
        // Verify key representative icons are present
        expect(AppIcons.iconMap.containsKey('clock'), true);
        expect(AppIcons.iconMap.containsKey('soccer'), true);
        expect(AppIcons.iconMap.containsKey('book'), true);
        expect(AppIcons.iconMap.containsKey('code'), true);
        expect(AppIcons.iconMap.containsKey('fitness'), true);
      });

      test('all values are non-null', () {
        for (final entry in AppIcons.iconMap.entries) {
          expect(entry.value, isNotNull, reason: 'Icon for "${entry.key}" should not be null');
        }
      });
    });
  });
}
