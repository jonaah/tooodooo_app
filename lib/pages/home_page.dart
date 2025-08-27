import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/util/todo_tile.dart';
import 'package:tooodooo_app/util/slider_element.dart';
import 'package:tooodooo_app/util/dialog_box.dart';
import 'package:tooodooo_app/util/icon_manager.dart';
import 'package:tooodooo_app/util/app_icons.dart';
import 'package:tooodooo_app/util/app_theme.dart';
import 'package:tooodooo_app/pages/settings_page.dart';

class SubTask {
  String name;
  bool completed;
  SubTask(this.name, {this.completed = false});

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
    json['name'],
    completed: json['completed'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'completed': completed,
  };
}

class Task {
  String name;
  bool completed; // for single task OR overall completion (all subtasks)
  double priority;
  String? iconName;
  Duration? duration; // Changed from time to duration
  bool isGroup;
  List<SubTask> subtasks;
  int? colorValue; // custom color (ARGB) optional

  Task(this.name, this.completed, this.priority, this.iconName, [this.duration, this.isGroup = false, List<SubTask>? subtasks, this.colorValue])
      : subtasks = subtasks ?? [];

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        json['name'],
        json['completed'],
        (json['priority'] as num).toDouble(),
        json['iconName'],
        json['duration'] != null ? Duration(minutes: json['duration']) : null,
        json['isGroup'] ?? false,
        (json['subtasks'] as List?)?.map<SubTask>((e) => SubTask.fromJson((e as Map).cast<String, dynamic>())).toList(),
        json['colorValue'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'completed': completed,
        'priority': priority,
        'iconName': iconName,
        'duration': duration?.inMinutes,
        'isGroup': isGroup,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'colorValue': colorValue,
      };

  IconData? getIcon() {
    return AppIcons.getIcon(iconName);
  }

  void recalcCompletion() {
    if (isGroup) {
      completed = subtasks.isNotEmpty && subtasks.every((s) => s.completed);
    }
  }
}


class HomePage extends StatefulWidget {
  final Function(List<Task>)? onTasksUpdated;
  final VoidCallback? onSettingsChanged;

  const HomePage({super.key, this.onTasksUpdated, this.onSettingsChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final GlobalKey<SliderElementState> _sliderKey = GlobalKey<SliderElementState>();
  final GlobalKey<DialogBoxState> _dialogKey = GlobalKey<DialogBoxState>();
  List<Task> toDoList = [];
  IconData? selectedIcon;
  int? _editingIndex;
  int durationHours = 0; // Store hours part of duration
  int durationMinutes = 0; // Store minutes part of duration
  Key listViewKey = UniqueKey(); // Key to force ListView rebuild

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadToDoList();
    IconManager.loadRecentIcons(); // Initialize icon manager
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        listViewKey = UniqueKey(); // Force ListView to rebuild on resume
      });
    }
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

  // Speichert die aktuelle Aufgabenliste
  void _saveToDoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('toDoList', jsonEncode(toDoList.map((task) => task.toJson()).toList()));
    _notifyTasksUpdated(); // Notify after saving
  }

  void checkBoxChanged(bool? value, int index) {
    setState(() {
      if (toDoList[index].isGroup) {
        // toggle all subtasks
        final newVal = !(toDoList[index].subtasks.every((s) => s.completed));
        for (final s in toDoList[index].subtasks) {
          s.completed = newVal;
        }
        toDoList[index].recalcCompletion();
      } else {
        toDoList[index].completed = value!;
      }
    });
    _saveToDoList();
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
        
        toDoList.add(Task(
          _controller.text,
          false,
          sliderValue,
          iconName,
          taskDuration,
          _dialogKey.currentState?.isGroup ?? false,
          (_dialogKey.currentState?.buildSubtasksCopy() ?? [])
              .map((m) => SubTask(m['name'] as String, completed: m['completed'] == true))
              .toList(),
          _dialogKey.currentState?.selectedColorValue?.value,
        ));
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
    setState(() {
      toDoList.removeAt(index);
    });
    _saveToDoList();
  }

  // Edit an existing task
  void editTask(int index) {
    _editingIndex = index;
    _controller.text = toDoList[index].name;
    selectedIcon = toDoList[index].getIcon();
    
    // Set initial duration if exists
    if (toDoList[index].duration != null) {
      durationHours = toDoList[index].duration!.inHours;
      durationMinutes = toDoList[index].duration!.inMinutes % 60;
    } else {
      durationHours = 0;
      durationMinutes = 0;
    }
    
    final initialPriority = toDoList[index].priority;
    final initialIcon = selectedIcon;
    
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          key: _dialogKey,
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
          initialIsGroup: toDoList[index].isGroup,
          initialSubtasks: toDoList[index].subtasks.map((s) => {'name': s.name, 'completed': s.completed}).toList(),
          initialColor: toDoList[index].colorValue != null ? Color(toDoList[index].colorValue!) : null,
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
        toDoList[_editingIndex!].isGroup = _dialogKey.currentState?.isGroup ?? false;
        toDoList[_editingIndex!].subtasks = (_dialogKey.currentState?.buildSubtasksCopy() ?? [])
            .map((m) => SubTask(m['name'] as String, completed: m['completed'] == true))
            .toList();
        toDoList[_editingIndex!].recalcCompletion();
        toDoList[_editingIndex!].colorValue = _dialogKey.currentState?.selectedColorValue?.value;

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
            key: _dialogKey,
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
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
            'TO DO',
            style: AppTheme.appBarTitle
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage(
                  onSettingsSaved: () {
                    widget.onSettingsChanged?.call();
                  },
                )),
              );
            },
          ),
        ],
        surfaceTintColor: AppTheme.primaryColor,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: createNewTask,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(
          Icons.add,
          color: AppTheme.textColor,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: toDoList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_box_outline_blank,
                          color: AppTheme.textColor.withOpacity(0.5),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks yet',
                          style: TextStyle(
                            color: AppTheme.textColor.withOpacity(0.7),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add a new task',
                          style: TextStyle(
                            color: AppTheme.textColor.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    key: listViewKey, // Use dynamic key to force rebuild
                    itemCount: toDoList.length,
                    itemBuilder: (context, index) {
                      return ToDoTile(
                        taskName: toDoList[index].name,
                        taskCompleted: toDoList[index].completed,
                        taskPriority: toDoList[index].priority,
                        taskIcon: toDoList[index].getIcon(),
                        taskDuration: toDoList[index].duration,
                        customColor: toDoList[index].colorValue != null ? Color(toDoList[index].colorValue!) : null,
                        onChanged: (value) => checkBoxChanged(value, index),
                        deleteFunction: (context) => deleteTask(index),
                        editFunction: (context) => editTask(index),
                        subtasks: toDoList[index].isGroup
                            ? toDoList[index]
                                .subtasks
                                .map((s) => {'name': s.name, 'completed': s.completed})
                                .toList()
                            : null,
                        onSubtaskChanged: (subIndex, newVal) {
                          setState(() {
                            toDoList[index].subtasks[subIndex].completed = newVal;
                            toDoList[index].recalcCompletion();
                          });
                          _saveToDoList();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
