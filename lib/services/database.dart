import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;
  DatabaseService({ required this.uid });

  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference quoteCollection = FirebaseFirestore.instance.collection('quotes');

  // Userdaten anlegen oder aktualisieren
  Future updateUserData(
    String name,
    String username, {
    int? freunde,
    int? maxStreak,
    int? streak,
    String? profilBild,
    String? lastStreakDate,
  }) async {
    Map<String, dynamic> data = {
      'name': name,
      'username': username,
      'last_updated': FieldValue.serverTimestamp(),
    };

    if (streak != null) data['streak'] = streak; // Nur setzen, wenn übergeben
    if (freunde != null) data['freunde_anzahl'] = freunde;
    if (maxStreak != null) data['laengster_streak'] = maxStreak;
    if (profilBild != null) data['profil_bild'] = profilBild;
    if (lastStreakDate != null) data['lastStreakDate'] = lastStreakDate;

    return await userCollection.doc(uid).set(data, SetOptions(merge: true));
  }

  // Aktuelle User-Daten streamen
  Stream<DocumentSnapshot> get userData {
    return userCollection.doc(uid).snapshots();
  }

  // Alle User-Dokumente streamen
  Stream<QuerySnapshot> get users {
    return userCollection.snapshots();
  }

  // Zufälliges Zitat holen
  Future<String> getRandomQuote() async {
    try {
      QuerySnapshot querySnapshot = await quoteCollection.get();
      if (querySnapshot.docs.isNotEmpty) {
        List<String> quotes = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .map((data) => data['text'] as String)
            .toList();
        quotes.shuffle();
        return quotes.first;
      } else {
        return "Fall in love with the process, and the results will come.";
      }
    } catch (e) {
      print('Zitate laden fehlgeschlagen: $e');
      return "Fall in love with the process, and the results will come.";
    }
  }

  /// Streak-Mechanismus: Erhöhe den Streak nur, wenn heute eine Aktivität gespeichert wird.
  /// Einträge für vergangene Tage erhöhen den Streak NICHT.
  Future<void> saveActivityForToday(Map<String, dynamic> activity) async {
    final userRef = userCollection.doc(uid);
    final userDoc = await userRef.get();
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // Nur für heute den Streak prüfen und ggf. erhöhen
    if (activity['datum'] == null || !activity['datum'].startsWith(todayStr)) return;

    int streak = 1;
    String lastStreakDate = todayStr;
    int maxStreak = 1;

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      final prevStreak = data['streak'] ?? 0;
      final prevMaxStreak = data['laengster_streak'] ?? 0;
      final prevDate = data['lastStreakDate'];

      if (prevDate != null) {
        final prev = DateTime.parse(prevDate);
        final diff = today.difference(prev).inDays;
        if (diff == 1) {
          streak = prevStreak + 1;
        } else if (diff == 0) {
          streak = prevStreak;
        }
      }
      // Maximalen Streak aktualisieren
      maxStreak = streak > prevMaxStreak ? streak : prevMaxStreak;
    }

    // User-Dokument aktualisieren
    await userRef.update({
      'streak': streak,
      'lastStreakDate': lastStreakDate,
      'laengster_streak': maxStreak,
    });

  }
}