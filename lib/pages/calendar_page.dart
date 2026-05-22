import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:tooodooo_app/calendar/appointment_data_source.dart';
import 'package:tooodooo_app/calendar/appointment_service.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';
import 'package:tooodooo_app/calendar/calendar_zoom_controller.dart';
import 'package:tooodooo_app/calendar/calendar_edit_dialog.dart';
import 'package:tooodooo_app/pages/home_page.dart';
import 'package:tooodooo_app/util/app_theme.dart';
import 'package:tooodooo_app/util/app_icons.dart';
import 'package:tooodooo_app/util/todo_selection_dialog.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;

import '../calendar/google_calendar_client.dart';

class CalendarPage extends StatefulWidget {
  final List<Task>? tasks;
  final Function(String)? onAppointmentsChanged;

  const CalendarPage({super.key, this.tasks, this.onAppointmentsChanged});

  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage>
    with WidgetsBindingObserver {
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

  int _startHour = 0;
  int _endHour = 24;
  Key _calendarKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _calendarController = CalendarController();
    _calendarController.view = CalendarView.week;
    _loadAppointments();
    _loadCalendarSettings();
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
      _loadCalendarSettings();
    }
  }

  Future<void> _loadCalendarSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _startHour = prefs.getInt('calendarStartHour') ?? 0;
    _endHour = prefs.getInt('calendarEndHour') ?? 24;

    final now = DateTime.now();
    // Berechne die Mitte des sichtbaren Intervalls
    final interval = (_endHour - _startHour).toDouble();
    final middleHour = _startHour + interval / 2;
    final displayDate = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour - 2,
      now.minute,
    );

    setState(() {
      // Setze die displayDate so, dass die aktuelle Zeit mittig ist
      _calendarController.displayDate = displayDate;
      _calendarKey = UniqueKey();
    });
  }

  Future<void> _syncWithGoogleCalendar() async {
    try {
      var calendarApi = await GoogleCalendarClient.getCalendarApi();
      if (calendarApi == null) {
        // Versuche den Benutzer anzumelden
        await GoogleCalendarClient.signIn();
        calendarApi = await GoogleCalendarClient.getCalendarApi();
      }

      if (calendarApi == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Anmeldung fehlgeschlagen')),
        );
        return;
      }

      await _loadAppointments();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Calendar synchronisiert')),
      );
    } catch (e) {
      print('Fehler beim Sync: $e');
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
  Future<void> _notifyComponents() async {
    // Benachrichtige andere Komponenten über die Änderung
    if (widget.onAppointmentsChanged != null) {
      widget.onAppointmentsChanged!('refresh');
    }
  }

  /// Fügt eine Aufgabe dem Kalender hinzu
  Future<void> _addTaskToCalendar(Task task, DateTime startTime) async {
    final Duration taskDuration = task.duration ?? const Duration(minutes: 30);
    final endTime = startTime.add(taskDuration);
    if (task.duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Standarddauer von 30 Minuten wird verwendet'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final newAppt = CalendarAppointment(
      subject: task.name,
      startTime: startTime,
      endTime: endTime,
      color:
          Colors
              .grey[800]!, // neutral background base (legacy color field kept)
      notes: task.iconName,
      isAllDay: false,
      priority: task.priority.toInt(),
      customColorValue: task.colorValue,
    );

    setState(() {
      _appointments.add(newAppt);
    });

    final copy = List<CalendarAppointment>.from(_appointments)..removeLast();
    final updatedList = await _appointmentService.addAppointment(copy, newAppt);

    if (!mounted) return;
    setState(() {
      _appointments.clear();
      _appointments.addAll(updatedList);
    });

    _notifyComponents();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${task.name} wurde zum Kalender hinzugefügt'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Erstellt eine neue Aufgabe und fügt sie direkt zum Kalender hinzu
  Future<void> _createAndAddNewTask(
    String taskName,
    double priority,
    IconData? taskIcon,
    Duration? taskDuration,
    DateTime startTime,
  ) async {
    final endTime = startTime.add(taskDuration ?? const Duration(minutes: 30));
    final newAppt = CalendarAppointment(
      subject: taskName,
      startTime: startTime,
      endTime: endTime,
      color: Colors.grey[800]!,
      notes: taskIcon != null ? AppIcons.getName(taskIcon) : null,
      isAllDay: false,
      priority: priority.toInt(),
    );

    setState(() {
      _appointments.add(newAppt);
    });

    final copy = List<CalendarAppointment>.from(_appointments)..removeLast();
    final updatedList = await _appointmentService.addAppointment(copy, newAppt);

    if (!mounted) return;
    setState(() {
      _appointments.clear();
      _appointments.addAll(updatedList);
    });

    _notifyComponents();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$taskName wurde zum Kalender hinzugefügt'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Entfernt einen Termin aus dem Kalender
  Future<void> _removeAppointment(CalendarAppointment appointment) async {
    final copy = List<CalendarAppointment>.from(_appointments);
    setState(() {
      _appointments.remove(appointment);
    });

    final updatedList = await _appointmentService.removeAppointment(
      copy,
      appointment,
    );

    if (!mounted) return;
    setState(() {
      _appointments.clear();
      _appointments.addAll(updatedList);
    });

    _notifyComponents();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Termin wurde aus dem Kalender entfernt'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Wechselt den Erledigungsstatus eines Termins
  Future<void> _toggleAppointmentCompletion(
    CalendarAppointment appointment,
  ) async {
    final index = _appointments.indexOf(appointment);
    if (index != -1) {
      final oldList = List<CalendarAppointment>.from(_appointments);
      final updatedAppt = appointment.copyWith(
        isCompleted: !appointment.isCompleted,
      );

      setState(() {
        _appointments[index] = updatedAppt;
      });

      final updatedList = await _appointmentService.toggleAppointmentCompletion(
        oldList,
        appointment,
      );

      if (!mounted) return;
      setState(() {
        _appointments.clear();
        _appointments.addAll(updatedList);
      });

      _notifyComponents();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appointment.isCompleted
                ? 'Aufgabe wurde als unerledigt markiert'
                : 'Aufgabe wurde als erledigt markiert',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Zeigt die Aufgabenauswahl an, wenn ein Zeitslot doppelt angetippt wird
  void _showTaskSelectionDialog(DateTime selectedDateTime) {
    showDialog(
      context: context,
      builder:
          (context) => TodoSelectionDialog(
            tasks: widget.tasks ?? [],
            selectedDateTime: selectedDateTime,
            onTaskSelected: (task) {
              _addTaskToCalendar(task, selectedDateTime);
            },
            onNewTaskCreated: (taskName, priority, icon, duration) {
              _createAndAddNewTask(
                taskName,
                priority,
                icon,
                duration,
                selectedDateTime,
              );
            },
          ),
    );
  }

  /// Zeigt Optionen an, wenn ein Termin angetippt wird
  void _showAppointmentOptions(CalendarAppointment appointment) {
    showDialog(
      context: context,
      builder:
          (context) => CalendarEditDialog(
            appointment: appointment,
            onSave: (updatedAppointment) async {
              Navigator.pop(context);
              // Finde den Index des aktuellen Termins
              final index = _appointments.indexOf(appointment);
              if (index != -1) {
                final copy = List<CalendarAppointment>.from(_appointments);

                setState(() {
                  // Ersetze den Termin durch den aktualisierten
                  _appointments[index] = updatedAppointment;
                });

                final updatedList = await _appointmentService.updateAppointment(
                  copy,
                  appointment,
                  updatedAppointment,
                );

                if (mounted) {
                  setState(() {
                    _appointments.clear();
                    _appointments.addAll(updatedList);
                  });

                  _notifyComponents();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Termin wurde aktualisiert'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            onDelete: () {
              Navigator.pop(context);
              _removeAppointment(appointment);
            },
            onToggleCompletion: (updatedAppointment) {
              Navigator.pop(context);
              _toggleAppointmentCompletion(updatedAppointment);
            },
            onCancel: () {
              Navigator.pop(context);
            },
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
    final bool isDoubleTap =
        currentTapTime.difference(_lastTapTime!).inMilliseconds < 300 &&
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
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.backgroundColor,
            title: Text(
              'Kalender Hilfe',
              style: TextStyle(
                color: AppTheme.darkTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• Doppeltippen Sie auf einen Zeitslot, um eine Aufgabe hinzuzufügen',
                  style: TextStyle(color: AppTheme.darkTextColor),
                ),
                SizedBox(height: 8),
                Text(
                  '• Tippen Sie auf einen Termin, um Details anzuzeigen oder ihn zu entfernen',
                  style: TextStyle(color: AppTheme.darkTextColor),
                ),
                SizedBox(height: 8),
                Text(
                  '• Aufgaben ohne Dauer erhalten eine Standarddauer von 30 Minuten',
                  style: TextStyle(color: AppTheme.darkTextColor),
                ),
                SizedBox(height: 8),
                Text(
                  '• Verwenden Sie Pinch-Gesten zum Vergrößern/Verkleinern der Zeitansicht',
                  style: TextStyle(color: AppTheme.darkTextColor),
                ),
                SizedBox(height: 8),
                Text(
                  '• Zeitintervalle passen sich je nach Zoom-Stufe an (5min bis 1h)',
                  style: TextStyle(color: AppTheme.darkTextColor),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text(
                  'Verstanden',
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

  void refreshSettings() {
    _loadCalendarSettings();
  }

  @override
  Widget build(BuildContext context) {
    // Setze System UI Overlay Style JEDES MAL beim Build
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppTheme.primaryColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor: AppTheme.calendarBackgroundColor,
      appBar: AppBar(
        title: const Text('KALENDER', style: AppTheme.appBarTitle),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        surfaceTintColor: AppTheme.primaryColor,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppTheme.primaryColor,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
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
            icon: const Icon(Icons.sync),
            onPressed: _syncWithGoogleCalendar,
            tooltip: 'Mit Google Calendar synchronisieren',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _buildCalendarWithZoom(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_fab',
        onPressed: () {
          _showTaskSelectionDialog(_selectedDate);
        },
        backgroundColor: AppTheme.primaryColor,
        tooltip: 'Aufgabe zum Kalender hinzufügen',
        child: const Icon(Icons.add_task, color: AppTheme.textColor),
      ),
    );
  }

  /// Erstellt den Kalender mit Zoom-Funktionalität
  Widget _buildCalendarWithZoom() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.hardEdge,
            child: Theme(
              data: Theme.of(context).copyWith(
                appBarTheme: AppBarTheme(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.textColor,
                  surfaceTintColor: AppTheme.primaryColor,
                  iconTheme: Theme.of(context).iconTheme,
                  titleTextStyle: AppTheme.appBarTitle,
                ),
                // Verhindert, dass das Calendar-Widget die System-UI beeinflusst
                brightness: Theme.of(context).brightness,
              ),
              child: GestureDetector(
                onScaleStart: (_) => {},
                onScaleUpdate: (details) {
                  setState(() {
                    _zoomController.handleScale(details);
                  });
                },
                onScaleEnd: (_) => {},
                child: SfCalendar(
                  key: _calendarKey,
                  controller: _calendarController,
                  view: CalendarView.week,
                  firstDayOfWeek: 1,
                  dataSource: AppointmentDataSource(_appointments),
                  allowViewNavigation: true,
                  showNavigationArrow: true,
                  minDate: DateTime.now().subtract(const Duration(days: 365)),
                  maxDate: DateTime.now().add(const Duration(days: 365)),
                  onTap: _handleCalendarTap,
                  timeSlotViewSettings: TimeSlotViewSettings(
                    timeFormat: 'HH:mm',
                    timeInterval: Duration(
                      minutes: _zoomController.currentMinutesInterval,
                    ),
                    timeIntervalHeight:
                        _zoomController.timeIntervalHeight * 0.6,
                    startHour: _startHour.toDouble(),
                    endHour: _endHour.toDouble(),
                    timeTextStyle: TextStyle(
                      color: AppTheme.darkTextColor,
                      fontSize: 12,
                    ),
                  ),
                  headerStyle: CalendarHeaderStyle(
                    textStyle: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  viewHeaderStyle: const ViewHeaderStyle(
                    dayTextStyle: TextStyle(
                      color: AppTheme.darkTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    dateTextStyle: TextStyle(
                      color: AppTheme.darkTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  cellBorderColor: Colors.black.withOpacity(0.1),
                  backgroundColor: Colors.white,
                  todayHighlightColor: AppTheme.accentColor,
                  selectionDecoration: BoxDecoration(
                    border: Border.all(color: AppTheme.dividerColor, width: 1),
                    borderRadius: BorderRadius.circular(
                      2
                    ),
                  ),
                  appointmentBuilder: (context, calendarAppointmentDetails) {
                    final appointment =
                        calendarAppointmentDetails.appointments.first
                            as CalendarAppointment;
                    final prio = (appointment.priority ?? 3).clamp(1, 5);
                    
                    final bgColor = appointment.customColorValue != null
                        ? Color(appointment.customColorValue!).withOpacity(0.25)
                        : Colors.grey[800]!.withOpacity(0.25);
                        
                    final icon =
                        appointment.notes != null
                            ? AppIcons.getIcon(appointment.notes!)
                            : null;
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 1,
                        vertical: 1,
                      ),
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white12.withOpacity(appointment.isCompleted ? 0.3 : 0.7),
                          width: 1.2,
                        ),
                        boxShadow: [
                          if (!appointment.isCompleted)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                        ]
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.getPriorityColor(prio).withValues(alpha: 1.0),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(3),
                                bottomLeft: Radius.circular(3),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      appointment.subject,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (icon != null) ...[
                                    Icon(icon, size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
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
      _showAppointmentOptions(
        details.appointments!.first as CalendarAppointment,
      );
    }
  }
}
