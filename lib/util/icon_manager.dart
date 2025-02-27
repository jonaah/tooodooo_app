import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IconManager {
  static const String _recentIconsKey = 'recentIcons';
  static const int _maxRecentIcons = 10;
  
  // List of all available icons
  static final List<IconData> allIcons = [
    Icons.lock_clock,
    Icons.sports_soccer,
    Icons.favorite,
    Icons.home,
    Icons.work_history,
    Icons.school,
    Icons.pets,
    Icons.music_note,
    Icons.sports_football,
    Icons.local_florist,
    Icons.restaurant,
    Icons.shopping_cart,
    Icons.flight,
    Icons.directions_car,
    Icons.fitness_center,
    Icons.book,
    Icons.code,
    Icons.beach_access,
    Icons.call,
    Icons.camera_alt,
    Icons.movie,
    Icons.games,
    Icons.headset,
    Icons.hiking,
    Icons.hotel,
    Icons.bug_report,
    Icons.celebration,
    Icons.cleaning_services,
    Icons.coffee,
    Icons.computer,
    Icons.medication,
    Icons.sunny,
    Icons.umbrella,
    Icons.water_drop,
    Icons.landscape,
    Icons.forest,
  ];

  // Default icons that will be shown initially if no recent icons exist
  static final List<IconData> defaultIcons = [
    Icons.lock_clock,
    Icons.sports_soccer,
    Icons.favorite,
    Icons.home,
    Icons.work_history,
    Icons.school,
    Icons.pets,
    Icons.music_note,
    Icons.sports_football,
    Icons.local_florist,
  ];
  
  static List<IconData> _recentIcons = [];
  static bool _hasLoadedRecentIcons = false;
  
  // Get recently used icons, fallback to default icons if empty
  // This will ALWAYS return exactly 10 icons, either from recent history or defaults
  static List<IconData> get recentIcons {
    if (_recentIcons.isEmpty) {
      // If no recent icons, return default icons
      return List<IconData>.from(defaultIcons);
    } else if (_recentIcons.length < _maxRecentIcons) {
      // If we have some recent icons but fewer than 10, 
      // pad with default icons that aren't already in the recent list
      List<IconData> result = List<IconData>.from(_recentIcons);
      
      // Add default icons that aren't in the recent list
      for (var icon in defaultIcons) {
        if (result.length >= _maxRecentIcons) break;
        if (!result.any((i) => i.codePoint == icon.codePoint)) {
          result.add(icon);
        }
      }
      
      // If we still don't have enough, add more from allIcons
      if (result.length < _maxRecentIcons) {
        for (var icon in allIcons) {
          if (result.length >= _maxRecentIcons) break;
          if (!result.any((i) => i.codePoint == icon.codePoint)) {
            result.add(icon);
          }
        }
      }
      
      return result;
    } else {
      // Just return the recent icons (should be exactly 10)
      return List<IconData>.from(_recentIcons);
    }
  }
  
  // Load recently used icons from SharedPreferences
  static Future<void> loadRecentIcons() async {
    if (_hasLoadedRecentIcons) return;
    
    final prefs = await SharedPreferences.getInstance();
    final recentIconsString = prefs.getString(_recentIconsKey);
    
    if (recentIconsString != null) {
      final List<dynamic> decoded = jsonDecode(recentIconsString);
      _recentIcons = decoded.map((codePoint) => 
        IconData(codePoint, fontFamily: 'MaterialIcons')
      ).toList();
    }
    
    _hasLoadedRecentIcons = true;
  }
  
  // Save recently used icons to SharedPreferences
  static Future<void> saveRecentIcons() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _recentIcons.map((icon) => icon.codePoint).toList()
    );
    await prefs.setString(_recentIconsKey, encoded);
  }
  
  // Add an icon to recently used
  static void addToRecentIcons(IconData icon) {
    // Remove if already exists
    _recentIcons.removeWhere((e) => e.codePoint == icon.codePoint);
    
    // Add to the beginning
    _recentIcons.insert(0, icon);
    
    // Trim if too many
    if (_recentIcons.length > _maxRecentIcons) {
      _recentIcons = _recentIcons.sublist(0, _maxRecentIcons);
    }
    
    // Save to SharedPreferences
    saveRecentIcons();
  }

  // Check if icon is a default icon
  static bool isDefaultIcon(IconData icon) {
    return defaultIcons.any((defaultIcon) => defaultIcon.codePoint == icon.codePoint);
  }
  
  // Check if we're using default icons or actual recent icons
  static bool get isUsingDefaultIcons {
    return _recentIcons.isEmpty;
  }
}
