import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

class GoogleCalendarClient {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [calendar.CalendarApi.calendarScope],
  );

  /// Zeigt den Google-Login-Dialog an
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      // API Exception 10 often means SHA-1 mismatch or wrong Client ID type
      print('Fehler beim Google Login: $e');
      return null;
    }
  }

  /// Meldet den Benutzer ab
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Gibt die aktuelle GoogleSignIn-Instanz zurück (z. B. um den User abzufragen)
  static GoogleSignIn get googleSignIn => _googleSignIn;

  /// Liefert eine einsatzbereite Instanz der CalendarApi.
  /// Gibt null zurück, wenn der Nutzer nicht eingeloggt ist.
  static Future<calendar.CalendarApi?> getCalendarApi() async {
    try {
      var account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();

      if (account == null) {
        print('Kein eingeloggter Google-Nutzer gefunden.');
        return null;
      }

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        print('Konnte keinen authentifizierten Client erstellen.');
        return null;
      }

      return calendar.CalendarApi(authClient);
    } catch (e) {
      print('Fehler beim Abrufen der Calendar API: $e');
      return null;
    }
  }
}