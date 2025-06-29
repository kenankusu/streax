import 'package:flutter/material.dart';
import 'package:flutter_application_1/Models/user.dart';
import 'package:flutter_application_1/Screens/Home/homepage.dart';
import 'package:flutter_application_1/Screens/Authenticate/authenticate.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: Image.asset(
              'assets/animations/streax-splash-animation.gif',
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    final user = Provider.of<StreaxUser?>(context);
    // return entweder Home oder Authenticate widget
    // wenn user null = nicht eingeloggt, dann Authenticate
    if (user == null) {
      return Authenticate();
    } else {
      return startseite();
    }
  }
}