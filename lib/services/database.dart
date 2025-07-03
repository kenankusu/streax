import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Für debugPrint
import 'dart:math';

/// Firestore Database Service für alle Datenbankoperationen
/// Verwaltet User-Profile, Aktivitäten, Ziele, Freundschaften und Streak-System
class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  // Firestore Collection-Referenzen
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference quoteCollection = FirebaseFirestore.instance.collection('quotes');

  /// Erstellt oder aktualisiert User-Profildaten in Firestore
  /// Verwendet merge:true um nur geänderte Felder zu überschreiben
  Future<void> updateUserData(
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
    try {
      Map<String, dynamic> data = {
        'firstName': firstName,
        'lastName': lastName,
        'last_updated': FieldValue.serverTimestamp(),
      };

      // Nur definierte Werte hinzufügen (null-Werte ignorieren)
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

      await userCollection.doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Fehler beim Update der User-Daten: $e');
      rethrow;
    }
  }

  /// Echtzeit-Stream für aktuelle User-Daten
  Stream<DocumentSnapshot> get userData {
    return userCollection.doc(uid).snapshots();
  }

  /// Stream für alle User (Admin-Funktionen, User-Suche)
  Stream<QuerySnapshot> get users {
    return userCollection.snapshots();
  }

  /// Lädt zufälliges Motivations-Zitat aus der Firestore-Collection
  /// Fallback auf Standard-Zitat bei Fehlern oder leerer Collection
  Future<String> getRandomQuote() async {
    try {
      QuerySnapshot querySnapshot = await quoteCollection.get();
      if (querySnapshot.docs.isNotEmpty) {
        List<String> quotes = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((data) => data['text'] != null)
            .map((data) => data['text'] as String)
            .toList();
        
        if (quotes.isNotEmpty) {
          quotes.shuffle();
          return quotes.first;
        }
      }
      
      // Fallback-Zitat
      return "Fall in love with the process, and the results will come.";
    } catch (e) {
      debugPrint('Fehler beim Laden der Zitate: $e');
      return "Fall in love with the process, and the results will come.";
    }
  }

  /// Lädt zufälliges Zitat mit Autor-Information
  /// Für erweiterte Zitat-Anzeige mit Quellenangabe
  Future<Map<String, String>> getRandomQuoteWithAuthor() async {
    try {
      QuerySnapshot querySnapshot = await quoteCollection.get();

      if (querySnapshot.docs.isNotEmpty) {
        // Zufälliges Zitat-Dokument auswählen
        final randomIndex = Random().nextInt(querySnapshot.docs.length);
        final randomDoc = querySnapshot.docs[randomIndex];
        final data = randomDoc.data() as Map<String, dynamic>;

        return {
          'text': data['text'] ?? "Fall in love with the process, and the results will come.",
          'author': data['author'] ?? "",
        };
      }
      
      // Fallback wenn Collection leer
      return {
        'text': "Fall in love with the process, and the results will come.",
        'author': "",
      };
    } catch (e) {
      debugPrint('Fehler beim Laden der Zitate mit Autor: $e');
      return {
        'text': "Fall in love with the process, and the results will come.",
        'author': "",
      };
    }
  }

  /// STREAK-SYSTEM: Speichert Aktivität und aktualisiert Streak
  /// Verhindert Manipulation durch Validierung von Datum und Erstellungszeit
  /// Streak wird nur bei echten "heute"-Aktivitäten erhöht
  Future<void> saveActivityForToday(Map<String, dynamic> activity) async {
    try {
      final userRef = userCollection.doc(uid);
      final userDoc = await userRef.get();
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      // Sicherheitsprüfungen gegen Streak-Manipulation
      final activityDate = activity['datum'];
      final createdAt = activity['createdAt'];

      // 1. Das eingegebene Datum muss heute sein
      if (activityDate == null || !activityDate.startsWith(todayStr)) {
        debugPrint('Aktivität nicht für heute - Streak nicht erhöht');
        return;
      }

      // 2. Die Aktivität muss auch heute erstellt worden sein (Server-Timestamp)
      if (createdAt != null && createdAt is Timestamp) {
        final createdDate = createdAt.toDate();
        final createdDateStr = "${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}";
        
        if (createdDateStr != todayStr) {
          debugPrint('Aktivität wurde nicht heute erstellt - Streak nicht erhöht');
          return;
        }
      }

      // Streak-Berechnung
      int newStreak = 1;
      String lastStreakDate = todayStr;
      int maxStreak = 1;

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final prevStreak = data['streak'] ?? 0;
        final prevMaxStreak = data['streak_max'] ?? 0;
        final prevDate = data['lastStreakDate'];

        if (prevDate != null) {
          try {
            final prev = DateTime.parse(prevDate);
            final diff = now.difference(prev).inDays;
            
            if (diff == 1) {
              // Aufeinanderfolgender Tag - Streak erhöhen
              newStreak = prevStreak + 1;
            } else if (diff == 0) {
              // Heute bereits eine Aktivität - Streak beibehalten
              newStreak = prevStreak;
            } else {
              // Lücke > 1 Tag - Streak neu starten
              newStreak = 1;
            }
          } catch (e) {
            debugPrint('Fehler beim Parsen des letzten Streak-Datums: $e');
            newStreak = 1;
          }
        }
        
        // Maximalen Streak aktualisieren
        maxStreak = newStreak > prevMaxStreak ? newStreak : prevMaxStreak;
      }

      // User-Dokument mit neuen Streak-Werten aktualisieren
      await userRef.update({
        'streak': newStreak,
        'lastStreakDate': lastStreakDate,
        'streak_max': maxStreak,
      });
      
      debugPrint('Streak aktualisiert: $newStreak (Max: $maxStreak)');
    } catch (e) {
      debugPrint('Fehler beim Speichern der Aktivität und Streak-Update: $e');
      rethrow;
    }
  }

  /// Prüft beim App-Start ob Streak unterbrochen wurde
  /// Setzt Streak auf 0 wenn mehr als 1 Tag ohne Aktivität
  Future<void> checkStreakStatus() async {
    try {
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
      
      // Prüfung basiert nur auf Kalendertagen, nicht auf Stunden
      // Streak nur zurücksetzen wenn weder heute noch gestern geloggt wurde
      if (lastStreakDate != todayStr && lastStreakDate != yesterdayStr) {
        // Mehr als 1 Kalendertag ohne Log → Streak zurücksetzen
        await userRef.update({
          'streak': 0,
          'lastStreakDate': null,
        });
        debugPrint('Streak zurückgesetzt - zu lange keine Aktivität');
      }
    } catch (e) {
      debugPrint('Fehler beim Streak-Status-Check: $e');
    }
  }

  /// Aktualisiert die Sport-Präferenzen des Users
  Future<void> updateUserSports(List<String> sports) async {
    try {
      await userCollection.doc(uid).set({
        'sports': sports,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Fehler beim Update der Sportarten: $e');
      rethrow;
    }
  }

  /// ACCOUNT-LÖSCHUNG: Entfernt alle User-Daten aus Firestore
  /// Löscht User-Dokument, Activities und Goals in einer Transaktion
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

      debugPrint('Alle User-Daten erfolgreich gelöscht');
      return true;
    } catch (e) {
      debugPrint('Fehler beim Löschen aller User-Daten: $e');
      return false;
    }
  }

  /// USERNAME-SYSTEM: Konvertiert Username zu User-ID
  Future<String?> getUserIdByUsername(String username) async {
    try {
      if (username.trim().isEmpty) return null;
      
      final query = await userCollection
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      return query.docs.isNotEmpty ? query.docs.first.id : null;
    } catch (e) {
      debugPrint('Fehler beim Finden des Users per Username: $e');
      return null;
    }
  }

  /// Prüft Username-Verfügbarkeit (mit Ausnahme für aktuellen User)
  Future<bool> isUsernameAvailable(String username, {String? excludeUid}) async {
    try {
      if (username.trim().isEmpty) return false;

      final query = await userCollection
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      // Kein User mit diesem Username gefunden
      if (query.docs.isEmpty) return true;

      // Username gehört dem aktuellen User
      if (excludeUid != null && query.docs.first.id == excludeUid) {
        return true;
      }

      return false; // Username bereits vergeben
    } catch (e) {
      debugPrint('Fehler beim Prüfen der Username-Verfügbarkeit: $e');
      return false;
    }
  }

  /// Username aktualisieren mit Verfügbarkeitsprüfung
  Future<bool> updateUsername(String newUsername) async {
    try {
      final trimmedUsername = newUsername.trim();
      
      // Verfügbarkeit prüfen (eigenen User ausschließen)
      bool available = await isUsernameAvailable(trimmedUsername, excludeUid: uid);
      if (!available) return false;

      await userCollection.doc(uid).update({
        'username': trimmedUsername,
        'last_updated': FieldValue.serverTimestamp(),
      });

      return true; // Username erfolgreich aktualisiert
    } catch (e) {
      debugPrint('Fehler beim Username-Update: $e');
      return false;
    }
  }

  // ZIELE-SYSTEM (Goals Management)

  /// Goals Collection Reference für aktuellen User
  CollectionReference get goalsCollection {
    return userCollection.doc(uid).collection('goals');
  }

  /// Neues Ziel hinzufügen mit automatischer Sortierung
  Future<void> addGoal(Map<String, dynamic> goalData) async {
    try {
      // Aktuelle Anzahl für Order-Index ermitteln
      final existingGoals = await goalsCollection.get();
      final orderIndex = existingGoals.docs.length;

      await goalsCollection.add({
        ...goalData,
        'orderIndex': orderIndex,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': uid,
      });
    } catch (e) {
      debugPrint('Fehler beim Hinzufügen des Ziels: $e');
      rethrow;
    }
  }

  /// Bestehendes Ziel aktualisieren
  Future<void> updateGoal(String goalId, Map<String, dynamic> goalData) async {
    try {
      await goalsCollection.doc(goalId).update({
        ...goalData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Fehler beim Aktualisieren des Ziels: $e');
      rethrow;
    }
  }

  /// Ziel löschen mit automatischer Neu-Sortierung
  /// Verwendet Batch-Operation für Konsistenz
  Future<void> deleteGoal(String goalId) async {
    try {
      // Alle Ziele in sortierter Reihenfolge laden
      final goals = await goalsCollection.orderBy('orderIndex').get();

      // Index des zu löschenden Ziels finden
      int deletedIndex = -1;
      for (int i = 0; i < goals.docs.length; i++) {
        if (goals.docs[i].id == goalId) {
          deletedIndex = i;
          break;
        }
      }

      if (deletedIndex == -1) {
        throw Exception('Ziel mit ID $goalId nicht gefunden');
      }

      // Batch-Operation für atomare Löschung + Neu-Sortierung
      final batch = FirebaseFirestore.instance.batch();

      // 1. Ziel löschen
      batch.delete(goalsCollection.doc(goalId));

      // 2. Alle nachfolgenden Ziele neu nummerieren
      for (int i = deletedIndex + 1; i < goals.docs.length; i++) {
        batch.update(goals.docs[i].reference, {
          'orderIndex': i - 1, // Index um 1 reduzieren
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Nur EIN batch.commit() statt zwei
      await batch.commit();
    } catch (e) {
      debugPrint('Fehler beim Löschen des Ziels: $e');
      rethrow;
    }
  }

  /// Ziele neu sortieren (für Drag & Drop Funktionalität)
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
      debugPrint('Fehler beim Neu-Sortieren der Ziele: $e');
      rethrow;
    }
  }

  /// Stream für alle Ziele des Users (sortiert nach orderIndex)
  Stream<QuerySnapshot> get userGoals {
    return goalsCollection.orderBy('orderIndex', descending: false).snapshots();
  }

  // FREUNDSCHAFTS-SYSTEM

  /// Friends Collection Reference
  CollectionReference get friendsCollection {
    return userCollection.doc(uid).collection('friends');
  }

  /// Friend Requests Collection Reference
  CollectionReference get friendRequestsCollection {
    return userCollection.doc(uid).collection('friendRequests');
  }

  /// Freundschaftsanfrage senden mit Duplikat-Prüfung
  Future<bool> sendFriendRequest(String targetUserId) async {
    try {
      if (targetUserId == uid) {
        debugPrint('Kann sich nicht selbst als Freund hinzufügen');
        return false;
      }

      final currentTime = FieldValue.serverTimestamp();

      // 1. Prüfen ob bereits Freunde sind
      final existingFriendship = await friendsCollection.doc(targetUserId).get();
      if (existingFriendship.exists) {
        debugPrint('Bereits mit User $targetUserId befreundet');
        return false;
      }

      // 2. Prüfen ob bereits eine Anfrage existiert
      final existingRequest = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('friendRequests')
          .doc(uid)
          .get();

      if (existingRequest.exists) {
        debugPrint('Freundschaftsanfrage bereits gesendet an $targetUserId');
        return false;
      }

      // 3. Freundschaftsanfrage beim Empfänger speichern
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

      // 4. Gesendete Anfrage für eigenes Tracking speichern
      await userCollection
          .doc(uid)
          .collection('sentRequests')
          .doc(targetUserId)
          .set({
            'receiverId': targetUserId,
            'sentAt': currentTime,
            'status': 'pending',
          });

      debugPrint('Freundschaftsanfrage erfolgreich gesendet an $targetUserId');
      return true;
    } catch (e) {
      debugPrint('Fehler beim Senden der Freundschaftsanfrage: $e');
      return false;
    }
  }

  /// Freundschaftsanfrage akzeptieren - Batch-Operation für Konsistenz
  Future<bool> acceptFriendRequest(String senderId) async {
    try {
      final currentTime = FieldValue.serverTimestamp();

      // Batch für atomare Operation
      final batch = FirebaseFirestore.instance.batch();

      // 1. Freundschaft bei beiden Usern hinzufügen
      batch.set(friendsCollection.doc(senderId), {
        'userId': senderId,
        'addedAt': currentTime,
        'status': 'accepted',
      });

      batch.set(
        FirebaseFirestore.instance.collection('users').doc(senderId).collection('friends').doc(uid),
        {
          'userId': uid,
          'addedAt': currentTime,
          'status': 'accepted',
        }
      );

      // 2. Friend-Requests bei beiden Usern löschen
      batch.delete(friendRequestsCollection.doc(senderId));
      batch.delete(
        FirebaseFirestore.instance.collection('users').doc(senderId).collection('sentRequests').doc(uid)
      );

      // 3. Friends-Counter bei beiden erhöhen
      batch.update(userCollection.doc(uid), {'friends_count': FieldValue.increment(1)});
      batch.update(userCollection.doc(senderId), {'friends_count': FieldValue.increment(1)});

      await batch.commit();
      debugPrint('Freundschaftsanfrage von $senderId erfolgreich akzeptiert');
      return true;
    } catch (e) {
      debugPrint('Fehler beim Akzeptieren der Freundschaftsanfrage: $e');
      return false;
    }
  }

  /// Freundschaftsanfrage ablehnen
  Future<bool> declineFriendRequest(String senderId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Anfrage bei beiden Usern löschen
      batch.delete(friendRequestsCollection.doc(senderId));
      batch.delete(
        FirebaseFirestore.instance.collection('users').doc(senderId).collection('sentRequests').doc(uid)
      );

      await batch.commit();
      debugPrint('Freundschaftsanfrage von $senderId abgelehnt');
      return true;
    } catch (e) {
      debugPrint('Fehler beim Ablehnen der Freundschaftsanfrage: $e');
      return false;
    }
  }

  /// Freundschaft entfernen
  Future<bool> removeFriend(String friendId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Freundschaft bei beiden Usern entfernen
      batch.delete(friendsCollection.doc(friendId));
      batch.delete(
        FirebaseFirestore.instance.collection('users').doc(friendId).collection('friends').doc(uid)
      );

      // Friends-Counter bei beiden reduzieren
      batch.update(userCollection.doc(uid), {'friends_count': FieldValue.increment(-1)});
      batch.update(userCollection.doc(friendId), {'friends_count': FieldValue.increment(-1)});

      await batch.commit();
      debugPrint('Freundschaft mit $friendId entfernt');
      return true;
    } catch (e) {
      debugPrint('Fehler beim Entfernen der Freundschaft: $e');
      return false;
    }
  }

  /// Freundschaftsstatus zwischen zwei Usern ermitteln
  Future<String> getFriendshipStatus(String targetUserId) async {
    try {
      // 1. Prüfen ob bereits Freunde
      final friendship = await friendsCollection.doc(targetUserId).get();
      if (friendship.exists) return 'friends';

      // 2. Prüfen ob Anfrage gesendet wurde
      final sentRequest = await userCollection
          .doc(uid)
          .collection('sentRequests')
          .doc(targetUserId)
          .get();
      if (sentRequest.exists) return 'request_sent';

      // 3. Prüfen ob Anfrage empfangen wurde
      final receivedRequest = await friendRequestsCollection.doc(targetUserId).get();
      if (receivedRequest.exists) return 'request_received';

      return 'none';
    } catch (e) {
      debugPrint('Fehler beim Prüfen des Freundschafts-Status: $e');
      return 'none';
    }
  }

  /// Stream für alle Freunde (sortiert nach hinzugefügt-Datum)
  Stream<QuerySnapshot> get userFriends {
    return friendsCollection.orderBy('addedAt', descending: true).snapshots();
  }

  /// Stream für eingehende Freundschaftsanfragen
  Stream<QuerySnapshot> get incomingFriendRequests {
    return friendRequestsCollection.orderBy('sentAt', descending: true).snapshots();
  }

  /// Stream für gesendete Freundschaftsanfragen
  Stream<QuerySnapshot> get sentFriendRequests {
    return userCollection
        .doc(uid)
        .collection('sentRequests')
        .orderBy('sentAt', descending: true)
        .snapshots();
  }

  /// Lädt vollständige Freundesdaten für Profil-Anzeige
  Future<Map<String, dynamic>?> getFriendData(String friendId) async {
    try {
      final doc = await userCollection.doc(friendId).get();
      if (doc.exists) {
        return {'uid': friendId, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      debugPrint('Fehler beim Laden der Freundes-Daten für $friendId: $e');
      return null;
    }
  }
}
