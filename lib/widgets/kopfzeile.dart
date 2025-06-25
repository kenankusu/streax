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
    return Transform.scale(
      scale: 3.5,
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color.fromARGB(255, 255, 255, 0),
              ),
              backgroundColor: Colors.grey[800],
              strokeCap: StrokeCap.round,
            ),
            Text(
              '${widget.streakWert}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Willkommen(),
            Padding(
              padding: const EdgeInsets.only(top: 20, right: 30),
              child: streakAnzeige(widget.streakWert / 30),
            ),
          ],
        ),
        SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            zitat ??
                "Fall in love with the process, and the results will come.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
