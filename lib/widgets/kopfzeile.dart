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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Hallo,\n${widget.username}!",
              style: TextStyle(color: Colors.white, fontSize: 26),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: widget.streakWert / 30,
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                  backgroundColor: Colors.grey[800],
                ),
                Text(
                  '${widget.streakWert}',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
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
