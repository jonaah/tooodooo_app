import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// This file defines a customizable to-do item widget used throughout the app.
// It displays tasks with visual indicators for completion status and priority,
// and supports swipe gestures for editing and deleting tasks.
class ToDoTile extends StatelessWidget {
  final String taskName;
  final bool taskCompleted;
  final double taskPriority;
  final IconData? taskIcon;
  final Duration? taskDuration; // Changed from time to duration
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
    this.taskDuration, // Changed parameter
    this.editFunction,
  });

  // Returns a color based on the task priority level
  // Higher priority tasks have warmer colors (orange/red)
  // Lower priority tasks have cooler colors (blue/green)
  Color? taskPriorityColor() {
    switch (taskPriority.toInt()) {
      case 1:
        return Colors.green[100]; // Lowest priority - relaxed green
      case 2:
        return Colors.blue[100]; // Low priority - calm blue
      case 3:
        return Colors.amber[100]; // Medium priority - attention amber
      case 4:
        return Colors.deepOrange[100]; // High priority - urgent orange
      case 5:
        return Colors.red[100]; // Highest priority - critical red
      default:
        return Colors.grey[100]; // No priority assigned
    }
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
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 32, top: 32),
      child: Slidable(
        // Start action pane is for swiping from left to right (Edit)
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: editFunction,
              icon: Icons.edit,
              foregroundColor: Colors.white, // Ensuring edit icon is white
              backgroundColor: Colors.blue.shade300,
              borderRadius: BorderRadius.circular(12),
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
              foregroundColor: Colors.white, // Ensuring delete icon is white
              backgroundColor: Colors.red.shade300,
              borderRadius: BorderRadius.circular(12),
            )
          ],
        ),
        child: GestureDetector(
          onTap: () {
            onChanged!(!taskCompleted);
          },
          child: Container(
            padding: const EdgeInsets.all(20), // Reduced padding
            decoration: BoxDecoration(
              color: taskPriorityColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: taskCompleted,
                  onChanged: onChanged,
                  activeColor: Colors.black,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taskName,
                        style: TextStyle(
                          fontSize: 18, // Reduced font size
                          decoration: taskCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                        maxLines: 2, // Limit to 2 lines
                        overflow: TextOverflow.ellipsis, // Add ellipsis if text is too long
                      ),
                      const SizedBox(height: 4), // Spacing between name and duration
                      Row(
                        children: [
                          Icon(Icons.timer, size: 14, color: Colors.black54), // Smaller icon
                          const SizedBox(width: 4),
                          Text(
                            formattedDuration(),
                            style: TextStyle(
                              fontSize: 12, // Smaller font size
                              color: Colors.black54,
                              decoration: taskCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (taskIcon != null) Icon(taskIcon, size: 20), // Slightly smaller icon
              ],
            ),
          ),
        ),
      ),
    );
  }
}