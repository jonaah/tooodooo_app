import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:tooodooo_app/pages/home_page.dart';
import 'package:tooodooo_app/util/app_theme.dart';
import 'package:tooodooo_app/util/todo_selection_dialog.dart';

class CalendarPage extends StatefulWidget {
  final List<Task>? tasks;

  const CalendarPage({Key? key, this.tasks}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
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
    _calendarController = CalendarController();
    // Set the calendar view to week view initially
    _calendarController.view = CalendarView.week;
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  // Get incomplete tasks
  List<Task> _getIncompleteTasks() {
    if (widget.tasks == null) return [];
    
    // Return only incomplete tasks
    return widget.tasks!.where((task) => !task.completed).toList();
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
    if (task.duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task needs a duration to be added to calendar'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final endTime = startTime.add(task.duration!);
    
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${task.name}" to calendar'),
        duration: const Duration(seconds: 2),
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
    final List<Task> incompleteTasks = _getIncompleteTasks();
    
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
        ],
      ),
      body: Column(
        children: [
          // Calendar section (60% of the screen)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: SfCalendar(
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
                }
              },
              timeSlotViewSettings: const TimeSlotViewSettings(
                timeFormat: 'HH:mm',
                timeInterval: Duration(minutes: 15), // Changed to 15 min for better precision
                timeIntervalHeight: 40,
                startHour: 6,
                endHour: 22,
              ),
              headerStyle: CalendarHeaderStyle(
                textStyle: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold
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
                  fontWeight: FontWeight.bold
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
          ),
          
          // Divider
          Container(
            height: 2,
            color: AppTheme.dividerColor,
          ),
          
          // Task grid section (remaining space)
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.smallPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(AppTheme.smallPadding),
                    child: Text(
                      'Incomplete Tasks',
                      style: AppTheme.calendarDayHeader,
                    ),
                  ),
                  Expanded(
                    child: incompleteTasks.isEmpty
                        ? Center(
                            child: Text(
                              'No incomplete tasks',
                              style: TextStyle(color: AppTheme.textColor.withOpacity(0.7)),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: incompleteTasks.length,
                            itemBuilder: (context, index) {
                              final task = incompleteTasks[index];
                              
                              return Card(
                                color: Colors.grey.shade800,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    // Show dialog to select time to add to calendar
                                    final now = DateTime.now();
                                    final defaultTime = DateTime(
                                      now.year, 
                                      now.month, 
                                      now.day, 
                                      now.hour, 
                                      (now.minute ~/ 15) * 15 // Round to nearest 15 minutes
                                    );
                                    
                                    if (task.duration == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Task needs a duration to be added to calendar'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    } else {
                                      _addTaskToCalendar(task, defaultTime);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                                  child: Padding(
                                    padding: EdgeInsets.all(AppTheme.smallPadding),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          task.getIcon() ?? Icons.task_alt,
                                          color: AppTheme.accentColor,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          task.name,
                                          style: TextStyle(
                                            color: AppTheme.textColor,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        if (task.duration != null)
                                          Text(
                                            '${task.duration!.inHours}h ${task.duration!.inMinutes % 60}m',
                                            style: TextStyle(
                                              color: AppTheme.textColor.withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom appointment data source for SfCalendar
class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
