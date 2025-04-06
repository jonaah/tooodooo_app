import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tooodooo_app/pages/home_page.dart';

class CalendarPage extends StatefulWidget {
  final List<Task>? tasks;

  const CalendarPage({Key? key, this.tasks}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedDay;
  late List<DateTime> _weekDays;
  int _selectedDayIndex = 0; // Default to today in the week
  
  final ScrollController _scrollController = ScrollController();

  // Each hour will be divided into 4 quarter-hour segments
  final int _segmentsPerHour = 4;
  final double _heightPerSegment = 20.0; // 20 height per 15-min segment (80 per hour)

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _generateWeekDays();
    
    // Scroll to morning hours (8 AM) after rendering, adjusted for segments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(8 * _segmentsPerHour * _heightPerSegment); // 8 hours * 4 segments * height per segment
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _generateWeekDays() {
    // Find the first day of the current week (Monday)
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    // Generate a list of the 7 days in the week
    _weekDays = List.generate(7, (index) {
      return firstDayOfWeek.add(Duration(days: index));
    });
    
    // Set selected day to today by default
    _selectedDayIndex = now.weekday - 1; // 0-based index
  }

  void _previousWeek() {
    setState(() {
      final firstDayOfCurrentWeek = _weekDays.first;
      final firstDayOfPrevWeek = firstDayOfCurrentWeek.subtract(const Duration(days: 7));
      
      _weekDays = List.generate(7, (index) {
        return firstDayOfPrevWeek.add(Duration(days: index));
      });
    });
  }

  void _nextWeek() {
    setState(() {
      final firstDayOfCurrentWeek = _weekDays.first;
      final firstDayOfNextWeek = firstDayOfCurrentWeek.add(const Duration(days: 7));
      
      _weekDays = List.generate(7, (index) {
        return firstDayOfNextWeek.add(Duration(days: index));
      });
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Filter tasks for a specific day
  List<Task> _getTasksForDay(DateTime day) {
    if (widget.tasks == null) return [];
    
    return widget.tasks!.where((task) {
      // For now, we have no specific date for tasks, so we'll just show all tasks
      // Later, you can add due dates to tasks and filter accordingly
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Task> selectedDayTasks = _getTasksForDay(_weekDays[_selectedDayIndex]);
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 87, 89, 90),
      appBar: AppBar(
        title: const Text(
          'WEEKLY CALENDAR',
          style: TextStyle(
            color: Color.fromARGB(255, 222, 222, 222),
            fontSize: 28, 
            fontWeight: FontWeight.bold
          )
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 73, 68, 67),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _generateWeekDays();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Week selector with navigation
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _previousWeek,
                ),
                Text(
                  '${DateFormat('MMM d').format(_weekDays.first)} - ${DateFormat('MMM d').format(_weekDays.last)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: _nextWeek,
                ),
              ],
            ),
          ),
          
          // Calendar section (3/5 of the screen)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55, // 55% of screen height
            child: Column(
              children: [
                // Day headers row with fixed time column
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade700)
                    )
                  ),
                  child: Row(
                    children: [
                      // Fixed time header
                      SizedBox(
                        width: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey.shade700, width: 1)
                            )
                          ),
                          child: Center(
                            child: Text(
                              'Time', 
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold
                              )
                            ),
                          ),
                        ),
                      ),
                      
                      // Day headers
                      ...List.generate(7, (index) {
                        final day = _weekDays[index];
                        final isToday = _isToday(day);
                        final isSelected = index == _selectedDayIndex;
                        
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDayIndex = index;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.amber.withOpacity(0.3) : Colors.transparent,
                                border: Border(
                                  right: BorderSide(color: Colors.grey.shade700, width: 1)
                                )
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('E').format(day), // Day name (Mon, Tue, etc.)
                                    style: TextStyle(
                                      color: isToday ? Colors.amber : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    day.day.toString(), // Day number
                                    style: TextStyle(
                                      color: isToday ? Colors.amber : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                
                // Calendar grid - all hours for all days in a single scrollable grid
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: List.generate(24 * _segmentsPerHour, (index) {
                        final hourIndex = index ~/ _segmentsPerHour; // Integer division to get hour
                        final minuteIndex = (index % _segmentsPerHour) * 15; // 0, 15, 30, 45
                        final isHourStart = minuteIndex == 0;
                        
                        // Apply border at the top instead of bottom to make it clearer which time is meant for the row
                        return Container(
                          height: _heightPerSegment,
                          decoration: BoxDecoration(
                            border: Border(
                              top: isHourStart && index > 0 
                                ? BorderSide(color: Colors.grey.shade700, width: 0.5) 
                                : BorderSide.none,
                              bottom: !isHourStart 
                                ? BorderSide(color: Colors.grey.shade800.withOpacity(0.3), width: 0.2)
                                : BorderSide.none
                            )
                          ),
                          child: Row(
                            children: [
                              // Time indicator column - only show hours, not 15-minute intervals
                              SizedBox(
                                width: 50,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    border: Border(
                                      right: BorderSide(color: Colors.grey.shade700, width: 1)
                                    )
                                  ),
                                  alignment: Alignment.center,
                                  // Only show time on the hour
                                  child: isHourStart ? Text(
                                    '${hourIndex.toString().padLeft(2, '0')}:00',
                                    style: TextStyle(
                                      color: Colors.white, 
                                      fontSize: 12
                                    ),
                                  ) : null,
                                ),
                              ),
                              
                              // Each day's column for this time slot
                              ...List.generate(7, (dayIndex) {
                                final day = _weekDays[dayIndex];
                                final isToday = _isToday(day);
                                final isSelected = dayIndex == _selectedDayIndex;
                                
                                return Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                        ? Colors.amber.withOpacity(0.1) 
                                        : Colors.transparent,
                                      border: Border(
                                        right: BorderSide(color: Colors.grey.shade700, width: 1)
                                      )
                                    ),
                                    child: _buildTasksForTimeSlot(day, hourIndex, minuteIndex),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            height: 2,
            color: Colors.amber,
          ),
          
          // Task list section (2/5 of the screen)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Tasks for ${DateFormat('EEEE, MMM d').format(_weekDays[_selectedDayIndex])}',
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                      ),
                    ),
                  ),
                  Expanded(
                    child: selectedDayTasks.isEmpty
                        ? Center(
                            child: Text(
                              'No tasks for this day',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            itemCount: selectedDayTasks.length,
                            itemBuilder: (context, index) {
                              final task = selectedDayTasks[index];
                              return Card(
                                color: Colors.grey.shade800,
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                child: ListTile(
                                  leading: Icon(
                                    task.getIcon() ?? Icons.task_alt,
                                    color: task.completed ? Colors.grey : Colors.amber,
                                  ),
                                  title: Text(
                                    task.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      decoration: task.completed 
                                          ? TextDecoration.lineThrough 
                                          : null,
                                    ),
                                  ),
                                  subtitle: task.duration != null 
                                      ? Text(
                                          'Duration: ${task.duration!.inHours}h ${task.duration!.inMinutes % 60}m',
                                          style: TextStyle(color: Colors.white70),
                                        )
                                      : null,
                                  trailing: Checkbox(
                                    value: task.completed,
                                    onChanged: null, // Read-only in calendar view
                                    activeColor: Colors.amber,
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
  
  Widget _buildTasksForTimeSlot(DateTime day, int hour, int minute) {
    // In the future, you can add task scheduling and display tasks at specific time slots
    // For now, we'll just show a placeholder at 9:15 as an example
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      alignment: Alignment.centerLeft,
      child: hour == 9 && minute == 15 && _isToday(day) ? 
        Container(
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: const Text(
            'Example Task',
            style: TextStyle(fontSize: 8),
            overflow: TextOverflow.ellipsis,
          ),
        ) : null,
    );
  }
}
