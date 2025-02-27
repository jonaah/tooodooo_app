import 'package:flutter/material.dart';
import 'package:tooodooo_app/pages/emoji_picker_page.dart';
import 'package:tooodooo_app/util/icon_manager.dart';
import 'package:tooodooo_app/util/my_button.dart';
import 'package:tooodooo_app/util/slider_element.dart';

class DialogBox extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final GlobalKey<SliderElementState> sliderKey;
  final Function(IconData) onIconSelected;

  const DialogBox({
    super.key,
    required this.controller,
    required this.onSave,
    required this.onCancel,
    required this.sliderKey,
    required this.onIconSelected,
  });

  @override
  _DialogBoxState createState() => _DialogBoxState();
}

class _DialogBoxState extends State<DialogBox> {
  IconData? _selectedIcon;

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

  @override
  Widget build(BuildContext context) {
    // Get icons to display - these should be exactly 10 icons
    final List<IconData> displayIcons = IconManager.recentIcons;
    
    // Safety check - ensure we have enough icons to display
    final int firstRowCount = displayIcons.length >= 5 ? 5 : displayIcons.length;
    final bool hasSecondRow = displayIcons.length > 5;
    final int secondRowCount = hasSecondRow ? displayIcons.length - 5 : 0;

    return AlertDialog(
      backgroundColor: Colors.brown[200],
      content: SizedBox(
        width: 300,
        height: 350, // Increased height to fix overflow
        child: SingleChildScrollView( // Added ScrollView to handle overflow
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use min size to avoid expansion
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
                padding: EdgeInsets.only(top: 4.0, bottom: 2.0), // Reduced padding
                child: Text(
                  "Task Icon",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
              // First row of icons (up to 5)
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
                      child: Icon(icon, color: isSelected ? Colors.white : Colors.black, size: 24), // Reduced size
                    ),
                  );
                }).toList(),
              ),
              // Second row of icons if available
              if (hasSecondRow)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0), // Reduced padding
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
                          child: Icon(icon, color: isSelected ? Colors.white : Colors.black, size: 24), // Reduced size
                        ),
                      );
                    }).toList(),
                  ),
                ),
              // Button to access more icons
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0), // Reduced padding
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
              // Save/Cancel buttons
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