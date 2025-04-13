import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';

/// Service zum Laden und Speichern von Kalendereinträgen (Appointments)
class AppointmentService {
  static const String _storageKey = 'calendar_appointments';
  
  /// Lädt alle gespeicherten Termine aus SharedPreferences
  Future<List<CalendarAppointment>> loadAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? appointmentsJson = prefs.getString(_storageKey);

      if (appointmentsJson != null && appointmentsJson.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(appointmentsJson);
        return decodedList
            .map((item) => CalendarAppointment.fromJson(item))
            .toList();
      }
      return [];
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
  Future<bool> addAppointment(
    List<CalendarAppointment> currentAppointments, 
    CalendarAppointment newAppointment
  ) async {
    final updatedAppointments = List<CalendarAppointment>.from(currentAppointments)
      ..add(newAppointment);
    return saveAppointments(updatedAppointments);
  }
  
  /// Entfernt einen Termin aus der Liste und speichert die aktualisierte Liste
  Future<bool> removeAppointment(
    List<CalendarAppointment> currentAppointments, 
    CalendarAppointment appointment
  ) async {
    final updatedAppointments = List<CalendarAppointment>.from(currentAppointments)
      ..remove(appointment);
    return saveAppointments(updatedAppointments);
  }
  
  /// Aktualisiert einen vorhandenen Termin und speichert die aktualisierte Liste
  Future<bool> updateAppointment(
    List<CalendarAppointment> currentAppointments, 
    CalendarAppointment oldAppointment,
    CalendarAppointment newAppointment
  ) async {
    final index = currentAppointments.indexOf(oldAppointment);
    if (index != -1) {
      final updatedAppointments = List<CalendarAppointment>.from(currentAppointments);
      updatedAppointments[index] = newAppointment;
      return saveAppointments(updatedAppointments);
    }
    return false;
  }
  
  /// Aktualisiert den Completion-Status eines vorhandenen Termins
  Future<bool> toggleAppointmentCompletion(
    List<CalendarAppointment> currentAppointments, 
    CalendarAppointment appointment
  ) async {
    final index = currentAppointments.indexOf(appointment);
    if (index != -1) {
      final updatedAppointments = List<CalendarAppointment>.from(currentAppointments);
      updatedAppointments[index] = appointment.copyWith(
        isCompleted: !appointment.isCompleted
      );
      return saveAppointments(updatedAppointments);
    }
    return false;
  }
}