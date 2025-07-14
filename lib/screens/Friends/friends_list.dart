import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:streax/services/database.dart';
import 'package:streax/screens/friends/profile_view.dart';

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
  bool _isDisposed = false; // Widgetlifecycle Tracking

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!_isDisposed && mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim();
          _filterData();
        });
      }
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
    
  // Filtert Freunde und Anfragen basierend auf der Sucheingabe
  void _filterData() {
    if (_isDisposed) return;
    
    if (_searchQuery.isEmpty) {
      _filteredFriends = List.from(_allFriends);
      _filteredRequests = List.from(_allRequests);
    } else {
      final query = _searchQuery.toLowerCase();
      
      _filteredFriends = _allFriends.where((friend) {
        final name = '${friend['firstName'] ?? ''} ${friend['lastName'] ?? ''}'.toLowerCase();
        final username = (friend['username'] ?? '').toString().toLowerCase();
        return name.contains(query) || username.contains(query);
      }).toList();
      
      _filteredRequests = _allRequests.where((request) {
        final name = '${request['firstName'] ?? ''} ${request['lastName'] ?? ''}'.toLowerCase();
        final username = (request['username'] ?? '').toString().toLowerCase();
        return name.contains(query) || username.contains(query);
      }).toList();
    }
  }

  Future<void> _loadAllData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _isDisposed) return;

    try {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Beide Streams parallel laden
      final results = await Future.wait([
        DatabaseService(uid: currentUser.uid).userFriends.first,
        DatabaseService(uid: currentUser.uid).incomingFriendRequests.first,
      ]);

      if (_isDisposed) return; // Früher Exit wenn Widget disposed

      final friendsSnapshot = results[0];
      final requestsSnapshot = results[1];

      // Freundedaten laden
      List<Map<String, dynamic>> friendsData = [];
      for (var friendDoc in friendsSnapshot.docs) {
        if (_isDisposed) break; // Breche ab wenn Widget disposed
        
        try {
          final friendData = friendDoc.data() as Map<String, dynamic>;
          final friendId = friendData['userId'];
          
          if (friendId != null && friendId.toString().isNotEmpty) {
            final userData = await _getFriendData(friendId);
            if (userData != null && !_isDisposed) {
              friendsData.add(userData);
            }
          }
        } catch (e) {
          print('Fehler beim Laden von Freund: $e');
        }
      }

      // Anfragen-Daten laden
      List<Map<String, dynamic>> requestsData = [];
      for (var requestDoc in requestsSnapshot.docs) {
        if (_isDisposed) break; // Breche ab wenn Widget disposed
        
        try {
          final requestData = requestDoc.data() as Map<String, dynamic>;
          final senderId = requestData['senderId'];
          
          if (senderId != null && senderId.toString().isNotEmpty) {
            final userData = await _getFriendData(senderId);
            if (userData != null && !_isDisposed) {
              requestsData.add(userData);
            }
          }
        } catch (e) {
          print('Fehler beim Laden von Anfrage: $e');
        }
      }

      if (!_isDisposed && mounted) {
        setState(() {
          _allFriends = friendsData;
          _allRequests = requestsData;
          _isLoading = false;
          _filterData();
        });
      }

    } catch (e) {
      print('Fehler beim Laden der Daten: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Sichere Methode zum Laden von Userdaten
  Future<Map<String, dynamic>?> _getFriendData(String friendId) async {
    if (_isDisposed) return null;
    
    try {
      if (friendId.isEmpty) return null;
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .get();
      
      if (doc.exists && doc.data() != null && !_isDisposed) {
        final data = doc.data()!;
        return {
          'uid': friendId,
          'firstName': data['firstName'] ?? 'Unbekannt',
          'lastName': data['lastName'] ?? '',
          'username': data['username'] ?? 'unbekannt',
          'profileImageUrl': data['profileImageUrl'] ?? '',
          'streak': data['streak'] ?? 0,
        };
      }
      return null;
    } catch (e) {
      print('Fehler beim Laden der User-Daten für $friendId: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return Scaffold(
        body: Container(),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header mit Zurück Button
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  // Zurück Button
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (!_isDisposed && mounted) {
                          Navigator.pop(context);
                        }
                      },
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
                                if (!_isDisposed) {
                                  _searchController.clear();
                                  _searchFocusNode.unfocus();
                                }
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

            SizedBox(height: 20),

            // Freundeliste
            Expanded(
              child: _isLoading
                  ? Center(
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
                    )
                  : SingleChildScrollView(
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
                                onComplete: () => _loadAllData(), // Neu laden nach Aktion
                              );
                            }).toList(),
                            
                            SizedBox(height: 32),
                          ],

                          // Freundeliste Titel
                          Text(
                            'Deine Freunde (${_filteredFriends.length})',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),

                          // Freundeliste
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
                                onComplete: () => _loadAllData(), // Neu laden nach Aktion
                              );
                            }).toList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Karte für Freundschaftsanfragen mit Akzeptieren/Ablehnen Buttons
class FriendRequestCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final String currentUserId;
  final VoidCallback onComplete;

  const FriendRequestCard({
    super.key,
    required this.user,
    required this.currentUserId,
    required this.onComplete,
  });

  @override
  State<FriendRequestCard> createState() => _FriendRequestCardState();
}

class _FriendRequestCardState extends State<FriendRequestCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Profilbild mit Tapfunktion
          GestureDetector(
            onTap: _isProcessing ? null : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileView(user: widget.user),
                ),
              );
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.user['profileImageUrl'] != null &&
                      widget.user['profileImageUrl'].toString().isNotEmpty
                  ? NetworkImage(widget.user['profileImageUrl'])
                  : null,
              child: widget.user['profileImageUrl'] == null ||
                      widget.user['profileImageUrl'].toString().isEmpty
                  ? Icon(Icons.person, color: Colors.grey[600], size: 24)
                  : null,
            ),
          ),

          SizedBox(width: 12),

          // Userinfo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${widget.user['firstName'] ?? 'Unbekannt'} ${widget.user['lastName'] ?? ''}'.trim(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    if ((widget.user['streak'] ?? 0) > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🔥 ${widget.user['streak']}',
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
                  '@${widget.user['username'] ?? 'unbekannt'}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),

          if (_isProcessing)
            SizedBox(
              width: 88,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            )
          else ...[
            // Ablehnen Button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () => _declineFriendRequest(),
                icon: Icon(Icons.close, color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
              ),
            ),

            SizedBox(width: 8),

            // Annehmen Button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () => _acceptFriendRequest(),
                icon: Icon(Icons.check, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _acceptFriendRequest() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await DatabaseService(uid: widget.currentUserId)
          .acceptFriendRequest(widget.user['uid']);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Freundschaftsanfrage von ${widget.user['firstName']} angenommen'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onComplete(); // Liste neu laden
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Annehmen der Anfrage'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _declineFriendRequest() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await DatabaseService(uid: widget.currentUserId)
          .declineFriendRequest(widget.user['uid']);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Freundschaftsanfrage von ${widget.user['firstName']} abgelehnt'),
              backgroundColor: Colors.orange,
            ),
          );
          widget.onComplete(); // Liste neu laden
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Ablehnen der Anfrage'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

// Freundkarte für die Slide in Ansicht mit Entfernen-Button
class SlideInFriendCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onComplete;

  const SlideInFriendCard({
    super.key, 
    required this.user, 
    required this.onComplete,
  });

  @override
  State<SlideInFriendCard> createState() => _SlideInFriendCardState();
}

class _SlideInFriendCardState extends State<SlideInFriendCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Profilbild mit Tap-Funktion
          GestureDetector(
            onTap: _isProcessing ? null : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileView(user: widget.user),
                ),
              );
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.user['profileImageUrl'] != null &&
                      widget.user['profileImageUrl'].toString().isNotEmpty
                  ? NetworkImage(widget.user['profileImageUrl'])
                  : null,
              child: widget.user['profileImageUrl'] == null ||
                      widget.user['profileImageUrl'].toString().isEmpty
                  ? Icon(Icons.person, color: Colors.grey[600], size: 24)
                  : null,
            ),
          ),

          SizedBox(width: 12),

          // Userinfo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${widget.user['firstName'] ?? 'Unbekannt'} ${widget.user['lastName'] ?? ''}'.trim(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    if ((widget.user['streak'] ?? 0) > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🔥 ${widget.user['streak']}',
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
                  '@${widget.user['username'] ?? 'unbekannt'}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),

          // Entfernen Button oder Loading
          if (_isProcessing)
            SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.red,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () => _removeFriend(),
                icon: Icon(Icons.person_remove, color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _removeFriend() async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(
          'Freundschaft entfernen',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Möchtest du ${widget.user['firstName']} wirklich als Freund entfernen?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Entfernen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
          .removeFriend(widget.user['uid']);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.user['firstName']} wurde entfernt'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onComplete(); // Liste neu laden
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Entfernen'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}