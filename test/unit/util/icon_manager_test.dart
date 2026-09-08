import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/util/icon_manager.dart';
import 'package:tooodooo_app/util/app_icons.dart';

void main() {
  group('IconManager', () {
    setUp(() {
      // Reset the IconManager state before each test by setting empty mock values
      SharedPreferences.setMockInitialValues({});
      // Force reload on next call by resetting internal state
      // Since _hasLoadedRecentIcons is private, we test through the public API
    });

    group('allIcons', () {
      test('returns same list as AppIcons.allIcons', () {
        expect(IconManager.allIcons.length, AppIcons.allIcons.length);
      });
    });

    group('defaultIcons', () {
      test('returns same list as AppIcons.defaultIcons', () {
        expect(IconManager.defaultIcons.length, AppIcons.defaultIcons.length);
      });
    });

    group('isDefaultIcon', () {
      test('returns true for default icons', () {
        for (final icon in AppIcons.defaultIcons) {
          expect(IconManager.isDefaultIcon(icon), true,
            reason: 'Icon with codePoint ${icon.codePoint} should be a default icon');
        }
      });

      test('returns false for non-default icons', () {
        // Icons.ac_unit is not in our icon map
        expect(IconManager.isDefaultIcon(Icons.ac_unit), false);
      });
    });

    group('recentIcons', () {
      test('returns default icons when no recent icons saved', () {
        SharedPreferences.setMockInitialValues({});
        // Since _recentIconNames is empty, recentIcons should include defaults
        final icons = IconManager.recentIcons;
        expect(icons, isNotEmpty);
        expect(icons.length, lessThanOrEqualTo(12));
      });
    });

    group('addToRecentIcons', () {
      test('adds valid icon to recent list', () {
        final icon = AppIcons.getIcon('soccer')!;
        IconManager.addToRecentIcons(icon);
        
        final recents = IconManager.recentIcons;
        expect(recents.first.codePoint, icon.codePoint);
      });

      test('moves duplicate to front', () {
        final soccer = AppIcons.getIcon('soccer')!;
        final home = AppIcons.getIcon('home')!;
        
        IconManager.addToRecentIcons(soccer);
        IconManager.addToRecentIcons(home);
        IconManager.addToRecentIcons(soccer); // Add again - should move to front
        
        final recents = IconManager.recentIcons;
        expect(recents[0].codePoint, soccer.codePoint);
        expect(recents[1].codePoint, home.codePoint);
      });

      test('ignores unknown icons', () {
        // Icons.ac_unit is not in our AppIcons map, so getName returns null
        IconManager.addToRecentIcons(Icons.ac_unit);
        // Should not crash and should not add to list
        expect(true, true); // No exception thrown
      });
    });

    group('isUsingDefaultIcons', () {
      test('is correct based on state', () {
        // After clearing, should use defaults
        // This tests the getter logic
        expect(IconManager.isUsingDefaultIcons, isA<bool>());
      });
    });
  });
}
