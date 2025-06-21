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

  const ToDoTile({
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
        key: ValueKey(taskName), // <-- Add a unique key for each tile
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
              icon: Icons.delete_outline,
              foregroundColor: Colors.white,
              backgroundColor: Colors.red.shade300,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            )
          ],
        ),
        child: InkWell(
          onTap: () {
            onChanged!(!taskCompleted);
          },
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.2),
          child: Ink(
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
                // Circular checkbox design, consistent with the today_tasks_page
                GestureDetector(
                  onTap: () {
                    onChanged!(!taskCompleted);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: taskCompleted ? Colors.black38 : Colors.transparent,
                      border: Border.all(
                        color: AppTheme.getTextColorForPriority(priorityInt).withOpacity(0.8),
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: taskCompleted
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: AppTheme.getTextColorForPriority(priorityInt),
                          )
                        : null,
                  ),
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