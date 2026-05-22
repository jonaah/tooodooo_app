import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';

/// Angepasster DataSource für das SfCalendar Widget
class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<CalendarAppointment> appointments) {
    this.appointments = appointments;
  }
  
  @override
  Color getColor(int index) {
    final CalendarAppointment appointment = appointments![index] as CalendarAppointment;
    // Gräuliche Version der originalen Farbe für erledigte Aufgaben anzeigen
    if (appointment.isCompleted) {
      // Mische die Originalfarbe mit Grau
      return Color.lerp(appointment.color, Colors.grey[400]!, 0.7)!;
    }
    return appointment.color;
  }
  
  @override
  String getSubject(int index) {
    final CalendarAppointment appointment = appointments![index] as CalendarAppointment;
    // Füge Häkchen hinzu für erledigte Aufgaben
    if (appointment.isCompleted) {
      return '✓ ${appointment.subject}';
    }
    return appointment.subject;
  }
  
  @override
  DateTime getStartTime(int index) {
    final CalendarAppointment appointment = appointments![index] as CalendarAppointment;
    return appointment.startTime;
  }
  
  @override
  DateTime getEndTime(int index) {
    final CalendarAppointment appointment = appointments![index] as CalendarAppointment;
    return appointment.endTime;
  }
  
  @override
  bool isAllDay(int index) {
    final CalendarAppointment appointment = appointments![index] as CalendarAppointment;
    return appointment.isAllDay;
  }
  
  @override
  String? getNotes(int index) {
    final CalendarAppointment appointment = appointments![index] as CalendarAppointment;
    return appointment.notes;
  }
  
  @override
  String getRecurrenceRule(int index) {
    return '';
  }
  
  @override
  Object? convertAppointmentToObject(Object? appointment, dynamic object) {
    return object;
  }
  

  TextStyle getTextStyle(int index) {
    final CalendarAppointment appointment = appointments![index] as CalendarAppointment;
    // Durchgestrichener Text für erledigte Aufgaben
    if (appointment.isCompleted) {
      return TextStyle(
        decoration: TextDecoration.lineThrough,
        color: Colors.white.withOpacity(1),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );
    }
    return const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
  }
  
  Widget buildAppointmentWidget(
      BuildContext context, CalendarAppointmentDetails details) {
    final CalendarAppointment appointment = details.appointments.first as CalendarAppointment;
    final int appointmentIndex = appointments!.indexOf(appointment);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Tap wird durch onTap des Kalenders behandelt
        },
        borderRadius: BorderRadius.circular(4),
        highlightColor: Colors.white.withOpacity(0.2),
        splashColor: Colors.white.withOpacity(0.3),
        child: Ink(
          decoration: BoxDecoration(
            color: getColor(appointmentIndex),
            borderRadius: BorderRadius.circular(4),
            border: appointment.isCompleted
                ? Border.all(color: Colors.grey.shade600, width: 1)
                : null,
            boxShadow: appointment.isCompleted
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getSubject(appointmentIndex),
                  style: getTextStyle(appointmentIndex),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      appointment.isCompleted ? Icons.check_circle_outline : Icons.access_time,
                      size: 10,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${DateFormat('HH:mm').format(appointment.startTime)} - ${DateFormat('HH:mm').format(appointment.endTime)}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}