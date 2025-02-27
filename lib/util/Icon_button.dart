import 'package:flutter/material.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.lock_clock,
      Icons.sports_soccer,
      Icons.favorite,
      Icons.home,
      Icons.work_history,
      Icons.school,
      Icons.pets,
      Icons.music_note,
      Icons.sports_football,
      Icons.local_florist,
    ];
    return AlertDialog(
      backgroundColor: Colors.brown[200],
      content: SizedBox(
        height: 280,
        child: Column(
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
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: icons.sublist(0, 5).map((icon) {
                    final isSelected = _selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => _handleIconTap(icon),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(icon, color: isSelected ? Colors.white : Colors.black, size: 32),
                      ),
                    );
                  }).toList(),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: icons.sublist(5, 10).map((icon) {
                      final isSelected = _selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => _handleIconTap(icon),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[300] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(icon, color: isSelected ? Colors.white : Colors.black, size: 32),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MyButton(text: "Save", onPressed: widget.onSave),
                  const SizedBox(width: 50),
                  MyButton(text: "Cancel", onPressed: widget.onCancel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}