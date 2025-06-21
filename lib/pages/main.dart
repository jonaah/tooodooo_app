import 'package:flutter/material.dart';
import 'package:tooodooo_app/pages/home_page.dart';
import 'package:tooodooo_app/pages/calendar_page.dart';
import 'package:tooodooo_app/pages/today_tasks_page.dart';
import 'package:tooodooo_app/util/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainNavigator(),
      theme: AppTheme.themeData,
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;
  final List<Task> _tasks = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Keys for each page to allow refreshing them
  final GlobalKey<_MainNavigatorState> _navigatorKey = GlobalKey();
  final GlobalKey<TodayTasksPageState> _todayPageKey = GlobalKey();
  final GlobalKey<CalendarPageState> _calendarPageKey = GlobalKey();

  // Method to update tasks from HomePage
  void updateTasks(List<Task> newTasks) {
    setState(() {
      _tasks.clear();
      _tasks.addAll(newTasks);
    });
  }
  
  // Method to handle changes in appointments
  void handleAppointmentsChanged(String action) {
    // Force refresh of the Today page when calendar appointments change
    if (_todayPageKey.currentState != null) {
      _todayPageKey.currentState!.refreshAppointments();
    }
  }
  
  // Method to handle task removal from Today page
  void handleTaskRemoved(String action) {
    // Force refresh of the Calendar page when a task is removed from Today page
    if (_calendarPageKey.currentState != null) {
      _calendarPageKey.currentState!.refreshAppointments();
    }
  }

  // Method to handle settings changes from SettingsPage
  void handleSettingsChanged() {
    if (_calendarPageKey.currentState != null) {
      _calendarPageKey.currentState!.refreshSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePage(
            onTasksUpdated: updateTasks,
            onSettingsChanged: handleSettingsChanged,
          ),
          TodayTasksPage(
            key: _todayPageKey,
            tasks: _tasks,
            onTaskRemoved: handleTaskRemoved,
          ),
          CalendarPage(
            key: _calendarPageKey,
            tasks: _tasks,
            onAppointmentsChanged: handleAppointmentsChanged,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: AppTheme.primaryColor,
        selectedItemColor: AppTheme.accentColor,
        unselectedItemColor: AppTheme.textColor,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }
}
