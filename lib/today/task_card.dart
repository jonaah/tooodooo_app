import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';
import 'package:tooodooo_app/util/PriorityIndicator.dart';
import 'package:tooodooo_app/util/app_icons.dart';
import 'package:tooodooo_app/util/app_theme.dart';

// Small pure helpers (facilitate testing & reuse)
String _formatWallClock(DateTime time) => DateFormat('h:mm a').format(time);
String _formatTimeRange(DateTime start, DateTime end) => '${_formatWallClock(start)} - ${_formatWallClock(end)}';
String _formatDuration(DateTime start, DateTime end) {
  final durationMinutes = end.difference(start).inMinutes;
  final h = durationMinutes ~/ 60;
  final m = durationMinutes % 60;
  return h > 0 ? '${h}h${m > 0 ? ' ${m}m' : ''}' : '${m}m';
}
String? _remainingUntil(DateTime start, DateTime now) {
  final remaining = start.difference(now).inMinutes;
  if (remaining < 0) return null;
  if (remaining < 60) return 'In $remaining m';
  if (remaining < 24 * 60) {
    final rh = remaining ~/ 60;
    final rm = remaining % 60;
    return 'In ${rh}h${rm > 0 ? ' ${rm}m' : ''}';
  }
  return null;
}

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

  @override
  Widget build(BuildContext context) {
    // Progress for current tasks
    double? progress;
    if (isCurrentTask) {
      final total = appointment.endTime.difference(appointment.startTime).inMinutes;
      final elapsed = DateTime.now().difference(appointment.startTime).inMinutes;
      progress = total <= 0 ? 1 : (elapsed / total).clamp(0.0, 1.0);
    }

    final timeRangeText = _formatTimeRange(appointment.startTime, appointment.endTime);
    final durationText = _formatDuration(appointment.startTime, appointment.endTime);
    final remainingTimeText = (isUpcomingTask && showRemainingTime)
        ? _remainingUntil(appointment.startTime, DateTime.now())
        : null;

    // Visual styling
    final priority = (appointment.priority ?? 3).clamp(1, 5);
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
                offset: const Offset(0, 2),
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
                    _CompletionToggle(
                      completed: appointment.isCompleted,
                      borderColor: borderColor,
                      onTap: () {
                        if (appointment.isCompleted) {
                          onTaskIncomplete(appointment);
                        } else {
                          onTaskCompleted(appointment);
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TitleRow(
                            subject: appointment.subject,
                            icon: icon,
                            textColor: textColor,
                            isCompleted: isCompletedTask,
                          ),
                          const SizedBox(height: 4),
                          _TimeInfoRow(
                            timeRangeText: timeRangeText,
                            durationText: durationText,
                            remainingTimeText: remainingTimeText,
                            textColor: textColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                    GestureDetector(
                      onTap: () => onTaskRemoved(appointment),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6, top: 2),
                        child: Icon(Icons.delete_outline, size: 20, color: Colors.white54),
                      ),
                    ),
                  ],
                ),
                if (isCurrentTask && progress != null)
                  _ProgressSection(progress: progress, color: priorityColor, textColor: textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionToggle extends StatelessWidget {
  final bool completed;
  final Color borderColor;
  final VoidCallback onTap;
  const _CompletionToggle({required this.completed, required this.borderColor, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: completed ? Colors.white24 : Colors.transparent,
          border: Border.all(
            color: completed ? Colors.white54 : borderColor,
            width: 2,
          ),
        ),
        child: completed ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final String subject;
  final IconData? icon;
  final Color textColor;
  final bool isCompleted;
  const _TitleRow({required this.subject, this.icon, required this.textColor, required this.isCompleted});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            subject,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
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
    );
  }
}

class _TimeInfoRow extends StatelessWidget {
  final String timeRangeText;
  final String durationText;
  final String? remainingTimeText;
  final Color textColor;
  const _TimeInfoRow({
    required this.timeRangeText,
    required this.durationText,
    required this.remainingTimeText,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
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
              remainingTimeText!,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ]
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final double progress;
  final Color color;
  final Color textColor;
  const _ProgressSection({required this.progress, required this.color, required this.textColor});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            color: color,
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
    );
  }
}