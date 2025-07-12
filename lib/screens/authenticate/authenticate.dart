import 'package:flutter/material.dart';
import 'package:streax/screens/authenticate/sign_in.dart';
import 'package:streax/screens/authenticate/register.dart';

/// Authentication Screen Controller
/// Wechselt zwischen Login und Registrierung 
class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {

  bool showSignIn = false;
  void toggleView() {
    setState(() => showSignIn = !showSignIn);
  }

  @override
  Widget build(BuildContext context) {
    if (showSignIn) {
      return SignIn(toggleView: toggleView);
    } else {
      return Register(toggleView: toggleView);
    }
  }
}