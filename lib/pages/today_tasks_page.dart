import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';
import 'package:tooodooo_app/pages/calendar_page.dart';
import 'package:tooodooo_app/pages/home_page.dart';
import 'package:tooodooo_app/today/task_card.dart';
import 'package:tooodooo_app/today/task_section_header.dart';
import 'package:tooodooo_app/today/today_tasks_service.dart';
import 'package:tooodooo_app/util/app_theme.dart';
import 'package:tooodooo_app/util/todo_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TodayTasksPage extends StatefulWidget {
  final List<Task>? tasks;
  final Function(String)? onTaskRemoved;
  final Function(List<Task>)? onTasksUpdated; // new callback for task state changes

  const TodayTasksPage({
    super.key,
    this.tasks,
    this.onTaskRemoved,
    this.onTasksUpdated,
  });

  @override
  State<TodayTasksPage> createState() => TodayTasksPageState();
}

class TodayTasksPageState extends State<TodayTasksPage> with WidgetsBindingObserver {
  final TodayTasksService _tasksService = TodayTasksService();
  List<CalendarAppointment> _appointments = [];
  DateTime _selectedDate = DateTime.now();
  DateTime _today = DateTime.now();
  List<Task> _tasksLocal = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAppointments();
    _tasksLocal = widget.tasks != null ? widget.tasks!.map((t) => t).toList() : [];
    _loadTasksFromPrefs();
    _today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _selectedDate = _today;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAppointments();
    }
  }

  // Navigation helpers
  void _goToPreviousDay() => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
  void _goToNextDay() => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
  void _goToToday() => setState(() => _selectedDate = _today);

  void _showMonthCalendarPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: AppTheme.accentColor,
              surface: AppTheme.primaryColor,
              onSurface: AppTheme.textColor,
            ), dialogTheme: const DialogThemeData(backgroundColor: AppTheme.backgroundColor),
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
        setState(() => _selectedDate = selectedDate);
      }
    });
  }

  Future<void> _loadAppointments() async {
    final loadedAppointments = await _tasksService.loadAppointments();
    if (!mounted) return;
    setState(() => _appointments = loadedAppointments);
  }

  Future<void> _saveAppointmentsAndNotify() async {
    await _tasksService.saveAppointments(_appointments);
    if (widget.onTaskRemoved != null) {
      widget.onTaskRemoved!('refresh');
    }
  }

  void refreshAppointments() => _loadAppointments();

  void _markAppointmentAsCompleted(CalendarAppointment appointment) {
    setState(() {
      final index = _appointments.indexWhere((a) => _sameAppointment(a, appointment));
      if (index != -1) _appointments[index] = _appointments[index].copyWith(isCompleted: true);
    });
    _saveAppointmentsAndNotify();
    _showSnack(TodayTasksService.msgTaskCompleted);
  }

  void _markAppointmentAsIncomplete(CalendarAppointment appointment) {
    setState(() {
      final index = _appointments.indexWhere((a) => _sameAppointment(a, appointment));
      if (index != -1) _appointments[index] = _appointments[index].copyWith(isCompleted: false);
    });
    _saveAppointmentsAndNotify();
    _showSnack(TodayTasksService.msgTaskIncomplete);
  }

  void _removeAppointment(CalendarAppointment appointment) {
    setState(() => _appointments.removeWhere((a) => _sameAppointment(a, appointment)));
    _saveAppointmentsAndNotify();
    _showSnack(TodayTasksService.msgTaskRemoved);
  }

  bool _sameAppointment(CalendarAppointment a, CalendarAppointment b) => a.id == b.id;

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _loadTasksFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('toDoList');
    if (str != null) {
      try {
        final decoded = jsonDecode(str) as List;
        if (!mounted) return;
        setState(() => _tasksLocal = decoded.map((e) => Task.fromJson(e)).toList());
      } catch (_) {}
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('toDoList', jsonEncode(_tasksLocal.map((t) => t.toJson()).toList()));
    widget.onTasksUpdated?.call(_tasksLocal);
  }

  void _toggleTask(int index, bool? value) {
    setState(() {
      final task = _tasksLocal[index];
      if (task.isGroup) {
        final allComplete = task.subtasks.isNotEmpty && task.subtasks.every((s) => s.completed);
        for (final s in task.subtasks) { s.completed = !allComplete; }
        task.recalcCompletion();
      } else {
        task.completed = value ?? !task.completed;
      }
    });
    _saveTasks();
  }

  void _toggleSubTask(int taskIndex, int subIndex, bool newVal) {
    setState(() {
      final task = _tasksLocal[taskIndex];
      task.subtasks[subIndex].completed = newVal;
      task.recalcCompletion();
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateAppointments = _tasksService.getAppointmentsForDate(_appointments, _selectedDate);
    final currentTime = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d').format(_selectedDate);
    final isToday = _isSameDay(_selectedDate, _today);

    final categorizedTasks = _tasksService.categorizeAppointments(selectedDateAppointments, currentTime, isToday);
    final completedTasks = categorizedTasks[TaskSection.completed] ?? [];
    final pendingTasks = categorizedTasks[TaskSection.pending] ?? [];
    final currentTasks = categorizedTasks[TaskSection.happeningNow] ?? [];
    final upcomingTasks = isToday
        ? (categorizedTasks[TaskSection.upcoming] ?? [])
        : (categorizedTasks[TaskSection.scheduled] ?? []);

    final hasAny = selectedDateAppointments.isNotEmpty || _tasksLocal.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(_tasksService.getDateTitle(_selectedDate), style: AppTheme.appBarTitle),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 14, color: AppTheme.textColor.withOpacity(0.8)),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        surfaceTintColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.today), onPressed: _goToToday, tooltip: 'Go to today'),
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: _showMonthCalendarPicker, tooltip: 'Select date'),
        ],
      ),
      body: Column(
        children: [
          DayNavigatorHeader(
            isToday: isToday,
            selectedDate: _selectedDate,
            today: _today,
            onPrev: _goToPreviousDay,
            onNext: _goToNextDay,
          ),
          Expanded(
            child: !hasAny
                ? _buildEmptyView(isPastDate: _selectedDate.isBefore(_today))
                : RefreshIndicator(
                    onRefresh: () async { await _loadAppointments(); await _loadTasksFromPrefs(); },
                    color: AppTheme.accentColor,
                    child: TaskSectionsList(
                      isToday: isToday,
                      currentTime: currentTime,
                      currentTasks: currentTasks,
                      pendingTasks: pendingTasks,
                      upcomingTasks: upcomingTasks,
                      completedTasks: completedTasks,
                      onMarkComplete: _markAppointmentAsCompleted,
                      onMarkIncomplete: _markAppointmentAsIncomplete,
                      onRemove: _removeAppointment,
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomDayStrip(
        today: _today,
        selectedDate: _selectedDate,
        onSelect: (d) => setState(() => _selectedDate = d),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

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
            isPastDate ? TodayTasksService.msgNoTasksScheduledPast : TodayTasksService.msgNoTasksScheduled,
            style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            TodayTasksService.msgDoubleTapToAdd,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => CalendarPage(tasks: widget.tasks)),
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

// ---------------- Sub Widgets ----------------
class DayNavigatorHeader extends StatelessWidget {
  final bool isToday;
  final DateTime selectedDate;
  final DateTime today;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const DayNavigatorHeader({
    super.key,
    required this.isToday,
    required this.selectedDate,
    required this.today,
    required this.onPrev,
    required this.onNext,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.textColor),
            onPressed: onPrev,
            tooltip: 'Previous day',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isToday ? AppTheme.accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isToday ? 'Today' : DateFormat('MMM d').format(selectedDate),
              style: const TextStyle(color: AppTheme.secondaryTextColor, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppTheme.textColor),
            onPressed: onNext,
            tooltip: 'Next day',
          ),
        ],
      ),
    );
  }
}

class TaskSectionsList extends StatelessWidget {
  final bool isToday;
  final DateTime currentTime;
  final List<CalendarAppointment> currentTasks;
  final List<CalendarAppointment> pendingTasks;
  final List<CalendarAppointment> upcomingTasks;
  final List<CalendarAppointment> completedTasks;
  final Function(CalendarAppointment) onMarkComplete;
  final Function(CalendarAppointment) onMarkIncomplete;
  final Function(CalendarAppointment) onRemove;
  const TaskSectionsList({
    super.key,
    required this.isToday,
    required this.currentTime,
    required this.currentTasks,
    required this.pendingTasks,
    required this.upcomingTasks,
    required this.completedTasks,
    required this.onMarkComplete,
    required this.onMarkIncomplete,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      children: [
        if (isToday) CurrentTimeBanner(currentTime: currentTime),
        if (isToday && currentTasks.isNotEmpty) const SizedBox(height: 24),
        if (currentTasks.isNotEmpty) ...[
          TaskSectionHeader(
            title: TodayTasksService.sectionHappeningNow,
            icon: Icons.play_circle_filled,
            color: Colors.green,
          ),
          ...currentTasks.map((task) => TaskCard(
                appointment: task,
                isCurrentTask: true,
                onTaskCompleted: onMarkComplete,
                onTaskIncomplete: onMarkIncomplete,
                onTaskRemoved: onRemove,
              )),
        ],
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
                onTaskCompleted: onMarkComplete,
                onTaskIncomplete: onMarkIncomplete,
                onTaskRemoved: onRemove,
              )),
        ],
        if (upcomingTasks.isNotEmpty) ...[
          const SizedBox(height: 24),
          TaskSectionHeader(
            title: isToday ? TodayTasksService.sectionUpcoming : TodayTasksService.sectionScheduled,
            icon: isToday ? Icons.upcoming : Icons.event,
            color: AppTheme.darkTextColor,
          ),
          ...upcomingTasks.map((task) => TaskCard(
                appointment: task,
                isUpcomingTask: true,
                showRemainingTime: isToday,
                onTaskCompleted: onMarkComplete,
                onTaskIncomplete: onMarkIncomplete,
                onTaskRemoved: onRemove,
              )),
        ],
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
                onTaskCompleted: onMarkComplete,
                onTaskIncomplete: onMarkIncomplete,
                onTaskRemoved: onRemove,
              )),
        ],
        const SizedBox(height: 60),
      ],
    );
  }
}

class CurrentTimeBanner extends StatelessWidget {
  final DateTime currentTime;
  const CurrentTimeBanner({super.key, required this.currentTime});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppTheme.defaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.dividerColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, color: AppTheme.accentColor),
          const SizedBox(width: 8),
          Text(
            'Current Time: ${DateFormat('h:mm a').format(currentTime)}',
            style: const TextStyle(color: AppTheme.secondaryTextColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class BottomDayStrip extends StatelessWidget {
  final DateTime today;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;
  const BottomDayStrip({super.key, required this.today, required this.selectedDate, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppTheme.primaryColor,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            final dayOffset = index - 2;
            final date = today.add(Duration(days: dayOffset));
            final isSelected = _isSameDay(date, selectedDate);
            return Expanded(
              child: InkWell(
                onTap: () => onSelect(date),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    border: isSelected ? const Border(top: BorderSide(color: AppTheme.accentColor, width: 3)) : null,
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
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}