import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/util/todo_tile.dart';
import 'package:tooodooo_app/util/slider_element.dart';
import 'package:tooodooo_app/util/dialog_box.dart';
import 'package:tooodooo_app/util/icon_manager.dart';
import 'package:tooodooo_app/util/app_icons.dart';
import 'package:tooodooo_app/util/app_theme.dart';

class Task {
  String name;
  bool completed;
  double priority;
  String? iconName;
  Duration? duration; // Changed from time to duration

  Task(this.name, this.completed, this.priority, this.iconName, [this.duration]); // Optional duration parameter

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    json['name'],
    json['completed'],
    json['priority'],
    json['iconName'],
    json['duration'] != null ? Duration(minutes: json['duration']) : null, // Parse duration in minutes
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'completed': completed,
    'priority': priority,
    'iconName': iconName,
    'duration': duration?.inMinutes, // Store duration as minutes
  };

  IconData? getIcon() {
    return AppIcons.getIcon(iconName);
  }
}


class HomePage extends StatefulWidget {
  final Function(List<Task>)? onTasksUpdated;
  
  const HomePage({super.key, this.onTasksUpdated});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  final GlobalKey<SliderElementState> _sliderKey = GlobalKey<SliderElementState>();
  List<Task> toDoList = [];
  IconData? selectedIcon;
  int? _editingIndex;
  int durationHours = 0; // Store hours part of duration
  int durationMinutes = 0; // Store minutes part of duration
  
  // Track view mode: 0 = All Tasks, 1 = Today's Tasks (planned in calendar)
  int _viewMode = 0;
  
  // List of appointments from calendar (populated in initState)
  List<String> _calendarTaskNames = [];

  @override
  void initState() {
    super.initState();
    _loadToDoList();
    _loadCalendarTasks();
    IconManager.loadRecentIcons(); // Initialize icon manager
  }

  // Update the parent navigator whenever todo list changes
  void _notifyTasksUpdated() {
    if (widget.onTasksUpdated != null) {
      widget.onTasksUpdated!(toDoList);
    }
  }

  // Aufgabenliste laden und in die toDoList einfügen
  void _loadToDoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? toDoListString = prefs.getString('toDoList');
    if (toDoListString != null) {
      List<dynamic> decodedList = jsonDecode(toDoListString);
      setState(() {
        toDoList = decodedList.map((item) => Task.fromJson(item)).toList();
        _notifyTasksUpdated(); // Notify after loading
      });
    }
  }
  
  // Load tasks from calendar
  void _loadCalendarTasks() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? appointmentsJson = prefs.getString('calendar_appointments');
      
      if (appointmentsJson != null && appointmentsJson.isNotEmpty) {
        final List<dynamic> appointments = jsonDecode(appointmentsJson);
        
        setState(() {
          _calendarTaskNames = appointments
              .map<String>((appointment) => appointment['subject'] as String)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading calendar tasks: $e');
    }
  }

  // Speichert die aktuelle Aufgabenliste
  void _saveToDoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('toDoList', jsonEncode(toDoList.map((task) => task.toJson()).toList()));
    _notifyTasksUpdated(); // Notify after saving
  }

  // Get filtered tasks based on current view mode
  List<Task> get _filteredTasks {
    if (_viewMode == 0) {
      // All tasks mode - return the full list
      return toDoList;
    } else {
      // Today's tasks mode - return only tasks in the calendar
      return toDoList.where((task) => 
        _calendarTaskNames.contains(task.name)).toList();
    }
  }

  void checkBoxChanged(bool? value, int index) {
    // Find actual task index in the full list
    final task = _filteredTasks[index];
    final fullListIndex = toDoList.indexWhere((t) => t.name == task.name);
    
    if (fullListIndex != -1) {
      setState(() {
        toDoList[fullListIndex].completed = value!;
      });
      _saveToDoList();
    }
  }

  void saveNewTask() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        double sliderValue = _sliderKey.currentState?.getSliderValue() ?? 1.0;
        String? iconName = AppIcons.getName(selectedIcon);
        
        // Create duration from hours and minutes if any are set
        Duration? taskDuration;
        if (durationHours > 0 || durationMinutes > 0) {
          taskDuration = Duration(
            hours: durationHours,
            minutes: durationMinutes
          );
        }
        
        toDoList.add(Task(_controller.text, false, sliderValue, iconName, taskDuration));
        sortTasksByPriority();
        _saveToDoList();
        Navigator.pop(context);
      });
      _controller.clear();
      selectedIcon = null;
      durationHours = 0;
      durationMinutes = 0;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task cannot be empty'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Reset the duration values
  void resetDuration() {
    setState(() {
      durationHours = 0;
      durationMinutes = 0;
    });
  }

  // Update duration values
  void setDuration(int hours, int minutes) {
    setState(() {
      durationHours = hours;
      durationMinutes = minutes;
    });
  }

  // Sortieren nach Priorität, höher priorisierte Aufgaben erscheinen oben
  void sortTasksByPriority() {
    setState(() {
      toDoList.sort((a, b) => b.priority.compareTo(a.priority));
    });
  }

  // Löschen einer Aufgabe
  void deleteTask(int index) {
    // Get the actual task from the filtered list
    final task = _filteredTasks[index];
    
    // Find it in the main list and remove it
    setState(() {
      toDoList.removeWhere((t) => t.name == task.name);
    });
    _saveToDoList();
  }

  // Edit an existing task
  void editTask(int index) {
    // Get the task from filtered list
    final task = _filteredTasks[index];
    
    // Find the actual index in the full list
    final fullListIndex = toDoList.indexWhere((t) => t.name == task.name);
    if (fullListIndex == -1) return;
    
    _editingIndex = fullListIndex;
    _controller.text = toDoList[fullListIndex].name;
    selectedIcon = toDoList[fullListIndex].getIcon();
    
    // Set initial duration if exists
    if (toDoList[fullListIndex].duration != null) {
      durationHours = toDoList[fullListIndex].duration!.inHours;
      durationMinutes = toDoList[fullListIndex].duration!.inMinutes % 60;
    } else {
      durationHours = 0;
      durationMinutes = 0;
    }
    
    final initialPriority = toDoList[fullListIndex].priority;
    final initialIcon = selectedIcon;
    
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          controller: _controller,
          onSave: saveEditedTask,
          onCancel: () {
            _editingIndex = null;
            _controller.clear();
            selectedIcon = null;
            resetDuration();
            Navigator.pop(context);
          },
          sliderKey: _sliderKey,
          onIconSelected: (icon) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                selectedIcon = icon;
              });
            });
          },
          durationHours: durationHours,
          durationMinutes: durationMinutes,
          onDurationChanged: setDuration,
          isEditing: true,
          initialIcon: initialIcon,
          initialPriority: initialPriority,
        );
      }
    );
  }

  // Save the edited task
  void saveEditedTask() {
    if (_editingIndex != null && _controller.text.isNotEmpty) {
      setState(() {
        double sliderValue = _sliderKey.currentState?.getSliderValue() ?? 1.0;
        toDoList[_editingIndex!].name = _controller.text;
        toDoList[_editingIndex!].priority = sliderValue;
        toDoList[_editingIndex!].iconName = AppIcons.getName(selectedIcon);
        
        // Update duration
        if (durationHours > 0 || durationMinutes > 0) {
          toDoList[_editingIndex!].duration = Duration(
            hours: durationHours,
            minutes: durationMinutes
          );
        } else {
          toDoList[_editingIndex!].duration = null;
        }
        
        sortTasksByPriority();
        _saveToDoList();
        
        _editingIndex = null;
        _controller.clear();
        selectedIcon = null;
        resetDuration();
        
        Navigator.pop(context);
      });
    }
  }

  // Create a new task
  void createNewTask() {
    _editingIndex = null;
    _controller.clear();
    selectedIcon = null;
    resetDuration();
    
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          controller: _controller,
          onSave: saveNewTask,
          onCancel: () => Navigator.pop(context),
          sliderKey: _sliderKey,
          onIconSelected: (icon) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                selectedIcon = icon;
              });
            });
          },
          durationHours: durationHours,
          durationMinutes: durationMinutes,
          onDurationChanged: setDuration,
          isEditing: false,
        );
      }
    );
  }
  
  // Toggle view mode between all tasks and scheduled tasks
  void _toggleViewMode() {
    // Refresh calendar tasks before toggling view
    _loadCalendarTasks();
    
    setState(() {
      _viewMode = _viewMode == 0 ? 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get filtered tasks based on view mode
    final displayTasks = _filteredTasks;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
            'TO DO',
            style: AppTheme.appBarTitle
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          // Toggle button for view mode
          TextButton.icon(
            onPressed: _toggleViewMode,
            icon: Icon(
              _viewMode == 0 ? Icons.calendar_today : Icons.list,
              color: AppTheme.textColor,
            ),
            label: Text(
              _viewMode == 0 ? "Today's Tasks" : "All Tasks",
              style: TextStyle(color: AppTheme.textColor),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(
          Icons.add,
          color: AppTheme.textColor,
        ),
      ),
      body: Column(
        children: [
          // Info bar for Today's Tasks view
          if (_viewMode == 1) Container(
            padding: EdgeInsets.all(AppTheme.smallPadding),
            color: AppTheme.accentColor.withOpacity(0.3),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.textColor, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing only tasks scheduled in your calendar',
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Empty state when no scheduled tasks
          if (_viewMode == 1 && displayTasks.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: AppTheme.textColor.withOpacity(0.5),
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No tasks scheduled for today',
                      style: TextStyle(
                        color: AppTheme.textColor.withOpacity(0.7),
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add tasks to your calendar in the Calendar tab',
                      style: TextStyle(
                        color: AppTheme.textColor.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: displayTasks.length,
                itemBuilder: (context, index) {
                  return ToDoTile(
                    taskName: displayTasks[index].name,
                    taskCompleted: displayTasks[index].completed,
                    taskPriority: displayTasks[index].priority,
                    taskIcon: displayTasks[index].getIcon(),
                    taskDuration: displayTasks[index].duration,
                    onChanged: (value) => checkBoxChanged(value, index),
                    deleteFunction: (context) => deleteTask(index),
                    editFunction: (context) => editTask(index),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
