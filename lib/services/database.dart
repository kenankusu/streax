import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

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

  // Zufälliges Zitat mit separaten Text- und Autor-Feldern
  Future<Map<String, String>> getRandomQuoteWithAuthor() async {
    try {
      // Hole alle Zitate aus der "quotes" Collection
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('quotes')
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        // Zufälliges Zitat auswählen
        final randomIndex = Random().nextInt(querySnapshot.docs.length);
        final randomDoc = querySnapshot.docs[randomIndex];
        final data = randomDoc.data() as Map<String, dynamic>;
        
        return {
          'text': data['text'] ?? "Fall in love with the process, and the results will come.",
          'author': data['author'] ?? "",
        };
      } else {
        // Fallback wenn keine Zitate in der Datenbank
        return {
          'text': "Fall in love with the process, and the results will come.",
          'author': "",
        };
      }
    } catch (e) {
      print('Fehler beim Laden der Zitate: $e');
      return {
        'text': "Fall in love with the process, and the results will come.",
        'author': "",
      };
    }
  }

  /// Streak-Mechanismus: Erhöhe den Streak nur, wenn heute eine Aktivität gespeichert wird.
  Future<void> saveActivityForToday(Map<String, dynamic> activity) async {
    final userRef = userCollection.doc(uid);
    final userDoc = await userRef.get();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // WICHTIG: Sowohl das eingegebene Datum als auch der Erstellungszeitpunkt müssen "heute" sein
    final activityDate = activity['datum'];
    final createdAt = activity['createdAt']; // Firestore ServerTimestamp
    
    // 1. Prüfung: Das eingegebene Datum muss heute sein
    if (activityDate == null || !activityDate.startsWith(todayStr)) return;
    
    // 2. Prüfung: Die Aktivität muss auch heute erstellt worden sein
    if (createdAt != null && createdAt is Timestamp) {
      final createdDate = createdAt.toDate();
      final createdDateStr = "${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}";
      
      // Wenn Erstellungsdatum != eingegebenes Datum, Streak nicht erhöhen
      if (createdDateStr != todayStr) return;
    }

    int streak = 1;
    String lastStreakDate = todayStr;
    int maxStreak = 1;

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      final prevStreak = data['streak'] ?? 0;
      final prevMaxStreak = data['streak_max'] ?? 0;
      final prevDate = data['lastStreakDate'];

      if (prevDate != null) {
        final prev = DateTime.parse(prevDate);
        final diff = now.difference(prev).inDays;
        if (diff == 1) {
          streak = prevStreak + 1;
        } else if (diff == 0) {
          // Bereits heute eine Aktivität geloggt
          streak = prevStreak;
        } else {
          // Mehr als 1 Tag Unterschied → Streak unterbrochen
          streak = 1;
        }
      }
      maxStreak = streak > prevMaxStreak ? streak : prevMaxStreak;
    }

    // User-Dokument aktualisieren
    await userRef.update({
      'streak': streak,
      'lastStreakDate': lastStreakDate,
      'streak_max': maxStreak,
    });
  }

  /// Prüft beim App-Start, ob der Streak unterbrochen wurde
  Future<void> checkStreakStatus() async {
    final userRef = userCollection.doc(uid);
    final userDoc = await userRef.get();
    
    if (!userDoc.exists) return;
    
    final data = userDoc.data() as Map<String, dynamic>;
    final lastStreakDate = data['lastStreakDate'];
    final currentStreak = data['streak'] ?? 0;
    
    // Wenn noch nie eine Aktivität geloggt wurde oder Streak bereits 0
    if (lastStreakDate == null || currentStreak == 0) return;
    
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final yesterdayStr = "${now.subtract(Duration(days: 1)).year}-${now.subtract(Duration(days: 1)).month.toString().padLeft(2, '0')}-${now.subtract(Duration(days: 1)).day.toString().padLeft(2, '0')}";
    
    try {
      // Prüfung basiert nur auf Kalendertagen, nicht auf Stunden
      // Streak bleibt bestehen wenn letzter Log heute oder gestern war
      if (lastStreakDate != todayStr && lastStreakDate != yesterdayStr) {
        // Mehr als 1 Kalendertag ohne Log → Streak zurücksetzen
        await userRef.update({
          'streak': 0,
          'lastStreakDate': null,
        });
        // Nachricht entfernt
      }
    } catch (e) {
      // Fehler-Log entfernt oder stumm gemacht
    }
  }

  // Sportarten des Users aktualisieren
  Future updateUserSports(List<String> sports) async {
    return await userCollection.doc(uid).set({
      'sports': sports,
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Alle User-Daten löschen (User-Dokument und alle Activities)
  Future<bool> deleteAllUserData() async {
    try {
      // 1. Alle Activities des Users löschen
      final activitiesQuery = await userCollection
          .doc(uid)
          .collection('activities')
          .get();
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

  // Username zu UID umwandeln
  Future<String?> getUserIdByUsername(String username) async {
    try {
      final query = await userCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return query.docs.first.id; // Das ist die UID
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Prüft, ob ein Username verfügbar ist
  Future<bool> isUsernameAvailable(String username) async {
    if (username.isEmpty) return false;
    
    final query = await userCollection
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    
    return query.docs.isEmpty; //true = verfügbar, false = nicht verfügbar
  }

  // Username aktualisieren, mit Verfügbarkeitsprüfung
  Future<bool> updateUsername(String newUsername) async {
    try {
      bool available = await isUsernameAvailable(newUsername);
      if (!available) return false;
      
      // Username speichern
      await userCollection.doc(uid).update({
        'username': newUsername,
        'last_updated': FieldValue.serverTimestamp(),
      });
      
      return true; // Username erfolgreich aktualisiert
    } catch (e) {
      return false;
    }
  }
}
