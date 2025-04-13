import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';
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
    Key? key,
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
  }) : super(key: key);

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
      progress = elapsedDuration / totalDuration;
      progress = progress.clamp(0.0, 1.0); // Ensure progress is between 0 and 1
    }
    
    // Get duration text
    final durationMinutes = appointment.endTime.difference(appointment.startTime).inMinutes;
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    final durationText = hours > 0 
        ? '${hours}h ${minutes > 0 ? '${minutes}m' : ''}'
        : '${minutes}m';
    
    // Get time range text (e.g., "9:30 AM - 10:30 AM")
    final timeRangeText = '${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}';
    
    // Get the remaining time for upcoming tasks
    String? remainingTimeText;
    if (isUpcomingTask && showRemainingTime) {
      final remainingMinutes = appointment.startTime.difference(DateTime.now()).inMinutes;
      if (remainingMinutes < 60) {
        remainingTimeText = 'In $remainingMinutes minute${remainingMinutes == 1 ? '' : 's'}';
      } else if (remainingMinutes < 24 * 60) {
        final hours = remainingMinutes ~/ 60;
        final minutes = remainingMinutes % 60;
        remainingTimeText = 'In $hours hour${hours == 1 ? '' : 's'}${minutes > 0 ? ' $minutes min' : ''}';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Ink(
        decoration: BoxDecoration(
          color: isCompletedTask 
              ? Colors.grey.shade800.withOpacity(0.5)
              : isPendingTask
                  ? Colors.orange.shade800.withOpacity(0.5)
                  : appointment.color,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
          border: isCompletedTask || isPendingTask
              ? Border.all(color: Colors.grey.shade700, width: 1)
              : null,
          boxShadow: isCompletedTask || isPendingTask 
              ? null 
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: InkWell(
          onTap: () {
            // Toggle completion status on task card tap
            if (isCompletedTask) {
              onTaskIncomplete(appointment);
            } else {
              onTaskCompleted(appointment);
            }
          },
          borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
          splashColor: isCompletedTask ? Colors.grey.shade400.withOpacity(0.3) : Colors.white.withOpacity(0.3),
          highlightColor: isCompletedTask ? Colors.grey.shade400.withOpacity(0.2) : Colors.white.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Only show the circular status indicator without any other checkbox elements
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Icon(
                        isCompletedTask ? Icons.check_circle : Icons.circle_outlined,
                        color: isCompletedTask ? Colors.grey.shade500 : Colors.white70,
                        size: 20,
                      ),
                    ),
                    // Task title
                    Expanded(
                      child: Text(
                        appointment.subject,
                        style: TextStyle(
                          color: isCompletedTask || isPendingTask ? Colors.grey.shade400 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: isCompletedTask ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    // Duration label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompletedTask || isPendingTask ? Colors.grey.shade700 : Colors.black26,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        durationText,
                        style: TextStyle(
                          color: isCompletedTask || isPendingTask ? Colors.grey.shade400 : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // Increased spacing to separate from delete button
                    // Delete button
                    GestureDetector(
                      onTap: () => onTaskRemoved(appointment),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.delete_outline,
                          color: isCompletedTask || isPendingTask ? Colors.grey.shade500 : Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: isCompletedTask || isPendingTask ? Colors.grey.shade500 : Colors.white70,
                      size: 14, 
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeRangeText,
                      style: TextStyle(
                        color: isCompletedTask || isPendingTask ? Colors.grey.shade500 : Colors.white70,
                        fontSize: 12,
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Progress indicator for current tasks
                if (isCurrentTask && progress != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'In progress (${(progress * 100).toInt()}% complete)',
                    style: const TextStyle(
                      color: Colors.white70,
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