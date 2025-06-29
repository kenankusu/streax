import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:streax/Models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Persistence nur setzen wenn der User es möchte
  Future<void> _configurePersistence(bool stayLoggedIn) async {
    if (kIsWeb) {
      if (stayLoggedIn) {
        await _auth.setPersistence(Persistence.LOCAL);
        debugPrint('Auth Persistence aktiviert - User bleibt eingeloggt');
      } else {
        await _auth.setPersistence(Persistence.SESSION);
        debugPrint('Session-only Persistence - Logout bei Browser-Schließung');
      }
    }
    // Bei Android/iOS ist Persistence automatisch aktiv
  }

  // create user obj based on FirebaseUser
  StreaxUser? _userFromFirebaseUser(User? user) {
    return user != null ? StreaxUser(uid: user.uid) : null;
  }

  // auth change user stream
  Stream<StreaxUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // sign in with email & password - jetzt mit optionaler Persistence
  Future signInWithEmailAndPassword(
    String email,
    String password, {
    bool stayLoggedIn = false,
  }) async {
    try {
      await _configurePersistence(stayLoggedIn);
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      debugPrint(
        'Login erfolgreich${stayLoggedIn ? ' - bleibt eingeloggt' : ' - Session only'}',
      );
      return _userFromFirebaseUser(user);
    } catch (e) {
      debugPrint('Anmelde-Fehler: ${e.toString()}');
      return null;
    }
  }

  // register with email & password - auch mit optionaler Persistence
  Future<StreaxUser?> registerWithEmailAndPassword(
    String email,
    String password, {
    bool stayLoggedIn = false,
  }) async {
    try {
      await _configurePersistence(stayLoggedIn);
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      debugPrint(
        'Registrierung erfolgreich${stayLoggedIn ? ' - bleibt eingeloggt' : ' - Session only'}',
      );
      return _userFromFirebaseUser(user);
    } catch (e) {
      debugPrint('Registrierungs-Fehler: ${e.toString()}');
      return null;
    }
  }

  // sign out
  Future signOut() async {
    try {
      await _auth.signOut();
      debugPrint('Logout erfolgreich');
    } catch (e) {
      debugPrint('Logout Fehler: ${e.toString()}');
      return null;
    }
  }

  // Account löschen - Vereinfacht
  Future<bool> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        debugPrint('Kein User eingeloggt');
        return false;
      }

      // Account löschen
      await user.delete();
      
      // Explizit ausloggen
      await _auth.signOut();
      
      debugPrint('Account erfolgreich gelöscht und ausgeloggt');
      return true;
    } catch (e) {
      debugPrint('Account-Löschung fehlgeschlagen: ${e.toString()}');
      return false;
    }
  }
}
