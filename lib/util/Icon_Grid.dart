import 'package:flutter/material.dart';
import 'package:tooodooo_app/util/app_theme.dart';

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
      physics: const NeverScrollableScrollPhysics(),
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
      },
    );
  }
}