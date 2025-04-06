import 'package:flutter/material.dart';

/// Icons utility class that uses constant IconData instances
class AppIcons {
  // Map of string keys to const IconData objects
  static const Map<String, IconData> iconMap = {
    'clock': Icons.lock_clock,
    'soccer': Icons.sports_soccer,
    'favorite': Icons.favorite,
    'home': Icons.home,
    'work': Icons.work_history,
    'school': Icons.school,
    'pets': Icons.pets,
    'music': Icons.music_note,
    'football': Icons.sports_football,
    'flower': Icons.local_florist,
    'restaurant': Icons.restaurant,
    'shopping': Icons.shopping_cart,
    'flight': Icons.flight,
    'car': Icons.directions_car,
    'fitness': Icons.fitness_center,
    'book': Icons.book,
    'code': Icons.code,
    'beach': Icons.beach_access,
    'call': Icons.call,
    'camera': Icons.camera_alt,
    'movie': Icons.movie,
    'games': Icons.games,
    'headset': Icons.headset,
    'hiking': Icons.hiking,
    'hotel': Icons.hotel,
    'bug': Icons.bug_report,
    'celebration': Icons.celebration,
    'cleaning': Icons.cleaning_services,
    'coffee': Icons.coffee,
    'computer': Icons.computer,
    'medication': Icons.medication,
    'sunny': Icons.sunny,
    'umbrella': Icons.umbrella,
    'water': Icons.water_drop,
    'landscape': Icons.landscape,
    'forest': Icons.forest,
  };
  
  // Get icon from name
  static IconData? getIcon(String? name) {
    if (name == null) return null;
    return iconMap[name];
  }
  
  // Get name from icon
  static String? getName(IconData? icon) {
    if (icon == null) return null;
    for (var entry in iconMap.entries) {
      if (entry.value.codePoint == icon.codePoint) {
        return entry.key;
      }
    }
    return null;
  }
  
  // Get all icons
  static List<IconData> get allIcons => List.unmodifiable(iconMap.values);
  
  // Get default icons (first 10)
  static List<IconData> get defaultIcons => allIcons.take(10).toList();
}
