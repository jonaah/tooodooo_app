import 'package:flutter/material.dart';
import 'package:tooodooo_app/pages/emoji_picker_page.dart';
import 'package:tooodooo_app/util/icon_manager.dart';
import 'package:tooodooo_app/util/my_button.dart';
import 'package:tooodooo_app/util/slider_element.dart';
import 'package:tooodooo_app/util/duration_picker.dart';
import 'package:tooodooo_app/util/app_theme.dart';

class DialogBox extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final GlobalKey<SliderElementState> sliderKey;
  final Function(IconData) onIconSelected;
  final int durationHours;
  final int durationMinutes;
  final Function(int, int) onDurationChanged;
  final bool isEditing;
  final IconData? initialIcon;
  final double? initialPriority;

  const DialogBox({
    super.key,
    required this.controller,
    required this.onSave,
    required this.onCancel,
    required this.sliderKey,
    required this.onIconSelected,
    required this.durationHours,
    required this.durationMinutes,
    required this.onDurationChanged,
    this.isEditing = false,
    this.initialIcon,
    this.initialPriority,
  });

  @override
  _DialogBoxState createState() => _DialogBoxState();
}

class _DialogBoxState extends State<DialogBox> {
  IconData? _selectedIcon;
  late int hours;
  late int minutes;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon;
    hours = widget.durationHours;
    minutes = widget.durationMinutes;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPriority != null) {
        widget.sliderKey.currentState?.setSliderValue(widget.initialPriority!);
      }
    });
  }

  void _handleIconTap(IconData icon) {
    setState(() {
      _selectedIcon = icon;
    });
    widget.onIconSelected(icon);
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

  String formattedDuration() {
    if (hours == 0 && minutes == 0) {
      return "--:--";
    }
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }

  Future<void> _openDurationPicker() async {
    final result = await showDurationPicker(
      context: context,
      initialHours: hours,
      initialMinutes: minutes,
    );

    if (result != null) {
      setState(() {
        hours = result['hours'] ?? 0;
        minutes = result['minutes'] ?? 0;
        widget.onDurationChanged(hours, minutes);
      });
    }
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
        widget.isEditing ? "Edit Task" : "Add Task",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.secondaryTextColor,
          fontSize: 22,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      content: SizedBox(
        width: 300,
        height: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Task input field
              Center(
                child: TextField(
                  controller: widget.controller,
                  style: TextStyle(color: AppTheme.backgroundColor),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius)),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius)),
                      borderSide: BorderSide(color: AppTheme.secondaryTextColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius)),
                      borderSide: BorderSide(color: AppTheme.accentColor, width: 2),
                    ),
                    hintText: 'Enter Task',
                    hintStyle: TextStyle(color: AppTheme.secondaryTextColor.withOpacity(0.6)),
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
                    color: AppTheme.secondaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SliderElement(key: widget.sliderKey),
              
              // Task icon section
              Padding(
                padding: EdgeInsets.only(top: AppTheme.smallPadding / 2, bottom: AppTheme.smallPadding / 2),
                child: Text(
                  "Task Icon",
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
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
                          color: isSelected ? AppTheme.accentColor.withOpacity(0.9) : Colors.grey[800],
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
                          color: isSelected ? Colors.white : AppTheme.accentColor.withOpacity(0.8),
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
                            color: isSelected ? Colors.white : AppTheme.accentColor.withOpacity(0.8),
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
                    foregroundColor: AppTheme.accentColor.withOpacity(0.1),
                    backgroundColor: Colors.grey[800],
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding, vertical: AppTheme.smallPadding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                    ),
                  ),
                  child: Text(
                    "More Icons",
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ),
              ),
              
              // Duration section
              Padding(
                padding: EdgeInsets.only(top: AppTheme.defaultPadding - 4),
                child: Text(
                  "Duration",
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // Duration picker button
              Container(
                margin: EdgeInsets.only(top: AppTheme.smallPadding),
                child: InkWell(
                  onTap: _openDurationPicker,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding, vertical: AppTheme.smallPadding),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                      border: Border.all(color: AppTheme.secondaryTextColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, size: AppTheme.iconSize, color: AppTheme.secondaryTextColor),
                        SizedBox(width: AppTheme.smallPadding),
                        Text(
                          formattedDuration(),
                          style: TextStyle(
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
              
              // Button row
              Container(
                margin: EdgeInsets.only(top: AppTheme.defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MyButton(
                      text: "Save",
                      onPressed: widget.onSave,
                      backgroundColor: AppTheme.accentColor.withOpacity(0.7),
                      textColor: Colors.white,
                    ),
                    MyButton(
                      text: "Cancel",
                      onPressed: widget.onCancel,
                      backgroundColor: AppTheme.accentColor.withOpacity(0.7),
                      textColor: Colors.white,
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