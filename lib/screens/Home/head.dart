import 'package:flutter/material.dart';
import 'package:flutter_application_1/Models/user.dart';
import 'package:flutter_application_1/Services/database.dart';
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
  String? quote;

  @override
  void initState() {
    super.initState();
    _loadQuote(); // Beim Starten direkt Zitat laden
  }


  Future<void> _loadQuote() async {
    // User UID holen damit wir DatabaseService benutzen können
    final user = Provider.of<StreaxUser?>(context, listen: false);
    if (user != null) {
      // Zufälliges Zitat von DatabaseService abfragen
      String randomQuote = await DatabaseService(uid: user.uid).getRandomQuote();
      setState(() {
        quote = randomQuote; // UI updaten mit dem neuen Zitat
      });
    }
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
                Theme.of(context).colorScheme.primary,
              ),
              backgroundColor: Colors.grey[800],
              strokeCap: StrokeCap.round,
            ),
            Text(
              '${widget.streakWert}',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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
          // Nur Vorname anzeigen
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
                // Falls das Zitat noch lädt, Fallback anzeigen
                quote ?? "Fall in love with the process, and the results will come.",
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
