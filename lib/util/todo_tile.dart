import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tooodooo_app/util/app_theme.dart';

// This file defines a customizable to-do item widget used throughout the app.
// It displays tasks with visual indicators for completion status and priority,
// and supports swipe gestures for editing and deleting tasks.
class ToDoTile extends StatelessWidget {
  final String taskName;
  final bool taskCompleted;
  final double taskPriority;
  final IconData? taskIcon;
  final Duration? taskDuration;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? deleteFunction;
  final Function(BuildContext)? editFunction;

  ToDoTile({
    super.key,
    required this.taskName,
    required this.taskCompleted,
    required this.onChanged,
    required this.deleteFunction,
    required this.taskPriority,
    this.taskIcon,
    this.taskDuration,
    this.editFunction,
  });

  // Returns a color based on the task priority level using our theme
  Color? taskPriorityColor() {
    return AppTheme.getPriorityColor(taskPriority.toInt());
  }

  // Format duration to display in a readable format (e.g. "02:30" format)
  String formattedDuration() {
    if (taskDuration == null) return "--:--";

    final hours = taskDuration!.inHours;
    final minutes = taskDuration!.inMinutes % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Get the priority as int for style lookups
    final priorityInt = taskPriority.toInt();
    
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.largePadding,
        right: AppTheme.largePadding,
        top: AppTheme.largePadding
      ),
      child: Slidable(
        // Start action pane is for swiping from left to right (Edit)
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: editFunction,
              icon: Icons.edit,
              foregroundColor: Colors.white,
              backgroundColor: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
          ],
        ),
        // End action pane is for swiping from right to left (Delete)
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: deleteFunction,
              icon: Icons.delete,
              foregroundColor: Colors.white,
              backgroundColor: Colors.red.shade300,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            )
          ],
        ),
        child: GestureDetector(
          onTap: () {
            onChanged!(!taskCompleted);
          },
          child: Container(
            padding: EdgeInsets.all(AppTheme.defaultPadding),
            decoration: BoxDecoration(
              color: taskPriorityColor(),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Checkbox(
                  value: taskCompleted,
                  onChanged: onChanged,
                  activeColor: AppTheme.primaryColor,
                  checkColor: Colors.white,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taskName,
                        style: taskCompleted 
                            ? AppTheme.taskCompleted(priorityInt)
                            : AppTheme.taskTitle(priorityInt),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppTheme.smallPadding / 2),
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: AppTheme.smallIconSize,
                            color: AppTheme.getTextColorForPriority(priorityInt).withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDuration(),
                            style: taskCompleted 
                                ? AppTheme.taskSubtitleCompleted(priorityInt)
                                : AppTheme.taskSubtitle(priorityInt),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (taskIcon != null) Icon(
                  taskIcon,
                  size: AppTheme.smallIconSize + 4,
                  color: AppTheme.getTextColorForPriority(priorityInt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}