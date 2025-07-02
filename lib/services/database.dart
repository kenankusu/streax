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
    String? birthdate
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
    if (birthdate != null) data['birthdate'] = birthdate;

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
          'text':
              data['text'] ??
              "Fall in love with the process, and the results will come.",
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
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // WICHTIG: Sowohl das eingegebene Datum als auch der Erstellungszeitpunkt müssen "heute" sein
    final activityDate = activity['datum'];
    final createdAt = activity['createdAt']; // Firestore ServerTimestamp

    // 1. Prüfung: Das eingegebene Datum muss heute sein
    if (activityDate == null || !activityDate.startsWith(todayStr)) return;

    // 2. Prüfung: Die Aktivität muss auch heute erstellt worden sein
    if (createdAt != null && createdAt is Timestamp) {
      final createdDate = createdAt.toDate();
      final createdDateStr =
          "${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}";

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
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final yesterdayStr =
        "${now.subtract(Duration(days: 1)).year}-${now.subtract(Duration(days: 1)).month.toString().padLeft(2, '0')}-${now.subtract(Duration(days: 1)).day.toString().padLeft(2, '0')}";

    try {
      // Prüfung basiert nur auf Kalendertagen, nicht auf Stunden
      // Streak bleibt bestehen wenn letzter Log heute oder gestern war
      if (lastStreakDate != todayStr && lastStreakDate != yesterdayStr) {
        // Mehr als 1 Kalendertag ohne Log → Streak zurücksetzen
        await userRef.update({'streak': 0, 'lastStreakDate': null});
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

      // 2. Alle Goals des Users löschen
      final goalsQuery = await userCollection
          .doc(uid)
          .collection('goals')
          .get();
      for (var doc in goalsQuery.docs) {
        await doc.reference.delete();
      }

      // 3. User-Dokument löschen
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

  // Prüft, ob ein Username verfügbar ist, aber unter Ausschluss des aktuellen Users
  Future<bool> isUsernameAvailable(
    String username, {
    String? excludeUid,
  }) async {
    if (username.isEmpty) return false;

    final query = await userCollection
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    // Wenn kein Dokument gefunden wird, ist der Username verfügbar
    if (query.docs.isEmpty) return true;

    // Wenn ein Dokument gefunden wird, prüfe ob es der aktuelle User ist
    if (excludeUid != null && query.docs.first.id == excludeUid) {
      return true; // Der aktuelle User darf seinen eigenen Username behalten
    }

    return false; // Username ist von einem anderen User belegt
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

  // Goals Collection Reference
  CollectionReference get goalsCollection {
    return userCollection.doc(uid).collection('goals');
  }

  // Ziel hinzufügen
  Future<void> addGoal(Map<String, dynamic> goalData) async {
    try {
      // Aktuelle Anzahl von Zielen holen für ordering
      final existingGoals = await goalsCollection.get();
      final orderIndex = existingGoals.docs.length;

      await goalsCollection.add({
        ...goalData,
        'orderIndex': orderIndex,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': uid,
      });
    } catch (e) {
      print('Fehler beim Hinzufügen des Ziels: $e');
      throw e;
    }
  }

  // Ziel aktualisieren
  Future<void> updateGoal(String goalId, Map<String, dynamic> goalData) async {
    try {
      await goalsCollection.doc(goalId).update({
        ...goalData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Fehler beim Aktualisieren des Ziels: $e');
      throw e;
    }
  }

  // Ziel löschen (OPTIMIERT)
  Future<void> deleteGoal(String goalId) async {
    try {
      // Hole alle Ziele in der richtigen Reihenfolge
      final goals = await goalsCollection.orderBy('orderIndex').get();

      // Finde das zu löschende Ziel
      int deletedIndex = -1;
      for (int i = 0; i < goals.docs.length; i++) {
        if (goals.docs[i].id == goalId) {
          deletedIndex = i;
          break;
        }
      }

      if (deletedIndex == -1) {
        throw Exception('Ziel nicht gefunden');
      }

      // EINE einzige Batch-Operation für Löschen + Neu-Sortieren
      final batch = FirebaseFirestore.instance.batch();

      // 1. Ziel löschen
      batch.delete(goalsCollection.doc(goalId));

      // 2. Alle nachfolgenden Ziele neu nummerieren (in derselben Batch)
      for (int i = deletedIndex + 1; i < goals.docs.length; i++) {
        batch.update(goals.docs[i].reference, {
          'orderIndex': i - 1, // Index um 1 reduzieren
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Nur EIN batch.commit() statt zwei
      await batch.commit();
    } catch (e) {
      print('Fehler beim Löschen des Ziels: $e');
      throw e;
    }
  }

  // Ziele neu sortieren (für Drag & Drop) - OPTIMIERT
  Future<void> reorderGoals(List<String> goalIds) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < goalIds.length; i++) {
        final goalRef = goalsCollection.doc(goalIds[i]);
        batch.update(goalRef, {
          'orderIndex': i,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Fehler beim Neu-Sortieren der Ziele: $e');
      throw e;
    }
  }

  // Alle Ziele des Users streamen
  Stream<QuerySnapshot> get userGoals {
    return goalsCollection.orderBy('orderIndex', descending: false).snapshots();
  }

  // FREUNDSCHAFTS-SYSTEM

  // Collection für Freundschaften
  CollectionReference get friendsCollection {
    return userCollection.doc(uid).collection('friends');
  }

  CollectionReference get friendRequestsCollection {
    return userCollection.doc(uid).collection('friendRequests');
  }

  // Freundschaftsanfrage senden
  Future<bool> sendFriendRequest(String targetUserId) async {
    try {
      final currentTime = FieldValue.serverTimestamp();

      // 1. Prüfen ob bereits Freunde oder Anfrage existiert
      final existingFriendship = await friendsCollection
          .doc(targetUserId)
          .get();
      if (existingFriendship.exists) {
        return false; // Bereits Freunde
      }

      final existingRequest = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('friendRequests')
          .doc(uid)
          .get();

      if (existingRequest.exists) {
        return false; // Anfrage bereits gesendet
      }

      // 2. Freundschaftsanfrage beim Empfänger speichern
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('friendRequests')
          .doc(uid)
          .set({
            'senderId': uid,
            'receiverId': targetUserId,
            'status': 'pending',
            'sentAt': currentTime,
          });

      // 3. Gesendete Anfrage bei sich selbst speichern (für Tracking)
      await userCollection
          .doc(uid)
          .collection('sentRequests')
          .doc(targetUserId)
          .set({
            'receiverId': targetUserId,
            'sentAt': currentTime,
            'status': 'pending',
          });

      return true;
    } catch (e) {
      print('Fehler beim Senden der Freundschaftsanfrage: $e');
      return false;
    }
  }

  // Freundschaftsanfrage akzeptieren
  Future<bool> acceptFriendRequest(String senderId) async {
    try {
      final currentTime = FieldValue.serverTimestamp();

      // Batch für atomare Operation
      final batch = FirebaseFirestore.instance.batch();

      // 1. Freundschaft bei beiden Usern hinzufügen
      final friendship1 = friendsCollection.doc(senderId);
      batch.set(friendship1, {
        'userId': senderId,
        'addedAt': currentTime,
        'status': 'accepted',
      });

      final friendship2 = FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('friends')
          .doc(uid);
      batch.set(friendship2, {
        'userId': uid,
        'addedAt': currentTime,
        'status': 'accepted',
      });

      // 2. Freundschaftsanfrage beim Empfänger löschen
      final requestToDelete = friendRequestsCollection.doc(senderId);
      batch.delete(requestToDelete);

      // 3. Gesendete Anfrage beim Sender löschen
      final sentRequestToDelete = FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('sentRequests')
          .doc(uid);
      batch.delete(sentRequestToDelete);

      // 4. Friends-Counter bei beiden erhöhen
      final user1Update = userCollection.doc(uid);
      batch.update(user1Update, {'friends_count': FieldValue.increment(1)});

      final user2Update = userCollection.doc(senderId);
      batch.update(user2Update, {'friends_count': FieldValue.increment(1)});

      await batch.commit();
      return true;
    } catch (e) {
      print('Fehler beim Akzeptieren der Freundschaftsanfrage: $e');
      return false;
    }
  }

  // Freundschaftsanfrage ablehnen
  Future<bool> declineFriendRequest(String senderId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Anfrage beim Empfänger löschen
      final requestToDelete = friendRequestsCollection.doc(senderId);
      batch.delete(requestToDelete);

      // 2. Gesendete Anfrage beim Sender löschen
      final sentRequestToDelete = FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('sentRequests')
          .doc(uid);
      batch.delete(sentRequestToDelete);

      await batch.commit();
      return true;
    } catch (e) {
      print('Fehler beim Ablehnen der Freundschaftsanfrage: $e');
      return false;
    }
  }

  // Freund entfernen
  Future<bool> removeFriend(String friendId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Freundschaft bei beiden Usern entfernen
      final friendship1 = friendsCollection.doc(friendId);
      batch.delete(friendship1);

      final friendship2 = FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(uid);
      batch.delete(friendship2);

      // 2. Friends-Counter bei beiden reduzieren
      final user1Update = userCollection.doc(uid);
      batch.update(user1Update, {'friends_count': FieldValue.increment(-1)});

      final user2Update = userCollection.doc(friendId);
      batch.update(user2Update, {'friends_count': FieldValue.increment(-1)});

      await batch.commit();
      return true;
    } catch (e) {
      print('Fehler beim Entfernen der Freundschaft: $e');
      return false;
    }
  }

  // Freundschaftsstatus prüfen
  Future<String> getFriendshipStatus(String targetUserId) async {
    try {
      // 1. Prüfen ob bereits Freunde
      final friendship = await friendsCollection.doc(targetUserId).get();
      if (friendship.exists) {
        return 'friends';
      }

      // 2. Prüfen ob Anfrage gesendet wurde
      final sentRequest = await userCollection
          .doc(uid)
          .collection('sentRequests')
          .doc(targetUserId)
          .get();
      if (sentRequest.exists) {
        return 'request_sent';
      }

      // 3. Prüfen ob Anfrage empfangen wurde
      final receivedRequest = await friendRequestsCollection
          .doc(targetUserId)
          .get();
      if (receivedRequest.exists) {
        return 'request_received';
      }

      return 'none';
    } catch (e) {
      print('Fehler beim Prüfen des Freundschafts-Status: $e');
      return 'none';
    }
  }

  // Alle Freunde streamen
  Stream<QuerySnapshot> get userFriends {
    return friendsCollection.orderBy('addedAt', descending: true).snapshots();
  }

  // Eingehende Freundschaftsanfragen streamen
  Stream<QuerySnapshot> get incomingFriendRequests {
    return friendRequestsCollection
        .orderBy('sentAt', descending: true)
        .snapshots();
  }

  // Gesendete Freundschaftsanfragen streamen
  Stream<QuerySnapshot> get sentFriendRequests {
    return userCollection
        .doc(uid)
        .collection('sentRequests')
        .orderBy('sentAt', descending: true)
        .snapshots();
  }

  // Freundesdaten laden (für Profil-Anzeige)
  Future<Map<String, dynamic>?> getFriendData(String friendId) async {
    try {
      final doc = await userCollection.doc(friendId).get();
      if (doc.exists) {
        return {'uid': friendId, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      print('Fehler beim Laden der Freundes-Daten: $e');
      return null;
    }
  }
}
