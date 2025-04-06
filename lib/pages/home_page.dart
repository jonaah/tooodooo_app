import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/util/todo_tile.dart';
import 'package:tooodooo_app/util/slider_element.dart';
import 'package:tooodooo_app/util/dialog_box.dart';
import 'package:tooodooo_app/util/icon_manager.dart';
import 'package:tooodooo_app/util/app_icons.dart';

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
  const HomePage({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadToDoList();
    IconManager.loadRecentIcons(); // Initialize icon manager
  }

  // Aufgabenliste laden und in die toDoList einfügen
  void _loadToDoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? toDoListString = prefs.getString('toDoList');
    if (toDoListString != null) {
      List<dynamic> decodedList = jsonDecode(toDoListString);
      setState(() {
        toDoList = decodedList.map((item) => Task.fromJson(item)).toList();
      });
    }
  }

  // Speichert die aktuelle Aufgabenliste
  void _saveToDoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('toDoList', jsonEncode(toDoList.map((task) => task.toJson()).toList()));
  }

  void checkBoxChanged(bool? value, int index) {
    setState(() {
      toDoList[index].completed = value!;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 87, 89, 90),
      appBar: AppBar(
        title: const Text(
            'TO DO',
            style: TextStyle(
                color: Color.fromARGB(255, 222, 222, 222),
                fontSize: 32,
                fontWeight: FontWeight.bold
            )
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 73, 68, 67),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        backgroundColor: const Color.fromARGB(255, 73, 68, 67),
        child: const Icon(
          Icons.add,
          color: Colors.white, // Set the icon color to white
        ),
      ),
      body: ListView.builder(
        itemCount: toDoList.length,
        itemBuilder: (context, index) {
          return ToDoTile(
            taskName: toDoList[index].name,
            taskCompleted: toDoList[index].completed,
            taskPriority: toDoList[index].priority,
            taskIcon: toDoList[index].getIcon(),
            taskDuration: toDoList[index].duration, // Pass duration instead of time
            onChanged: (value) => checkBoxChanged(value, index),
            deleteFunction: (context) => deleteTask(index),
            editFunction: (context) => editTask(index),
          );
        },
      ),
    );
  }
}
