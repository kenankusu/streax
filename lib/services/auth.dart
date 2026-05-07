import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:streax/Models/user.dart';

/// Authentication Service für Firebase Auth-Operationen
/// Verwaltet Registrierung, Login, Email-Verifizierung und Passwort-Reset
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Konvertiert Firebase User zu StreaxUser - nur für verifizierte Accounts
  StreaxUser? _userFromFirebaseUser(User? user) {
    return (user != null && user.emailVerified) ? StreaxUser(uid: user.uid) : null;
  }

  /// Haupt-Auth-Stream für den Provider - nur verifizierte User
  Stream<StreaxUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  /// Prüft ob User eingeloggt aber noch nicht verifiziert ist
  bool get isUserLoggedInButNotVerified {
    final user = _auth.currentUser;
    return user != null && !user.emailVerified;
  }

  /// Direkter Zugriff auf Firebase-User für Verifizierungs-Operationen
  User? get currentUser => _auth.currentUser;

  /// Login mit Email/Passwort und Email-Verifizierung-Check
  /// Wirft FirebaseAuthException bei Fehlern
  Future<StreaxUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Deutsche Firebase-Nachrichten aktivieren
      await _auth.setLanguageCode('de');
      
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(), 
        password: password
      );
      
      User? user = result.user;

      // Email-Verifizierung sofort prüfen
      if (user != null && !user.emailVerified) {
        debugPrint('Login erfolgreich, aber Email nicht verifiziert für: ${user.email}');
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Email-Adresse ist nicht verifiziert'
        );
      }

      debugPrint('Login erfolgreich für: ${user?.email}');
      return _userFromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      debugPrint('Anmelde-Fehler: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unerwarteter Login-Fehler: ${e.toString()}');
      rethrow;
    }
  }

  /// Registrierung mit automatischer Email-Verifizierung
  /// Gibt detaillierte Erfolgs/Fehler-Map zurück
  Future<Map<String, dynamic>> registerWithEmailAndPassword(String email, String password) async {
    try {
      // Deutsche Firebase-Nachrichten aktivieren
      await _auth.setLanguageCode('de');
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), 
        password: password
      );
      
      User? user = result.user;
      
      if (user != null) {
        // Verifizierungs-Email sofort senden
        await user.sendEmailVerification();
        debugPrint('Registrierung erfolgreich für: ${user.email}, Verifizierungs-Email gesendet');
        
        return {
          'success': true,
          'user': user,
          'uid': user.uid,
          'email': user.email,
          'message': 'Verifizierungs-Email gesendet'
        };
      } else {
        return {
          'success': false,
          'error': 'Unbekannter Fehler bei der Registrierung'
        };
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Registrierungs-Fehler: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': _getGermanErrorMessage(e.code)
      };
    } catch (e) {
      debugPrint('Unerwarteter Registrierungs-Fehler: ${e.toString()}');
      return {
        'success': false,
        'error': 'Ein unerwarteter Fehler ist aufgetreten'
      };
    }
  }

  /// Konvertiert Firebase-Fehlercodes zu deutschen Benutzer-Nachrichten
  String _getGermanErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Das Passwort ist zu schwach (mindestens 10 Zeichen)';
      case 'email-already-in-use':
        return 'Diese Email-Adresse wird bereits verwendet';
      case 'invalid-email':
        return 'Ungültige Email-Adresse';
      case 'operation-not-allowed':
        return 'Email/Passwort-Anmeldung ist deaktiviert';
      case 'too-many-requests':
        return 'Zu viele Anfragen. Bitte versuche es später erneut';
      default:
        return 'Registrierung fehlgeschlagen. Bitte versuche es erneut';
    }
  }

  /// Verifizierungs-Email erneut senden mit Spam-Schutz
  /// Behandelt "too-many-requests" als Erfolg da Email bereits versendet
  Future<bool> resendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        debugPrint('Kein User eingeloggt für Email-Resend');
        return false;
      }

      // User-Status vom Server aktualisieren
      await user.reload();
      user = _auth.currentUser;
      
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint('Verifizierungs-Email erneut gesendet an: ${user.email}');
        return true;
      } else if (user != null && user.emailVerified) {
        debugPrint('User ${user.email} ist bereits verifiziert');
        return false;
      } else {
        debugPrint('Kein User eingeloggt oder bereits verifiziert');
        return false;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Fehler beim Email-Resend: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'too-many-requests':
          debugPrint('Email-Spam-Schutz aktiv - Email wurde bereits kürzlich gesendet');
          return true; // Als Erfolg werten, da Email bereits versendet wurde
        case 'user-not-found':
          debugPrint('User für Email-Resend nicht gefunden');
          return false;
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Unerwarteter Fehler beim Email-Resend: $e');
      return false;
    }
  }

  /// Email-Verifizierungsstatus mit Server-Synchronisation prüfen
  /// Wartet kurz für Firebase-Server-Synchronisation
  Future<bool> checkEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        debugPrint('Kein User für Verifizierungs-Check eingeloggt');
        return false;
      }

      // User-Daten vom Firebase-Server neu laden
      await user.reload();
      // Kurze Wartezeit für Server-Synchronisation
      await Future.delayed(const Duration(seconds: 1));
        
      // Aktuellen User-Status holen
      user = _auth.currentUser;
      bool isVerified = user?.emailVerified ?? false;
        
      debugPrint('Email-Verifizierung Status für ${user?.email}: $isVerified');
      return isVerified;
    } catch (e) {
      debugPrint('Fehler beim Email-Verifizierungs-Check: $e');
      return false;
    }
  }

  /// Sicherer Logout mit vollständiger Session-Bereinigung
  Future<void> signOut() async {
    try {
      final userEmail = _auth.currentUser?.email;
      await _auth.signOut();
      debugPrint('Logout erfolgreich für: $userEmail');
    } catch (e) {
      debugPrint('Logout-Fehler: ${e.toString()}');
    }
  }

  /// Account vollständig und unwiderruflich löschen
  Future<bool> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        debugPrint('Kein User für Account-Löschung eingeloggt');
        return false;
      }

      final userEmail = user.email;

      // Firebase Auth Account löschen (beendet Session automatisch)
      await user.delete();

      debugPrint('Firebase Auth Account erfolgreich gelöscht für: $userEmail');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Löschungs-Fehler: ${e.code} - ${e.message}');
      if (e.code == 'requires-recent-login') {
        debugPrint('Account-Löschung erfordert erneute Anmeldung');
      }
      return false;
    } catch (e) {
      debugPrint('Unerwarteter Account-Löschungs-Fehler: ${e.toString()}');
      return false;
    }
  }

  /// Passwort-Reset-Email versenden mit deutscher Lokalisierung
  /// Wirft FirebaseAuthException bei spezifischen Fehlern
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      // Deutsche Reset-Emails aktivieren
      await _auth.setLanguageCode('de');
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('Passwort-Reset-Email gesendet an: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Passwort-Reset Firebase-Fehler: ${e.code} - ${e.message}');
      rethrow; // Spezifische Fehlerbehandlung im UI
    } catch (e) {
      debugPrint('Unerwarteter Passwort-Reset-Fehler: $e');
      return false;
    }
  }
}
