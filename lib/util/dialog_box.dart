import 'package:flutter/material.dart';
import 'package:tooodooo_app/pages/emoji_picker_page.dart';
import 'package:tooodooo_app/util/icon_manager.dart';
import 'package:tooodooo_app/util/my_button.dart';
import 'package:tooodooo_app/util/slider_element.dart';
import 'package:tooodooo_app/util/duration_picker.dart';

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
      backgroundColor: Colors.brown[200],
      title: Text(
        widget.isEditing ? "Edit Task" : "Add Task",
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 300,
        height: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(
                child: TextField(
                  controller: widget.controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    hintText: 'Enter Task',
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Priority Level",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
              SliderElement(key: widget.sliderKey),
              const Padding(
                padding: EdgeInsets.only(top: 4.0, bottom: 2.0),
                child: Text(
                  "Task Icon",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: displayIcons.take(firstRowCount).map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => _handleIconTap(icon),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(icon, color: isSelected ? Colors.white : Colors.black, size: 24),
                    ),
                  );
                }).toList(),
              ),
              if (hasSecondRow)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: displayIcons.sublist(5, 5 + secondRowCount).map((icon) {
                      final isSelected = _selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => _handleIconTap(icon),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[300] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(icon, color: isSelected ? Colors.white : Colors.black, size: 24),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                child: TextButton(
                  onPressed: _openEmojiPicker,
                  child: const Text(
                    "More Icons",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Duration",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Duration',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  InkWell(
                    onTap: _openDurationPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            formattedDuration(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MyButton(text: "Save", onPressed: widget.onSave),
                  const SizedBox(width: 50),
                  MyButton(text: "Cancel", onPressed: widget.onCancel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}