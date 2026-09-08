import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';
import 'package:tooodooo_app/today/today_tasks_service.dart';

void main() {
  late TodayTasksService service;

  setUp(() {
    service = TodayTasksService();
  });

  CalendarAppointment _makeAppointment({
    required String subject,
    required DateTime startTime,
    required DateTime endTime,
    bool isCompleted = false,
  }) {
    return CalendarAppointment(
      id: '${subject.hashCode}',
      subject: subject,
      startTime: startTime,
      endTime: endTime,
      color: Colors.blue,
      isCompleted: isCompleted,
    );
  }

  group('getDateTitle', () {
    test('returns TODAY for today', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(service.getDateTitle(today), 'TODAY');
    });

    test('returns TOMORROW for tomorrow', () {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      expect(service.getDateTitle(tomorrow), 'TOMORROW');
    });

    test('returns YESTERDAY for yesterday', () {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      expect(service.getDateTitle(yesterday), 'YESTERDAY');
    });

    test('returns IN X DAYS for 2-6 days in the future', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      expect(service.getDateTitle(today.add(const Duration(days: 3))), 'IN 3 DAYS');
      expect(service.getDateTitle(today.add(const Duration(days: 6))), 'IN 6 DAYS');
    });

    test('returns X DAYS AGO for 2-6 days in the past', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      expect(service.getDateTitle(today.subtract(const Duration(days: 2))), '2 DAYS AGO');
      expect(service.getDateTitle(today.subtract(const Duration(days: 5))), '5 DAYS AGO');
    });

    test('returns DATE for dates more than 7 days away', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      expect(service.getDateTitle(today.add(const Duration(days: 30))), 'DATE');
      expect(service.getDateTitle(today.subtract(const Duration(days: 30))), 'DATE');
    });
  });

  group('getAppointmentsForDate', () {
    test('filters appointments by date', () {
      final appointments = [
        _makeAppointment(
          subject: 'Today Task',
          startTime: DateTime(2026, 9, 8, 10, 0),
          endTime: DateTime(2026, 9, 8, 11, 0),
        ),
        _makeAppointment(
          subject: 'Tomorrow Task',
          startTime: DateTime(2026, 9, 9, 10, 0),
          endTime: DateTime(2026, 9, 9, 11, 0),
        ),
        _makeAppointment(
          subject: 'Today Task 2',
          startTime: DateTime(2026, 9, 8, 14, 0),
          endTime: DateTime(2026, 9, 8, 15, 0),
        ),
      ];

      final result = service.getAppointmentsForDate(appointments, DateTime(2026, 9, 8));
      expect(result.length, 2);
      expect(result[0].subject, 'Today Task');
      expect(result[1].subject, 'Today Task 2');
    });

    test('sorts by start time', () {
      final appointments = [
        _makeAppointment(
          subject: 'Later',
          startTime: DateTime(2026, 9, 8, 15, 0),
          endTime: DateTime(2026, 9, 8, 16, 0),
        ),
        _makeAppointment(
          subject: 'Earlier',
          startTime: DateTime(2026, 9, 8, 9, 0),
          endTime: DateTime(2026, 9, 8, 10, 0),
        ),
      ];

      final result = service.getAppointmentsForDate(appointments, DateTime(2026, 9, 8));
      expect(result[0].subject, 'Earlier');
      expect(result[1].subject, 'Later');
    });

    test('returns empty list when no appointments match', () {
      final appointments = [
        _makeAppointment(
          subject: 'Other Day',
          startTime: DateTime(2026, 9, 10, 10, 0),
          endTime: DateTime(2026, 9, 10, 11, 0),
        ),
      ];

      final result = service.getAppointmentsForDate(appointments, DateTime(2026, 9, 8));
      expect(result, isEmpty);
    });

    test('ignores time component when comparing dates', () {
      final appointments = [
        _makeAppointment(
          subject: 'Night Task',
          startTime: DateTime(2026, 9, 8, 23, 59),
          endTime: DateTime(2026, 9, 9, 0, 30),
        ),
      ];

      // Should match by start date
      final result = service.getAppointmentsForDate(appointments, DateTime(2026, 9, 8, 5, 0));
      expect(result.length, 1);
    });
  });

  group('categorizeAppointments', () {
    group('for today (isToday=true)', () {
      test('categorizes completed tasks', () {
        final now = DateTime(2026, 9, 8, 12, 0);
        final appointments = [
          _makeAppointment(
            subject: 'Done Task',
            startTime: DateTime(2026, 9, 8, 10, 0),
            endTime: DateTime(2026, 9, 8, 11, 0),
            isCompleted: true,
          ),
        ];

        final result = service.categorizeAppointments(appointments, now, true);
        expect(result[TaskSection.completed]?.length, 1);
        expect(result[TaskSection.completed]?[0].subject, 'Done Task');
      });

      test('categorizes past incomplete tasks as pending', () {
        final now = DateTime(2026, 9, 8, 12, 0);
        final appointments = [
          _makeAppointment(
            subject: 'Missed Task',
            startTime: DateTime(2026, 9, 8, 9, 0),
            endTime: DateTime(2026, 9, 8, 10, 0),
            isCompleted: false,
          ),
        ];

        final result = service.categorizeAppointments(appointments, now, true);
        expect(result[TaskSection.pending]?.length, 1);
        expect(result[TaskSection.pending]?[0].subject, 'Missed Task');
      });

      test('categorizes currently running tasks as happeningNow', () {
        final now = DateTime(2026, 9, 8, 10, 30);
        final appointments = [
          _makeAppointment(
            subject: 'Current Task',
            startTime: DateTime(2026, 9, 8, 10, 0),
            endTime: DateTime(2026, 9, 8, 11, 0),
            isCompleted: false,
          ),
        ];

        final result = service.categorizeAppointments(appointments, now, true);
        expect(result[TaskSection.happeningNow]?.length, 1);
        expect(result[TaskSection.happeningNow]?[0].subject, 'Current Task');
      });

      test('categorizes future tasks as upcoming', () {
        final now = DateTime(2026, 9, 8, 10, 0);
        final appointments = [
          _makeAppointment(
            subject: 'Future Task',
            startTime: DateTime(2026, 9, 8, 14, 0),
            endTime: DateTime(2026, 9, 8, 15, 0),
            isCompleted: false,
          ),
        ];

        final result = service.categorizeAppointments(appointments, now, true);
        expect(result[TaskSection.upcoming]?.length, 1);
        expect(result[TaskSection.upcoming]?[0].subject, 'Future Task');
      });

      test('categorizes mixed tasks correctly', () {
        final now = DateTime(2026, 9, 8, 12, 0);
        final appointments = [
          _makeAppointment(
            subject: 'Completed',
            startTime: DateTime(2026, 9, 8, 8, 0),
            endTime: DateTime(2026, 9, 8, 9, 0),
            isCompleted: true,
          ),
          _makeAppointment(
            subject: 'Pending',
            startTime: DateTime(2026, 9, 8, 10, 0),
            endTime: DateTime(2026, 9, 8, 11, 0),
            isCompleted: false,
          ),
          _makeAppointment(
            subject: 'Happening Now',
            startTime: DateTime(2026, 9, 8, 11, 30),
            endTime: DateTime(2026, 9, 8, 12, 30),
            isCompleted: false,
          ),
          _makeAppointment(
            subject: 'Upcoming',
            startTime: DateTime(2026, 9, 8, 15, 0),
            endTime: DateTime(2026, 9, 8, 16, 0),
            isCompleted: false,
          ),
        ];

        final result = service.categorizeAppointments(appointments, now, true);
        expect(result[TaskSection.completed]?.length, 1);
        expect(result[TaskSection.pending]?.length, 1);
        expect(result[TaskSection.happeningNow]?.length, 1);
        expect(result[TaskSection.upcoming]?.length, 1);
      });

      test('task exactly at startTime is happeningNow', () {
        final now = DateTime(2026, 9, 8, 10, 0);
        final appointments = [
          _makeAppointment(
            subject: 'Just Started',
            startTime: DateTime(2026, 9, 8, 10, 0),
            endTime: DateTime(2026, 9, 8, 11, 0),
            isCompleted: false,
          ),
        ];

        final result = service.categorizeAppointments(appointments, now, true);
        expect(result[TaskSection.happeningNow]?.length, 1);
      });
    });

    group('for another day (isToday=false)', () {
      test('categorizes all incomplete tasks as scheduled', () {
        final now = DateTime(2026, 9, 8, 12, 0);
        final appointments = [
          _makeAppointment(
            subject: 'Future Task 1',
            startTime: DateTime(2026, 9, 10, 10, 0),
            endTime: DateTime(2026, 9, 10, 11, 0),
            isCompleted: false,
          ),
          _makeAppointment(
            subject: 'Future Task 2',
            startTime: DateTime(2026, 9, 10, 14, 0),
            endTime: DateTime(2026, 9, 10, 15, 0),
            isCompleted: false,
          ),
        ];

        final result = service.categorizeAppointments(appointments, now, false);
        expect(result[TaskSection.scheduled]?.length, 2);
        expect(result[TaskSection.pending], isEmpty);
        expect(result[TaskSection.happeningNow], isEmpty);
      });

      test('categorizes completed tasks normally', () {
        final now = DateTime(2026, 9, 8, 12, 0);
        final appointments = [
          _makeAppointment(
            subject: 'Done Yesterday',
            startTime: DateTime(2026, 9, 7, 10, 0),
            endTime: DateTime(2026, 9, 7, 11, 0),
            isCompleted: true,
          ),
        ];

        final result = service.categorizeAppointments(appointments, now, false);
        expect(result[TaskSection.completed]?.length, 1);
      });
    });
  });

  group('TaskSection labels', () {
    test('all sections have correct labels', () {
      expect(TaskSection.happeningNow.label, TodayTasksService.sectionHappeningNow);
      expect(TaskSection.pending.label, TodayTasksService.sectionPending);
      expect(TaskSection.upcoming.label, TodayTasksService.sectionUpcoming);
      expect(TaskSection.scheduled.label, TodayTasksService.sectionScheduled);
      expect(TaskSection.completed.label, TodayTasksService.sectionCompleted);
    });
  });
}
