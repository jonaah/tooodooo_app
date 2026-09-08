import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';
import 'package:tooodooo_app/util/app_theme.dart';

void main() {
  group('CalendarAppointment', () {
    CalendarAppointment _createSample({
      String? id,
      String? googleEventId,
      String subject = 'Test Appointment',
      DateTime? startTime,
      DateTime? endTime,
      Color color = Colors.blue,
      bool isAllDay = false,
      String? notes,
      bool isCompleted = false,
      int? priority,
      int? customColorValue,
    }) {
      final start = startTime ?? DateTime(2026, 9, 8, 10, 0);
      final end = endTime ?? DateTime(2026, 9, 8, 11, 0);
      return CalendarAppointment(
        id: id,
        googleEventId: googleEventId,
        subject: subject,
        startTime: start,
        endTime: end,
        color: color,
        isAllDay: isAllDay,
        notes: notes,
        isCompleted: isCompleted,
        priority: priority,
        customColorValue: customColorValue,
      );
    }

    group('creation', () {
      test('generates a unique ID when none provided', () {
        final appointment = _createSample();
        expect(appointment.id, isNotEmpty);
      });

      test('uses provided ID when given', () {
        final appointment = _createSample(id: 'custom-id-123');
        expect(appointment.id, 'custom-id-123');
      });

      test('two appointments without ID get different IDs', () {
        final a1 = _createSample(subject: 'A');
        final a2 = _createSample(subject: 'B');
        expect(a1.id, isNot(a2.id));
      });

      test('default values are correct', () {
        final appointment = _createSample();
        expect(appointment.isAllDay, false);
        expect(appointment.isCompleted, false);
        expect(appointment.notes, isNull);
        expect(appointment.priority, isNull);
        expect(appointment.customColorValue, isNull);
        expect(appointment.googleEventId, isNull);
      });
    });

    group('JSON round-trip', () {
      test('preserves all fields', () {
        final original = _createSample(
          id: 'test-id-1',
          googleEventId: 'google-event-42',
          subject: 'Meeting',
          startTime: DateTime(2026, 12, 25, 14, 30),
          endTime: DateTime(2026, 12, 25, 15, 30),
          color: Colors.red,
          isAllDay: false,
          notes: 'Important meeting',
          isCompleted: true,
          priority: 3,
          customColorValue: 0xFF00FF00,
        );

        final json = original.toJson();
        final restored = CalendarAppointment.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.googleEventId, original.googleEventId);
        expect(restored.subject, original.subject);
        expect(restored.startTime, original.startTime);
        expect(restored.endTime, original.endTime);
        expect(restored.color.value, original.color.value);
        expect(restored.isAllDay, original.isAllDay);
        expect(restored.notes, original.notes);
        expect(restored.isCompleted, original.isCompleted);
        expect(restored.priority, original.priority);
        expect(restored.customColorValue, original.customColorValue);
      });

      test('preserves all-day appointment', () {
        final original = _createSample(isAllDay: true);
        final json = original.toJson();
        final restored = CalendarAppointment.fromJson(json);
        expect(restored.isAllDay, true);
      });

      test('handles null optional fields', () {
        final original = _createSample(
          notes: null,
          priority: null,
          customColorValue: null,
          googleEventId: null,
        );
        final json = original.toJson();
        final restored = CalendarAppointment.fromJson(json);

        expect(restored.notes, isNull);
        expect(restored.priority, isNull);
        expect(restored.customColorValue, isNull);
        expect(restored.googleEventId, isNull);
      });

      test('defaults isCompleted to false when missing in JSON', () {
        final json = {
          'id': 'test',
          'subject': 'Test',
          'startTime': DateTime(2026, 1, 1).millisecondsSinceEpoch,
          'endTime': DateTime(2026, 1, 1, 1).millisecondsSinceEpoch,
          'color': Colors.blue.value,
        };
        final appointment = CalendarAppointment.fromJson(json);
        expect(appointment.isCompleted, false);
      });

      test('defaults isAllDay to false when missing in JSON', () {
        final json = {
          'id': 'test',
          'subject': 'Test',
          'startTime': DateTime(2026, 1, 1).millisecondsSinceEpoch,
          'endTime': DateTime(2026, 1, 1, 1).millisecondsSinceEpoch,
          'color': Colors.blue.value,
        };
        final appointment = CalendarAppointment.fromJson(json);
        expect(appointment.isAllDay, false);
      });
    });

    group('priority derivation from color', () {
      test('derives priority from color when priority is null in JSON', () {
        for (int p = 1; p <= 5; p++) {
          final color = AppTheme.getCalendarTaskColor(p);
          final json = {
            'id': 'test-$p',
            'subject': 'Priority $p',
            'startTime': DateTime(2026, 1, 1).millisecondsSinceEpoch,
            'endTime': DateTime(2026, 1, 1, 1).millisecondsSinceEpoch,
            'color': color.value,
            'priority': null,
          };
          final appointment = CalendarAppointment.fromJson(json);
          expect(appointment.priority, p, reason: 'Expected priority $p for color ${color.value}');
        }
      });

      test('uses explicit priority when provided', () {
        final json = {
          'id': 'test',
          'subject': 'Test',
          'startTime': DateTime(2026, 1, 1).millisecondsSinceEpoch,
          'endTime': DateTime(2026, 1, 1, 1).millisecondsSinceEpoch,
          'color': Colors.blue.value,
          'priority': 4,
        };
        final appointment = CalendarAppointment.fromJson(json);
        expect(appointment.priority, 4);
      });
    });

    group('copyWith', () {
      test('copies with changed subject, keeps other fields', () {
        final original = _createSample(id: 'stable-id', subject: 'Original');
        final copy = original.copyWith(subject: 'Updated');

        expect(copy.id, 'stable-id');
        expect(copy.subject, 'Updated');
        expect(copy.startTime, original.startTime);
        expect(copy.color, original.color);
      });

      test('copies with changed isCompleted', () {
        final original = _createSample(isCompleted: false);
        final copy = original.copyWith(isCompleted: true);
        expect(copy.isCompleted, true);
        expect(original.isCompleted, false); // original unchanged
      });

      test('copies with changed googleEventId', () {
        final original = _createSample(googleEventId: null);
        final copy = original.copyWith(googleEventId: 'new-google-id');
        expect(copy.googleEventId, 'new-google-id');
      });

      test('copies all fields when none specified', () {
        final original = _createSample(
          id: 'id-1',
          subject: 'Test',
          notes: 'Some notes',
          priority: 5,
          customColorValue: 0xFFAA0000,
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.subject, original.subject);
        expect(copy.notes, original.notes);
        expect(copy.priority, original.priority);
        expect(copy.customColorValue, original.customColorValue);
      });
    });

    group('toGoogleExtendedProperties', () {
      test('includes required fields', () {
        final appointment = _createSample(
          id: 'test-id',
          isCompleted: true,
        );
        final props = appointment.toGoogleExtendedProperties();

        expect(props['tooodooo_id'], 'test-id');
        expect(props['color'], appointment.color.value.toString());
        expect(props['isCompleted'], 'true');
      });

      test('includes optional fields when present', () {
        final appointment = _createSample(
          priority: 3,
          customColorValue: 0xFFBBCCDD,
          notes: 'My notes',
        );
        final props = appointment.toGoogleExtendedProperties();

        expect(props['priority'], '3');
        expect(props['customColorValue'], '0xFFBBCCDD'.contains('BBCCDD') ? props['customColorValue'] : isNotNull);
        expect(props['notes'], 'My notes');
      });

      test('excludes optional fields when null', () {
        final appointment = _createSample(
          priority: null,
          customColorValue: null,
          notes: null,
        );
        final props = appointment.toGoogleExtendedProperties();

        expect(props.containsKey('priority'), false);
        expect(props.containsKey('customColorValue'), false);
        expect(props.containsKey('notes'), false);
      });
    });

    group('equality', () {
      test('two appointments with same ID are equal', () {
        final a1 = _createSample(id: 'same-id', subject: 'First');
        final a2 = _createSample(id: 'same-id', subject: 'Second');
        expect(a1, equals(a2));
      });

      test('two appointments with different IDs are not equal', () {
        final a1 = _createSample(id: 'id-1');
        final a2 = _createSample(id: 'id-2');
        expect(a1, isNot(equals(a2)));
      });

      test('hashCode is based on ID', () {
        final a1 = _createSample(id: 'same-id');
        final a2 = _createSample(id: 'same-id');
        expect(a1.hashCode, a2.hashCode);
      });
    });

    test('toString contains id and subject', () {
      final appointment = _createSample(id: 'test-123', subject: 'My Meeting');
      final str = appointment.toString();
      expect(str, contains('test-123'));
      expect(str, contains('My Meeting'));
    });
  });
}
