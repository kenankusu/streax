import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/models/user.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // create user obj based on FirebaseUser
  StreaxUser? _userFromFirebaseUser(User? user) {
    return user != null ? StreaxUser(uid: user.uid) : null;
  }

  // auth change user stream
  Stream<StreaxUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // sign in with email & password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      debugPrint('Anmelde-Fehler: ${e.toString()}');
      return null;
    }
  }

  // register with email & password
  Future<StreaxUser?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

    
      return _userFromFirebaseUser(user);
    } catch (e) {
      debugPrint('Registrierungs-Fehler: ${e.toString()}');
      return null;
    }
  }

  // sign out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      debugPrint('Logout Fehler: ${e.toString()}');
      return null;
    }
  }
}