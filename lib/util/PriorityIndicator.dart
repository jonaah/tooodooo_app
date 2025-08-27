import 'package:flutter/material.dart';

class PriorityIndicator extends StatelessWidget {
  final int priority; // 1 bis 5
  final double width;
  final double height;
  final Color activeColor;
  final Color inactiveColor;
  final Color borderColor;
  final bool vertical; // neu: Ausrichtung
  final double spacing;

  const PriorityIndicator({
    Key? key,
    required this.priority,
    this.width = 20.0,
    this.height = 20.0,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
    this.borderColor = Colors.black54,
    this.vertical = true,
    this.spacing = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p = priority.clamp(0, 5);
    if (vertical) {
      final segmentHeight = (height - (4 * spacing)) / 5;
      return SizedBox(
        width: width,
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final bool isActive = (5 - index) <= p; // von unten nach oben
            return Container(
              width: width,
              height: segmentHeight,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor.withOpacity(0.25),
                border: Border.all(color: borderColor.withOpacity(0.4), width: 0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }).reversed.toList(),
        ),
      );
    } else {
      final segmentWidth = (width - (4 * spacing)) / 5;
      return SizedBox(
        width: width,
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final bool isActive = index < p; // links nach rechts fuellen
            return Container(
              width: segmentWidth,
              height: height,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor.withOpacity(0.25),
                border: Border.all(color: borderColor.withOpacity(0.4), width: 0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        ),
      );
    }
  }
}
