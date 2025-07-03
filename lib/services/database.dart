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
    double? height,
    String? gender,
    String? birthdate,
  }) async {
    Map<String, dynamic> data = {
      'firstName': firstName,
      'lastName': lastName,
      'last_updated': FieldValue.serverTimestamp(),
    };

    if (username != null) data['username'] = username;
    if (streak != null) data['streak'] = streak;
    if (friends != null) data['friends_count'] = friends;
    if (maxStreak != null) data['streak_max'] = maxStreak;
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
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('quotes')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
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

  // Streak-Mechanismus
  Future<void> saveActivityForToday(Map<String, dynamic> activity) async {
    final userRef = userCollection.doc(uid);
    final userDoc = await userRef.get();
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final activityDate = activity['datum'];
    final createdAt = activity['createdAt'];

    if (activityDate == null || !activityDate.startsWith(todayStr)) return;

    if (createdAt != null && createdAt is Timestamp) {
      final createdDate = createdAt.toDate();
      final createdDateStr =
          "${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}";

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
          streak = prevStreak;
        } else {
          streak = 1;
        }
      }
      maxStreak = streak > prevMaxStreak ? streak : prevMaxStreak;
    }

    await userRef.update({
      'streak': streak,
      'lastStreakDate': lastStreakDate,
      'streak_max': maxStreak,
    });
  }

  // Streak-Status prüfen
  Future<void> checkStreakStatus() async {
    final userRef = userCollection.doc(uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) return;

    final data = userDoc.data() as Map<String, dynamic>;
    final lastStreakDate = data['lastStreakDate'];
    final currentStreak = data['streak'] ?? 0;

    if (lastStreakDate == null || currentStreak == 0) return;

    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final yesterdayStr =
        "${now.subtract(Duration(days: 1)).year}-${now.subtract(Duration(days: 1)).month.toString().padLeft(2, '0')}-${now.subtract(Duration(days: 1)).day.toString().padLeft(2, '0')}";
    try {
      if (lastStreakDate != todayStr && lastStreakDate != yesterdayStr) {
        await userRef.update({'streak': 0, 'lastStreakDate': null});
      }
    } catch (e) {
      // Fehler-Log stumm
    }
  }

  // Sportarten des Users aktualisieren
  Future updateUserSports(List<String> sports) async {
    return await userCollection.doc(uid).set({
      'sports': sports,
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Alle User-Daten löschen
  Future<bool> deleteAllUserData() async {
    try {
      final activitiesQuery = await userCollection
          .doc(uid)
          .collection('activities')
          .get();
      for (var doc in activitiesQuery.docs) {
        await doc.reference.delete();
      }

      final goalsQuery = await userCollection
          .doc(uid)
          .collection('goals')
          .get();
      for (var doc in goalsQuery.docs) {
        await doc.reference.delete();
      }

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
        return query.docs.first.id;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Prüft, ob ein Username verfügbar ist
  Future<bool> isUsernameAvailable(
    String username, {
    String? excludeUid,
  }) async {
    if (username.isEmpty) return false;

    final query = await userCollection
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return true;

    if (excludeUid != null && query.docs.first.id == excludeUid) {
      return true;
    }

    return false;
  }

  // Username aktualisieren
  Future<bool> updateUsername(String newUsername) async {
    try {
      bool available = await isUsernameAvailable(newUsername);
      if (!available) return false;

      await userCollection.doc(uid).update({
        'username': newUsername,
        'last_updated': FieldValue.serverTimestamp(),
      });

      return true;
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

  // Ziel löschen
  Future<void> deleteGoal(String goalId) async {
    try {
      final goals = await goalsCollection.orderBy('orderIndex').get();

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

      final batch = FirebaseFirestore.instance.batch();

      batch.delete(goalsCollection.doc(goalId));

      for (int i = deletedIndex + 1; i < goals.docs.length; i++) {
        batch.update(goals.docs[i].reference, {
          'orderIndex': i - 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Fehler beim Löschen des Ziels: $e');
      throw e;
    }
  }

  // Ziele neu sortieren
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

      final existingFriendship = await friendsCollection
          .doc(targetUserId)
          .get();
      if (existingFriendship.exists) {
        return false;
      }

      final existingRequest = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('friendRequests')
          .doc(uid)
          .get();

      if (existingRequest.exists) {
        return false;
      }

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

  // Freundschaftsanfrage akzeptieren - VEREINFACHT
  Future<bool> acceptFriendRequest(String senderId) async {
    try {
      print('Start acceptFriendRequest: $uid -> $senderId');
      
      final batch = FirebaseFirestore.instance.batch();
      
      // Freundschaften erstellen
      batch.set(
        friendsCollection.doc(senderId),
        {
          'userId': senderId,
          'addedAt': DateTime.now(),
          'status': 'accepted',
        }
      );
      
      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .collection('friends')
            .doc(uid),
        {
          'userId': uid,
          'addedAt': DateTime.now(),
          'status': 'accepted',
        }
      );
      
      // Anfragen löschen
      batch.delete(friendRequestsCollection.doc(senderId));
      batch.delete(
        FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .collection('sentRequests')
            .doc(uid)
      );
      
      await batch.commit();
      
      print('Batch commit erfolgreich');
      
      // Counter separat und defensiv
      _updateFriendsCountAsync(uid, 1);
      _updateFriendsCountAsync(senderId, 1);
      
      return true;

    } catch (e) {
      print('Fehler in acceptFriendRequest: $e');
      return false;
    }
  }

  // Freund entfernen - VEREINFACHT
  Future<bool> removeFriend(String friendId) async {
    try {
      print('Start removeFriend: $uid -> $friendId');
      
      final batch = FirebaseFirestore.instance.batch();
      
      batch.delete(
        userCollection.doc(uid).collection('friends').doc(friendId)
      );
      batch.delete(
        userCollection.doc(friendId).collection('friends').doc(uid)
      );
      
      await batch.commit();
      
      print('Freundschaften gelöscht');
      
      _updateFriendsCountAsync(uid, -1);
      _updateFriendsCountAsync(friendId, -1);
      
      return true;

    } catch (e) {
      print('Fehler in removeFriend: $e');
      return false;
    }
  }

  // Freundschaftsanfrage ablehnen - VEREINFACHT
  Future<bool> declineFriendRequest(String senderId) async {
    try {
      print('Start declineFriendRequest: $uid -> $senderId');

      final batch = FirebaseFirestore.instance.batch();
      
      batch.delete(friendRequestsCollection.doc(senderId));
      batch.delete(
        FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .collection('sentRequests')
            .doc(uid)
      );
      
      await batch.commit();
      
      print('declineFriendRequest erfolgreich');
      return true;

    } catch (e) {
      print('Fehler in declineFriendRequest: $e');
      return false;
    }
  }

  // Async Counter-Update (ohne await)
  void _updateFriendsCountAsync(String userId, int increment) {
    userCollection.doc(userId).get().then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final currentCount = data['friends_count'] ?? 0;
        final newCount = increment > 0 
            ? currentCount + increment 
            : (currentCount + increment).clamp(0, double.infinity).toInt();
        
        userCollection.doc(userId).update({
          'friends_count': newCount,
          'last_updated': DateTime.now(),
        }).catchError((e) {
          print('Counter-Update fehlgeschlagen für $userId: $e');
        });
      }
    }).catchError((e) {
      print('Counter-Read fehlgeschlagen für $userId: $e');
    });
  }

  // Freundschaftsstatus prüfen
  Future<String> getFriendshipStatus(String targetUserId) async {
    try {
      final friendship = await friendsCollection.doc(targetUserId).get();
      if (friendship.exists) {
        return 'friends';
      }

      final sentRequest = await userCollection
          .doc(uid)
          .collection('sentRequests')
          .doc(targetUserId)
          .get();
      if (sentRequest.exists) {
        return 'request_sent';
      }

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

  // Freundesdaten laden
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

  // Stream für Friend-Aktivitäten der letzten 7 Tage
  Stream<List<Map<String, dynamic>>> get friendActivities {
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
    
    return userFriends.asyncMap((friendsSnapshot) async {
      List<Map<String, dynamic>> allActivities = [];
      
      print('Debug: Anzahl Freunde gefunden: ${friendsSnapshot.docs.length}');
      
      for (var friendDoc in friendsSnapshot.docs) {
        final friendData = friendDoc.data() as Map<String, dynamic>;
        final friendId = friendData['userId'];
        
        print('Debug: Lade Aktivitäten für Freund: $friendId');
        
        try {
          final activitiesSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(friendId)
              .collection('activities')
              .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
              .orderBy('createdAt', descending: true)
              .get();
          
          print('Debug: Aktivitäten für $friendId gefunden: ${activitiesSnapshot.docs.length}');
          
          final userData = await getFriendData(friendId);
          
          if (userData != null) {
            for (var activityDoc in activitiesSnapshot.docs) {
              final activityData = activityDoc.data();
              print('Debug: Aktivität gefunden: ${activityData['option']} von ${userData['firstName']}');
              
              allActivities.add({
                'activityId': activityDoc.id,
                'userId': friendId,
                'userName': '${userData['firstName']} ${userData['lastName']}'.trim(),
                'username': userData['username'] ?? friendId,
                'userProfileImage': userData['profileImageUrl'] ?? '',
                'userStreak': userData['streak'] ?? 0,
                'title': activityData['option'] ?? 'Unbekannte Aktivität',
                'description': activityData['text'] ?? '',
                'category': activityData['option'] ?? 'sonstiges',
                'duration': _calculateDuration(activityData['von'], activityData['bis']),
                'timestamp': activityData['createdAt'],
                'emoji': activityData['emoji'] ?? '',
                'von': activityData['von'] ?? '',
                'bis': activityData['bis'] ?? '',
                'datum': activityData['datum'] ?? '',
              });
            }
          }
        } catch (e) {
          print('Debug: Fehler beim Laden der Aktivitäten von $friendId: $e');
        }
      }
      
      allActivities.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      
      print('Debug: Gesamt-Aktivitäten im Feed: ${allActivities.length}');
      return allActivities;
    });
  }

  // Hilfsmethode: Dauer berechnen
  int _calculateDuration(String? von, String? bis) {
    if (von == null || bis == null || von.isEmpty || bis.isEmpty) return 0;
    
    try {
      final vonParts = von.split(':');
      final bisParts = bis.split(':');
      
      final vonMinutes = int.parse(vonParts[0]) * 60 + int.parse(vonParts[1]);
      final bisMinutes = int.parse(bisParts[0]) * 60 + int.parse(bisParts[1]);
      
      return bisMinutes - vonMinutes;
    } catch (e) {
      print('Fehler beim Berechnen der Dauer: $e');
      return 0;
    }
  }

  // Einzelne Aktivität laden
  Future<Map<String, dynamic>?> getActivityDetails(String userId, String activityId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activities')
          .doc(activityId)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print('Fehler beim Laden der Aktivitäts-Details: $e');
    }
    return null;
  }
}
