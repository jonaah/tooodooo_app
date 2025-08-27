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
  final bool? initialIsGroup;
  final List<Map<String, dynamic>>? initialSubtasks; // [{name, completed}]
  final Color? initialColor;
  final Color? initialColorValue; // alternative name support

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
    this.initialIsGroup,
    this.initialSubtasks,
    this.initialColor,
    this.initialColorValue,
  });

  @override
  DialogBoxState createState() => DialogBoxState();
}

class DialogBoxState extends State<DialogBox> {
  IconData? _selectedIcon;
  late int hours;
  late int minutes;
  bool _isGroup = false;
  final TextEditingController _subtaskController = TextEditingController();
  final List<Map<String, dynamic>> _subtasks = [];
  Color? _selectedColor; // renamed internal storage
  Color? get selectedColor => _selectedColor; // public getter expected by callers
  Color? get selectedColorValue => _selectedColor; // legacy public getter

  // Preset palette
  static const List<Color> _presetColors = [
    Color(0xFF81DA83), // green
    Color(0xFF63C8BF), // teal
    Color(0xFF6A96DC), // blue
    Color(0xFFF87C47), // orange
    Color(0xFFFF554C), // red
    Color(0xFFAA66CC), // purple
    Color(0xFFFFC107), // amber
    Color(0xFF26A69A), // green teal
    Color(0xFF9E9E9E), // gray
  ];

  bool get isGroup => _isGroup;
  List<Map<String, dynamic>> getSubtasks() => _subtasks
      .map((e) => {"name": e['name'], "completed": e['completed'] == true})
      .toList();

  List<Map<String, dynamic>> buildSubtasksCopy() => getSubtasks();

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon;
    hours = widget.durationHours;
    minutes = widget.durationMinutes;
    _isGroup = widget.initialIsGroup ?? false;
    if (widget.initialSubtasks != null) {
      _subtasks.addAll(widget.initialSubtasks!);
    }
    _selectedColor = widget.initialColor ?? widget.initialColorValue;

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

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subtasks.add({'name': text, 'completed': false});
        _subtaskController.clear();
      });
    }
  }

  void _toggleSubtask(int index) {
    setState(() {
      _subtasks[index]['completed'] = !(_subtasks[index]['completed'] == true);
    });
  }

  void _deleteSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
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
        width: 320,
        height: 560,
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

              // Group toggle
              Padding(
                padding: EdgeInsets.only(top: AppTheme.smallPadding),
                child: Row(
                  children: [
                    Switch(
                      value: _isGroup,
                      activeColor: AppTheme.accentColor,
                      onChanged: (val) {
                        setState(() { _isGroup = val; });
                      },
                    ),
                    Text(
                      "Group Task",
                      style: TextStyle(color: AppTheme.secondaryTextColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              if (_isGroup) ...[
                // Subtasks input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        style: TextStyle(color: AppTheme.secondaryTextColor),
                        decoration: InputDecoration(
                          hintText: 'Add item',
                          hintStyle: TextStyle(color: AppTheme.secondaryTextColor.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.grey[800],
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                        ),
                        onSubmitted: (_) => _addSubtask(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addSubtask,
                      icon: Icon(Icons.add_circle, color: AppTheme.accentColor),
                      tooltip: 'Add subtask',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Subtasks list
                if (_subtasks.isEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No items yet',
                      style: TextStyle(color: AppTheme.secondaryTextColor.withOpacity(0.6)),
                    ),
                  )
                else
                  Column(
                    children: List.generate(_subtasks.length, (i) {
                      final sub = _subtasks[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _toggleSubtask(i),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: sub['completed'] == true ? AppTheme.accentColor.withOpacity(0.8) : Colors.transparent,
                                  border: Border.all(color: AppTheme.secondaryTextColor, width: 1.5),
                                  shape: BoxShape.circle,
                                ),
                                child: sub['completed'] == true
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sub['name'] ?? '',
                                style: TextStyle(
                                  color: AppTheme.secondaryTextColor.withOpacity(sub['completed'] == true ? 0.5 : 0.9),
                                  decoration: sub['completed'] == true ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _deleteSubtask(i),
                              icon: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent.withOpacity(0.8)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Remove',
                            )
                          ],
                        ),
                      );
                    }),
                  ),
                const SizedBox(height: 8),
              ],

              // Color picker section
              Padding(
                padding: EdgeInsets.only(top: AppTheme.smallPadding),
                child: Row(
                  children: [
                    Text(
                      "Task Color",
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (selectedColor != null)
                      TextButton(
                        onPressed: () { setState(() { _selectedColor = null; }); },
                        child: const Text('Clear', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._presetColors.map((c) {
                    final bool isSel = _selectedColor?.value == c.value;
                    return GestureDetector(
                      onTap: () { setState(() { _selectedColor = c; }); },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? Colors.white : Colors.black54,
                            width: isSel ? 3 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 3,
                              offset: const Offset(0,2),
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
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
