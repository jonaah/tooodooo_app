import 'package:flutter/material.dart';


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

  Color? taskPriorityColor(double sliderValue) {
    switch (sliderValue.round()) {
      case 1:
        return Colors.blue[300];
      case 2:
        return Colors.green[300];
      case 3:
        return Colors.yellow[800];
      case 4:
        return Colors.orange[500];
      case 5:
        return Colors.red[300];
      default:
        return Colors.grey[300];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _sliderValue,
      min: 1, // Add minimum value
      max: 5,
      divisions: 4, // Change to 4 since we now have 5 steps (1-5)
      activeColor: taskPriorityColor(_sliderValue),
      label: _sliderValue.round().toString(),
      onChanged: (double value) {
        setState(() {
          _sliderValue = value;
        });
      },
    );
  }
}
