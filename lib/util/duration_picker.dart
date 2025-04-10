import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:tooodooo_app/util/app_theme.dart';

class DurationPickerDialog extends StatefulWidget {
  final int initialHours;
  final int initialMinutes;
  
  const DurationPickerDialog({
    Key? key,
    this.initialHours = 0,
    this.initialMinutes = 0,
  }) : super(key: key);

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late int _hours;
  late int _minutes;
  
  @override
  void initState() {
    super.initState();
    _hours = widget.initialHours;
    _minutes = widget.initialMinutes;
  }
  
  // Handle minutes overflow and underflow
  void _updateMinutes(int newMinuteIndex) {
    final int oldMinuteIndex = (_minutes / 5).round();
    
    // Check if we're scrolling up or down
    if ((newMinuteIndex == 0 && oldMinuteIndex == 11) || 
        (newMinuteIndex > oldMinuteIndex && newMinuteIndex - oldMinuteIndex > 6) ||
        (newMinuteIndex < oldMinuteIndex && oldMinuteIndex - newMinuteIndex < 6)) {
      // Scrolling up, add an hour when minutes overflow
      setState(() {
        _minutes = newMinuteIndex * 5;
        if (_hours < 23) {
          _hours++;
        }
      });
    } else if ((newMinuteIndex == 11 && oldMinuteIndex == 0) || 
              (newMinuteIndex < oldMinuteIndex && oldMinuteIndex - newMinuteIndex > 6) ||
              (newMinuteIndex > oldMinuteIndex && newMinuteIndex - oldMinuteIndex < 6)) {
      // Scrolling down, subtract an hour when minutes underflow
      setState(() {
        _minutes = newMinuteIndex * 5;
        if (_hours > 0) {
          _hours--;
        }
      });
    } else {
      // Normal minute change, no overflow/underflow
      setState(() {
        _minutes = newMinuteIndex * 5;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.primaryColor, // Removed opacity for clarity
      title: Text(
        'Set Duration',
        style: TextStyle(
          color: AppTheme.textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      content: Container(
        height: 180,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hours wheel
            SizedBox(
              width: 70,
              child: CupertinoPicker(
                selectionOverlay: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppTheme.accentColor, width: 1.5),
                      bottom: BorderSide(color: AppTheme.accentColor, width: 1.5),
                    ),
                  ),
                ),
                itemExtent: 32,
                looping: false, // Don't loop hours
                onSelectedItemChanged: (index) {
                  setState(() {
                    _hours = index;
                  });
                },
                scrollController: FixedExtentScrollController(
                  initialItem: _hours,
                ),
                children: List<Widget>.generate(24, (index) {
                  return Center(
                    child: Text(
                      '${index.toString().padLeft(2, '0')} h',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppTheme.textColor,
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // Divider between hours and minutes
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                ':',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            
            // Minutes wheel
            SizedBox(
              width: 80,
              child: CupertinoPicker(
                selectionOverlay: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppTheme.accentColor, width: 1.5),
                      bottom: BorderSide(color: AppTheme.accentColor, width: 1.5),
                    ),
                  ),
                ),
                itemExtent: 32,
                looping: true, // Allow minutes to loop
                onSelectedItemChanged: _updateMinutes,
                children: List<Widget>.generate(12, (index) {
                  return Center(
                    child: Text(
                      '${(index * 5).toString().padLeft(2, '0')} min',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppTheme.textColor,
                      ),
                    ),
                  );
                }),
                scrollController: FixedExtentScrollController(
                  initialItem: (_minutes / 5).round(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
          ),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop({
              'hours': _hours,
              'minutes': _minutes,
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.accentColor,
          ),
          child: Text('Save'),
        ),
      ],
    );
  }
}

Future<Map<String, int>?> showDurationPicker({
  required BuildContext context,
  int initialHours = 0,
  int initialMinutes = 0,
}) async {
  return await showDialog<Map<String, int>>(
    context: context,
    builder: (BuildContext context) {
      return DurationPickerDialog(
        initialHours: initialHours,
        initialMinutes: initialMinutes,
      );
    },
  );
}
