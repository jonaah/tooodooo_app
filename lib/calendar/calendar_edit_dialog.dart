import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';
import 'package:tooodooo_app/util/app_theme.dart';
import 'package:tooodooo_app/util/app_icons.dart';
import 'package:tooodooo_app/util/slider_element.dart';
import 'package:tooodooo_app/util/duration_picker.dart';
import 'package:tooodooo_app/pages/emoji_picker_page.dart';
import 'package:tooodooo_app/util/icon_manager.dart';

class CalendarEditDialog extends StatefulWidget {
  final CalendarAppointment appointment;
  final Function(CalendarAppointment) onSave;
  final VoidCallback onDelete;
  final Function(CalendarAppointment) onToggleCompletion;
  final VoidCallback onCancel;

  const CalendarEditDialog({
    super.key,
    required this.appointment,
    required this.onSave,
    required this.onDelete,
    required this.onToggleCompletion,
    required this.onCancel,
  });

  @override
  CalendarEditDialogState createState() => CalendarEditDialogState();
}

class CalendarEditDialogState extends State<CalendarEditDialog> {
  late TextEditingController _subjectController;
  late DateTime _startTime;
  late DateTime _endTime;
  Color? _selectedColor;
  late bool _isCompleted;
  IconData? _selectedIcon;
  final GlobalKey<SliderElementState> _sliderKey = GlobalKey<SliderElementState>();
  int _priority = 3;
  int _hours = 0;
  int _minutes = 0;
  double? _dialogHeight;

  static const List<Map<String, dynamic>> _presetColorOptions = [
    {'color': null, 'name': 'Keine Farbe'},
    {'color': Color(0xFFE57373), 'name': 'Zartrot'},
    {'color': Color(0xFFEF5350), 'name': 'Koralle'},
    {'color': Color(0xFFF06292), 'name': 'Rosa'},
    {'color': Color(0xFFBA68C8), 'name': 'Lavendel'},
    {'color': Color(0xFF9575CD), 'name': 'Flieder'},
    {'color': Color(0xFF7986CB), 'name': 'Indigo'},
    {'color': Color(0xFF64B5F6), 'name': 'Himmelblau'},
    {'color': Color(0xFF4FC3F7), 'name': 'Pastellblau'},
    {'color': Color(0xFF4DB6AC), 'name': 'Türkis'},
    {'color': Color(0xFF81C784), 'name': 'Salbeigrün'},
    {'color': Color(0xFFDCE775), 'name': 'Limette'},
    {'color': Color(0xFFFFF176), 'name': 'Sonnengelb'},
    {'color': Color(0xFFFFD54F), 'name': 'Bernstein'},
    {'color': Color(0xFFFFB74D), 'name': 'Pastellorange'},
    {'color': Color(0xFFA1887F), 'name': 'Kupferbraun'},
  ];

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.appointment.subject);
    _startTime = widget.appointment.startTime;
    _endTime = widget.appointment.endTime;
    _isCompleted = widget.appointment.isCompleted;

    final duration = _endTime.difference(_startTime);
    _hours = duration.inHours;
    _minutes = duration.inMinutes % 60;

    if (widget.appointment.priority != null) {
      _priority = widget.appointment.priority!;
    } else {
      for (int i = 1; i <= 5; i++) {
        if (widget.appointment.color.toARGB32() == AppTheme.getCalendarTaskColor(i).toARGB32()) {
          _priority = i;
          break;
        }
      }
    }

    if (widget.appointment.customColorValue != null) {
      _selectedColor = Color(widget.appointment.customColorValue!);
    } else {
      bool isPriorityColor = false;
      for (int i = 1; i <= 5; i++) {
        if (widget.appointment.color.toARGB32() == AppTheme.getCalendarTaskColor(i).toARGB32()) {
          isPriorityColor = true;
          break;
        }
      }
      if (!isPriorityColor) {
        _selectedColor = widget.appointment.color;
      } else {
        _selectedColor = null;
      }
    }

    if (widget.appointment.notes != null) {
      _selectedIcon = AppIcons.getIcon(widget.appointment.notes!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sliderKey.currentState?.setSliderValue(_priority.toDouble());
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  void _handleIconTap(IconData icon) {
    setState(() {
      _selectedIcon = icon;
    });
    IconManager.addToRecentIcons(icon);
  }

  void _openEmojiPicker() async {
    await showIconPicker(
      context: context,
      onIconSelected: _handleIconTap,
    );
  }

  void _openColorPicker() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final double screenHeight = MediaQuery.of(dialogContext).size.height;
        return Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 380,
              maxHeight: screenHeight * 0.68,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    itemCount: _presetColorOptions.length,
                    itemBuilder: (context, index) {
                      final item = _presetColorOptions[index];
                      final Color? color = item['color'] as Color?;
                      final String name = item['name'] as String;
                      final bool isSelected = (_selectedColor == null && color == null) ||
                          (_selectedColor != null && color != null && _selectedColor!.toARGB32() == color.toARGB32());

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                            Navigator.pop(dialogContext);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                  : AppTheme.backgroundColor,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: color ?? Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: color != null
                                          ? Colors.white.withValues(alpha: 0.4)
                                          : AppTheme.secondaryTextColor.withValues(alpha: 0.6),
                                      width: 1.5,
                                    ),
                                    boxShadow: color != null
                                        ? [
                                            BoxShadow(
                                              color: color.withValues(alpha: 0.35),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: color == null
                                      ? const Icon(Icons.block, size: 16, color: AppTheme.secondaryTextColor)
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? color : AppTheme.secondaryTextColor,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle, size: 20, color: color),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDateTimePicker(bool isStartTime) async {
    final DateTime initialDateTime = isStartTime ? _startTime : _endTime;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: AppTheme.primaryColor,
            colorScheme: ColorScheme.dark(
              primary: AppTheme.secondaryTextColor,
              onPrimary: AppTheme.darkTextColor,
              surface: AppTheme.primaryColor,
              onSurface: AppTheme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await AppTheme.showStyledTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDateTime),
      );

      if (pickedTime != null) {
        final DateTime newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStartTime) {
            _startTime = newDateTime;
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(minutes: 30));
            }
          } else {
            _endTime = newDateTime;
            if (_startTime.isAfter(_endTime)) {
              _startTime = _endTime.subtract(const Duration(minutes: 30));
            }
          }

          final duration = _endTime.difference(_startTime);
          _hours = duration.inHours;
          _minutes = duration.inMinutes % 60;
        });
      }
    }
  }

  Future<void> _openDurationPicker() async {
    final result = await showDurationPicker(
      context: context,
      initialHours: _hours,
      initialMinutes: _minutes,
    );

    if (result != null) {
      setState(() {
        _hours = result['hours'] ?? 0;
        _minutes = result['minutes'] ?? 0;

        _endTime = _startTime.add(Duration(hours: _hours, minutes: _minutes));
      });
    }
  }

  void _saveChanges() {
    final double priorityValue = _sliderKey.currentState?.getSliderValue() ?? _priority.toDouble();
    final int newPriority = priorityValue.round();

    final updatedAppointment = CalendarAppointment(
      id: widget.appointment.id,
      googleEventId: widget.appointment.googleEventId,
      subject: _subjectController.text,
      startTime: _startTime,
      endTime: _endTime,
      color: _selectedColor ?? AppTheme.getCalendarTaskColor(newPriority),
      isAllDay: widget.appointment.isAllDay,
      notes: _selectedIcon != null ? AppIcons.getName(_selectedIcon!) : widget.appointment.notes,
      isCompleted: _isCompleted,
      priority: newPriority,
      customColorValue: _selectedColor?.toARGB32(),
    );

    widget.onSave(updatedAppointment);
  }

  String formattedDate(DateTime dateTime) {
    return DateFormat('dd.MM.yyyy').format(dateTime);
  }

  String formattedTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String formattedDuration() {
    if (_hours == 0 && _minutes == 0) {
      return "--:--";
    }
    return "${_hours.toString().padLeft(2, '0')}:${_minutes.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final List<IconData> displayIcons = IconManager.recentIcons;
    final int firstRowCount = displayIcons.length >= 6 ? 6 : displayIcons.length;
    final bool hasSecondRow = displayIcons.length > 6;
    final int secondRowCount = hasSecondRow ? (displayIcons.length - 6).clamp(0, 6) : 0;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double minHeight = screenHeight * 0.45;
    final double maxHeight = screenHeight * 0.94;
    _dialogHeight ??= screenHeight * 0.85;
    final double currentHeight = _dialogHeight!.clamp(minHeight, maxHeight);

    return Dialog(
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.bottomCenter,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        height: currentHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 30,
              spreadRadius: 4,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Resizable Drag Handle & Header
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _dialogHeight = (_dialogHeight! - details.delta.dy).clamp(minHeight, maxHeight);
                  });
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! > 600) {
                    widget.onCancel();
                  }
                },
                child: Column(
                  children: [
                    // Modern Drag Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 6),
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryTextColor.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.defaultPadding,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Close button on the LEFT
                          SizedBox(
                            width: 68,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: AppTheme.secondaryTextColor),
                                onPressed: widget.onCancel,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Close',
                              ),
                            ),
                          ),

                          // Centered Title
                          const Expanded(
                            child: Center(
                              child: Text(
                                "Edit Task",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryTextColor,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),

                          // Save button on the RIGHT
                          SizedBox(
                            width: 68,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: _saveChanges,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  "Save",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Divider(color: AppTheme.dividerColor, thickness: 2),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 16),

                    // Task input field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
                      child: TextField(
                        controller: _subjectController,
                        style: const TextStyle(color: AppTheme.textColor),
                        textAlign: TextAlign.start,
                        decoration: const InputDecoration(
                          hintText: 'Task Name',
                          hintStyle: TextStyle(color: AppTheme.textColor, fontSize: 20),
                          filled: true,
                          fillColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Mark as completed toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text(
                            "Mark as completed",
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Checkbox(
                            value: _isCompleted,
                            activeColor: AppTheme.accentColor,
                            checkColor: Colors.white,
                            onChanged: (val) {
                              setState(() {
                                _isCompleted = val ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.dividerColor, thickness: 2),
                    const SizedBox(height: 8),

                    // Color picker section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Task Color",
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: InkWell(
                              onTap: _openColorPicker,
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius * 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.smallPadding,
                                  vertical: AppTheme.smallPadding,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedColor ?? AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius * 2),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 25, height: 25),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.dividerColor, thickness: 2),
                    const SizedBox(height: 8),

                    // Priority section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Priority Level",
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SliderElement(key: _sliderKey),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.dividerColor, thickness: 2),
                    const SizedBox(height: 8),

                    // Task icon section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Task Icon",
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // First row of icons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: displayIcons.take(firstRowCount).map((icon) {
                              final isSelected = _selectedIcon == icon;
                              return GestureDetector(
                                onTap: () => _handleIconTap(icon),
                                child: Container(
                                  padding: const EdgeInsets.all(AppTheme.smallPadding),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.accentColor.withValues(alpha: 0.9)
                                        : AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    icon,
                                    color: Colors.white,
                                    size: AppTheme.iconSize,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          // Second row of icons (if needed)
                          if (hasSecondRow) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: displayIcons.sublist(6, 6 + secondRowCount).map((icon) {
                                final isSelected = _selectedIcon == icon;
                                return GestureDetector(
                                  onTap: () => _handleIconTap(icon),
                                  child: Container(
                                    padding: const EdgeInsets.all(AppTheme.smallPadding),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.accentColor : AppTheme.backgroundColor,
                                      borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      icon,
                                      color: Colors.white,
                                      size: AppTheme.iconSize,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 8),
                          // More icons button
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: _openEmojiPicker,
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.accentColor.withValues(alpha: 0.1),
                                backgroundColor: AppTheme.accentColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.defaultPadding,
                                  vertical: AppTheme.smallPadding,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                                ),
                              ),
                              child: const Text(
                                "More Icons",
                                style: TextStyle(
                                  color: AppTheme.secondaryTextColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.dividerColor, thickness: 2),
                    const SizedBox(height: 8),

                    // Date & Time section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Date & Time",
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.play_arrow, size: 18, color: AppTheme.accentColor),
                                    const SizedBox(width: 6),
                                    const Text(
                                      "Start:",
                                      style: TextStyle(
                                        color: AppTheme.secondaryTextColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    InkWell(
                                      onTap: () => _openDateTimePicker(true),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.backgroundColor,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.secondaryTextColor.withValues(alpha: 0.25)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.calendar_today, size: 13, color: AppTheme.accentColor),
                                            const SizedBox(width: 5),
                                            Text(
                                              formattedDate(_startTime),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.secondaryTextColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => _openDateTimePicker(true),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.backgroundColor,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.secondaryTextColor.withValues(alpha: 0.25)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time, size: 13, color: AppTheme.accentColor),
                                            const SizedBox(width: 5),
                                            Text(
                                              formattedTime(_startTime),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.secondaryTextColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Divider(color: AppTheme.dividerColor.withValues(alpha: 0.15), height: 1),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.stop, size: 18, color: AppTheme.accentColor),
                                    const SizedBox(width: 6),
                                    const Text(
                                      "End:",
                                      style: TextStyle(
                                        color: AppTheme.secondaryTextColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    InkWell(
                                      onTap: () => _openDateTimePicker(false),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.backgroundColor,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.secondaryTextColor.withValues(alpha: 0.25)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.calendar_today, size: 13, color: AppTheme.accentColor),
                                            const SizedBox(width: 5),
                                            Text(
                                              formattedDate(_endTime),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.secondaryTextColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => _openDateTimePicker(false),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.backgroundColor,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.secondaryTextColor.withValues(alpha: 0.25)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time, size: 13, color: AppTheme.accentColor),
                                            const SizedBox(width: 5),
                                            Text(
                                              formattedTime(_endTime),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.secondaryTextColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.dividerColor, thickness: 2),
                    const SizedBox(height: 8),

                    // Duration section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Duration",
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.center,
                            child: InkWell(
                              onTap: _openDurationPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.defaultPadding,
                                  vertical: AppTheme.smallPadding,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                                  border: Border.all(color: AppTheme.secondaryTextColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.timer,
                                      size: AppTheme.iconSize,
                                      color: AppTheme.secondaryTextColor,
                                    ),
                                    const SizedBox(width: AppTheme.smallPadding),
                                    Text(
                                      formattedDuration(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.dividerColor, thickness: 2),
                    const SizedBox(height: 16),

                    // Delete button
                    Center(
                      child: TextButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        label: const Text(
                          "Delete Task",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                          ),
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}