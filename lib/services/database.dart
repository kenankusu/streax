import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;
  DatabaseService({ required this.uid });

  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');

  // ✅ Erweiterte updateUserData Methode
  Future updateUserData(String name, String username, {
    int? freundeAnzahl,
    int? laengsterStreak,
    String? profilBild,
  }) async {
    Map<String, dynamic> data = {
      'name': name,
      'username': username,
      'last_updated': FieldValue.serverTimestamp(),
    };

    // Optionale Felder nur hinzufügen wenn sie übergeben werden
    if (freundeAnzahl != null) data['freunde_anzahl'] = freundeAnzahl;
    if (laengsterStreak != null) data['laengster_streak'] = laengsterStreak;
    if (profilBild != null) data['profil_bild'] = profilBild;

    return await userCollection.doc(uid).set(data, SetOptions(merge: true));
  }

  // ✅ Nur aktueller User
  Stream<DocumentSnapshot> get userData {
    return userCollection.doc(uid).snapshots();
  }

  // Alle Users (für andere Zwecke)
  Stream<QuerySnapshot> get users {
    return userCollection.snapshots();
  }
}