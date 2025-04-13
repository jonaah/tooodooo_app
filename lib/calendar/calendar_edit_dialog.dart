import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tooodooo_app/calendar/calendar_appointment.dart';
import 'package:tooodooo_app/util/app_theme.dart';
import 'package:tooodooo_app/util/app_icons.dart';
import 'package:tooodooo_app/util/my_button.dart';
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
    Key? key,
    required this.appointment,
    required this.onSave,
    required this.onDelete,
    required this.onToggleCompletion,
    required this.onCancel,
  }) : super(key: key);

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
    
    // Calculate duration from start and end time
    final duration = _endTime.difference(_startTime);
    _hours = duration.inHours;
    _minutes = duration.inMinutes % 60;
    
    // Extract priority from color
    for (int i = 1; i <= 5; i++) {
      if (_color.value == AppTheme.getCalendarTaskColor(i).value) {
        _priority = i;
        break;
      }
    }
    
    // Extract icon if it exists
    if (widget.appointment.notes != null) {
      _selectedIcon = AppIcons.getIcon(widget.appointment.notes!);
    }
    
    // Schedule setting the slider value after the widget is built
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmojiPickerPage(
          recentlyUsed: IconManager.recentIcons,
          allEmojis: IconManager.allIcons,
          onIconSelected: _handleIconTap,
        ),
      ),
    );
  }
  
  Future<void> _openDateTimePicker(bool isStartTime) async {
    final DateTime initialDateTime = isStartTime ? _startTime : _endTime;
    
    // First, select a date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: AppTheme.accentColor,
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentColor,
              onPrimary: Colors.white,
              surface: AppTheme.backgroundColor,
              onSurface: AppTheme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      // Then, select a time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDateTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              primaryColor: AppTheme.accentColor,
              colorScheme: ColorScheme.dark(
                primary: AppTheme.accentColor,
                onPrimary: Colors.white,
                surface: AppTheme.backgroundColor,
                onSurface: AppTheme.textColor,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null) {
        // Combine date and time
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
            // Ensure end time is not before start time
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(minutes: 30));
            }
          } else {
            _endTime = newDateTime;
            // Ensure start time is not after end time
            if (_startTime.isAfter(_endTime)) {
              _startTime = _endTime.subtract(const Duration(minutes: 30));
            }
          }
          
          // Update hours and minutes based on the new duration
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
        
        // Update end time based on new duration
        _endTime = _startTime.add(Duration(hours: _hours, minutes: _minutes));
      });
    }
  }
  
  void _saveChanges() {
    // Get the current priority value from the slider
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
          fontSize: 22,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      content: SizedBox(
        width: 300,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Task completed checkbox
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
              
              // Task input field
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
              
              // Priority section
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
              
              // Date & Time section
              Padding(
                padding: EdgeInsets.only(top: AppTheme.smallPadding),
                child: Text(
                  "Date & Time",
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // Start time selector
              Container(
                margin: EdgeInsets.only(top: AppTheme.smallPadding),
                child: InkWell(
                  onTap: () => _openDateTimePicker(true),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding, vertical: AppTheme.smallPadding),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                      border: Border.all(color: AppTheme.accentColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Icon(Icons.event, size: AppTheme.iconSize, color: AppTheme.accentColor),
                        SizedBox(width: AppTheme.smallPadding),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Start Time",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textColor.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                formattedDateTime(_startTime),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // End time selector
              Container(
                margin: EdgeInsets.only(top: AppTheme.smallPadding),
                child: InkWell(
                  onTap: () => _openDateTimePicker(false),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding, vertical: AppTheme.smallPadding),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                      border: Border.all(color: AppTheme.accentColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Icon(Icons.event, size: AppTheme.iconSize, color: AppTheme.accentColor),
                        SizedBox(width: AppTheme.smallPadding),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "End Time",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textColor.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                formattedDateTime(_endTime),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Duration picker
              Container(
                margin: EdgeInsets.only(top: AppTheme.smallPadding),
                child: InkWell(
                  onTap: _openDurationPicker,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding, vertical: AppTheme.smallPadding),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                      border: Border.all(color: AppTheme.accentColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, size: AppTheme.iconSize, color: AppTheme.accentColor),
                        SizedBox(width: AppTheme.smallPadding),
                        Text(
                          "Duration: ${formattedDuration()}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Task icon section
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
              
              // First row of icons
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
              
              // Second row of icons (if needed)
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
              
              // More icons button
              Padding(
                padding: EdgeInsets.only(top: AppTheme.smallPadding, bottom: AppTheme.smallPadding / 2),
                child: TextButton(
                  onPressed: _openEmojiPicker,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentColor,
                    backgroundColor: Colors.grey[800],
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding, vertical: AppTheme.smallPadding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                    ),
                  ),
                  child: Text(
                    "More Icons",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Buttons row
              Container(
                margin: EdgeInsets.only(top: AppTheme.defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MyButton(text: "Save", onPressed: _saveChanges),
                    MyButton(text: "Cancel", onPressed: widget.onCancel),
                  ],
                ),
              ),
              
              // Delete button
              Container(
                margin: EdgeInsets.only(top: AppTheme.smallPadding),
                child: TextButton(
                  onPressed: widget.onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red[700],
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding, vertical: AppTheme.smallPadding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                    ),
                  ),
                  child: Text(
                    "Delete Task",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}