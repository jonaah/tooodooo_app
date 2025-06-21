import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';
import 'package:tooodooo_app/pages/calendar_page.dart';
import 'package:tooodooo_app/pages/home_page.dart';
import 'package:tooodooo_app/today/task_card.dart';
import 'package:tooodooo_app/today/task_section_header.dart';
import 'package:tooodooo_app/today/today_tasks_service.dart';
import 'package:tooodooo_app/util/app_theme.dart';

class TodayTasksPage extends StatefulWidget {
  final List<Task>? tasks;
  final Function(String)? onTaskRemoved;

  const TodayTasksPage({
    super.key, 
    this.tasks,
    this.onTaskRemoved,
  });

  @override
  State<TodayTasksPage> createState() => TodayTasksPageState();
}

class TodayTasksPageState extends State<TodayTasksPage> with WidgetsBindingObserver {
  // Service for managing tasks
  final TodayTasksService _tasksService = TodayTasksService();
  
  // List of appointments 
  List<CalendarAppointment> _appointments = [];
  
  // Current date to display tasks for
  DateTime _selectedDate = DateTime.now();
  DateTime _today = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAppointments();
    
    // Initialize today with just the date part (no time)
    _today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    
    // Initialize selected date to today
    _selectedDate = _today;
  }
  
  // Navigate to the previous day
  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }
  
  // Navigate to the next day
  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }
  
  // Reset to today
  void _goToToday() {
    setState(() {
      _selectedDate = _today;
    });
  }
  
  // Show month picker dialog
  void _showMonthCalendarPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.white,
              onPrimary: AppTheme.accentColor,
              surface: AppTheme.primaryColor,
              onSurface: AppTheme.textColor,
            ), dialogTheme: DialogThemeData(backgroundColor: AppTheme.backgroundColor),
          ),
          child: DatePickerDialog(
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            initialEntryMode: DatePickerEntryMode.calendar,
            helpText: "SELECT A DATE",
            confirmText: "SELECT",
            cancelText: "CANCEL",
          ),
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          _selectedDate = selectedDate;
        });
      }
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload appointments when app is resumed
      _loadAppointments();
    }
  }

  // Load appointments from SharedPreferences
  Future<void> _loadAppointments() async {
    final loadedAppointments = await _tasksService.loadAppointments();
    setState(() {
      _appointments = loadedAppointments;
    });
  }
  
  // Save appointments and notify listeners
  Future<void> _saveAppointmentsAndNotify() async {
    await _tasksService.saveAppointments(_appointments);
    
    // Notify any listeners that appointments changed
    if (widget.onTaskRemoved != null) {
      widget.onTaskRemoved!('refresh');
    }
  }

  // Public method to refresh appointments (called from main navigator)
  void refreshAppointments() {
    _loadAppointments();
  }

  // Mark an appointment as completed
  void _markAppointmentAsCompleted(CalendarAppointment appointment) {
    setState(() {
      // Find the appointment in the list
      final index = _appointments.indexWhere((a) => 
        a.subject == appointment.subject && 
        a.startTime.isAtSameMomentAs(appointment.startTime) &&
        a.endTime.isAtSameMomentAs(appointment.endTime));
      
      if (index != -1) {
        // Replace with completed version using copyWith
        _appointments[index] = _appointments[index].copyWith(isCompleted: true);
      }
    });
    
    _saveAppointmentsAndNotify();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TodayTasksService.msgTaskCompleted),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Mark an appointment as incomplete
  void _markAppointmentAsIncomplete(CalendarAppointment appointment) {
    setState(() {
      // Find the appointment in the list
      final index = _appointments.indexWhere((a) => 
        a.subject == appointment.subject && 
        a.startTime.isAtSameMomentAs(appointment.startTime) &&
        a.endTime.isAtSameMomentAs(appointment.endTime));
      
      if (index != -1) {
        // Replace with incomplete version using copyWith
        _appointments[index] = _appointments[index].copyWith(isCompleted: false);
      }
    });
    
    _saveAppointmentsAndNotify();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TodayTasksService.msgTaskIncomplete),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Remove an appointment
  void _removeAppointment(CalendarAppointment appointment) {
    setState(() {
      _appointments.removeWhere((a) => 
        a.subject == appointment.subject && 
        a.startTime.isAtSameMomentAs(appointment.startTime) &&
        a.endTime.isAtSameMomentAs(appointment.endTime));
    });
    
    _saveAppointmentsAndNotify();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TodayTasksService.msgTaskRemoved),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get appointments for the selected date
    final selectedDateAppointments = _tasksService.getAppointmentsForDate(
      _appointments, 
      _selectedDate
    );
    
    final currentTime = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d').format(_selectedDate);
    
    // Check if the selected date is today
    final isToday = _selectedDate.year == _today.year && 
                     _selectedDate.month == _today.month && 
                     _selectedDate.day == _today.day;
    
    // Categorize tasks
    final categorizedTasks = _tasksService.categorizeAppointments(
      selectedDateAppointments, 
      currentTime, 
      isToday
    );
    
    final completedTasks = categorizedTasks['completed'] ?? [];
    final pendingTasks = categorizedTasks['pending'] ?? [];
    final currentTasks = categorizedTasks['current'] ?? [];
    final upcomingTasks = categorizedTasks['upcoming'] ?? [];
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(_tasksService.getDateTitle(_selectedDate), style: AppTheme.appBarTitle),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        surfaceTintColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            tooltip: 'Go to today',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _showMonthCalendarPicker,
            tooltip: 'Select date',
          ),
        ],
      ),
      body: Column(
        children: [
          // Day navigation header
          Container(
            color: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppTheme.textColor),
                  onPressed: _goToPreviousDay,
                  tooltip: 'Previous day',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isToday ? AppTheme.accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isToday ? 'Today' : DateFormat('MMM d').format(_selectedDate),
                    style: const TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppTheme.textColor),
                  onPressed: _goToNextDay,
                  tooltip: 'Next day',
                ),
              ],
            ),
          ),
          
          // Tasks list
          Expanded(
            child: selectedDateAppointments.isEmpty
                ? _buildEmptyView(isPastDate: _selectedDate.isBefore(_today))
                : RefreshIndicator(
                    onRefresh: _loadAppointments,
                    color: AppTheme.accentColor,
                    child: ListView(
                      padding: const EdgeInsets.all(AppTheme.defaultPadding),
                      children: [
                        // Current time indicator (only for today)
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12, 
                              horizontal: AppTheme.defaultPadding
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.dividerColor.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  color: AppTheme.accentColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Current Time: ${DateFormat('h:mm a').format(currentTime)}',
                                  style: const TextStyle(
                                    color: AppTheme.secondaryTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Current tasks (if any and today)
                        if (currentTasks.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          TaskSectionHeader(
                            title: TodayTasksService.sectionHappeningNow,
                            icon: Icons.play_circle_filled,
                            color: Colors.green,
                          ),
                          ...currentTasks.map((task) => TaskCard(
                            appointment: task,
                            isCurrentTask: true,
                            onTaskCompleted: _markAppointmentAsCompleted,
                            onTaskIncomplete: _markAppointmentAsIncomplete,
                            onTaskRemoved: _removeAppointment,
                          )),
                        ],
                        
                        // Pending tasks (past but not completed)
                        if (pendingTasks.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          TaskSectionHeader(
                            title: TodayTasksService.sectionPending,
                            icon: Icons.pending_actions,
                            color: Colors.orange,
                          ),
                          ...pendingTasks.map((task) => TaskCard(
                            appointment: task,
                            isPendingTask: true,
                            onTaskCompleted: _markAppointmentAsCompleted,
                            onTaskIncomplete: _markAppointmentAsIncomplete,
                            onTaskRemoved: _removeAppointment,
                          )),
                        ],
                        
                        // Upcoming tasks (if any)
                        if (upcomingTasks.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          TaskSectionHeader(
                            title: isToday 
                              ? TodayTasksService.sectionUpcoming 
                              : TodayTasksService.sectionScheduled,
                            icon: isToday ? Icons.upcoming : Icons.event,
                            color: AppTheme.darkTextColor,
                          ),
                          ...upcomingTasks.map((task) => TaskCard(
                            appointment: task,
                            isUpcomingTask: true,
                            showRemainingTime: isToday,
                            onTaskCompleted: _markAppointmentAsCompleted,
                            onTaskIncomplete: _markAppointmentAsIncomplete,
                            onTaskRemoved: _removeAppointment,
                          )),
                        ],
                        
                        // Completed tasks (if any)
                        if (completedTasks.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          TaskSectionHeader(
                            title: TodayTasksService.sectionCompleted,
                            icon: Icons.check_circle,
                            color: Colors.grey,
                          ),
                          ...completedTasks.map((task) => TaskCard(
                            appointment: task,
                            isCompletedTask: true,
                            onTaskCompleted: _markAppointmentAsCompleted,
                            onTaskIncomplete: _markAppointmentAsIncomplete,
                            onTaskRemoved: _removeAppointment,
                          )),
                        ],
                        
                        // Add extra space at the bottom
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      // Bottom navigation to quickly switch between days
      bottomNavigationBar: BottomAppBar(
        color: AppTheme.primaryColor,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              // Generate buttons for -2, -1, 0 (today), +1, +2 days
              final dayOffset = index - 2;
              final date = _today.add(Duration(days: dayOffset));
              final isSelected = date.year == _selectedDate.year && 
                              date.month == _selectedDate.month && 
                              date.day == _selectedDate.day;
              
              String label;
              if (dayOffset == -2) {
                label = 'Day -2';
              } else if (dayOffset == -1) label = 'Yesterday';
              else if (dayOffset == 0) label = 'Today';
              else if (dayOffset == 1) label = 'Tomorrow';
              else label = 'Day +2';
              
              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      border: isSelected ? const Border(
                        top: BorderSide(color: AppTheme.accentColor, width: 3)
                      ) : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('E').format(date),
                          style: TextStyle(
                            color: isSelected ? AppTheme.accentColor : AppTheme.textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            color: isSelected ? AppTheme.accentColor : AppTheme.textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyView({bool isPastDate = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPastDate ? Icons.history : Icons.event_available,
            size: 64,
            color: AppTheme.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            isPastDate
                ? TodayTasksService.msgNoTasksScheduledPast
                : TodayTasksService.msgNoTasksScheduled,
            style: TextStyle(
              color: AppTheme.secondaryTextColor,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            TodayTasksService.msgDoubleTapToAdd,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.secondaryTextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Switch to calendar tab
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => CalendarPage(tasks: widget.tasks),
                ),
              );
            },
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            label: const Text('Go to Calendar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}