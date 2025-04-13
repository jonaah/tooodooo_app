import 'package:flutter/material.dart';

/// Modellklasse für einen Kalendereintrag (Termin)
class CalendarAppointment {
  String subject;
  DateTime startTime;
  DateTime endTime;
  Color color;
  bool isAllDay;
  String? notes;
  bool isCompleted;

  CalendarAppointment({
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.isAllDay = false,
    this.notes,
    this.isCompleted = false,
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
    };
  }

  /// Erstellt ein Appointment aus einer JSON-Map
  factory CalendarAppointment.fromJson(Map<String, dynamic> json) {
    return CalendarAppointment(
      subject: json['subject'],
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime']),
      color: Color(json['color']),
      notes: json['notes'],
      isAllDay: json['isAllDay'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
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
  }) {
    return CalendarAppointment(
      subject: subject ?? this.subject,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}