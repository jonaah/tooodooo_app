import 'package:flutter/material.dart';
import 'package:tooodooo_app/util/app_theme.dart';

/// Modellklasse für einen Kalendereintrag (Termin)
class CalendarAppointment {
  String subject;
  DateTime startTime;
  DateTime endTime;
  Color color;
  bool isAllDay;
  String? notes;
  bool isCompleted;
  int? priority; // 1-5 optional
  int? customColorValue; // ARGB custom color if chosen

  CalendarAppointment({
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.isAllDay = false,
    this.notes,
    this.isCompleted = false,
    this.priority,
    this.customColorValue,
  });

  /// Konvertiert das Appointment in eine JSON-Map
  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'color': color.value,
      'notes': notes,
      'isAllDay': isAllDay,
      'isCompleted': isCompleted,
      'priority': priority,
      'customColorValue': customColorValue,
    };
  }

  /// Erstellt ein Appointment aus einer JSON-Map
  factory CalendarAppointment.fromJson(Map<String, dynamic> json) {
    Color c = Color(json['color']);
    int? p = json['priority'];
    // Fallback: infer priority from color if missing
    if (p == null) {
      for (int i = 1; i <= 5; i++) {
        if (AppTheme.getCalendarTaskColor(i).value == c.value) {
          p = i;
          break;
        }
      }
    }
    return CalendarAppointment(
      subject: json['subject'],
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime']),
      color: c,
      notes: json['notes'],
      isAllDay: json['isAllDay'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      priority: p,
      customColorValue: json['customColorValue'],
    );
  }

  /// Erstellt eine Kopie des Appointments mit aktualisierten Werten
  CalendarAppointment copyWith({
    String? subject,
    DateTime? startTime,
    DateTime? endTime,
    Color? color,
    bool? isAllDay,
    String? notes,
    bool? isCompleted,
    int? priority,
    int? customColorValue,
  }) {
    return CalendarAppointment(
      subject: subject ?? this.subject,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      customColorValue: customColorValue ?? this.customColorValue,
    );
  }
}