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
  
  // Keys for each page to allow refreshing them and triggering actions
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();
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

  void _onActionButtonPressed() {
    if (_selectedIndex == 0) {
      _homePageKey.currentState?.createNewTask();
    } else if (_selectedIndex == 1) {
      _todayPageKey.currentState?.goToToday();
    } else if (_selectedIndex == 2) {
      _calendarPageKey.currentState?.showAddTaskDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              HomePage(
                key: _homePageKey,
                onTasksUpdated: updateTasks,
                onSettingsChanged: handleSettingsChanged,
              ),
              TodayTasksPage(
                key: _todayPageKey,
                tasks: _tasks,
                onTaskRemoved: handleTaskRemoved,
                onGoToCalendar: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              CalendarPage(
                key: _calendarPageKey,
                tasks: _tasks,
                onAppointmentsChanged: handleAppointmentsChanged,
              ),
            ],
          ),
          Positioned(
            left: AppTheme.largePadding,
            right: AppTheme.largePadding,
            bottom: bottomPadding > 0 ? AppTheme.largePadding : AppTheme.defaultPadding,
            child: Row(
              children: [
                Expanded(
                  child: _buildNavigationPill(),
                ),
                const SizedBox(width: 12),
                _buildCircleActionButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationPill() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            spreadRadius: 0,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            spreadRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            index: 0,
            label: 'Tasks',
            activeIcon: Icons.check_box,
            inactiveIcon: Icons.check_box_outlined,
          ),
          _buildNavItem(
            index: 1,
            label: 'Today',
            activeIcon: Icons.today,
            inactiveIcon: Icons.today_outlined,
          ),
          _buildNavItem(
            index: 2,
            label: 'Calendar',
            activeIcon: Icons.calendar_month,
            inactiveIcon: Icons.calendar_month_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 84,
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    size: 22,
                    color: isSelected ? AppTheme.primaryColor : const Color(0xFF8E9BAE),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.primaryColor : const Color(0xFF8E9BAE),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleActionButton() {
    IconData icon;
    String tooltip;

    if (_selectedIndex == 0) {
      icon = Icons.add;
      tooltip = 'New Task';
    } else if (_selectedIndex == 1) {
      icon = Icons.today;
      tooltip = 'Go to Today';
    } else {
      icon = Icons.add_task;
      tooltip = 'Add to Calendar';
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            spreadRadius: 0,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            spreadRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _onActionButtonPressed,
          child: Tooltip(
            message: tooltip,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Icon(
                  icon,
                  key: ValueKey<IconData>(icon),
                  size: 28,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
