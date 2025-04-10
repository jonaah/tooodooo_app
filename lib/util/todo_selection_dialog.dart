import 'package:flutter/material.dart';
import 'package:tooodooo_app/pages/home_page.dart';
import 'package:tooodooo_app/util/app_theme.dart';

class TodoSelectionDialog extends StatefulWidget {
  final List<Task> tasks;
  final DateTime selectedDateTime;
  final Function(Task) onTaskSelected;

  const TodoSelectionDialog({
    Key? key,
    required this.tasks,
    required this.selectedDateTime,
    required this.onTaskSelected,
  }) : super(key: key);

  @override
  State<TodoSelectionDialog> createState() => _TodoSelectionDialogState();
}

class _TodoSelectionDialogState extends State<TodoSelectionDialog> {
  // Filter for incomplete tasks only
  List<Task> get _incompleteTasks => 
    widget.tasks.where((task) => !task.completed).toList();

  @override
  Widget build(BuildContext context) {
    final formattedDate = '${widget.selectedDateTime.day}/${widget.selectedDateTime.month}/${widget.selectedDateTime.year}';
    final formattedTime = '${widget.selectedDateTime.hour.toString().padLeft(2, '0')}:${widget.selectedDateTime.minute.toString().padLeft(2, '0')}';
    
    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
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
                color: AppTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Selected Time: $formattedDate at $formattedTime',
              style: TextStyle(
                color: AppTheme.textColor.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a task to add:',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
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
                                'No duration set',
                                style: TextStyle(
                                  color: Colors.red.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: AppTheme.textColor.withOpacity(0.5),
                            size: 16,
                          ),
                          onTap: () {
                            if (task.duration == null) {
                              // Show warning for tasks without duration
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Task needs a duration to be added to calendar'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else {
                              // Return the selected task
                              widget.onTaskSelected(task);
                              Navigator.pop(context);
                            }
                          },
                        ),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 16),
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