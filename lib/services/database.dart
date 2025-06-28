import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;
  DatabaseService({ required this.uid });

  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference quoteCollection = FirebaseFirestore.instance.collection('quotes');

  // updateUserData Methode
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

  // aktuelle User-Daten streamen
  Stream<DocumentSnapshot> get userData {
    return userCollection.doc(uid).snapshots();
  }

  // Alle Users (für andere Zwecke)
  Stream<QuerySnapshot> get users {
    return userCollection.snapshots();
  }

  // Funktion für die Zitate
  Future<String> getRandomQuote() async {
    try {
      // Alle Zitate aus Firebase holen
      QuerySnapshot querySnapshot = await quoteCollection.get();
      
      if (querySnapshot.docs.isNotEmpty) {
        // Alle Zitate in eine Liste packen (nur der Text)
        List<String> quotes = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .map((data) => data['text'] as String)
            .toList();
        
        // Zufällig mischen und das erste nehmen - easy!
        quotes.shuffle();
        return quotes.first;
      } else {
        // Falls Firebase mal leer ist - Fallback damit nicht alles crasht
        return "Fall in love with the process, and the results will come.";
      }
    } catch (e) {
      // Error handling falls Internet weg ist oder so
      print('Zitate laden fehlgeschlagen: $e');
      return "Fall in love with the process, and the results will come.";
    }
  }
}