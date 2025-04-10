import 'package:flutter/material.dart';
import 'package:tooodooo_app/util/app_theme.dart';

class SliderElement extends StatefulWidget {
  const SliderElement({super.key});

  @override
  State<SliderElement> createState() => SliderElementState();
}

class SliderElementState extends State<SliderElement> {
  double _sliderValue = 1.0;

  double getSliderValue() {
    return _sliderValue;
  }

  void setSliderValue(double value) {
    setState(() {
      _sliderValue = value;
    });
  }

  // Verbesserte Farbpalette: Grün -> Blau -> Orange -> Rot
  Color? taskPriorityColor(double sliderValue) {
    switch (sliderValue.round()) {
      case 1:
        return Colors.green[600]; // Niedrigste Priorität - Grün
      case 2:
        return Colors.teal[500]; // Niedrige Priorität - Teal
      case 3:
        return Colors.blue[500]; // Mittlere Priorität - Blau
      case 4:
        return Colors.orange[600]; // Hohe Priorität - Orange
      case 5:
        return Colors.red[600]; // Höchste Priorität - Rot
      default:
        return Colors.grey[500];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _sliderValue,
      min: 1,
      max: 5,
      divisions: 4,
      activeColor: taskPriorityColor(_sliderValue),
      inactiveColor: Colors.grey[600],
      label: _sliderValue.round().toString(),
      onChanged: (double value) {
        setState(() {
          _sliderValue = value;
        });
      },
    );
  }
}
