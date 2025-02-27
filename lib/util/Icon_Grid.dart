import 'package:flutter/material.dart';

class IconGrid extends StatefulWidget {
  final List<IconData> icons;
  final ValueChanged<IconData> onIconSelected;

  const IconGrid({
    super.key,
    required this.icons,
    required this.onIconSelected,
  });

  @override
  _IconGridState createState() => _IconGridState();
}

class _IconGridState extends State<IconGrid> {
  IconData? _selectedIcon;

  void _handleIconTap(IconData icon) {
    setState(() {
      _selectedIcon = icon;
    });
    widget.onIconSelected(icon);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
      ),
      itemCount: widget.icons.length,
      itemBuilder: (context, index) {
        final icon = widget.icons[index];
        final isSelected = _selectedIcon == icon;
        return GestureDetector(
          onTap: () => _handleIconTap(icon),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        );
      },
    );
  }
}