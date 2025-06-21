import 'package:flutter/material.dart';
import 'package:tooodooo_app/pages/home_page.dart';
import 'package:tooodooo_app/util/app_theme.dart';
import 'package:tooodooo_app/util/dialog_box.dart';
import 'package:tooodooo_app/util/slider_element.dart';

class TodoSelectionDialog extends StatefulWidget {
  final List<Task> tasks;
  final DateTime selectedDateTime;
  final Function(Task) onTaskSelected;
  final Function(String, double, IconData?, Duration?) onNewTaskCreated;

  const TodoSelectionDialog({
    Key? key,
    required this.tasks,
    required this.selectedDateTime,
    required this.onTaskSelected,
    required this.onNewTaskCreated,
  }) : super(key: key);

  @override
  State<TodoSelectionDialog> createState() => _TodoSelectionDialogState();
}

class _TodoSelectionDialogState extends State<TodoSelectionDialog> {
  // Filter for incomplete tasks only
  List<Task> get _incompleteTasks => 
    widget.tasks.where((task) => !task.completed).toList();

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
              
              // Create the new task and add it to calendar
              widget.onNewTaskCreated(
                controller.text,
                priorityValue, 
                selectedIcon,
                taskDuration
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
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = '${widget.selectedDateTime.day}/${widget.selectedDateTime.month}/${widget.selectedDateTime.year}';
    final formattedTime = '${widget.selectedDateTime.hour.toString().padLeft(2, '0')}:${widget.selectedDateTime.minute.toString().padLeft(2, '0')}';
    
    return Dialog(
      backgroundColor: AppTheme.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Task to Calendar',
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Selected Time: $formattedDate at $formattedTime',
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            
            // New Task option button
            InkWell(
              onTap: _showCreateNewTaskDialog,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Create New Task',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Text(
              'Or select an existing task:',
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: _incompleteTasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.defaultPadding),
                      child: Text(
                        'No incomplete tasks available',
                        style: TextStyle(color: AppTheme.textColor.withOpacity(0.7)),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _incompleteTasks.length,
                    itemBuilder: (context, index) {
                      final task = _incompleteTasks[index];
                      final taskColor = AppTheme.getCalendarTaskColor(task.priority.toInt());
                      
                      return Card(
                        color: Colors.grey.shade800,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                        ),
                        child: ListTile(
                          leading: Icon(
                            task.getIcon() ?? Icons.task_alt,
                            color: taskColor,
                          ),
                          title: Text(
                            task.name,
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: task.duration != null
                            ? Text(
                                'Duration: ${task.duration!.inHours}h ${task.duration!.inMinutes % 60}m',
                                style: TextStyle(
                                  color: AppTheme.textColor.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              )
                            : Text(
                                'No duration set (will use 30min default)',
                                style: TextStyle(
                                  color: AppTheme.textColor.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: AppTheme.textColor.withOpacity(0.5),
                            size: 16,
                          ),
                          onTap: () {
                            // Return the selected task
                            widget.onTaskSelected(task);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textColor,
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}