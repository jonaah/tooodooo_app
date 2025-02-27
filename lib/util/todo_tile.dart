import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ToDoTile extends StatelessWidget {
  final String taskName;
  final bool taskCompleted;
  final double taskPriority;
  final IconData? taskIcon;
  Function(bool?)? onChanged;
  Function(BuildContext)? deleteFunction;
  Function(BuildContext)? editFunction; // Add edit function

  ToDoTile({
    super.key,
    required this.taskName,
    required this.taskCompleted,
    required this.onChanged,
    required this.deleteFunction,
    required this.taskPriority,
    this.taskIcon,
    this.editFunction, // Add edit function parameter
  });

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
            padding: const EdgeInsets.all(24),
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
                  child: Text(
                    taskName,
                    style: TextStyle(
                      fontSize: 24,
                      decoration: taskCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
                if (taskIcon != null) Icon(taskIcon),
              ],
            ),
          ),
        ),
      ),
    );
  }
}