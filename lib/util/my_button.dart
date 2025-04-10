import 'package:flutter/material.dart';
import 'package:tooodooo_app/util/app_theme.dart';

class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  
  MyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: isPrimary ? AppTheme.primaryButtonStyle : AppTheme.secondaryButtonStyle,
      child: Text(text),
    );
  }
}
