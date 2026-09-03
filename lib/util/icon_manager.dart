import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/util/app_icons.dart';

class IconManager {
  static const String _recentIconsKey = 'recentIconNames'; // Changed from recentIcons
  static const int _maxRecentIcons = 12;
  
  // Use AppIcons for all icon lists
  static final List<IconData> allIcons = AppIcons.allIcons;
  static final List<IconData> defaultIcons = AppIcons.defaultIcons;
  
  // Store icon names rather than IconData objects
  static List<String> _recentIconNames = [];
  static bool _hasLoadedRecentIcons = false;
  
  // Get recently used icons
  static List<IconData> get recentIcons {
    List<IconData> result = [];
    
    // Convert stored names to icons
    for (String name in _recentIconNames) {
      IconData? icon = AppIcons.getIcon(name);
      if (icon != null) result.add(icon);
    }
    
    // If we don't have enough recent icons, use defaults
    if (result.length < _maxRecentIcons) {
      for (var icon in defaultIcons) {
        if (result.length >= _maxRecentIcons) break;
        if (!result.contains(icon)) {
          result.add(icon);
        }
      }
    }
    
    return result;
  }
  
  // Load icons from SharedPreferences (by name)
  static Future<void> loadRecentIcons() async {
    if (_hasLoadedRecentIcons) return;
    
    final prefs = await SharedPreferences.getInstance();
    final recentIconsString = prefs.getString(_recentIconsKey);
    
    if (recentIconsString != null) {
      final List<dynamic> decoded = jsonDecode(recentIconsString);
      _recentIconNames = List<String>.from(decoded);
    }
    
    _hasLoadedRecentIcons = true;
  }
  
  // Save icon names to SharedPreferences
  static Future<void> saveRecentIcons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recentIconsKey, jsonEncode(_recentIconNames));
  }
  
  // Add an icon to recently used
  static void addToRecentIcons(IconData icon) {
    String? iconName = AppIcons.getName(icon);
    if (iconName == null) return;
    
    // Remove if already exists
    _recentIconNames.remove(iconName);
    
    // Add to the beginning
    _recentIconNames.insert(0, iconName);
    
    // Trim if too many
    if (_recentIconNames.length > _maxRecentIcons) {
      _recentIconNames = _recentIconNames.sublist(0, _maxRecentIcons);
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
    return _recentIconNames.isEmpty;
  }
}
