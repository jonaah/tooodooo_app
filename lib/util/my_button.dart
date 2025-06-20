import 'package:flutter/material.dart';
import 'package:tooodooo_app/util/app_theme.dart';

class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color backgroundColor;
  final Color textColor;
  
  MyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
