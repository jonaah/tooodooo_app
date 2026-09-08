import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/models/task.dart';
import 'package:tooodooo_app/util/todo_tile.dart';
import 'package:tooodooo_app/util/slider_element.dart';
import 'package:tooodooo_app/util/dialog_box.dart';
import 'package:tooodooo_app/util/icon_manager.dart';
import 'package:tooodooo_app/util/app_icons.dart';
import 'package:tooodooo_app/util/app_theme.dart';
import 'package:tooodooo_app/pages/settings_page.dart';

export 'package:tooodooo_app/models/task.dart';


class HomePage extends StatefulWidget {
  final Function(List<Task>)? onTasksUpdated;
  final VoidCallback? onSettingsChanged;

  const HomePage({super.key, this.onTasksUpdated, this.onSettingsChanged});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final GlobalKey<SliderElementState> _sliderKey = GlobalKey<SliderElementState>();
  final GlobalKey<DialogBoxState> _dialogKey = GlobalKey<DialogBoxState>();
  List<Task> toDoList = [];
  IconData? selectedIcon;
  int? _editingIndex;
  int durationHours = 0; // Store hours part of duration
  int durationMinutes = 0; // Store minutes part of duration
  Key listViewKey = UniqueKey(); // Key to force ListView rebuild

  late final AnimationController _appBarAnimationController;
  late final Animation<double> _appBarFadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarVisible = true;
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0,
    );
    _appBarFadeAnimation = CurvedAnimation(
      parent: _appBarAnimationController,
      curve: Curves.easeInOut,
    );
    _scrollController.addListener(_onScroll);
    _loadToDoList();
    IconManager.loadRecentIcons(); // Initialize icon manager
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastScrollOffset;

    if (currentOffset <= 0) {
      // Reached the top -> ensure AppBar is fully visible
      if (!_isAppBarVisible) {
        _isAppBarVisible = true;
        _appBarAnimationController.forward();
      }
    } else if (delta > 3 && currentOffset > 20) {
      // Scrolling down past threshold -> dissolve AppBar slowly
      if (_isAppBarVisible) {
        _isAppBarVisible = false;
        _appBarAnimationController.reverse();
      }
    } else if (delta < -3) {
      // Scrolling back up -> reveal AppBar
      if (!_isAppBarVisible) {
        _isAppBarVisible = true;
        _appBarAnimationController.forward();
      }
    }

    _lastScrollOffset = currentOffset;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _appBarAnimationController.dispose();
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
      if (toDoList.isEmpty && !_isAppBarVisible) {
        _isAppBarVisible = true;
        _appBarAnimationController.forward();
      }
    });
    _saveToDoList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.offset <= 0 && !_isAppBarVisible) {
        _isAppBarVisible = true;
        _appBarAnimationController.forward();
      }
    });
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
    final topPadding = MediaQuery.of(context).padding.top;
    final appBarHeight = kToolbarHeight + topPadding;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedBuilder(
          animation: _appBarFadeAnimation,
          builder: (context, child) {
            final opacity = _appBarFadeAnimation.value;
            return Opacity(
              opacity: opacity,
              child: IgnorePointer(
                ignoring: opacity < 0.1,
                child: child,
              ),
            );
          },
          child: AppBar(
            title: const Padding(
              padding: EdgeInsets.only(left: AppTheme.defaultPadding), // Kleiner zusätzlicher Abstand
              child: Text(
                'TO DO',
                style: AppTheme.appBarTitle,
              ),
            ),
            centerTitle: false,
            backgroundColor: AppTheme.backgroundColor.withOpacity(0.2),
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
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
          ),
        ),
      ),
      body: toDoList.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.only(top: appBarHeight),
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
              ),
            )
          : ListView.builder(
              key: listViewKey, // Use dynamic key to force rebuild
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: appBarHeight,
                bottom: 96,
              ),
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
    );
  }
}
