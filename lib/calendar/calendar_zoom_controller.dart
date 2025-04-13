import 'package:flutter/material.dart';

/// Controller für die Zoom-Funktionalität des Kalenders
class CalendarZoomController {
  /// Standardhöhe für Zeitintervalle
  double _timeIntervalHeight = 40;
  
  /// Minimale Höhe eines Zeitintervalls beim Zoomen
  static const double minTimeIntervalHeight = 20;
  
  /// Maximale Höhe eines Zeitintervalls beim Zoomen
  static const double maxTimeIntervalHeight = 80;
  
  /// Aktuelles Zeitintervall in Minuten (5, 10, 15, 30 oder 60)
  int _currentMinutesInterval = 15;
  
  /// Getter für aktuelle Zeitintervallhöhe
  double get timeIntervalHeight => _timeIntervalHeight;
  
  /// Getter für aktuelles Zeitintervall in Minuten
  int get currentMinutesInterval => _currentMinutesInterval;
  
  /// Ermittelt das passende Zeitintervall für eine bestimmte Zoom-Höhe
  int _getTimeIntervalForHeight(double height) {
    if (height >= 70) return 5;
    if (height >= 60) return 10;
    if (height >= 50) return 15;
    if (height >= 40) return 30;
    return 60;
  }
  
  /// Behandelt Scale-Gesten für Zoom-Funktionalität
  /// Gibt zurück, ob sich das Zeitintervall geändert hat
  bool handleScale(ScaleUpdateDetails details) {
    final newHeight = (_timeIntervalHeight * details.scale)
        .clamp(minTimeIntervalHeight, maxTimeIntervalHeight);
    
    // Ermittle das passende Zeitintervall für diese Höhe
    final newInterval = _getTimeIntervalForHeight(newHeight);
    
    bool intervalChanged = false;
    // Aktualisiere das Zeitintervall nur, wenn es sich wirklich geändert hat
    if (newInterval != _currentMinutesInterval) {
      _currentMinutesInterval = newInterval;
      intervalChanged = true;
    }
    
    _timeIntervalHeight = newHeight;
    return intervalChanged;
  }
  
  /// Setzt die Höhe des Zeitintervalls
  void setTimeIntervalHeight(double height) {
    _timeIntervalHeight = height.clamp(minTimeIntervalHeight, maxTimeIntervalHeight);
    _currentMinutesInterval = _getTimeIntervalForHeight(_timeIntervalHeight);
  }
}