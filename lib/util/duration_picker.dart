import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:tooodooo_app/util/app_theme.dart';

class DurationPickerDialog extends StatefulWidget {
  final int initialHours;
  final int initialMinutes;
  final ValueChanged<Map<String, int>>? onChanged;
  final VoidCallback? onCancelled;
  
  const DurationPickerDialog({
    super.key,
    this.initialHours = 0,
    this.initialMinutes = 0,
    this.onChanged,
    this.onCancelled,
  });

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late int _hours;
  late int _minutes;
  
  // Whether we're in manual input mode (for durations >= 24h)
  bool _manualMode = false;
  
  // Controllers for the CupertinoPickers – held as state to avoid rebuild issues
  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minutesController;
  
  // Controllers for manual text input
  late TextEditingController _manualHoursController;
  late TextEditingController _manualMinutesController;
  
  // Focus nodes for manual input
  final FocusNode _hoursFocusNode = FocusNode();
  final FocusNode _minutesFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _hours = widget.initialHours;
    _minutes = widget.initialMinutes;
    
    // If initial value is >= 24h, start in manual mode
    _manualMode = _hours >= 24;
    
    _hoursController = FixedExtentScrollController(
      initialItem: _manualMode ? 24 : _hours,
    );
    _minutesController = FixedExtentScrollController(
      initialItem: (_minutes / 5).round(),
    );
    
    _manualHoursController = TextEditingController(
      text: _hours.toString(),
    );
    _manualMinutesController = TextEditingController(
      text: _minutes.toString().padLeft(2, '0'),
    );
  }
  
  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _manualHoursController.dispose();
    _manualMinutesController.dispose();
    _hoursFocusNode.dispose();
    _minutesFocusNode.dispose();
    super.dispose();
  }
  
  void _notifyChanged() {
    widget.onChanged?.call(_getResult());
  }
  
  void _onHoursChanged(int index) {
    setState(() {
      if (index == 24) {
        // Switch to manual mode
        _hours = 24;
        _manualMode = true;
        _manualHoursController.text = '24';
        _manualMinutesController.text = _minutes.toString().padLeft(2, '0');
      } else {
        _hours = index;
        // If we were in manual mode and scrolled back, stay in picker mode
        if (_manualMode) {
          _manualMode = false;
        }
      }
    });
    _notifyChanged();
  }
  
  void _onMinutesChanged(int index) {
    setState(() {
      _minutes = index * 5;
    });
    _notifyChanged();
  }
  
  void _switchToPickerMode() {
    setState(() {
      _manualMode = false;
      // Parse current manual values and clamp to picker range
      final parsedHours = int.tryParse(_manualHoursController.text) ?? 0;
      _hours = parsedHours.clamp(0, 23);
      final parsedMinutes = int.tryParse(_manualMinutesController.text) ?? 0;
      _minutes = (parsedMinutes ~/ 5) * 5; // Round to nearest 5
      _minutes = _minutes.clamp(0, 55);
      
      // Recreate controllers for new positions
      _hoursController.dispose();
      _minutesController.dispose();
      _hoursController = FixedExtentScrollController(initialItem: _hours);
      _minutesController = FixedExtentScrollController(initialItem: _minutes ~/ 5);
    });
    _notifyChanged();
  }
  
  Map<String, int> _getResult() {
    int hours = _hours;
    int minutes = _minutes;
    
    if (_manualMode) {
      hours = int.tryParse(_manualHoursController.text) ?? 0;
      minutes = int.tryParse(_manualMinutesController.text) ?? 0;
      if (hours < 0) hours = 0;
      if (minutes < 0) minutes = 0;
      if (minutes > 59) minutes = 59;
    }
    
    return {'hours': hours, 'minutes': minutes};
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.primaryColor,
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
      content: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: _manualMode ? _buildManualInput() : _buildPickerInput(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onCancelled?.call();
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textColor.withOpacity(0.7),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: AppTheme.textColor.withOpacity(0.7),
              fontSize: 15,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          child: const Text(
            'Save',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPickerInput() {
    return SizedBox(
      height: 200,
      child: Column(
        children: [
          // Labels row
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    'Hours',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textColor.withOpacity(0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 24), // Space for the colon
                SizedBox(
                  width: 80,
                  child: Text(
                    'Minutes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textColor.withOpacity(0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Picker row
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hours wheel (0–24, where 24 triggers manual mode)
                SizedBox(
                  width: 80,
                  child: CupertinoPicker(
                    backgroundColor: Colors.transparent,
                    selectionOverlay: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.accentColor.withOpacity(0.12),
                        border: Border(
                          top: BorderSide(
                            color: AppTheme.accentColor.withOpacity(0.3),
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: AppTheme.accentColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    itemExtent: 36,
                    looping: false,
                    onSelectedItemChanged: _onHoursChanged,
                    scrollController: _hoursController,
                    children: List<Widget>.generate(25, (index) {
                      final bool isManualTrigger = index == 24;
                      return Center(
                        child: Text(
                          isManualTrigger
                              ? '24+ h'
                              : '${index.toString().padLeft(2, '0')} h',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: isManualTrigger
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isManualTrigger
                                ? AppTheme.accentColor
                                : AppTheme.textColor,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                
                // Divider colon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor.withOpacity(0.6),
                    ),
                  ),
                ),
                
                // Minutes wheel (0, 5, 10, ... 55)
                SizedBox(
                  width: 80,
                  child: CupertinoPicker(
                    backgroundColor: Colors.transparent,
                    selectionOverlay: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.accentColor.withOpacity(0.12),
                        border: Border(
                          top: BorderSide(
                            color: AppTheme.accentColor.withOpacity(0.3),
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: AppTheme.accentColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    itemExtent: 36,
                    looping: true,
                    onSelectedItemChanged: _onMinutesChanged,
                    scrollController: _minutesController,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildManualInput() {
    return SizedBox(
      height: 160,
      child: Column(
        children: [
          // Back to picker button
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: _switchToPickerMode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 14,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Back to picker',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  'Hours',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 30),
              SizedBox(
                width: 90,
                child: Text(
                  'Minutes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Input fields
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hours input
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _manualHoursController,
                  focusNode: _hoursFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: (_) => _notifyChanged(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    filled: true,
                    fillColor: AppTheme.accentColor.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.accentColor.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.accentColor.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.accentColor,
                        width: 1.5,
                      ),
                    ),
                    hintText: '00',
                    hintStyle: TextStyle(
                      color: AppTheme.textColor.withOpacity(0.2),
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Colon separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor.withOpacity(0.6),
                  ),
                ),
              ),
              // Minutes input
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _manualMinutesController,
                  focusNode: _minutesFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  onChanged: (_) => _notifyChanged(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    filled: true,
                    fillColor: AppTheme.accentColor.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.accentColor.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.accentColor.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.accentColor,
                        width: 1.5,
                      ),
                    ),
                    hintText: '00',
                    hintStyle: TextStyle(
                      color: AppTheme.textColor.withOpacity(0.2),
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<Map<String, int>?> showDurationPicker({
  required BuildContext context,
  int initialHours = 0,
  int initialMinutes = 0,
}) async {
  // Track the latest values via callback – this way barrier dismiss
  // (tap outside) automatically returns the current values.
  Map<String, int> latestValues = {
    'hours': initialHours,
    'minutes': initialMinutes,
  };
  bool wasCancelled = false;
  
  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return DurationPickerDialog(
        initialHours: initialHours,
        initialMinutes: initialMinutes,
        onChanged: (values) => latestValues = values,
        onCancelled: () => wasCancelled = true,
      );
    },
  );
  
  // Cancel → null, everything else (Save / barrier dismiss) → save values
  return wasCancelled ? null : latestValues;
}
