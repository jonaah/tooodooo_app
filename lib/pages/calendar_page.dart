import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:tooodooo_app/pages/home_page.dart';
import 'package:tooodooo_app/util/app_theme.dart';
import 'package:tooodooo_app/util/todo_selection_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Custom appointment class that extends the SfCalendar Appointment
class Appointment {
  String subject;
  DateTime startTime;
  DateTime endTime;
  Color color;
  bool isAllDay;
  String? notes;
  bool isCompleted;

  Appointment({
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.isAllDay = false,
    this.notes,
    this.isCompleted = false,
  });
}

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

  // Store calendar appointments directly
  final List<Appointment> _appointments = [];

  // Track last tap time for double-tap detection
  DateTime? _lastTapTime;
  DateTime? _lastTapPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _calendarController = CalendarController();
    // Set the calendar view to week view initially
    _calendarController.view = CalendarView.week;

    // Load saved appointments when the page initializes
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
      // Reload appointments when app is resumed
      _loadAppointments();
    }
  }

  // Convert Appointment to JSON-serializable Map
  Map<String, dynamic> _appointmentToJson(Appointment appointment) {
    return {
      'subject': appointment.subject,
      'startTime': appointment.startTime.millisecondsSinceEpoch,
      'endTime': appointment.endTime.millisecondsSinceEpoch,
      'color': appointment.color.value,
      'notes': appointment.notes,
      'isAllDay': appointment.isAllDay,
      'isCompleted': appointment.isCompleted,
    };
  }

  // Create Appointment from JSON Map
  Appointment _appointmentFromJson(Map<String, dynamic> json) {
    return Appointment(
      subject: json['subject'],
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime']),
      color: Color(json['color']),
      notes: json['notes'],
      isAllDay: json['isAllDay'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  // Save appointments to SharedPreferences
  Future<void> _saveAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serializedAppointments =
          _appointments.map((appointment) => _appointmentToJson(appointment)).toList();

      await prefs.setString('calendar_appointments', jsonEncode(serializedAppointments));
      
      // Notify other pages about the change
      if (widget.onAppointmentsChanged != null) {
        widget.onAppointmentsChanged!('refresh');
      }
    } catch (e) {
      // Handle potential errors during saving
      debugPrint('Error saving appointments: $e');
    }
  }

  // Load appointments from SharedPreferences
  Future<void> _loadAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? appointmentsJson = prefs.getString('calendar_appointments');

      if (appointmentsJson != null && appointmentsJson.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(appointmentsJson);

        setState(() {
          _appointments.clear();
          for (var item in decodedList) {
            _appointments.add(_appointmentFromJson(item));
          }
        });
      }
    } catch (e) {
      // Handle potential errors during loading
      debugPrint('Error loading appointments: $e');
    }
  }

  // Public method to refresh appointments (called from main navigator)
  void refreshAppointments() {
    _loadAppointments();
  }

  // Show the task selection dialog when a calendar cell is double-tapped
  void _showTaskSelectionDialog(DateTime selectedDateTime) {
    if (widget.tasks == null || widget.tasks!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tasks available to add to calendar'),
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

  // Add a task to the calendar at the specified time
  void _addTaskToCalendar(Task task, DateTime startTime) {
    // Get task duration or use default 30 minutes if not set
    final Duration taskDuration = task.duration ?? const Duration(minutes: 30);
    final endTime = startTime.add(taskDuration);
    
    // Display a message if using default duration
    if (task.duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Using default 30 minute duration for this task'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      _appointments.add(
        Appointment(
          subject: task.name,
          startTime: startTime,
          endTime: endTime,
          color: AppTheme.getCalendarTaskColor(task.priority.toInt()),
          notes: task.iconName,
          isAllDay: false,
        ),
      );
    });

    // Save appointments after adding a new one
    _saveAppointments();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${task.name}" to calendar'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Remove appointment from calendar
  void _removeAppointment(Appointment appointment) {
    setState(() {
      _appointments.remove(appointment);
    });

    // Save appointments after removing one
    _saveAppointments();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed appointment from calendar'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Mark appointment as completed
  void _markAppointmentAsCompleted(Appointment appointment) {
    setState(() {
      final index = _appointments.indexOf(appointment);
      if (index != -1) {
        // Create a new appointment with updated completed status
        _appointments[index] = Appointment(
          subject: appointment.subject,
          startTime: appointment.startTime,
          endTime: appointment.endTime,
          color: appointment.color,
          notes: appointment.notes,
          isAllDay: appointment.isAllDay,
          isCompleted: true,
        );
      }
    });
    
    // Save appointments after updating one
    _saveAppointments();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task marked as completed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Mark appointment as incomplete
  void _markAppointmentAsIncomplete(Appointment appointment) {
    setState(() {
      final index = _appointments.indexOf(appointment);
      if (index != -1) {
        // Create a new appointment with updated completed status
        _appointments[index] = Appointment(
          subject: appointment.subject,
          startTime: appointment.startTime,
          endTime: appointment.endTime,
          color: appointment.color,
          notes: appointment.notes,
          isAllDay: appointment.isAllDay,
          isCompleted: false,
        );
      }
    });
    
    // Save appointments after updating one
    _saveAppointments();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task marked as incomplete'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Toggle appointment completion status
  void _toggleAppointmentCompletion(Appointment appointment) {
    if (appointment.isCompleted) {
      _markAppointmentAsIncomplete(appointment);
    } else {
      _markAppointmentAsCompleted(appointment);
    }
  }

  // Show options when an appointment is tapped
  void _showAppointmentOptions(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: Row(
          children: [
            // Add checkbox at the beginning of title row
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
              'Status: ${appointment.isCompleted ? "Completed" : "Not completed"}',
              style: TextStyle(
                color: appointment.isCompleted ? Colors.green : AppTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start: ${DateFormat('MMM d, yyyy - HH:mm').format(appointment.startTime)}',
              style: TextStyle(color: AppTheme.textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'End: ${DateFormat('MMM d, yyyy - HH:mm').format(appointment.endTime)}',
              style: TextStyle(color: AppTheme.textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: ${appointment.endTime.difference(appointment.startTime).inHours}h ${appointment.endTime.difference(appointment.startTime).inMinutes % 60}m',
              style: TextStyle(color: AppTheme.textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Remove', style: TextStyle(color: Colors.red)),
            onPressed: () {
              _removeAppointment(appointment);
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text(
              appointment.isCompleted ? 'Mark as Incomplete' : 'Mark as Completed', 
              style: TextStyle(color: AppTheme.accentColor)
            ),
            onPressed: () {
              _toggleAppointmentCompletion(appointment);
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text('Close', style: TextStyle(color: AppTheme.accentColor)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // Check if this is a double tap
  bool _isDoubleTap(DateTime currentTapTime, DateTime? cellDate) {
    if (_lastTapTime == null || _lastTapPosition == null || cellDate == null) {
      _lastTapTime = currentTapTime;
      _lastTapPosition = cellDate;
      return false;
    }

    // Check if the time between taps is less than 300ms (standard double-tap time)
    // and that the tapped position (date+time) is the same
    final bool isDoubleTap = currentTapTime.difference(_lastTapTime!).inMilliseconds < 300 &&
        _isSameTimeSlot(cellDate, _lastTapPosition!);

    // Reset tracking for next tap sequence
    _lastTapTime = null;
    _lastTapPosition = null;

    return isDoubleTap;
  }

  // Check if two dates are in the same time slot (same day, hour, and 15-min block)
  bool _isSameTimeSlot(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day &&
        date1.hour == date2.hour &&
        (date1.minute ~/ 15) == (date2.minute ~/ 15);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('CALENDAR', style: AppTheme.appBarTitle),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              // Jump to today's date
              _calendarController.displayDate = DateTime.now();
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
            tooltip: 'Refresh calendar',
          ),
          // Add help icon to show instructions
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.backgroundColor,
                  title: Text('Calendar Help', 
                    style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Double-tap any time slot to add a task',
                        style: TextStyle(color: AppTheme.textColor),
                      ),
                      SizedBox(height: 8),
                      Text('• Tap on an appointment to view details or remove it',
                        style: TextStyle(color: AppTheme.textColor),
                      ),
                      SizedBox(height: 8),
                      Text('• Tasks without duration will get a default 30-minute duration',
                        style: TextStyle(color: AppTheme.textColor),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text('Got it', style: TextStyle(color: AppTheme.accentColor)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SfCalendar(
        controller: _calendarController,
        view: CalendarView.week,
        firstDayOfWeek: 1, // Monday
        dataSource: _AppointmentDataSource(_appointments),
        onTap: (CalendarTapDetails details) {
          if (details.targetElement == CalendarElement.calendarCell &&
              details.date != null) {
            setState(() {
              _selectedDate = details.date!;
            });

            // Check if this is a double tap
            final now = DateTime.now();
            if (_isDoubleTap(now, details.date)) {
              // Show task selection dialog on double tap
              _showTaskSelectionDialog(details.date!);
            } else {
              // Store this tap for potential double-tap detection
              _lastTapTime = now;
              _lastTapPosition = details.date;
            }
          } else if (details.targetElement == CalendarElement.appointment &&
              details.appointments != null &&
              details.appointments!.isNotEmpty) {
            // When an appointment is tapped, show options
            _showAppointmentOptions(details.appointments!.first);
          }
        },
        timeSlotViewSettings: const TimeSlotViewSettings(
          timeFormat: 'HH:mm',
          timeInterval: Duration(minutes: 15), // Changed to 15 min for better precision
          timeIntervalHeight: 40,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showTaskSelectionDialog(_selectedDate);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add_task, color: AppTheme.textColor),
        tooltip: 'Add task to calendar',
      ),
    );
  }
}

// Custom appointment data source for SfCalendar
class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
  
  @override
  Color getColor(int index) {
    final Appointment appointment = appointments![index] as Appointment;
    // Return a faded color for completed tasks
    if (appointment.isCompleted) {
      return Colors.grey.shade700;
    }
    return appointment.color;
  }
  
  @override
  String getSubject(int index) {
    final Appointment appointment = appointments![index] as Appointment;
    // Add a checkmark to indicate completed tasks
    if (appointment.isCompleted) {
      return '✓ ${appointment.subject}';
    }
    return appointment.subject;
  }
  
  @override
  DateTime getStartTime(int index) {
    final Appointment appointment = appointments![index] as Appointment;
    return appointment.startTime;
  }
  
  @override
  DateTime getEndTime(int index) {
    final Appointment appointment = appointments![index] as Appointment;
    return appointment.endTime;
  }
  
  @override
  bool isAllDay(int index) {
    final Appointment appointment = appointments![index] as Appointment;
    return appointment.isAllDay;
  }
  
  @override
  String? getNotes(int index) {
    final Appointment appointment = appointments![index] as Appointment;
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
  
  @override
  TextStyle getTextStyle(int index) {
    final Appointment appointment = appointments![index] as Appointment;
    // Return strikethrough text style for completed tasks
    if (appointment.isCompleted) {
      return TextStyle(
        decoration: TextDecoration.lineThrough,
        color: Colors.white.withOpacity(0.7),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );
    }
    return const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold, // Make text bold for better visibility
    );
  }
  
  @override
  Widget buildAppointmentWidget(
      BuildContext context, CalendarAppointmentDetails details) {
    // Get the appointment directly from details.appointments instead of using index
    final Appointment appointment = details.appointments.first as Appointment;
    // Find the index of this appointment in the appointments list
    final int appointmentIndex = appointments!.indexOf(appointment);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // The tap will be handled by the calendar's onTap handler
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
