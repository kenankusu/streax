import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/database.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Kopfzeile extends StatefulWidget {
  final int streakWert;

  const Kopfzeile({
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

  Widget Willkommen(String name) {
    return Text(
      "Hallo,\n$name!",
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
    final user = Provider.of<StreaxUser?>(context)!;

    return StreamBuilder<DocumentSnapshot>(
      stream: DatabaseService(uid: user.uid).userData,
      builder: (context, snapshot) {
        String name = "Benutzer";
        
        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String fullName = userData['name'] ?? 'Benutzer';
          // ✅ Nur den ersten Teil (Vorname) nehmen
          name = fullName.split(' ').first;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Willkommen(name),
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
      },
    );
  }
}
