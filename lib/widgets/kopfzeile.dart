import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Kopfzeile extends StatefulWidget {
  final String username;
  final int streakWert;

  const Kopfzeile({
    required this.username,
    required this.streakWert,
    super.key,
  });

  @override
  _KopfzeileState createState() => _KopfzeileState();
}

class _KopfzeileState extends State<Kopfzeile> {
  String? zitat;

  @override
  void initState() {
    super.initState();
    _ladeZitat();
  }

  Future<void> _ladeZitat() async {
    final String jsonString = await rootBundle.loadString('assets/zitate.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<String> zitate = List<String>.from(data['zitate']);
    setState(() {
      zitat = (zitate..shuffle()).first;
    });
  }

  Widget Willkommen() {
    return Text(
      "Hallo,\n${widget.username}!",
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }

  Widget streakAnzeige(double progress) {
    return SizedBox(
      width: 200,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress, // Fortschrittswert wird übergeben
            strokeWidth: 50,
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color.fromARGB(255, 118, 3, 212),
            ),
            backgroundColor: Colors.grey[800],
          ),
          Text(
            '${widget.streakWert}',
            style: TextStyle(color: Colors.white, fontSize: 40),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Willkommen(), streakAnzeige(widget.streakWert / 30)],
        ),
        SizedBox(height: 16),
        Text(
          zitat ?? "Zitat wird geladen...",
          style: TextStyle(
            color: Colors.grey[400],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
