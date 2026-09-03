import 'package:tooodooo_app/calendar/calendar_appointment.dart';
import 'package:tooodooo_app/calendar/appointment_service.dart';

/// Sections for task categorization
enum TaskSection { happeningNow, pending, upcoming, scheduled, completed }

extension TaskSectionLabel on TaskSection {
  String get label => switch (this) {
        TaskSection.happeningNow => TodayTasksService.sectionHappeningNow,
        TaskSection.pending => TodayTasksService.sectionPending,
        TaskSection.upcoming => TodayTasksService.sectionUpcoming,
        TaskSection.scheduled => TodayTasksService.sectionScheduled,
        TaskSection.completed => TodayTasksService.sectionCompleted,
      };
}

/// Service for managing today's tasks (appointments) classification & helper text
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
  
  // Key for storing appointments in SharedPreferences (legacy usage)
  static const String prefKeyAppointments = 'calendar_appointments';

  final AppointmentService _appointmentService = AppointmentService();

  /// Load appointments (delegates to AppointmentService)
  Future<List<CalendarAppointment>> loadAppointments() => _appointmentService.loadAppointments();

  /// Save appointments (delegates to AppointmentService)
  Future<bool> saveAppointments(List<CalendarAppointment> appointments) => _appointmentService.saveAppointments(appointments);

  /// Remove appointment (delegates to AppointmentService)
  Future<List<CalendarAppointment>> removeAppointment(List<CalendarAppointment> currentAppointments, CalendarAppointment appointment) => _appointmentService.removeAppointment(currentAppointments, appointment);

  /// Update appointment (delegates to AppointmentService)
  Future<List<CalendarAppointment>> updateAppointment(List<CalendarAppointment> currentAppointments, CalendarAppointment oldAppointment, CalendarAppointment newAppointment) => _appointmentService.updateAppointment(currentAppointments, oldAppointment, newAppointment);

  /// Get appointments for a specific date
  List<CalendarAppointment> getAppointmentsForDate(
    List<CalendarAppointment> allAppointments, 
    DateTime selectedDate
  ) {
    final selectedDateNoTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
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
    final selectedDateNoTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    if (selectedDateNoTime.isAtSameMomentAs(today)) return 'TODAY';
    if (selectedDateNoTime.isAtSameMomentAs(tomorrow)) return 'TOMORROW';
    if (selectedDateNoTime.isAtSameMomentAs(yesterday)) return 'YESTERDAY';
    final difference = selectedDateNoTime.difference(today).inDays;
    if (difference > 0 && difference < 7) return 'IN $difference DAYS';
    if (difference < 0 && difference > -7) return '${-difference} DAYS AGO';
    return 'DATE';
  }
  
  /// Split appointments into different categories based on current time
  Map<TaskSection, List<CalendarAppointment>> categorizeAppointments(
    List<CalendarAppointment> appointments,
    DateTime currentTime,
    bool isToday,
  ) {
    final completed = <CalendarAppointment>[];
    final pending = <CalendarAppointment>[]; // past but not completed (today only)
    final happeningNow = <CalendarAppointment>[]; // overlapping now (today only)
    final upcomingOrScheduled = <CalendarAppointment>[]; // future today OR any not-today incomplete

    for (final task in appointments) {
      if (task.isCompleted) {
        completed.add(task);
        continue;
      }
      if (isToday) {
        if (task.endTime.isBefore(currentTime)) {
          pending.add(task);
        } else if (!task.startTime.isAfter(currentTime) && !task.endTime.isBefore(currentTime)) {
          happeningNow.add(task);
        } else if (task.startTime.isAfter(currentTime)) {
          upcomingOrScheduled.add(task);
        }
      } else {
        // For non-today date, treat all incomplete as scheduled
        upcomingOrScheduled.add(task);
      }
    }

    return {
      TaskSection.completed: completed,
      TaskSection.pending: pending,
      TaskSection.happeningNow: happeningNow,
      // Distinguish upcoming vs scheduled by isToday flag when consumed
      (isToday ? TaskSection.upcoming : TaskSection.scheduled): upcomingOrScheduled,
    };
  }
}