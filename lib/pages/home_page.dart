import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/util/todo_tile.dart';
import 'package:tooodooo_app/util/slider_element.dart';
import 'package:tooodooo_app/util/dialog_box.dart';
import 'package:tooodooo_app/util/icon_manager.dart';

class Task {
  String name;
  bool completed;
  double priority;
  int? iconCodePoint;

  Task(this.name, this.completed, this.priority, this.iconCodePoint);

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    json['name'],
    json['completed'],
    json['priority'],
    json['iconCodePoint'],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'completed': completed,
    'priority': priority,
    'iconCodePoint': iconCodePoint,
  };
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
  int? _editingIndex; // Track which task is being edited

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
        toDoList.add(Task(_controller.text, false, sliderValue, selectedIcon?.codePoint));
        sortTasksByPriority(); // Sortiert die Liste nach Priorität
        _saveToDoList();
        Navigator.pop(context); // Dialog schließen
      });
      _controller.clear();
      selectedIcon = null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task cannot be empty'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
    selectedIcon = toDoList[index].iconCodePoint != null ? 
                  IconData(toDoList[index].iconCodePoint!, fontFamily: 'MaterialIcons') : null;
    
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
            Navigator.pop(context);
          },
          sliderKey: _sliderKey,
          onIconSelected: (icon) {
            // Avoid using setState during build
            // Instead, update the state only when dialog is fully rendered
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                selectedIcon = icon;
              });
            });
          },
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
        toDoList[_editingIndex!].iconCodePoint = selectedIcon?.codePoint;
        
        sortTasksByPriority();
        _saveToDoList();
        
        _editingIndex = null;
        _controller.clear();
        selectedIcon = null;
        
        Navigator.pop(context);
      });
    }
  }

  // Create a new task (existing function)
  void createNewTask() {
    _editingIndex = null;
    _controller.clear();
    selectedIcon = null;
    
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
          isEditing: false,
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[400],
      appBar: AppBar(
        title: const Text(
            'TO DO',
            style: TextStyle(
                color: Colors.black,
                fontSize: 32,
                fontWeight: FontWeight.bold
            )
        ),
        centerTitle: true,
        backgroundColor: Colors.brown[400],
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        backgroundColor: Colors.brown[400],
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: toDoList.length,
        itemBuilder: (context, index) {
          return ToDoTile(
            taskName: toDoList[index].name,
            taskCompleted: toDoList[index].completed,
            taskPriority: toDoList[index].priority,
            taskIcon: toDoList[index].iconCodePoint != null ? IconData(toDoList[index].iconCodePoint!, fontFamily: 'MaterialIcons') : null,
            onChanged: (value) => checkBoxChanged(value, index),
            deleteFunction: (context) => deleteTask(index),
            editFunction: (context) => editTask(index), // Add edit function
          );
        },
      ),
    );
  }
}
