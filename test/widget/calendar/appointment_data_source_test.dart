import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';
import 'package:tooodooo_app/calendar/appointment_data_source.dart';

void main() {
  group('AppointmentDataSource', () {
    late List<CalendarAppointment> appointments;
    late AppointmentDataSource dataSource;

    setUp(() {
      appointments = [
        CalendarAppointment(
          id: 'open-1',
          subject: 'Open Task',
          startTime: DateTime(2026, 9, 8, 10, 0),
          endTime: DateTime(2026, 9, 8, 11, 0),
          color: Colors.blue,
          isCompleted: false,
          notes: 'Some notes',
        ),
        CalendarAppointment(
          id: 'done-1',
          subject: 'Completed Task',
          startTime: DateTime(2026, 9, 8, 14, 0),
          endTime: DateTime(2026, 9, 8, 15, 0),
          color: Colors.red,
          isCompleted: true,
        ),
        CalendarAppointment(
          id: 'allday-1',
          subject: 'All Day Event',
          startTime: DateTime(2026, 9, 8),
          endTime: DateTime(2026, 9, 9),
          color: Colors.green,
          isAllDay: true,
          isCompleted: false,
        ),
      ];
      dataSource = AppointmentDataSource(appointments);
    });

    group('getColor', () {
      test('returns original color for open task', () {
        final color = dataSource.getColor(0);
        expect(color, Colors.blue);
      });

      test('returns grey-mixed color for completed task', () {
        final color = dataSource.getColor(1);
        // The color should be different from the original (mixed with grey)
        expect(color, isNot(Colors.red));
        // It should be a valid color
        expect(color, isA<Color>());
      });
    });

    group('getSubject', () {
      test('returns plain subject for open task', () {
        final subject = dataSource.getSubject(0);
        expect(subject, 'Open Task');
      });

      test('adds checkmark prefix for completed task', () {
        final subject = dataSource.getSubject(1);
        expect(subject, '✓ Completed Task');
      });
    });

    group('getStartTime', () {
      test('returns correct start time', () {
        expect(dataSource.getStartTime(0), DateTime(2026, 9, 8, 10, 0));
        expect(dataSource.getStartTime(1), DateTime(2026, 9, 8, 14, 0));
      });
    });

    group('getEndTime', () {
      test('returns correct end time', () {
        expect(dataSource.getEndTime(0), DateTime(2026, 9, 8, 11, 0));
        expect(dataSource.getEndTime(1), DateTime(2026, 9, 8, 15, 0));
      });
    });

    group('isAllDay', () {
      test('returns false for regular appointment', () {
        expect(dataSource.isAllDay(0), false);
      });

      test('returns true for all-day appointment', () {
        expect(dataSource.isAllDay(2), true);
      });
    });

    group('getNotes', () {
      test('returns notes when present', () {
        expect(dataSource.getNotes(0), 'Some notes');
      });

      test('returns null when no notes', () {
        expect(dataSource.getNotes(1), isNull);
      });
    });

    group('getRecurrenceRule', () {
      test('returns empty string', () {
        expect(dataSource.getRecurrenceRule(0), '');
      });
    });

    group('getTextStyle', () {
      test('returns line-through for completed task', () {
        final style = dataSource.getTextStyle(1);
        expect(style.decoration, TextDecoration.lineThrough);
      });

      test('returns bold without line-through for open task', () {
        final style = dataSource.getTextStyle(0);
        expect(style.fontWeight, FontWeight.bold);
        expect(style.decoration, isNull);
      });
    });
  });
}
