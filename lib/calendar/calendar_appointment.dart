import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tooodooo_app/util/app_theme.dart';

/// Modellklasse für einen Kalendereintrag (Termin) - jetzt unveränderlich (immutable)
class CalendarAppointment {
  final String id; // stabile eindeutige ID
  final String subject;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final bool isAllDay;
  final String? notes;
  final bool isCompleted;
  final int? priority; // 1-5 optional
  final int? customColorValue; // ARGB custom color if chosen

  CalendarAppointment({
    String? id,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.isAllDay = false,
    this.notes,
    this.isCompleted = false,
    this.priority,
    this.customColorValue,
  }) : id = id ?? _generateId(subject, startTime);

  static String _generateId(String subject, DateTime start) {
    final rnd = Random().nextInt(1 << 32);
    return '${start.millisecondsSinceEpoch}_${subject.hashCode}_$rnd';
  }

  /// Konvertiert das Appointment in eine JSON-Map
  Map<String, dynamic> toJson() => {
        'id': id,
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

  /// Erstellt ein Appointment aus einer JSON-Map (vergibt ID wenn fehlend für Backward-Kompatibilität)
  factory CalendarAppointment.fromJson(Map<String, dynamic> json) {
    final c = Color(json['color']);
    int? p = json['priority'];
    if (p == null) {
      for (int i = 1; i <= 5; i++) {
        if (AppTheme.getCalendarTaskColor(i).value == c.value) {
          p = i;
          break;
        }
      }
    }
    final start = DateTime.fromMillisecondsSinceEpoch(json['startTime']);
    return CalendarAppointment(
      id: json['id'],
      subject: json['subject'],
      startTime: start,
      endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime']),
      color: c,
      notes: json['notes'],
      isAllDay: json['isAllDay'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      priority: p,
      customColorValue: json['customColorValue'],
    );
  }

  /// Kopie mit aktualisierten Werten (ID bleibt per Default erhalten)
  CalendarAppointment copyWith({
    String? id,
    String? subject,
    DateTime? startTime,
    DateTime? endTime,
    Color? color,
    bool? isAllDay,
    String? notes,
    bool? isCompleted,
    int? priority,
    int? customColorValue,
  }) => CalendarAppointment(
        id: id ?? this.id,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CalendarAppointment && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CalendarAppointment(id=$id, subject=$subject, start=$startTime)';
}