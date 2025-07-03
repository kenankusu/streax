import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Shared/navigationbar.dart';
import '../../services/database.dart';
import 'friend_actions.dart';
import 'dart:async';
import 'friends_list.dart';
import 'profile_view.dart';

class Feed extends StatefulWidget {
  const Feed({super.key});

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  Map<String, dynamic>? _exactMatch;
  bool _isSearching = false;
  bool _isAlreadyFriend = false;
  bool _isSearchExpanded = false;
  bool _requestSent = false;
  
  StreamSubscription<QuerySnapshot>? _friendsStreamSubscription;
  
  // Stream wird einmal beim Start erstellt um unnötige Neuladungen zu vermeiden
  Stream<List<Map<String, dynamic>>>? _cachedFeedStream;

  @override
  void initState() {
    super.initState();
    
    // Feed-Stream beim Start initialisieren (wird nicht mehr neugeladen)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _cachedFeedStream = DatabaseService(uid: currentUser.uid).friendActivities;
    }
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
        if (_searchQuery.isNotEmpty) {
          _searchForExactMatch();
        } else {
          _exactMatch = null;
          _isAlreadyFriend = false;
          _requestSent = false;
        }
      });
    });

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchExpanded = _searchFocusNode.hasFocus || _searchQuery.isNotEmpty;
      });
    });

    _setupFriendsListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _friendsStreamSubscription?.cancel();
    super.dispose();
  }

// Überwacht Änderungen in der Freundesliste um zu prüfen ob gesuchte User zu Freunden werden
  void _setupFriendsListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _friendsStreamSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('friends')
        .snapshots()
        .listen((snapshot) {
      if (_exactMatch != null && _searchQuery.isNotEmpty && !_isAlreadyFriend) {
        _checkIfSearchedUserBecameFriend(snapshot);
      }
    });
  }

// Prüft ob der gesuchte User inzwischen Freund geworden ist
  void _checkIfSearchedUserBecameFriend(QuerySnapshot snapshot) {
    if (_exactMatch == null) return;

    final searchedUserId = _exactMatch!['uid'];
    
    final isFriendNow = snapshot.docs.any((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['userId'] == searchedUserId;
    });

    if (isFriendNow && !_isAlreadyFriend) {
      setState(() {
        _isAlreadyFriend = true;
        _requestSent = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_exactMatch!['firstName']} ist jetzt dein Freund! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
// Sucht nach einem User mit exakt diesem Username in der Datenbank
  Future<void> _searchForExactMatch() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isSearching = true;
      _requestSent = false;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: _searchQuery.toLowerCase())
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        
        if (doc.id != currentUser.uid) {
          final friendshipStatus = await _checkFullFriendshipStatus(currentUser.uid, doc.id);
          
          setState(() {
            _exactMatch = {
              'uid': doc.id,
              'username': data['username'] ?? '',
              'firstName': data['firstName'] ?? '',
              'lastName': data['lastName'] ?? '',
              'profileImageUrl': data['profileImageUrl'] ?? '',
              'streak': data['streak'] ?? 0,
            };
            _isAlreadyFriend = friendshipStatus['isFriend'] ?? false;
            _requestSent = friendshipStatus['requestSent'] ?? false;
          });
        } else {
          setState(() {
            _exactMatch = null;
            _isAlreadyFriend = false;
            _requestSent = false;
          });
        }
      } else {
        setState(() {
          _exactMatch = null;
          _isAlreadyFriend = false;
          _requestSent = false;
        });
      }
    } catch (e) {
      print('Fehler bei der Suche: $e');
      setState(() {
        _exactMatch = null;
        _isAlreadyFriend = false;
        _requestSent = false;
      });
    }

    setState(() {
      _isSearching = false;
    });
  }

// Überprüft ob User bereits Freund ist oder eine Anfrage gesendet wurde
  Future<Map<String, bool>> _checkFullFriendshipStatus(String currentUserId, String targetUserId) async {
    try {
      final friendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .where('userId', isEqualTo: targetUserId)
          .get();
      
      if (friendsSnapshot.docs.isNotEmpty) {
        return {'isFriend': true, 'requestSent': false};
      }

      final sentRequestSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('sentRequests')
          .doc(targetUserId)
          .get();
    
      if (sentRequestSnapshot.exists) {
        return {'isFriend': false, 'requestSent': true};
      }

      return {'isFriend': false, 'requestSent': false};
      
    } catch (e) {
      print('Fehler beim Prüfen des vollständigen Freundschafts-Status: $e');
      return {'isFriend': false, 'requestSent': false};
    }
  }

// Berechnet wie lange eine Aktivität her ist (z.B. "2h", "1d")
  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'jetzt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text('Nicht eingeloggt')),
        bottomNavigationBar: const NavigationsLeiste(currentPage: 1),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Hauptinhalt
          Column(
            children: [
              // Header mit Suchfeld und Benachrichtigungs-Button
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Suchfeld mit Gradient-Umrandung
                    Expanded(
                      child: Container(
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
                          child: Column(
                            children: [
                              // Suchfeld
                              Container(
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
                                    hintText: 'Nutzer suchen...',
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
                                                setState(() {
                                                  _searchQuery = '';
                                                  _exactMatch = null;
                                                  _isAlreadyFriend = false;
                                                  _requestSent = false;
                                                });
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
                              // Erweiterte Suchansicht - zeigt Suchergebnisse unter dem Suchfeld an
                              if (_isSearchExpanded && _searchQuery.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                Container(
                                  padding: EdgeInsets.all(16),
                                  child: _isSearching
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Theme.of(context).colorScheme.primary,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Suche nach "$_searchQuery"...',
                                              style: TextStyle(color: Colors.white70, fontSize: 14),
                                            ),
                                          ],
                                        )
                                      : _exactMatch != null
                                          ? Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor: Colors.grey[300],
                                                  backgroundImage: _exactMatch!['profileImageUrl'] != null &&
                                                          _exactMatch!['profileImageUrl'].toString().isNotEmpty
                                                      ? NetworkImage(_exactMatch!['profileImageUrl'])
                                                      : null,
                                                  child: _exactMatch!['profileImageUrl'] == null ||
                                                          _exactMatch!['profileImageUrl'].toString().isEmpty
                                                      ? Icon(Icons.person, color: Colors.grey[600], size: 24)
                                                      : null,
                                                ),
                                                
                                                SizedBox(width: 12),
                                                
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        '${_exactMatch!['firstName']} ${_exactMatch!['lastName']}'.trim(),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        '@${_exactMatch!['username']}',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      if (_exactMatch!['streak'] > 0)
                                                        Text(
                                                          '🔥 ${_exactMatch!['streak']} Tag${_exactMatch!['streak'] == 1 ? '' : 'e'} Streak',
                                                          style: TextStyle(
                                                            color: Theme.of(context).colorScheme.primary,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                
                                                // Dynamischer Button: Freund hinzufügen / Anfrage gesendet / Bereits Freund
                                                Container(
                                                  width: 35,
                                                  height: 35,
                                                  decoration: BoxDecoration(
                                                    gradient: _isAlreadyFriend
                                                        ? LinearGradient(
                                                            colors: [
                                                              Color(0xFF4CAF50),
                                                              Color(0xFF66BB6A),
                                                            ],
                                                            begin: Alignment.centerLeft,
                                                            end: Alignment.centerRight,
                                                          )
                                                        : _requestSent
                                                            ? null
                                                            : LinearGradient(
                                                                colors: [
                                                                  Theme.of(context).colorScheme.primary,
                                                                  Theme.of(context).colorScheme.secondary,
                                                                ],
                                                                begin: Alignment.centerLeft,
                                                                end: Alignment.centerRight,
                                                              ),
                                                    color: _requestSent ? Colors.grey : null,
                                                    borderRadius: BorderRadius.circular(17.5),
                                                    boxShadow: _isAlreadyFriend
                                                        ? [
                                                            BoxShadow(
                                                              color: Color(0xFF4CAF50).withOpacity(0.3),
                                                              blurRadius: 4,
                                                              offset: Offset(0, 2),
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                  child: IconButton(
                                                    onPressed: (_isAlreadyFriend || _requestSent) ? null : () {
                                                      setState(() {
                                                        _requestSent = true;
                                                      });
                                                      
                                                      FriendActions.sendFriendRequest(
                                                        context,
                                                        _exactMatch!,
                                                        () {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Freundschaftsanfrage gesendet!'),
                                                              backgroundColor: Colors.green,
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                    icon: Icon(
                                                      _isAlreadyFriend 
                                                          ? Icons.check 
                                                          : _requestSent 
                                                              ? Icons.hourglass_empty
                                                              : Icons.person_add,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.search_off,
                                                  color: Colors.white70,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Kein User mit diesem Namen gefunden',
                                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                                ),
                                              ],
                                            ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    
                    // Freunde-Button mit Benachrichtigungs-Badge für neue Anfragen
                    StreamBuilder<QuerySnapshot>(
                      stream: DatabaseService(uid: currentUser.uid).incomingFriendRequests,
                      builder: (context, requestSnapshot) {
                        final requestCount = requestSnapshot.hasData ? requestSnapshot.data!.docs.length : 0;
                        
                        return Stack(
                          children: [
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => FriendsSlideInView(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.easeInOutCubic;

                                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                        var offsetAnimation = animation.drive(tween);

                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                      transitionDuration: Duration(milliseconds: 300),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.group,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            // Badge für Anzhal Freundschaftsanfragen
                            if (requestCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.surface,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      requestCount > 99 ? '99+' : requestCount.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: requestCount > 99 ? 8 : 10,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Feed mit Aktivitäten der Freunde
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _cachedFeedStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: colorScheme.primary),
                            SizedBox(height: 16),
                            Text(
                              'Lade Feed...',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                            SizedBox(height: 16),
                            Text(
                              'Fehler beim Laden des Feeds',
                              style: TextStyle(color: Colors.red[400]),
                            ),
                          ],
                        ),
                      );
                    }

                    final activities = snapshot.data ?? [];

                    if (activities.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_outlined,
                                size: 80,
                                color: colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Keine Aktivitäten in den letzten 7 Tagen',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Füge Freunde hinzu, um deinen Feed zu füllen!',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Liste der Aktivitäten anzeigen
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(20, 28, 20, 10),
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return ActivityCard(
                          activity: activity, 
                          timeAgo: _getTimeAgo(activity['timestamp']),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          
          // Navigation Bar am unteren Rand
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: NavigationsLeiste(currentPage: 1),
          ),
        ],
      ),
    );
  }
}

// einzelne Aktivitäten im Feed anzeigen
class ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final String timeAgo;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.timeAgo,
  });

  Widget _buildActivityIcon(String category) {
    switch (category.toLowerCase()) {
      case 'krafttraining':
        return Image.asset('assets/icons/journal/gym.png', width: 36, height: 36);
      case 'laufen':
        return Image.asset('assets/icons/journal/laufen.png', width: 36, height: 36);
      case 'boxen':
        return Image.asset('assets/icons/journal/boxen.png', width: 36, height: 36);
      case 'tischtennis':
        return Image.asset('assets/icons/journal/tt.png', width: 36, height: 36);
      case 'fussball':
        return Image.asset('assets/icons/journal/fussball.png', width: 36, height: 36);
      case 'ruhetag':
        return Image.asset('assets/icons/journal/rest.png', width: 36, height: 36);
      default:
        return Icon(Icons.fitness_center, color: Colors.orange, size: 36);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDescription = activity['description'] != null && 
                          activity['description'].toString().trim().isNotEmpty;
    
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profilbild (anklickbar für Profil-Ansicht)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProfileView(user: {
                        'uid': activity['userId'],
                        'firstName': activity['userName']?.split(' ').first ?? 'Unbekannt',
                        'lastName': activity['userName']?.split(' ').skip(1).join(' ') ?? '',
                        'username': activity['username'],
                        'profileImageUrl': activity['userProfileImage'],
                        'streak': activity['userStreak'],
                      }),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: activity['userProfileImage'] != null &&
                          activity['userProfileImage'].toString().isNotEmpty
                      ? NetworkImage(activity['userProfileImage'])
                      : null,
                  child: activity['userProfileImage'] == null ||
                          activity['userProfileImage'].toString().isEmpty
                      ? Icon(Icons.person, color: Colors.grey[600], size: 24)
                      : null,
                ),
              ),
              
              SizedBox(width: 12),
              
              // User-Infos: Name, Username, Zeit und Streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name und Streak in einer Zeile
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            activity['userName'] ?? 'Unbekannt',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        // Streak-Badge neben dem Namen
                        if ((activity['userStreak'] ?? 0) > 0)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🔥 ${activity['userStreak']}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Username
                    Text(
                      '@${activity['username'] ?? 'unknown'}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                    
                    SizedBox(height: 4),
                    
                    // Zeitstempel
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(width: 12),
              
              // Aktivitäts-Icon und Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildActivityIcon(activity['category'] ?? ''),
                  
                  SizedBox(height: 8),
                  
                  Text(
                    activity['title'] ?? 'Aktivität',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Beschreibung falls vorhanden
        if (hasDescription)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.black.withOpacity(0.1),
            child: Text(
              activity['description'].toString().trim(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        
        SizedBox(height: 16),
        
        // Gradient-Trennlinie
        Container(
          height: 1,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                Colors.transparent,
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        
        SizedBox(height: 16),
      ],
    );
  }
}
