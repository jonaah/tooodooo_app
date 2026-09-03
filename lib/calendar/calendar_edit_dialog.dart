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
  _CalendarEditDialogState createState() => _CalendarEditDialogState();
}

class _CalendarEditDialogState extends State<CalendarEditDialog> {
  late TextEditingController _subjectController;
  late DateTime _startTime;
  late DateTime _endTime;
  late Color _color;
  late bool _isCompleted;
  IconData? _selectedIcon;
  final GlobalKey<SliderElementState> _sliderKey = GlobalKey<SliderElementState>();
  int _priority = 3;
  int _hours = 0;
  int _minutes = 0;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.appointment.subject);
    _startTime = widget.appointment.startTime;
    _endTime = widget.appointment.endTime;
    _color = widget.appointment.color;
    _isCompleted = widget.appointment.isCompleted;

    final duration = _endTime.difference(_startTime);
    _hours = duration.inHours;
    _minutes = duration.inMinutes % 60;

    for (int i = 1; i <= 5; i++) {
      if (_color.value == AppTheme.getCalendarTaskColor(i).value) {
        _priority = i;
        break;
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
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDateTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              primaryColor: AppTheme.accentColor,
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

    final updatedAppointment = widget.appointment.copyWith(
      subject: _subjectController.text,
      startTime: _startTime,
      endTime: _endTime,
      color: AppTheme.getCalendarTaskColor(newPriority),
      notes: _selectedIcon != null ? AppIcons.getName(_selectedIcon!) : widget.appointment.notes,
      isCompleted: _isCompleted,
    );

    widget.onSave(updatedAppointment);
  }

  String formattedDateTime(DateTime dateTime) {
    return DateFormat('dd.MM.yyyy - HH:mm').format(dateTime);
  }

  String formattedDate(DateTime dateTime) {
    return DateFormat('dd.MM.yyyy').format(dateTime);
  }

  String formattedTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String formattedDuration() {
    return "${_hours.toString().padLeft(2, '0')}:${_minutes.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final List<IconData> displayIcons = IconManager.recentIcons;
    final int firstRowCount = displayIcons.length >= 5 ? 5 : displayIcons.length;
    final bool hasSecondRow = displayIcons.length > 5;
    final int secondRowCount = hasSecondRow ? displayIcons.length - 5 : 0;

    return AlertDialog(
      backgroundColor: AppTheme.primaryColor,
      title: Text(
        "Edit Task",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textColor,
          fontSize: AppTheme.dialogTitle.fontSize,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      content: SizedBox(
        width: 300,
        height: 550, // Increased height for the dialog
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _isCompleted,
                    onChanged: (value) {
                      setState(() {
                        _isCompleted = value ?? false;
                      });
                    },
                    activeColor: AppTheme.accentColor,
                    checkColor: Colors.white,
                  ),
                  Text(
                    "Mark as completed",
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: AppTheme.smallPadding),
                child: TextField(
                  controller: _subjectController,
                  style: TextStyle(color: AppTheme.textColor),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius)),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius)),
                      borderSide: BorderSide(color: AppTheme.accentColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius)),
                      borderSide: BorderSide(color: AppTheme.accentColor, width: 2),
                    ),
                    hintText: 'Enter Task',
                    hintStyle: TextStyle(color: AppTheme.textColor.withOpacity(0.6)),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: AppTheme.smallPadding),
                child: Text(
                  "Priority Level",
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SliderElement(key: _sliderKey),
              Padding(
                padding: EdgeInsets.only(top: AppTheme.smallPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Date & Time",
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _openDurationPicker,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: AppTheme.smallPadding, vertical: AppTheme.smallPadding / 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer, size: AppTheme.smallIconSize, color: AppTheme.accentColor),
                            SizedBox(width: 4),
                            Text(
                              formattedDuration(),
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: AppTheme.smallPadding),
                padding: EdgeInsets.all(AppTheme.smallPadding),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.play_arrow, size: AppTheme.smallIconSize, color: AppTheme.accentColor),
                        SizedBox(width: 4),
                        Text("Start:", style: TextStyle(color: AppTheme.textColor, fontSize: 14)),
                        Spacer(),
                        InkWell(
                          onTap: () => _openDateTimePicker(true),
                          child: Chip(
                            backgroundColor: Colors.grey[700],
                            label: Text(
                              formattedDate(_startTime),
                              style: TextStyle(fontSize: 13, color: AppTheme.textColor),
                            ),
                            avatar: Icon(Icons.calendar_today, size: AppTheme.smallIconSize, color: AppTheme.accentColor),
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        SizedBox(width: 4),
                        InkWell(
                          onTap: () => _openDateTimePicker(true),
                          child: Chip(
                            backgroundColor: Colors.grey[700],
                            label: Text(
                              formattedTime(_startTime),
                              style: TextStyle(fontSize: 13, color: AppTheme.textColor),
                            ),
                            avatar: Icon(Icons.access_time, size: AppTheme.smallIconSize, color: AppTheme.accentColor),
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.smallPadding),
                    Row(
                      children: [
                        Icon(Icons.stop, size: AppTheme.smallIconSize, color: AppTheme.accentColor),
                        SizedBox(width: 4),
                        Text("End:", style: TextStyle(color: AppTheme.textColor, fontSize: 14)),
                        Spacer(),
                        InkWell(
                          onTap: () => _openDateTimePicker(false),
                          child: Chip(
                            backgroundColor: Colors.grey[700],
                            label: Text(
                              formattedDate(_endTime),
                              style: TextStyle(fontSize: 13, color: AppTheme.textColor),
                            ),
                            avatar: Icon(Icons.calendar_today, size: AppTheme.smallIconSize, color: AppTheme.accentColor),
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        SizedBox(width: 4),
                        InkWell(
                          onTap: () => _openDateTimePicker(false),
                          child: Chip(
                            backgroundColor: Colors.grey[700],
                            label: Text(
                              formattedTime(_endTime),
                              style: TextStyle(fontSize: 13, color: AppTheme.textColor),
                            ),
                            avatar: Icon(Icons.access_time, size: AppTheme.smallIconSize, color: AppTheme.accentColor),
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: AppTheme.defaultPadding, bottom: AppTheme.smallPadding / 2),
                child: Text(
                  "Task Icon",
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: AppTheme.smallPadding / 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: displayIcons.take(firstRowCount).map((icon) {
                    final isSelected = _selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => _handleIconTap(icon),
                      child: Container(
                        padding: EdgeInsets.all(AppTheme.smallPadding),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.accentColor : Colors.grey[800],
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : AppTheme.textColor,
                          size: AppTheme.iconSize,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (hasSecondRow)
                Container(
                  margin: EdgeInsets.only(top: AppTheme.smallPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: displayIcons.sublist(5, 5 + secondRowCount).map((icon) {
                      final isSelected = _selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => _handleIconTap(icon),
                        child: Container(
                          padding: EdgeInsets.all(AppTheme.smallPadding),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.accentColor : Colors.grey[800],
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? Colors.white : AppTheme.textColor,
                            size: AppTheme.iconSize,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              InkWell(
                onTap: _openEmojiPicker,
                child: Padding(
                  padding: EdgeInsets.only(top: AppTheme.smallPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: AppTheme.smallIconSize, color: AppTheme.accentColor),
                      SizedBox(width: 4),
                      Text(
                        "More Icons",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: AppTheme.defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Green Save button
                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.defaultPadding / 2, 
                          vertical: AppTheme.smallPadding
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: AppTheme.smallIconSize, color: Colors.white),
                          SizedBox(width: 4),
                          Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    
                    // Cancel button
                    ElevatedButton(
                      onPressed: widget.onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.defaultPadding / 2, 
                          vertical: AppTheme.smallPadding
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                        ),
                      ),
                      child: Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    
                    // Delete button
                    ElevatedButton(
                      onPressed: widget.onDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.defaultPadding / 2, 
                          vertical: AppTheme.smallPadding
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: AppTheme.smallIconSize, color: Colors.white),
                          SizedBox(width: 4),
                          Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
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