import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference quoteCollection = FirebaseFirestore.instance
      .collection('quotes');

  // Userdaten anlegen oder aktualisieren
  Future updateUserData(
    String firstName,
    String lastName, {
    String? username,
    int? friends,
    int? maxStreak,
    int? streak,
    String? profilePicture,
    String? lastStreakDate,
    double? weight,
    int? height,
    String? gender,
  }) async {
    Map<String, dynamic> data = {
      'firstName': firstName,
      'lastName': lastName,
      'last_updated': FieldValue.serverTimestamp(),
    };

    if (username != null) data['username'] = username;

    if (streak != null) data['streak'] = streak;
    if (friends != null) data['friends_count'] = friends;
    if (maxStreak != null) data['longest_streak'] = maxStreak;
    if (profilePicture != null) data['profile_picture'] = profilePicture;
    if (lastStreakDate != null) data['lastStreakDate'] = lastStreakDate;
    if (weight != null) data['weight'] = weight;
    if (height != null) data['height'] = height;
    if (gender != null) data['gender'] = gender;

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
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // Nur für heute den Streak prüfen und ggf. erhöhen
    if (activity['datum'] == null || !activity['datum'].startsWith(todayStr))
      return;

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

  // Alle User-Daten löschen (User-Dokument und alle Activities)
  Future<bool> deleteAllUserData() async {
    try {
      // 1. Alle Activities des Users löschen
      final activitiesQuery = await userCollection.doc(uid).collection('activities').get();
      for (var doc in activitiesQuery.docs) {
        await doc.reference.delete();
      }

      // 2. User-Dokument löschen
      await userCollection.doc(uid).delete();
      
      print('Alle User-Daten erfolgreich gelöscht');
      return true;
    } catch (e) {
      print('Fehler beim Löschen der User-Daten: $e');
      return false;
    }
  }
}
