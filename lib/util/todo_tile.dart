import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tooodooo_app/util/app_theme.dart';
import 'package:tooodooo_app/util/PriorityIndicator.dart';

// This file defines a customizable to-do item widget used throughout the app.
// It displays tasks with visual indicators for completion status and priority,
// and supports swipe gestures for editing and deleting tasks.
class ToDoTile extends StatefulWidget {
  final String taskName;
  final bool taskCompleted;
  final double taskPriority;
  final IconData? taskIcon;
  final Duration? taskDuration;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? deleteFunction;
  final Function(BuildContext)? editFunction;
  final List<Map<String, dynamic>>? subtasks; // each: {name: String, completed: bool}
  final Function(int, bool)? onSubtaskChanged; // index, newValue
  final Color? customColor; // user defined base color

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
    this.subtasks,
    this.onSubtaskChanged,
    this.customColor,
  });

  @override
  State<ToDoTile> createState() => _ToDoTileState();
}

class _ToDoTileState extends State<ToDoTile> {
  bool _expanded = false;

  bool get isGroup => (widget.subtasks != null && widget.subtasks!.isNotEmpty);

  int get completedSubtasks => widget.subtasks?.where((s) => s['completed'] == true).length ?? 0;

  @override
  Widget build(BuildContext context) {
    final priorityInt = widget.taskPriority.toInt();

    final neutralBg = widget.customColor != null
        ? widget.customColor!.withOpacity(0.25)
        : Colors.grey[800];

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.largePadding,
        right: AppTheme.largePadding,
        top: AppTheme.largePadding,
      ),
      child: Slidable(
        key: ValueKey(widget.taskName),
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            if (widget.editFunction != null)
              SlidableAction(
                onPressed: widget.editFunction,
                icon: Icons.edit,
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.accentColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: widget.deleteFunction,
              icon: Icons.delete_outline,
              foregroundColor: Colors.white,
              backgroundColor: Colors.red.shade300,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            )
          ],
        ),
        child: InkWell(
          onTap: () {
            if (isGroup) {
              setState(() { _expanded = !_expanded; });
            } else {
              widget.onChanged?.call(!widget.taskCompleted);
            }
          },
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          splashColor: Colors.white.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Ink(
            padding: EdgeInsets.all(AppTheme.defaultPadding),
            decoration: BoxDecoration(
              color: neutralBg,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(color: Colors.white12, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox / group progress toggle
                    GestureDetector(
                      onTap: () {
                        if (isGroup) {
                          // toggle all
                          final newValue = !(completedSubtasks == widget.subtasks!.length);
                          for (int i = 0; i < widget.subtasks!.length; i++) {
                            widget.onSubtaskChanged?.call(i, newValue);
                          }
                        } else {
                          widget.onChanged?.call(!widget.taskCompleted);
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: widget.taskCompleted || (isGroup && completedSubtasks == widget.subtasks!.length)
                              ? Colors.white24
                              : Colors.transparent,
                          border: Border.all(
                            color: AppTheme.getTextColorForPriority(priorityInt).withOpacity(0.8),
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: (widget.taskCompleted || (isGroup && completedSubtasks == widget.subtasks!.length))
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.taskName + (isGroup ? ' (${completedSubtasks}/${widget.subtasks!.length})' : ''),
                                  style: widget.taskCompleted
                                      ? AppTheme.taskCompleted(priorityInt)
                                      : AppTheme.taskTitle(priorityInt),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isGroup)
                                GestureDetector(
                                  onTap: () { setState(() { _expanded = !_expanded; }); },
                                  child: Icon(
                                    _expanded ? Icons.expand_less : Icons.expand_more,
                                    color: AppTheme.getTextColorForPriority(priorityInt),
                                  ),
                                ),
                            ],
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
                                _formattedDuration(),
                                style: widget.taskCompleted
                                    ? AppTheme.taskSubtitleCompleted(priorityInt)
                                    : AppTheme.taskSubtitle(priorityInt),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Right side icon + horizontal priority bar above
                    Column(
                      children: [
                        PriorityIndicator(
                          priority: priorityInt,
                          width: 40,
                          height: 6,
                          vertical: false,
                          activeColor: AppTheme.getPriorityColor(priorityInt),
                          inactiveColor: Colors.white30,
                          borderColor: Colors.transparent,
                          spacing: 1,
                        ),
                        const SizedBox(height: 4),
                        if (widget.taskIcon != null)
                          Icon(
                            widget.taskIcon,
                            size: AppTheme.smallIconSize + 6,
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ],
                ),
                if (isGroup && _expanded) ...[
                  const SizedBox(height: 12),
                    Column(
                      children: [
                      Divider(
                      color: Colors.white24,
                      thickness: 2,
                      height: 8,
                    ),
                  ...List.generate(widget.subtasks!.length * 2 - 1, (i) {
                        if (i.isOdd) {
                          return Divider(
                        color: Colors.white24,
                        thickness: 2,
                        height: 8,
                        );
                        }
                      final subIndex = i ~/ 2;
                      final sub = widget.subtasks![subIndex];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                widget.onSubtaskChanged?.call(subIndex, !(sub['completed'] == true));
                              },
                              child: Container(
                                width: 20,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: sub['completed'] == true ? Colors.white24 : Colors.transparent,
                                  border: Border.all(color: Colors.white70, width: 1.5),
                                  shape: BoxShape.circle,
                                ),
                                child: sub['completed'] == true
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                sub['name'] ?? '',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(sub['completed'] == true ? 0.5 : 0.9),
                                  decoration: sub['completed'] == true ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                        Divider(
                            color: Colors.white24,
                            thickness: 2,
                            height: 8,
                        )
                    ]
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formattedDuration() {
    if (widget.taskDuration == null) return "--:--";
    final hours = widget.taskDuration!.inHours;
    final minutes = widget.taskDuration!.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}