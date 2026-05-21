import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooodooo_app/util/app_theme.dart';
import 'package:tooodooo_app/calendar/google_calendar_client.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

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

  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadTimes();
    _initGoogleSignIn();
  }

  void _initGoogleSignIn() {
    GoogleCalendarClient.googleSignIn.onCurrentUserChanged.listen((account) {
      if (mounted) {
        setState(() {
          _currentUser = account;
        });
      }
    });
    // Check if implicitly signed in
    _currentUser = GoogleCalendarClient.googleSignIn.currentUser;
  }

  Future<void> _testGoogleCalendarInsert() async {
    try {
      // 1. Hole den authentifizierten API-Client
      final calendarApi = await GoogleCalendarClient.getCalendarApi();

      if (calendarApi == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kalender-API nicht bereit. Bitte erst einloggen.')),
          );
        }
        return;
      }

      // 2. Erstelle ein Test-Event
      final event = calendar.Event()
        ..summary = 'Test von Tooodooo App'
        ..description = 'Dies ist ein automatisch erstellter Test-Termin.'
        ..start = (calendar.EventDateTime()
          ..dateTime = DateTime.now().add(const Duration(hours: 1)).toUtc()
          ..timeZone = 'UTC')
        ..end = (calendar.EventDateTime()
          ..dateTime = DateTime.now().add(const Duration(hours: 2)).toUtc()
          ..timeZone = 'UTC');

      // 3. In den Hauptkalender ('primary') einfügen
      await calendarApi.events.insert(event, 'primary');


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test-Termin erfolgreich erstellt! Schau in deinen Kalender.')),
        );
      }
    } catch (e) {
      print('Fehler beim Kalender-Test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  Future<List<calendar.Event>> _getEventsFromGoogleCalendar() async {
    final calendarApi = await GoogleCalendarClient.getCalendarApi();
    if (calendarApi == null) return [];

    try {
      final events = await calendarApi.events.list(
        'primary',
        maxResults: 10,
        orderBy: 'startTime',
        singleEvents: true,
        timeMin: DateTime.now().toUtc(), // Stellt sicher, dass zukünftige Termine geladen werden
      );
      return events.items ?? [];
    } catch (e) {
      print('Fehler beim Abrufen der Events: $e');
      return [];
    }
  }

  Future<void> _testDeleteGoogleCalendarEvent(String? id) async {
    if (id == null) return;
    try {
      final calendarApi = await GoogleCalendarClient.getCalendarApi();
      if (calendarApi == null) return;

      await calendarApi.events.delete('primary', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Termin erfolgreich gelöscht!')),
        );
      }
    } catch (e) {
      print('Fehler beim Löschen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Löschen: $e')),
        );
      }
    }
  }

  Future<void> _showEventsListDialog() async {
    List<calendar.Event> events = await _getEventsFromGoogleCalendar();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nächste 10 Termine'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: events.isEmpty
                    ? const Center(child: Text('Keine Termine gefunden.'))
                    : ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          final timeStr = event.start?.dateTime?.toLocal().toString().substring(0, 16) ?? 'Keine Startzeit';
                          return ListTile(
                            title: Text(event.summary ?? '(Ohne Titel)'),
                            subtitle: Text(timeStr),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _testDeleteGoogleCalendarEvent(event.id);
                                setState(() {
                                  events.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Schließen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final account = await GoogleCalendarClient.signIn();
    if (account != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erfolgreich eingeloggt als ${account.email}')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login abgebrochen oder fehlgeschlagen')),
        );
      }
    }
  }

  Future<void> _handleGoogleSignOut() async {
    await GoogleCalendarClient.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erfolgreich abgemeldet')),
      );
    }
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
                        Icon(Icons.sync, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text('Google Kalender', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1, color: AppTheme.dividerColor),
                    ListTile(
                      leading: const Icon(Icons.cloud_sync, color: AppTheme.accentColor),
                      title: Text(
                        _currentUser == null ? 'Nicht verbunden' : 'Verbunden mit',
                        style: const TextStyle(fontSize: 16, color: AppTheme.darkTextColor)
                      ),
                      subtitle: _currentUser != null
                        ? Text(_currentUser!.email, style: const TextStyle(fontSize: 12, color: AppTheme.secondaryTextColor))
                        : const Text('Tippe, um sich anzumelden'),
                      trailing: ElevatedButton(
                        onPressed: _currentUser == null ? _handleGoogleSignIn : _handleGoogleSignOut,
                        style: _currentUser == null ? AppTheme.primaryButtonStyle : ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text(_currentUser == null ? 'Login' : 'Logout', style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                    if (_currentUser != null) ...[ // Nur anzeigen, wenn eingeloggt
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: OutlinedButton.icon(
                          onPressed: _testGoogleCalendarInsert,
                          icon: const Icon(Icons.add_alert),
                          label: const Text('Test-Termin erstellen'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                        child: OutlinedButton.icon(
                          onPressed: _showEventsListDialog,
                          icon: const Icon(Icons.list_alt),
                          label: const Text('Events anzeigen & löschen'),
                        ),
                      ),
                    ],
                ]
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
