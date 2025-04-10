import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:tooodooo_app/pages/home_page.dart';
import 'package:tooodooo_app/util/app_theme.dart';

class CalendarPage extends StatefulWidget {
  final List<Task>? tasks;

  const CalendarPage({Key? key, this.tasks}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late CalendarController _calendarController;
  DateTime _selectedDate = DateTime.now();
  
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

  // Convert Task objects to Appointment objects for SfCalendar
  List<Appointment> _getCalendarAppointments() {
    List<Appointment> appointments = [];
    
    if (widget.tasks != null) {
      for (var task in widget.tasks!) {
        // Skip completed tasks or tasks without duration
        if (task.completed || task.duration == null) continue;
        
        // Set a default start time at 9 AM today if not specified
        DateTime now = DateTime.now();
        DateTime startTime = DateTime(
          now.year, now.month, now.day, 9, 0, 0
        );
        
        // End time is start time + duration
        DateTime endTime = startTime.add(task.duration!);
        
        // Create an appointment for the task
        appointments.add(
          Appointment(
            subject: task.name,
            startTime: startTime,
            endTime: endTime,
            color: AppTheme.getCalendarTaskColor(task.priority.toInt()),
            notes: task.iconName,
            isAllDay: false,
          ),
        );
      }
    }
    
    return appointments;
  }

  // Get tasks for the selected date
  List<Task> _getTasksForSelectedDate() {
    if (widget.tasks == null) return [];
    
    // For now, we'll just return all tasks
    // Later, this can be enhanced to filter by date when tasks have scheduled dates
    return widget.tasks!;
  }

  @override
  Widget build(BuildContext context) {
    final List<Task> selectedDateTasks = _getTasksForSelectedDate();
    
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
              dataSource: _AppointmentDataSource(_getCalendarAppointments()),
              onTap: (CalendarTapDetails details) {
                if (details.targetElement == CalendarElement.calendarCell && 
                    details.date != null) {
                  setState(() {
                    _selectedDate = details.date!;
                  });
                }
              },
              timeSlotViewSettings: const TimeSlotViewSettings(
                timeFormat: 'HH:mm',
                timeInterval: Duration(minutes: 30),
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
          
          // Task list section (remaining space)
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.smallPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(AppTheme.smallPadding),
                    child: Text(
                      'Tasks for ${DateFormat('EEEE, MMM d').format(_selectedDate)}',
                      style: AppTheme.calendarDayHeader,
                    ),
                  ),
                  Expanded(
                    child: selectedDateTasks.isEmpty
                        ? Center(
                            child: Text(
                              'No tasks for this day',
                              style: TextStyle(color: AppTheme.textColor.withOpacity(0.7)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: selectedDateTasks.length,
                            itemBuilder: (context, index) {
                              final task = selectedDateTasks[index];
                              return Card(
                                color: Colors.grey.shade800,
                                margin: EdgeInsets.symmetric(vertical: AppTheme.smallPadding / 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    task.getIcon() ?? Icons.task_alt,
                                    color: task.completed ? Colors.grey : AppTheme.accentColor,
                                  ),
                                  title: Text(
                                    task.name,
                                    style: TextStyle(
                                      color: AppTheme.textColor,
                                      decoration: task.completed 
                                          ? TextDecoration.lineThrough 
                                          : null,
                                    ),
                                  ),
                                  subtitle: task.duration != null 
                                      ? Text(
                                          'Duration: ${task.duration!.inHours}h ${task.duration!.inMinutes % 60}m',
                                          style: TextStyle(color: AppTheme.textColor.withOpacity(0.7)),
                                        )
                                      : null,
                                  trailing: Checkbox(
                                    value: task.completed,
                                    onChanged: null, // Read-only in calendar view
                                    activeColor: AppTheme.accentColor,
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
