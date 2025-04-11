import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/pages/home_page.dart';
import 'package:tooodooo_app/util/app_theme.dart';
import 'package:tooodooo_app/pages/calendar_page.dart';

class TodayTasksPage extends StatefulWidget {
  final List<Task>? tasks;
  final Function(String)? onTaskRemoved;

  const TodayTasksPage({
    Key? key, 
    this.tasks,
    this.onTaskRemoved,
  }) : super(key: key);

  @override
  State<TodayTasksPage> createState() => TodayTasksPageState();
}

class TodayTasksPageState extends State<TodayTasksPage> with WidgetsBindingObserver {
  // List of appointments from calendar
  List<CalendarAppointment> _appointments = [];
  List<CalendarAppointment> _completedAppointments = [];
  List<CalendarAppointment> _currentAppointments = [];
  List<CalendarAppointment> _upcomingAppointments = [];
  List<CalendarAppointment> _pendingAppointments = [];
  DateTime _today = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAppointments();
    _today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? appointmentsJson = prefs.getString('calendar_appointments');
      
      if (appointmentsJson != null && appointmentsJson.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(appointmentsJson);
        
        setState(() {
          _appointments = decodedList.map((item) => CalendarAppointment.fromJson(item)).toList();
        });
      } else {
        setState(() {
          _appointments = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading appointments: $e');
    }
  }
  
  // Save appointments back to SharedPreferences
  Future<void> _saveAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serializedAppointments = 
          _appointments.map((appointment) => appointment.toJson()).toList();
      
      await prefs.setString('calendar_appointments', jsonEncode(serializedAppointments));
      
      // Notify any listeners that appointments changed
      if (widget.onTaskRemoved != null) {
        widget.onTaskRemoved!('refresh');
      }
    } catch (e) {
      debugPrint('Error saving appointments: $e');
    }
  }

  // Save appointments to SharedPreferences
  Future<void> _saveAppointmentsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serializedAppointments = 
          _appointments.map((appointment) => appointment.toJson()).toList();
      
      await prefs.setString('calendar_appointments', jsonEncode(serializedAppointments));
    } catch (e) {
      debugPrint('Error saving appointments: $e');
    }
  }

  // Public method to refresh appointments (called from main navigator)
  void refreshAppointments() {
    _loadAppointments();
  }

  // Get scheduled tasks for today
  List<CalendarAppointment> get _todayAppointments {
    return _appointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.startTime.year,
        appointment.startTime.month,
        appointment.startTime.day,
      );
      
      return appointmentDate.isAtSameMomentAs(_today);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  // Mark an appointment as completed
  void _markAppointmentAsCompleted(CalendarAppointment appointment) {
    setState(() {
      // Update the appointment in the main list to mark as completed
      final index = _appointments.indexWhere((a) => 
        a.subject == appointment.subject && 
        a.startTime.isAtSameMomentAs(appointment.startTime) &&
        a.endTime.isAtSameMomentAs(appointment.endTime));
      
      if (index != -1) {
        // Create a new appointment with isCompleted set to true
        final updatedAppointment = CalendarAppointment(
          subject: appointment.subject,
          startTime: appointment.startTime,
          endTime: appointment.endTime,
          color: appointment.color,
          notes: appointment.notes,
          isAllDay: appointment.isAllDay,
          isCompleted: true,
        );
        
        // Replace the appointment in the list
        _appointments[index] = updatedAppointment;
      }
    });
    
    // Save the updated appointments list to SharedPreferences
    _saveAppointments();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task marked as completed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Mark an appointment as incomplete
  void _markAppointmentAsIncomplete(CalendarAppointment appointment) {
    setState(() {
      // Update the appointment in the main list to mark as incomplete
      final index = _appointments.indexWhere((a) => 
        a.subject == appointment.subject && 
        a.startTime.isAtSameMomentAs(appointment.startTime) &&
        a.endTime.isAtSameMomentAs(appointment.endTime));
      
      if (index != -1) {
        // Create a new appointment with isCompleted set to false
        final updatedAppointment = CalendarAppointment(
          subject: appointment.subject,
          startTime: appointment.startTime,
          endTime: appointment.endTime,
          color: appointment.color,
          notes: appointment.notes,
          isAllDay: appointment.isAllDay,
          isCompleted: false,
        );
        
        // Replace the appointment in the list
        _appointments[index] = updatedAppointment;
      }
    });
    
    // Save the updated appointments list to SharedPreferences
    _saveAppointments();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task marked as incomplete'),
        duration: Duration(seconds: 2),
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
    
    _saveAppointments();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task removed from calendar'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Format time as "9:30 AM"
  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }
  
  // Check if a time is now or in the future
  bool _isCurrentOrFuture(DateTime time) {
    return DateTime.now().isBefore(time) || 
        (time.hour == DateTime.now().hour && time.minute >= DateTime.now().minute);
  }

  @override
  Widget build(BuildContext context) {
    final todayAppointments = _todayAppointments;
    final currentTime = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d').format(_today);
    
    // Split tasks into different categories
    final completedTasks = todayAppointments.where(
      (task) => task.isCompleted
    ).toList();
    
    final pendingTasks = todayAppointments.where(
      (task) => task.endTime.isBefore(currentTime) && !task.isCompleted
    ).toList();
    
    final currentTasks = todayAppointments.where(
      (task) => !task.endTime.isBefore(currentTime) && 
                !task.startTime.isAfter(currentTime) &&
                !task.isCompleted
    ).toList();
    
    final upcomingTasks = todayAppointments.where(
      (task) => task.startTime.isAfter(currentTime) && !task.isCompleted
    ).toList();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('TODAY', style: AppTheme.appBarTitle),
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
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
            tooltip: 'Refresh tasks',
          ),
        ],
      ),
      body: todayAppointments.isEmpty
          ? _buildEmptyView()
          : RefreshIndicator(
              onRefresh: _loadAppointments,
              color: AppTheme.accentColor,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.defaultPadding),
                children: [
                  // Current time indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12, 
                      horizontal: AppTheme.defaultPadding
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.2),
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
                            color: AppTheme.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Current tasks (if any)
                  if (currentTasks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('HAPPENING NOW', Icons.play_circle_filled, Colors.green),
                    ...currentTasks.map((task) => _buildTaskCard(
                      task, 
                      isCurrentTask: true,
                    )),
                  ],
                  
                  // Pending tasks (past but not completed)
                  if (pendingTasks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('PENDING', Icons.pending_actions, Colors.orange),
                    ...pendingTasks.map((task) => _buildTaskCard(
                      task,
                      isPendingTask: true,
                    )),
                  ],
                  
                  // Upcoming tasks (if any)
                  if (upcomingTasks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('UPCOMING', Icons.upcoming, AppTheme.accentColor),
                    ...upcomingTasks.map((task) => _buildTaskCard(
                      task,
                      isUpcomingTask: true,
                    )),
                  ],
                  
                  // Completed tasks (if any)
                  if (completedTasks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('COMPLETED', Icons.check_circle, Colors.grey),
                    ...completedTasks.map((task) => _buildTaskCard(
                      task,
                      isCompletedTask: true,
                    )),
                  ],
                  
                  // Add extra space at the bottom
                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: AppTheme.textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks scheduled for today',
            style: TextStyle(
              color: AppTheme.textColor.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Double-tap on the calendar to add tasks',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textColor.withOpacity(0.5),
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
            icon: const Icon(Icons.calendar_month),
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
  
  Widget _buildTaskCard(CalendarAppointment appointment, {
    bool isCurrentTask = false,
    bool isPastTask = false,
    bool isPendingTask = false,
    bool isUpcomingTask = false,
    bool isCompletedTask = false,
  }) {
    // Calculate progress for current tasks
    double? progress;
    if (isCurrentTask) {
      final totalDuration = appointment.endTime.difference(appointment.startTime).inMinutes;
      final elapsedDuration = DateTime.now().difference(appointment.startTime).inMinutes;
      progress = elapsedDuration / totalDuration;
      progress = progress.clamp(0.0, 1.0); // Ensure progress is between 0 and 1
    }
    
    // Get duration text
    final durationMinutes = appointment.endTime.difference(appointment.startTime).inMinutes;
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    final durationText = hours > 0 
        ? '${hours}h ${minutes > 0 ? '${minutes}m' : ''}'
        : '${minutes}m';
    
    // Get time range text (e.g., "9:30 AM - 10:30 AM")
    final timeRangeText = '${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}';
    
    // Get the remaining time for upcoming tasks
    String? remainingTimeText;
    if (isUpcomingTask) {
      final remainingMinutes = appointment.startTime.difference(DateTime.now()).inMinutes;
      if (remainingMinutes < 60) {
        remainingTimeText = 'In $remainingMinutes minute${remainingMinutes == 1 ? '' : 's'}';
      } else if (remainingMinutes < 24 * 60) {
        final hours = remainingMinutes ~/ 60;
        final minutes = remainingMinutes % 60;
        remainingTimeText = 'In $hours hour${hours == 1 ? '' : 's'}${minutes > 0 ? ' $minutes min' : ''}';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          // Toggle completion status on task card tap
          if (isCompletedTask) {
            _markAppointmentAsIncomplete(appointment);
          } else {
            _markAppointmentAsCompleted(appointment);
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
        splashColor: isCompletedTask ? Colors.grey.shade400.withOpacity(0.3) : Colors.white.withOpacity(0.3),
        highlightColor: isCompletedTask ? Colors.grey.shade400.withOpacity(0.2) : Colors.white.withOpacity(0.2),
        child: Ink(
          decoration: BoxDecoration(
            color: isCompletedTask 
                ? Colors.grey.shade800.withOpacity(0.5)
                : isPendingTask
                    ? Colors.orange.shade800.withOpacity(0.5)
                    : Color(appointment.color),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
            border: isCompletedTask || isPendingTask
                ? Border.all(color: Colors.grey.shade700, width: 1)
                : null,
            boxShadow: isCompletedTask || isPendingTask 
                ? null 
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Task completion checkbox - positioned on the left
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isCompletedTask ? Colors.grey.shade500 : Colors.white70,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: isCompletedTask ? Colors.grey.shade600 : Colors.transparent,
                      ),
                      child: isCompletedTask 
                          ? const Icon(Icons.check, size: 16, color: Colors.white) 
                          : null,
                    ),
                    const SizedBox(width: 8),
                    if (appointment.notes != null && appointment.notes!.isNotEmpty)
                      Icon(
                        IconData(
                          int.tryParse(appointment.notes!) ?? 0xe158, // Default to event icon
                          fontFamily: 'MaterialIcons',
                        ),
                        color: isCompletedTask || isPendingTask ? Colors.grey : Colors.white,
                        size: 18,
                      )
                    else
                      Icon(
                        Icons.task_alt,
                        color: isCompletedTask || isPendingTask ? Colors.grey : Colors.white,
                        size: 18,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.subject,
                        style: TextStyle(
                          color: isCompletedTask || isPendingTask ? Colors.grey.shade400 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: isCompletedTask ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompletedTask || isPendingTask ? Colors.grey.shade700 : Colors.black26,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        durationText,
                        style: TextStyle(
                          color: isCompletedTask || isPendingTask ? Colors.grey.shade400 : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // Increased spacing to separate from delete button
                    GestureDetector(
                      onTap: () => _removeAppointment(appointment),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.delete_outline,
                          color: isCompletedTask || isPendingTask ? Colors.grey.shade500 : Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: isCompletedTask || isPendingTask ? Colors.grey.shade500 : Colors.white70,
                      size: 14, 
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeRangeText,
                      style: TextStyle(
                        color: isCompletedTask || isPendingTask ? Colors.grey.shade500 : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    if (remainingTimeText != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          remainingTimeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Progress indicator for current tasks
                if (isCurrentTask) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'In progress (${(progress! * 100).toInt()}% complete)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Model for calendar appointments
class CalendarAppointment {
  final String subject;
  final DateTime startTime;
  final DateTime endTime;
  final int color;
  final String? notes;
  final bool isAllDay;
  final bool isCompleted;
  
  CalendarAppointment({
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.notes,
    this.isAllDay = false,
    this.isCompleted = false,
  });
  
  factory CalendarAppointment.fromJson(Map<String, dynamic> json) {
    return CalendarAppointment(
      subject: json['subject'],
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime']),
      color: json['color'],
      notes: json['notes'],
      isAllDay: json['isAllDay'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'color': color,
      'notes': notes,
      'isAllDay': isAllDay,
      'isCompleted': isCompleted,
    };
  }
}