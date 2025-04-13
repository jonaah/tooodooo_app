import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';

/// Service for managing today's tasks (appointments)
class TodayTasksService {
  // Section titles
  static const String sectionHappeningNow = 'HAPPENING NOW';
  static const String sectionPending = 'PENDING';
  static const String sectionUpcoming = 'UPCOMING';
  static const String sectionScheduled = 'SCHEDULED';
  static const String sectionCompleted = 'COMPLETED';
  
  // Messages
  static const String msgTaskCompleted = 'Task marked as completed';
  static const String msgTaskIncomplete = 'Task marked as incomplete';
  static const String msgTaskRemoved = 'Task removed from calendar';
  static const String msgNoTasksScheduledPast = 'No tasks were scheduled for this day';
  static const String msgNoTasksScheduled = 'No tasks scheduled for this day';
  static const String msgDoubleTapToAdd = 'Double-tap on the calendar to add tasks';
  
  // Key for storing appointments in SharedPreferences
  static const String prefKeyAppointments = 'calendar_appointments';
  
  /// Load appointments from SharedPreferences
  Future<List<CalendarAppointment>> loadAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? appointmentsJson = prefs.getString(prefKeyAppointments);
      
      if (appointmentsJson != null && appointmentsJson.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(appointmentsJson);
        return decodedList.map((item) => CalendarAppointment.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      return [];
    }
  }
  
  /// Save appointments to SharedPreferences
  Future<bool> saveAppointments(List<CalendarAppointment> appointments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serializedAppointments = 
          appointments.map((appointment) => appointment.toJson()).toList();
      
      await prefs.setString(prefKeyAppointments, jsonEncode(serializedAppointments));
      return true;
    } catch (e) {
      debugPrint('Error saving appointments: $e');
      return false;
    }
  }
  
  /// Mark an appointment as completed
  CalendarAppointment markAppointmentAsCompleted(CalendarAppointment appointment) {
    return CalendarAppointment(
      subject: appointment.subject,
      startTime: appointment.startTime,
      endTime: appointment.endTime,
      color: appointment.color,
      notes: appointment.notes,
      isAllDay: appointment.isAllDay,
      isCompleted: true,
    );
  }
  
  /// Mark an appointment as incomplete
  CalendarAppointment markAppointmentAsIncomplete(CalendarAppointment appointment) {
    return CalendarAppointment(
      subject: appointment.subject,
      startTime: appointment.startTime,
      endTime: appointment.endTime,
      color: appointment.color,
      notes: appointment.notes,
      isAllDay: appointment.isAllDay,
      isCompleted: false,
    );
  }
  
  /// Get appointments for a specific date
  List<CalendarAppointment> getAppointmentsForDate(
    List<CalendarAppointment> allAppointments, 
    DateTime selectedDate
  ) {
    final selectedDateNoTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    
    return allAppointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.startTime.year,
        appointment.startTime.month,
        appointment.startTime.day,
      );
      
      return appointmentDate.isAtSameMomentAs(selectedDateNoTime);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  /// Get a descriptive title for the selected date
  String getDateTitle(DateTime selectedDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    
    final selectedDateNoTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    
    if (selectedDateNoTime.isAtSameMomentAs(today)) {
      return 'TODAY';
    } else if (selectedDateNoTime.isAtSameMomentAs(tomorrow)) {
      return 'TOMORROW';
    } else if (selectedDateNoTime.isAtSameMomentAs(yesterday)) {
      return 'YESTERDAY';
    } else {
      // Check if it's within the current week
      final difference = selectedDateNoTime.difference(today).inDays;
      if (difference > 0 && difference < 7) {
        return 'IN ${difference} DAYS';
      } else if (difference < 0 && difference > -7) {
        return '${-difference} DAYS AGO';
      } else {
        return 'DATE';  // Will be formatted in the actual UI
      }
    }
  }
  
  /// Split appointments into different categories based on current time
  Map<String, List<CalendarAppointment>> categorizeAppointments(
    List<CalendarAppointment> appointments,
    DateTime currentTime,
    bool isToday
  ) {
    final completedTasks = appointments.where(
      (task) => task.isCompleted
    ).toList();
    
    final pendingTasks = appointments.where(
      (task) => isToday && task.endTime.isBefore(currentTime) && !task.isCompleted
    ).toList();
    
    final currentTasks = appointments.where(
      (task) => isToday && 
                !task.endTime.isBefore(currentTime) && 
                !task.startTime.isAfter(currentTime) &&
                !task.isCompleted
    ).toList();
    
    final upcomingTasks = appointments.where(
      (task) => (isToday && task.startTime.isAfter(currentTime) && !task.isCompleted) ||
                (!isToday && !task.isCompleted)
    ).toList();
    
    return {
      'completed': completedTasks,
      'pending': pendingTasks,
      'current': currentTasks,
      'upcoming': upcomingTasks,
    };
  }
}