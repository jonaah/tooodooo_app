import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tooodooo_app/pages/home_page.dart';
import 'package:tooodooo_app/util/app_theme.dart';
import 'package:tooodooo_app/util/dialog_box.dart';
import 'package:tooodooo_app/util/slider_element.dart';

class TodoSelectionDialog extends StatefulWidget {
  final List<Task> tasks;
  final DateTime selectedDateTime;
  final Function(Task, DateTime) onTaskSelected;
  final Function(String, double, IconData?, Duration?, DateTime) onNewTaskCreated;

  const TodoSelectionDialog({
    super.key,
    required this.tasks,
    required this.selectedDateTime,
    required this.onTaskSelected,
    required this.onNewTaskCreated,
  });

  @override
  State<TodoSelectionDialog> createState() => _TodoSelectionDialogState();
}

class _TodoSelectionDialogState extends State<TodoSelectionDialog> {
  double? _dialogHeight;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.selectedDateTime;
  }

  // Filter for incomplete tasks only
  List<Task> get _incompleteTasks =>
      widget.tasks.where((task) => !task.completed).toList();

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: AppTheme.primaryColor,
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.secondaryTextColor,
              onPrimary: AppTheme.darkTextColor,
              surface: AppTheme.primaryColor,
              onSurface: AppTheme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await AppTheme.showStyledTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _showCreateNewTaskDialog() {
    final TextEditingController controller = TextEditingController();
    final GlobalKey<SliderElementState> sliderKey = GlobalKey<SliderElementState>();
    IconData? selectedIcon;
    int durationHours = 0;
    int durationMinutes = 30; // Default to 30 minutes

    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          controller: controller,
          onSave: () {
            if (controller.text.isNotEmpty) {
              double priorityValue = sliderKey.currentState?.getSliderValue() ?? 3.0;
              Duration taskDuration = Duration(hours: durationHours, minutes: durationMinutes);

              // Close the DialogBox
              Navigator.pop(context);

              // Close the TodoSelectionDialog
              Navigator.pop(context);

              // Create the new task and add it to calendar at _selectedDateTime
              widget.onNewTaskCreated(
                controller.text,
                priorityValue,
                selectedIcon,
                taskDuration,
                _selectedDateTime,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task cannot be empty'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          onCancel: () => Navigator.pop(context),
          sliderKey: sliderKey,
          onIconSelected: (icon) {
            selectedIcon = icon;
          },
          durationHours: durationHours,
          durationMinutes: durationMinutes,
          onDurationChanged: (hours, minutes) {
            durationHours = hours;
            durationMinutes = minutes;
          },
          isEditing: false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd.MM.yyyy').format(_selectedDateTime);
    final formattedTime = DateFormat('HH:mm').format(_selectedDateTime);

    final double screenHeight = MediaQuery.of(context).size.height;
    final double minHeight = screenHeight * 0.45;
    final double maxHeight = screenHeight * 0.94;
    _dialogHeight ??= screenHeight * 0.80;
    final double currentHeight = _dialogHeight!.clamp(minHeight, maxHeight);

    return Dialog(
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.bottomCenter,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        height: currentHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 30,
              spreadRadius: 4,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Resizable Drag Handle & Header
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _dialogHeight = (_dialogHeight! - details.delta.dy).clamp(minHeight, maxHeight);
                  });
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! > 600) {
                    Navigator.pop(context);
                  }
                },
                child: Column(
                  children: [
                    // Modern Drag Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 6),
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryTextColor.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.defaultPadding,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Close button on LEFT
                          SizedBox(
                            width: 68,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: AppTheme.secondaryTextColor),
                                onPressed: () => Navigator.pop(context),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Close',
                              ),
                            ),
                          ),

                          // Centered Title
                          const Expanded(
                            child: Center(
                              child: Text(
                                "Add to Calendar",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryTextColor,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),

                          // Spacer for symmetrical centering
                          const SizedBox(width: 68),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Divider(color: AppTheme.dividerColor, thickness: 2),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 16),

                    // Editable Selected Time Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Selected Time",
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, size: 20, color: AppTheme.accentColor),
                                const SizedBox(width: 10),
                                const Text(
                                  "Start:",
                                  style: TextStyle(
                                    color: AppTheme.secondaryTextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                // Date Picker Button
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.secondaryTextColor.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.calendar_today, size: 13, color: AppTheme.accentColor),
                                        const SizedBox(width: 5),
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.secondaryTextColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Time Picker Button
                                InkWell(
                                  onTap: _pickTime,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.secondaryTextColor.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.access_time, size: 13, color: AppTheme.accentColor),
                                        const SizedBox(width: 5),
                                        Text(
                                          formattedTime,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.secondaryTextColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.dividerColor, thickness: 2),
                    const SizedBox(height: 8),

                    // Create New Task button card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
                      child: InkWell(
                        onTap: _showCreateNewTaskDialog,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                            border: Border.all(
                              color: AppTheme.accentColor.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create New Task',
                                      style: TextStyle(
                                        color: AppTheme.secondaryTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Create and schedule a new task',
                                      style: TextStyle(
                                        color: AppTheme.textColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: AppTheme.secondaryTextColor,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.dividerColor, thickness: 2),
                    const SizedBox(height: 8),

                    // Existing Tasks header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Select Existing Task",
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Choose from your uncompleted tasks:",
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Incomplete Tasks List
                    if (_incompleteTasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.defaultPadding,
                          vertical: 24,
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 40,
                                color: AppTheme.secondaryTextColor.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No incomplete tasks available',
                                style: TextStyle(
                                  color: AppTheme.secondaryTextColor.withValues(alpha: 0.6),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._incompleteTasks.map((task) {
                        final Color taskColor = task.colorValue != null
                            ? Color(task.colorValue!)
                            : AppTheme.getCalendarTaskColor(task.priority.toInt());

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.defaultPadding,
                            vertical: 4,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                widget.onTaskSelected(task, _selectedDateTime);
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                  border: Border.all(
                                    color: AppTheme.dividerColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: taskColor.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: taskColor, width: 1.5),
                                      ),
                                      child: Icon(
                                        task.getIcon() ?? Icons.task_alt,
                                        color: taskColor,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.name,
                                            style: const TextStyle(
                                              color: AppTheme.secondaryTextColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            task.duration != null
                                                ? 'Duration: ${task.duration!.inHours}h ${task.duration!.inMinutes % 60}m'
                                                : 'No duration set (30 min default)',
                                            style: TextStyle(
                                              color: AppTheme.textColor.withValues(alpha: 0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: AppTheme.secondaryTextColor.withValues(alpha: 0.4),
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}