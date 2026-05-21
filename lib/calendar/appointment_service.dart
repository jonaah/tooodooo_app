import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';
import 'package:tooodooo_app/calendar/google_calendar_client.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;

/// Service zum Laden und Speichern von Kalendereinträgen (Appointments)
class AppointmentService {
  static const String _storageKey = 'calendar_appointments';

  Future<List<CalendarAppointment>> _syncWithGoogle(
    List<CalendarAppointment> localAppointments,
  ) async {
    final api = await GoogleCalendarClient.getCalendarApi();
    if (api == null) return localAppointments;

    try {
      final now = DateTime.now();
      final events = await api.events.list(
        'primary',
        timeMin: now.subtract(const Duration(days: 90)).toUtc(),
        timeMax: now.add(const Duration(days: 365)).toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );
      final googleEvents = events.items ?? [];

      List<CalendarAppointment> updatedLocal = List.from(localAppointments);
      Set<String> activeGoogleEventIds = {};

      for (var event in googleEvents) {
        if (event.status == 'cancelled') {
          if (event.id != null) {
            updatedLocal.removeWhere((a) => a.googleEventId == event.id);
          }
          continue;
        }
        
        if (event.id != null) {
          activeGoogleEventIds.add(event.id!);
        }

        final props = event.extendedProperties?.private ?? {};
        final tooodoooId = props['tooodooo_id'];

        DateTime startTime =
            event.start?.dateTime ?? event.start?.date ?? DateTime.now();
        DateTime endTime =
            event.end?.dateTime ??
            event.end?.date ??
            startTime.add(const Duration(hours: 1));

        final newAppt = CalendarAppointment(
          id: tooodoooId, // Use existing ID if available, otherwise generate new
          googleEventId: event.id,
          subject: event.summary ?? 'No Title',
          startTime: startTime.toLocal(),
          endTime: endTime.toLocal(),
          color:
              props.containsKey('color')
                  ? Color(int.parse(props['color']!))
                  : Colors.blue,
          isCompleted: props['isCompleted'] == 'true',
          priority:
              props.containsKey('priority')
                  ? int.tryParse(props['priority']!)
                  : null,
          customColorValue:
              props.containsKey('customColorValue')
                  ? int.tryParse(props['customColorValue']!)
                  : null,
          notes:
              props.containsKey('notes') ? props['notes'] : event.description,
          isAllDay: event.start?.dateTime == null,
        );

        final index = updatedLocal.indexWhere(
          (a) => a.id == newAppt.id || a.googleEventId == newAppt.googleEventId,
        );
        if (index != -1) {
          updatedLocal[index] = newAppt;
        } else {
          updatedLocal.add(newAppt);
        }
      }
      
      // Cleanup events that were synced before but are missing from Google now
      updatedLocal.removeWhere((a) => 
        a.googleEventId != null && !activeGoogleEventIds.contains(a.googleEventId)
      );
      
      return updatedLocal;
    } catch (e) {
      debugPrint('Error syncing with Google: $e');
      return localAppointments;
    }
  }

  google_calendar.Event _toGoogleEvent(CalendarAppointment appointment) {
    return google_calendar.Event(
      summary: appointment.subject,
      description: appointment.notes,
      start:
          appointment.isAllDay
              ? google_calendar.EventDateTime(date: appointment.startTime)
              : google_calendar.EventDateTime(dateTime: appointment.startTime),
      end:
          appointment.isAllDay
              ? google_calendar.EventDateTime(date: appointment.endTime)
              : google_calendar.EventDateTime(dateTime: appointment.endTime),
      extendedProperties: google_calendar.EventExtendedProperties(
        private: appointment.toGoogleExtendedProperties(),
      ),
    );
  }

  /// Lädt alle gespeicherten Termine aus SharedPreferences
  Future<List<CalendarAppointment>> loadAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? appointmentsJson = prefs.getString(_storageKey);

      if (appointmentsJson != null && appointmentsJson.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(appointmentsJson);
        List<CalendarAppointment> loaded =
            decodedList
                .map((item) => CalendarAppointment.fromJson(item))
                .toList();

        // Trigger sync in background or await it
        loaded = await _syncWithGoogle(loaded);
        await saveAppointments(loaded); // Save synced results

        return loaded;
      }

      // If none local, still try sync
      List<CalendarAppointment> synced = await _syncWithGoogle([]);
      if (synced.isNotEmpty) {
        await saveAppointments(synced);
      }
      return synced;
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      return [];
    }
  }

  /// Speichert die übergebene Liste von Terminen in SharedPreferences
  Future<bool> saveAppointments(List<CalendarAppointment> appointments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serializedAppointments =
          appointments.map((appointment) => appointment.toJson()).toList();

      await prefs.setString(_storageKey, jsonEncode(serializedAppointments));
      return true;
    } catch (e) {
      debugPrint('Error saving appointments: $e');
      return false;
    }
  }

  /// Fügt einen neuen Termin zur Liste hinzu und speichert die aktualisierte Liste
  Future<List<CalendarAppointment>> addAppointment(
    List<CalendarAppointment> currentAppointments,
    CalendarAppointment newAppointment,
  ) async {
    CalendarAppointment appointmentToSave = newAppointment;

    final api = await GoogleCalendarClient.getCalendarApi();
    if (api != null) {
      try {
        final event = _toGoogleEvent(newAppointment);
        final createdEvent = await api.events.insert(event, 'primary');
        appointmentToSave = newAppointment.copyWith(
          googleEventId: createdEvent.id,
        );
      } catch (e) {
        debugPrint('Error inserting to Google Calendar: $e');
      }
    }

    final updatedAppointments = List<CalendarAppointment>.from(
      currentAppointments,
    )..add(appointmentToSave);
    await saveAppointments(updatedAppointments);
    return updatedAppointments;
  }

  /// Entfernt einen Termin aus der Liste und speichert die aktualisierte Liste
  Future<List<CalendarAppointment>> removeAppointment(
    List<CalendarAppointment> currentAppointments,
    CalendarAppointment appointment,
  ) async {
    final api = await GoogleCalendarClient.getCalendarApi();
    if (api != null && appointment.googleEventId != null) {
      try {
        await api.events.delete('primary', appointment.googleEventId!);
      } catch (e) {
        debugPrint('Error deleting from Google Calendar: $e');
      }
    }

    final updatedAppointments = List<CalendarAppointment>.from(
      currentAppointments,
    )..remove(appointment);
    await saveAppointments(updatedAppointments);
    return updatedAppointments;
  }

  /// Aktualisiert einen vorhandenen Termin und speichert die aktualisierte Liste
  Future<List<CalendarAppointment>> updateAppointment(
    List<CalendarAppointment> currentAppointments,
    CalendarAppointment oldAppointment,
    CalendarAppointment newAppointment,
  ) async {
    final index = currentAppointments.indexOf(oldAppointment);
    if (index != -1) {
      CalendarAppointment appointmentToSave = newAppointment;

      final api = await GoogleCalendarClient.getCalendarApi();
      if (api != null && oldAppointment.googleEventId != null) {
        try {
          final event = _toGoogleEvent(newAppointment);
          final updatedEvent = await api.events.update(
            event,
            'primary',
            oldAppointment.googleEventId!,
          );
          appointmentToSave = newAppointment.copyWith(
            googleEventId: updatedEvent.id,
          );
        } catch (e) {
          debugPrint('Error updating Google Calendar: $e');
        }
      } else if (api != null && oldAppointment.googleEventId == null) {
        // Fallback: If it wasn't synced before, insert it now
        try {
          final event = _toGoogleEvent(newAppointment);
          final createdEvent = await api.events.insert(event, 'primary');
          appointmentToSave = newAppointment.copyWith(
            googleEventId: createdEvent.id,
          );
        } catch (e) {
          debugPrint('Error inserting to Google Calendar during update: $e');
        }
      }

      final updatedAppointments = List<CalendarAppointment>.from(
        currentAppointments,
      );
      updatedAppointments[index] = appointmentToSave;
      await saveAppointments(updatedAppointments);
      return updatedAppointments;
    }
    return currentAppointments;
  }

  /// Aktualisiert den Completion-Status eines vorhandenen Termins
  Future<List<CalendarAppointment>> toggleAppointmentCompletion(
    List<CalendarAppointment> currentAppointments,
    CalendarAppointment appointment,
  ) async {
    final index = currentAppointments.indexOf(appointment);
    if (index != -1) {
      final updatedAppt = appointment.copyWith(
        isCompleted: !appointment.isCompleted,
      );

      return updateAppointment(currentAppointments, appointment, updatedAppt);
    }
    return currentAppointments;
  }
}
