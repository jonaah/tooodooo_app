import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:tooodooo_app/calendar/appointment_data_source.dart';
import 'package:tooodooo_app/calendar/appointment_service.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';
import 'package:tooodooo_app/calendar/calendar_zoom_controller.dart';
import 'package:tooodooo_app/pages/home_page.dart';
import 'package:tooodooo_app/util/app_theme.dart';
import 'package:tooodooo_app/util/todo_selection_dialog.dart';

class CalendarPage extends StatefulWidget {
  final List<Task>? tasks;
  final Function(String)? onAppointmentsChanged;

  const CalendarPage({
    Key? key, 
    this.tasks,
    this.onAppointmentsChanged,
  }) : super(key: key);

  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> with WidgetsBindingObserver {
  late CalendarController _calendarController;
  DateTime _selectedDate = DateTime.now();

  // Service für die Datenpersistenz
  final AppointmentService _appointmentService = AppointmentService();
  
  // Controller für die Zoom-Funktionalität
  final CalendarZoomController _zoomController = CalendarZoomController();

  // Liste der Termine im Kalender
  final List<CalendarAppointment> _appointments = [];

  // Tracking für Doppeltipp-Erkennung
  DateTime? _lastTapTime;
  DateTime? _lastTapPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _calendarController = CalendarController();
    _calendarController.view = CalendarView.week;
    _loadAppointments();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _calendarController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAppointments();
    }
  }

  /// Lädt alle gespeicherten Termine
  Future<void> _loadAppointments() async {
    final appointments = await _appointmentService.loadAppointments();
    setState(() {
      _appointments.clear();
      _appointments.addAll(appointments);
    });
  }
  
  /// Speichert Termine und benachrichtigt andere Komponenten über Änderungen
  Future<void> _saveAppointmentsAndNotify() async {
    await _appointmentService.saveAppointments(_appointments);
    
    // Benachrichtige andere Komponenten über die Änderung
    if (widget.onAppointmentsChanged != null) {
      widget.onAppointmentsChanged!('refresh');
    }
  }

  /// Fügt eine Aufgabe dem Kalender hinzu
  void _addTaskToCalendar(Task task, DateTime startTime) {
    // Verwende die Aufgabendauer oder Standarddauer (30 Minuten)
    final Duration taskDuration = task.duration ?? const Duration(minutes: 30);
    final endTime = startTime.add(taskDuration);
    
    // Zeige Nachricht bei Verwendung der Standarddauer
    if (task.duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Standarddauer von 30 Minuten wird verwendet'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      _appointments.add(
        CalendarAppointment(
          subject: task.name,
          startTime: startTime,
          endTime: endTime,
          color: AppTheme.getCalendarTaskColor(task.priority.toInt()),
          notes: task.iconName,
          isAllDay: false,
        ),
      );
    });

    _saveAppointmentsAndNotify();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${task.name} wurde zum Kalender hinzugefügt'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Entfernt einen Termin aus dem Kalender
  void _removeAppointment(CalendarAppointment appointment) {
    setState(() {
      _appointments.remove(appointment);
    });

    _saveAppointmentsAndNotify();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Termin wurde aus dem Kalender entfernt'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Wechselt den Erledigungsstatus eines Termins
  void _toggleAppointmentCompletion(CalendarAppointment appointment) {
    final index = _appointments.indexOf(appointment);
    if (index != -1) {
      setState(() {
        _appointments[index] = appointment.copyWith(
          isCompleted: !appointment.isCompleted
        );
      });
      
      _saveAppointmentsAndNotify();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appointment.isCompleted 
            ? 'Aufgabe wurde als unerledigt markiert'
            : 'Aufgabe wurde als erledigt markiert'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Zeigt die Aufgabenauswahl an, wenn ein Zeitslot doppelt angetippt wird
  void _showTaskSelectionDialog(DateTime selectedDateTime) {
    if (widget.tasks == null || widget.tasks!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine Aufgaben zum Hinzufügen verfügbar'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => TodoSelectionDialog(
        tasks: widget.tasks!,
        selectedDateTime: selectedDateTime,
        onTaskSelected: (task) {
          _addTaskToCalendar(task, selectedDateTime);
        },
      ),
    );
  }

  /// Zeigt Optionen an, wenn ein Termin angetippt wird
  void _showAppointmentOptions(CalendarAppointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: Row(
          children: [
            Checkbox(
              value: appointment.isCompleted,
              onChanged: (value) {
                Navigator.pop(context);
                _toggleAppointmentCompletion(appointment);
              },
              activeColor: AppTheme.accentColor,
              checkColor: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                appointment.subject,
                style: TextStyle(
                  color: AppTheme.textColor, 
                  fontWeight: FontWeight.bold,
                  decoration: appointment.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${appointment.isCompleted ? "Erledigt" : "Nicht erledigt"}',
              style: TextStyle(
                color: appointment.isCompleted ? Colors.green : AppTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start: ${DateFormat('dd.MM.yyyy - HH:mm').format(appointment.startTime)}',
              style: TextStyle(color: AppTheme.textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Ende: ${DateFormat('dd.MM.yyyy - HH:mm').format(appointment.endTime)}',
              style: TextStyle(color: AppTheme.textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Dauer: ${appointment.endTime.difference(appointment.startTime).inHours}h ${appointment.endTime.difference(appointment.startTime).inMinutes % 60}m',
              style: TextStyle(color: AppTheme.textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Entfernen', style: TextStyle(color: Colors.red)),
            onPressed: () {
              _removeAppointment(appointment);
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text(
              appointment.isCompleted ? 'Als unerledigt markieren' : 'Als erledigt markieren', 
              style: TextStyle(color: AppTheme.accentColor)
            ),
            onPressed: () {
              _toggleAppointmentCompletion(appointment);
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text('Schließen', style: TextStyle(color: AppTheme.accentColor)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /// Prüft, ob es sich um einen Doppeltipp handelt
  bool _isDoubleTap(DateTime currentTapTime, DateTime? cellDate) {
    if (_lastTapTime == null || _lastTapPosition == null || cellDate == null) {
      _lastTapTime = currentTapTime;
      _lastTapPosition = cellDate;
      return false;
    }

    // Prüfe, ob die Zeit zwischen Tipps weniger als 300ms beträgt
    // und ob die getippte Position (Datum+Zeit) dieselbe ist
    final bool isDoubleTap = currentTapTime.difference(_lastTapTime!).inMilliseconds < 300 &&
        _isSameTimeSlot(cellDate, _lastTapPosition!);

    // Setze Tracking zurück für die nächste Tippsequenz
    _lastTapTime = null;
    _lastTapPosition = null;

    return isDoubleTap;
  }

  /// Prüft, ob zwei Zeitpunkte im selben Zeitslot liegen
  bool _isSameTimeSlot(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day &&
        date1.hour == date2.hour &&
        (date1.minute ~/ 15) == (date2.minute ~/ 15);
  }
  
  /// Zeigt Hilfe-Informationen an
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: Text('Kalender Hilfe', 
          style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Doppeltippen Sie auf einen Zeitslot, um eine Aufgabe hinzuzufügen',
              style: TextStyle(color: AppTheme.textColor),
            ),
            SizedBox(height: 8),
            Text('• Tippen Sie auf einen Termin, um Details anzuzeigen oder ihn zu entfernen',
              style: TextStyle(color: AppTheme.textColor),
            ),
            SizedBox(height: 8),
            Text('• Aufgaben ohne Dauer erhalten eine Standarddauer von 30 Minuten',
              style: TextStyle(color: AppTheme.textColor),
            ),
            SizedBox(height: 8),
            Text('• Verwenden Sie Pinch-Gesten zum Vergrößern/Verkleinern der Zeitansicht',
              style: TextStyle(color: AppTheme.textColor),
            ),
            SizedBox(height: 8),
            Text('• Zeitintervalle passen sich je nach Zoom-Stufe an (5min bis 1h)',
              style: TextStyle(color: AppTheme.textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Verstanden', style: TextStyle(color: AppTheme.accentColor)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Öffentliche Methode zum Aktualisieren der Termine (aufgerufen vom Navigator)
  void refreshAppointments() {
    _loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('KALENDER', style: AppTheme.appBarTitle),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              // Springe zum heutigen Datum
              _calendarController.displayDate = DateTime.now();
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
            tooltip: 'Kalender aktualisieren',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _buildCalendarWithZoom(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showTaskSelectionDialog(_selectedDate);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add_task, color: AppTheme.textColor),
        tooltip: 'Aufgabe zum Kalender hinzufügen',
      ),
    );
  }
  
  /// Erstellt den Kalender mit Zoom-Funktionalität
  Widget _buildCalendarWithZoom() {
    return GestureDetector(
      onScaleStart: (_) => {},
      onScaleUpdate: (details) {
        setState(() {
          _zoomController.handleScale(details);
        });
      },
      onScaleEnd: (_) => {},
      child: SfCalendar(
        controller: _calendarController,
        view: CalendarView.week,
        firstDayOfWeek: 1, // Montag
        dataSource: AppointmentDataSource(_appointments),
        allowViewNavigation: true,
        showNavigationArrow: true,
        minDate: DateTime.now().subtract(const Duration(days: 365)),
        maxDate: DateTime.now().add(const Duration(days: 365)),
        onTap: _handleCalendarTap,
        timeSlotViewSettings: TimeSlotViewSettings(
          timeFormat: 'HH:mm',
          timeInterval: Duration(minutes: _zoomController.currentMinutesInterval),
          timeIntervalHeight: _zoomController.timeIntervalHeight,
          startHour: 0,
          endHour: 24,
        ),
        headerStyle: CalendarHeaderStyle(
          textStyle: const TextStyle(
            color: AppTheme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: AppTheme.primaryColor.withOpacity(0.7),
        ),
        viewHeaderStyle: const ViewHeaderStyle(
          dayTextStyle: TextStyle(
            color: AppTheme.textColor,
            fontSize: 12,
          ),
          dateTextStyle: TextStyle(
            color: AppTheme.textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        cellBorderColor: Colors.grey.shade700,
        backgroundColor: Colors.black.withOpacity(0.2),
        todayHighlightColor: AppTheme.accentColor,
        selectionDecoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.accentColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius / 3),
        ),
      ),
    );
  }
  
  /// Behandelt Tipp-Ereignisse auf dem Kalender
  void _handleCalendarTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.calendarCell && 
        details.date != null) {
      setState(() {
        _selectedDate = details.date!;
      });

      // Prüfe, ob dies ein Doppeltipp ist
      final now = DateTime.now();
      if (_isDoubleTap(now, details.date)) {
        _showTaskSelectionDialog(details.date!);
      } else {
        // Speichere diesen Tipp für potentielle Doppeltipp-Erkennung
        _lastTapTime = now;
        _lastTapPosition = details.date;
      }
    } else if (details.targetElement == CalendarElement.appointment &&
        details.appointments != null &&
        details.appointments!.isNotEmpty) {
      // Wenn ein Termin angetippt wird, zeige Optionen an
      _showAppointmentOptions(details.appointments!.first as CalendarAppointment);
    }
  }
}
