import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ToDoTile extends StatelessWidget {
  final String taskName;
  final bool taskCompleted;
  final double taskPriority;
  final IconData? taskIcon;
  Function(bool?)? onChanged;
  Function(BuildContext)? deleteFunction;

  ToDoTile({
    super.key,
    required this.taskName,
    required this.taskCompleted,
    required this.onChanged,
    required this.deleteFunction,
    required this.taskPriority,
    this.taskIcon,
  });

  Color? taskPriorityColor() {
    switch (taskPriority.toInt()) {
      case 1:
        return Colors.blue[100];
      case 2:
        return Colors.green[100];
      case 3:
        return Colors.yellow[100];
      case 4:
        return Colors.orange[100];
      case 5:
        return Colors.red[100];
      default:
        return Colors.grey[100];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 32, top: 32),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: deleteFunction,
              icon: Icons.delete,
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