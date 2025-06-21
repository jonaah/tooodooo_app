import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/util/app_theme.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onSettingsSaved;
  const SettingsPage({super.key, this.onSettingsSaved});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _initialDisplayTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isEndTimeMidnight = true;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _loadTimes();
  }

  Future<void> _loadTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final endHour = prefs.getInt('calendarEndHour') ?? 24;
    setState(() {
      _startTime = TimeOfDay(
        hour: prefs.getInt('calendarStartHour') ?? 6,
        minute: prefs.getInt('calendarStartMinute') ?? 0,
      );
      _isEndTimeMidnight = endHour == 24;
      _endTime = TimeOfDay(
        hour: _isEndTimeMidnight ? 0 : endHour,
        minute: prefs.getInt('calendarEndMinute') ?? 0,
      );
      _initialDisplayTime = TimeOfDay(
        hour: prefs.getInt('calendarInitialDisplayHour') ?? 8,
        minute: prefs.getInt('calendarInitialDisplayMinute') ?? 0,
      );
      _hasChanged = false;
    });
  }

  Future<void> _saveTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('calendarStartHour', _startTime.hour);
    await prefs.setInt('calendarStartMinute', _startTime.minute);
    await prefs.setInt('calendarEndHour', _isEndTimeMidnight ? 24 : _endTime.hour);
    await prefs.setInt('calendarEndMinute', _isEndTimeMidnight ? 0 : _endTime.minute);
    await prefs.setInt('calendarInitialDisplayHour', _initialDisplayTime.hour);
    await prefs.setInt('calendarInitialDisplayMinute', _initialDisplayTime.minute);
    setState(() {
      _hasChanged = false;
    });
    widget.onSettingsSaved?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Einstellungen gespeichert und übernommen!')),
      );
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _hasChanged = true;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _isEndTimeMidnight = picked.hour == 0 && picked.minute == 0;
        _hasChanged = true;
      });
    }
  }

  Future<void> _pickInitialDisplayTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _initialDisplayTime,
    );
    if (picked != null) {
      setState(() {
        _initialDisplayTime = picked;
        _hasChanged = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: AppTheme.appBarTitle),
        backgroundColor: AppTheme.primaryColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text('Kalenderzeitraum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1, color: AppTheme.dividerColor),
                    ListTile(
                      leading: const Icon(Icons.play_arrow, color: AppTheme.accentColor),
                      title: const Text('Startzeit', style: TextStyle(fontSize: 16, color: AppTheme.darkTextColor)),
                      trailing: ElevatedButton(
                        onPressed: _pickStartTime,
                        style: AppTheme.primaryButtonStyle,
                        child: Text(_startTime.format(context)),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.stop, color: AppTheme.accentColor),
                      title: const Text('Endzeit', style: TextStyle(fontSize: 16, color: AppTheme.darkTextColor)),
                      trailing: ElevatedButton(
                        onPressed: _pickEndTime,
                        style: AppTheme.primaryButtonStyle,
                        child: Text(_isEndTimeMidnight ? '24:00' : _endTime.format(context)),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.visibility, color: AppTheme.accentColor),
                      title: const Text('Anfangszeit Ansicht', style: TextStyle(fontSize: 16, color: AppTheme.darkTextColor)),
                      trailing: ElevatedButton(
                        onPressed: _pickInitialDisplayTime,
                        style: AppTheme.primaryButtonStyle,
                        child: Text(_initialDisplayTime.format(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.palette, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text('App Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1, color: AppTheme.dividerColor),
                    ListTile(
                      leading: const Icon(Icons.brightness_6, color: AppTheme.accentColor),
                      title: const Text('Designmodus', style: TextStyle(fontSize: 16, color: AppTheme.darkTextColor)),
                      subtitle: const Text('Bald verfügbar', style: TextStyle(fontSize: 12, color: AppTheme.secondaryTextColor)),
                      trailing: Switch(
                        value: false,
                        onChanged: null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: _hasChanged ? _saveTimes : null,
                style: AppTheme.primaryButtonStyle,
                icon: const Icon(Icons.save),
                label: const Text('Speichern'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
