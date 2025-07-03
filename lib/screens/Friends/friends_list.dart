import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database.dart';
import 'friend_actions.dart';
import 'profile_view.dart';

// Slide-in Ansicht für Freunde und Anfragen
class FriendsSlideInView extends StatefulWidget {
  const FriendsSlideInView({super.key});

  @override
  State<FriendsSlideInView> createState() => _FriendsSlideInViewState();
}

class _FriendsSlideInViewState extends State<FriendsSlideInView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredFriends = [];
  List<Map<String, dynamic>> _allFriends = [];
  List<Map<String, dynamic>> _allRequests = [];
  List<Map<String, dynamic>> _filteredRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
        _filterData();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
    
// Filtert Freunde und Anfragen basierend auf der Sucheingabe
  void _filterData() {
    if (_searchQuery.isEmpty) {
      _filteredFriends = List.from(_allFriends);
      _filteredRequests = List.from(_allRequests);
    } else {
      final query = _searchQuery.toLowerCase();
      
      _filteredFriends = _allFriends.where((friend) {
        final name = '${friend['firstName']} ${friend['lastName']}'.toLowerCase();
        final username = friend['username'].toString().toLowerCase();
        return name.contains(query) || username.contains(query);
      }).toList();
      
      _filteredRequests = _allRequests.where((request) {
        final name = '${request['firstName']} ${request['lastName']}'.toLowerCase();
        final username = request['username'].toString().toLowerCase();
        return name.contains(query) || username.contains(query);
      }).toList();
    }
  }

  Future<void> _loadAllData() async {
    // Lädt alle Freunde und Anfragen parallel aus Firebase
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Beide Streams parallel laden
      final results = await Future.wait([
        DatabaseService(uid: currentUser.uid).userFriends.first,
        DatabaseService(uid: currentUser.uid).incomingFriendRequests.first,
      ]);

      final friendsSnapshot = results[0];
      final requestsSnapshot = results[1];

      // Freunde-Daten laden
      List<Map<String, dynamic>> friendsData = [];
      for (var friendDoc in friendsSnapshot.docs) {
        final friendData = friendDoc.data() as Map<String, dynamic>;
        final friendId = friendData['userId'];
        
        try {
          final userData = await DatabaseService(uid: currentUser.uid).getFriendData(friendId);
          if (userData != null) {
            friendsData.add(userData);
          }
        } catch (e) {
          print('Fehler beim Laden von Freund $friendId: $e');
        }
      }

      // Anfragen-Daten laden
      List<Map<String, dynamic>> requestsData = [];
      for (var requestDoc in requestsSnapshot.docs) {
        final requestData = requestDoc.data() as Map<String, dynamic>;
        final senderId = requestData['senderId'];
        
        try {
          final userData = await DatabaseService(uid: currentUser.uid).getFriendData(senderId);
          if (userData != null) {
            requestsData.add(userData);
          }
        } catch (e) {
          print('Fehler beim Laden von Anfrage $senderId: $e');
        }
      }

      setState(() {
        _allFriends = friendsData;
        _allRequests = requestsData;
        _isLoading = false;
        _filterData();
      });

    } catch (e) {
      print('Fehler beim Laden der Daten: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header mit Zurück-Button
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  // Zurück-Button
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  
                  SizedBox(width: 15),
                  
                  // Titel
                  Text(
                    'Freunde',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Suchfeld
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27.5),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Container(
                margin: EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Container(
                  height: 55,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: TextStyle(color: Colors.white),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          Icons.search,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: 54,
                        minHeight: 55,
                      ),
                      hintText: 'Freunde durchsuchen...',
                      hintStyle: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: IconButton(
                                icon: Icon(Icons.clear, color: Colors.white70, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchFocusNode.unfocus();
                                },
                              ),
                            )
                          : null,
                      suffixIconConstraints: BoxConstraints(
                        minWidth: 54,
                        minHeight: 55,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Freunde-Liste mit StreamBuilder für Updates
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid).userFriends,
                builder: (context, friendsSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid).incomingFriendRequests,
                    builder: (context, requestsSnapshot) {
                      
                      // Nur bei Datenänderungen neu laden
                      if (friendsSnapshot.hasData && requestsSnapshot.hasData) {
                        // Prüfe ob sich die Anzahl der Dokumente geändert hat
                        final friendsCount = friendsSnapshot.data!.docs.length;
                        final requestsCount = requestsSnapshot.data!.docs.length;
                        
                        if (_allFriends.length != friendsCount || _allRequests.length != requestsCount) {
                          // Nur dann neu laden wenn sich etwas geändert hat
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _loadAllData();
                          });
                        }
                      }
                      
                      // Während des ersten Ladens
                      if (_isLoading) {
                        // Initiales Laden starten
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_allFriends.isEmpty && _allRequests.isEmpty) {
                            _loadAllData();
                          }
                        });
                        
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                              SizedBox(height: 16),
                              Text(
                                'Lade Freunde...',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        );
                      }

                      // Daten anzeigen
                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Freundschaftsanfragen (falls vorhanden)
                            if (_filteredRequests.isNotEmpty) ...[
                              Text(
                                'Offene Anfragen (${_filteredRequests.length})',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12),
                              
                              ..._filteredRequests.map((request) {
                                return FriendRequestCard(
                                  user: request,
                                  currentUserId: FirebaseAuth.instance.currentUser!.uid,
                                  key: ValueKey(request['uid']),
                                );
                              }).toList(),
                              
                              SizedBox(height: 32), // GEÄNDERT: Mehr Abstand statt Gradient-Linie
                            ],

                            // Freunde-Liste Titel
                            Text(
                              'Deine Freunde (${_filteredFriends.length})',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),

                            // Freunde-Liste
                            if (_filteredFriends.isEmpty && _searchQuery.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                                      SizedBox(height: 12),
                                      Text(
                                        'Keine Freunde gefunden',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (_filteredFriends.isEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.group_outlined, size: 48, color: Colors.grey[400]),
                                      SizedBox(height: 12),
                                      Text(
                                        'Noch keine Freunde',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ..._filteredFriends.map((friend) {
                                return SlideInFriendCard(
                                  user: friend,
                                  key: ValueKey(friend['uid']),
                                );
                              }).toList(),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Karte für Freundschaftsanfragen mit Akzeptieren/Ablehnen Buttons
class FriendRequestCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String currentUserId;

  const FriendRequestCard({
    super.key,
    required this.user,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Profilbild mit Tap-Funktion
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileView(user: user),
                ),
              );
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              backgroundImage: user['profileImageUrl'] != null &&
                      user['profileImageUrl'].toString().isNotEmpty
                  ? NetworkImage(user['profileImageUrl'])
                  : null,
              child: user['profileImageUrl'] == null ||
                      user['profileImageUrl'].toString().isEmpty
                  ? Icon(Icons.person, color: Colors.grey[600], size: 24)
                  : null,
            ),
          ),

          SizedBox(width: 12),

          // User-Info mit Tap-Funktion
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProfileView(user: user),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${user['firstName'] ?? 'Unbekannt'} ${user['lastName'] ?? ''}'.trim(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      if ((user['streak'] ?? 0) > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🔥 ${user['streak']}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '@${user['username'] ?? 'unbekannt'}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => FriendActions.acceptFriendRequest(
                    context,
                    user,
                    currentUserId,
                  ),
                  icon: Icon(Icons.check, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => FriendActions.declineFriendRequest(
                    context,
                    user,
                    currentUserId,
                  ),
                  icon: Icon(Icons.close, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Freund-Karte für die Slide-in Ansicht mit Entfernen-Button
class SlideInFriendCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const SlideInFriendCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Profilbild mit Tap-Funktion
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileView(user: user),
                ),
              );
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              backgroundImage: user['profileImageUrl'] != null &&
                      user['profileImageUrl'].toString().isNotEmpty
                  ? NetworkImage(user['profileImageUrl'])
                  : null,
              child: user['profileImageUrl'] == null ||
                      user['profileImageUrl'].toString().isEmpty
                  ? Icon(Icons.person, color: Colors.grey[600], size: 24)
                  : null,
            ),
          ),

          SizedBox(width: 12),

          // User-Info mit Tap-Funktion
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProfileView(user: user),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${user['firstName'] ?? 'Unbekannt'} ${user['lastName'] ?? ''}'.trim(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      if ((user['streak'] ?? 0) > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🔥 ${user['streak']}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '@${user['username'] ?? 'unbekannt'}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // Entfernen-Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () => FriendActions.removeFriend(context, user),
              icon: Icon(Icons.person_remove, color: Colors.red, size: 20),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

// Bestehende Klassen für Rückwärtskompatibilität
class FriendsListTab extends StatelessWidget {
  final String uid;

  const FriendsListTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService(uid: uid).userFriends,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Fehler: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text('Noch keine Freunde'),
              ],
            ),
          );
        }

        final friends = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friendData = friends[index].data() as Map<String, dynamic>;
            final friendId = friendData['userId'];

            return FutureBuilder<Map<String, dynamic>?>(
              future: DatabaseService(uid: uid).getFriendData(friendId),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: CircularProgressIndicator()),
                      title: Text('Lade...'),
                    ),
                  );
                }

                if (!userSnapshot.hasData || userSnapshot.data == null) {
                  return SizedBox.shrink();
                }

                final userData = userSnapshot.data!;
                return FriendCard(
                  user: userData,
                  key: ValueKey(friendId),
                );
              },
            );
          },
        );
      },
    );
  }
}

class FriendCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const FriendCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[300],
          backgroundImage: user['profileImageUrl'] != null &&
                  user['profileImageUrl'].toString().isNotEmpty
              ? NetworkImage(user['profileImageUrl'])
              : null,
          child: user['profileImageUrl'] == null ||
                  user['profileImageUrl'].toString().isEmpty
              ? Icon(Icons.person, color: Colors.grey[600])
              : null,
        ),
        title: Text(
          '${user['firstName'] ?? 'Unbekannt'} ${user['lastName'] ?? ''}'.trim(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '@${user['username'] ?? 'unbekannt'}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            if ((user['streak'] ?? 0) > 0)
              Text(
                '🔥 ${user['streak']} Tag${user['streak'] == 1 ? '' : 'e'} Streak',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: Colors.grey[400]),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Text('Freund entfernen'),
              onTap: () => FriendActions.removeFriend(context, user),
            ),
          ],
        ),
      ),
    );
  }
}