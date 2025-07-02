import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:streax/Models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User-Objekt nur für verifizierte Firebase-User erstellen
  StreaxUser? _userFromFirebaseUser(User? user) {
    return (user != null && user.emailVerified) ? StreaxUser(uid: user.uid) : null;
  }

  // Haupt-Auth-Stream für Provider
  Stream<StreaxUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // Prüft ob User eingeloggt aber nicht verifiziert ist
  bool get isUserLoggedInButNotVerified {
    final user = _auth.currentUser;
    return user != null && !user.emailVerified;
  }

  // Direkter Zugriff auf Firebase-User für Verifizierungs-Operationen
  User? get currentUser => _auth.currentUser;

  // Login-Methode mit Email-Verifizierung Check
  Future<StreaxUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.setLanguageCode('de');
      
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? user = result.user;

      // Sofort prüfen ob Email verifiziert ist
      if (user != null && !user.emailVerified) {
        debugPrint('Login erfolgreich, aber Email nicht verifiziert');
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Email-Adresse ist nicht verifiziert'
        );
      }

      debugPrint('Login erfolgreich');
      return _userFromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      debugPrint('Anmelde-Fehler: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Anmelde-Fehler: ${e.toString()}');
      rethrow;
    }
  }

  // Registrierung mit automatischer Email-Verifizierung
  Future<Map<String, dynamic>> registerWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.setLanguageCode('de');
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? user = result.user;
      
      if (user != null) {
        await user.sendEmailVerification();
        debugPrint('Registrierung erfolgreich, Verifizierungs-Email gesendet');
        
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
      debugPrint('Registrierungs-Fehler: ${e.toString()}');
      return {
        'success': false,
        'error': 'Ein unerwarteter Fehler ist aufgetreten'
      };
    }
  }

  // Deutsche Fehlermeldungen
  String _getGermanErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Das Passwort ist zu schwach';
      case 'email-already-in-use':
        return 'Diese Email-Adresse wird bereits verwendet';
      case 'invalid-email':
        return 'Ungültige Email-Adresse';
      case 'operation-not-allowed':
        return 'Email/Passwort-Anmeldung ist deaktiviert';
      default:
        return 'Registrierung fehlgeschlagen';
    }
  }

  // Verifizierungs-Email erneut senden
  Future<bool> resendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.reload(); // User-Status vom Server aktualisieren
        user = _auth.currentUser;
        
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          debugPrint('Verifizierungs-Email erneut gesendet an: ${user.email}');
          return true;
        } else {
          debugPrint('User ist bereits verifiziert');
          return false;
        }
      } else {
        debugPrint('Kein User eingeloggt oder bereits verifiziert');
        return false;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Fehler: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'too-many-requests':
          debugPrint('Zu viele Requests - Email wurde bereits gesendet');
          return true; // Als Erfolg werten da Email bereits versendet
        case 'user-not-found':
          debugPrint('User nicht gefunden');
          return false;
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Allgemeiner Fehler beim Email-Versand: $e');
      return false;
    }
  }

  // Email-Verifizierungsstatus prüfen mit Server-Reload
  Future<bool> checkEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // User-Daten vom Firebase-Server neu laden
        await user.reload();
        await Future.delayed(const Duration(seconds: 2)); // Firebase Zeit für Synchronisation geben
        
        user = _auth.currentUser;
        bool isVerified = user?.emailVerified ?? false;
        
        debugPrint('Email-Verifizierung Status: $isVerified');
        return isVerified;
      }
      return false;
    } catch (e) {
      debugPrint('Fehler beim Prüfen der Email-Verifizierung: $e');
      return false;
    }
  }

  // Sicherer Logout mit Fehlerbehandlung
  Future signOut() async {
    try {
      await _auth.signOut();
      debugPrint('Logout erfolgreich');
    } catch (e) {
      debugPrint('Logout Fehler: ${e.toString()}');
      return null;
    }
  }

  // Account vollständig löschen
  Future<bool> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        debugPrint('Kein User eingeloggt');
        return false;
      }

      // Firebase Auth Account unwiderruflich löschen
      await user.delete();
      // Zusätzlicher expliziter Logout für Sicherheit
      await _auth.signOut();
      
      debugPrint('Account erfolgreich gelöscht und ausgeloggt');
      return true;
    } catch (e) {
      debugPrint('Account-Löschung fehlgeschlagen: ${e.toString()}');
      return false;
    }
  }

  // Passwort-Reset-Email versenden
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.setLanguageCode('de'); // Deutsche Reset-Emails
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Passwort-Reset-Email gesendet an: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Passwort-Reset-Fehler: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Allgemeiner Fehler: $e');
      return false;
    }
  }
}
