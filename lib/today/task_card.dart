import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';
import 'package:tooodooo_app/util/PriorityIndicator.dart';
import 'package:tooodooo_app/util/app_icons.dart';
import 'package:tooodooo_app/util/app_theme.dart';

class TaskCard extends StatelessWidget {
  final CalendarAppointment appointment;
  final bool isCurrentTask;
  final bool isPastTask;
  final bool isPendingTask;
  final bool isUpcomingTask;
  final bool isCompletedTask;
  final bool showRemainingTime;
  final Function(CalendarAppointment) onTaskCompleted;
  final Function(CalendarAppointment) onTaskIncomplete;
  final Function(CalendarAppointment) onTaskRemoved;

  const TaskCard({
    super.key,
    required this.appointment,
    this.isCurrentTask = false,
    this.isPastTask = false,
    this.isPendingTask = false,
    this.isUpcomingTask = false,
    this.isCompletedTask = false,
    this.showRemainingTime = true,
    required this.onTaskCompleted,
    required this.onTaskIncomplete,
    required this.onTaskRemoved,
  });

  // Format time as "9:30 AM"
  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress for current tasks
    double? progress;
    if (isCurrentTask) {
      final totalDuration = appointment.endTime.difference(appointment.startTime).inMinutes;
      final elapsedDuration = DateTime.now().difference(appointment.startTime).inMinutes;
      progress = totalDuration <= 0 ? 1 : (elapsedDuration / totalDuration).clamp(0.0, 1.0);
    }
    
    // Duration / time strings
    final durationMinutes = appointment.endTime.difference(appointment.startTime).inMinutes;
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    final durationText = hours > 0 
        ? '${hours}h${minutes > 0 ? ' ${minutes}m' : ''}'
        : '${minutes}m';
    final timeRangeText = '${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}';
    
    // Remaining time label for upcoming
    String? remainingTimeText;
    if (isUpcomingTask && showRemainingTime) {
      final remainingMinutes = appointment.startTime.difference(DateTime.now()).inMinutes;
      if (remainingMinutes >= 0) {
        if (remainingMinutes < 60) {
          remainingTimeText = 'In $remainingMinutes m';
        } else if (remainingMinutes < 24 * 60) {
          final rh = remainingMinutes ~/ 60;
            final rm = remainingMinutes % 60;
            remainingTimeText = 'In ${rh}h${rm > 0 ? ' ${rm}m' : ''}';
        }
      }
    }

    // Visual styling (neutral background + subtle accent border)
    final priority = (appointment.priority ?? 3).clamp(1,5);
    final customColor = appointment.customColorValue != null ? Color(appointment.customColorValue!) : null;
    final priorityColor = AppTheme.getPriorityColor(priority);
    final baseBg = customColor != null
        ? customColor.withOpacity(0.25)
        : Colors.grey[800]?.withOpacity(0.15);
    final cardBg = baseBg?.withOpacity(isCompletedTask ? 0.4 : 0.7);
    final borderColor = Colors.white12;
    final textColor = Colors.white.withOpacity(isCompletedTask ? 0.55 : 0.9);



    final icon = appointment.notes != null ? AppIcons.getIcon(appointment.notes!) : null;


      return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Ink(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius / 1.3),
          border: Border.all(
            color: borderColor.withOpacity(isCompletedTask ? 0.3 : 0.7),
            width: 1.2,
          ),
          boxShadow: [
            if (!isCompletedTask)
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0,2),
              ),
          ],
        ),
        child: InkWell(
          onTap: () {
            if (isCompletedTask) {
              onTaskIncomplete(appointment);
            } else {
              onTaskCompleted(appointment);
            }
          },
          borderRadius: BorderRadius.circular(AppTheme.borderRadius / 1.3),
          splashColor: Colors.white24,
          highlightColor: Colors.white12,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status circle
                    GestureDetector(
                      onTap: () {
                        if (appointment.isCompleted) {
                          onTaskIncomplete(appointment);
                        } else {
                          onTaskCompleted(appointment);
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: appointment.isCompleted ? Colors.white24 : Colors.transparent,
                          border: Border.all(
                            color: appointment.isCompleted ? Colors.white54 : borderColor,
                            width: 2,
                          ),
                        ),
                        child: appointment.isCompleted
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Title + time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  appointment.subject,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    decoration: isCompletedTask ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (icon != null) ...[
                                const SizedBox(width: 8),
                                Icon(icon, size: 20, color: Colors.white70),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 14, color: textColor.withOpacity(0.8)),
                              const SizedBox(width: 4),
                              Text(
                                timeRangeText,
                                style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  durationText,
                                  style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ),
                              if (remainingTimeText != null) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    remainingTimeText,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Priority bar (horizontal stacked) sized box
                    PriorityIndicator(
                      priority: priority,
                      width: 46,
                      height: 6,
                      vertical: false,
                      activeColor: priorityColor,
                      inactiveColor: Colors.white24,
                      borderColor: Colors.transparent,
                      spacing: 1,
                    ),
                    // Delete button
                    GestureDetector(
                      onTap: () => onTaskRemoved(appointment),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6, top: 2),
                        child: Icon(Icons.delete_outline, size: 20, color: Colors.white54),
                      ),
                    ),
                  ],
                ),
                // Progress indicator for current tasks
                if (isCurrentTask && progress != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white12,
                      color: priorityColor,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'In progress ${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}