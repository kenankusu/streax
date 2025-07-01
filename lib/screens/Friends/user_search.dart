import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database.dart';
import 'friend_actions.dart';

class UserSearchTab extends StatefulWidget {
  const UserSearchTab({super.key});

  @override
  State<UserSearchTab> createState() => _UserSearchTabState();
}

class _UserSearchTabState extends State<UserSearchTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Suche nach Benutzern basierend auf Username
  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query.trim();
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThan: query.toLowerCase() + '\uf8ff')
          .limit(10)
          .get();

      List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (doc.id != currentUser.uid) {
          results.add({
            'uid': doc.id,
            'username': data['username'] ?? 'Unbekannt',
            'firstName': data['firstName'] ?? 'Unbekannt',
            'lastName': data['lastName'] ?? '',
            'profileImageUrl': data['profileImageUrl'] ?? '',
            'streak': data['streak'] ?? 0,
          });
        }
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Fehler bei der Benutzersuche: $e');
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Suchfeld
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nach Username suchen...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: () {
                        _searchController.clear();
                        _searchUsers('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              setState(() {});
              _searchUsers(value);
            },
          ),
        ),

        // Suchergebnisse
        Expanded(child: _buildSearchContent()),
      ],
    );
  }

  Widget _buildSearchContent() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            SizedBox(height: 16),
            Text(
              'Suche nach "$_searchQuery"...',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          return UserSearchCard(
            user: user,
            onSearchUpdate: () => _searchUsers(_searchQuery),
          );
        },
      );
    }

    if (_searchQuery.isNotEmpty && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Keine Benutzer gefunden',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Suche nach Freunden',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gib einen Username ein um zu suchen',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// User-Suchkarte mit dynamischem Button
class UserSearchCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onSearchUpdate;

  const UserSearchCard({
    super.key,
    required this.user,
    required this.onSearchUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Container();

    return FutureBuilder<String>(
      future: DatabaseService(uid: currentUser.uid).getFriendshipStatus(user['uid']),
      builder: (context, statusSnapshot) {
        final status = statusSnapshot.data ?? 'none';

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          color: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Profilbild
                CircleAvatar(
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

                SizedBox(width: 12),

                // Benutzerinfo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user['firstName']} ${user['lastName']}'.trim(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${user['username']}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                      if (user['streak'] > 0)
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
                ),

                // Action Button basierend auf Status
                ActionButton(
                  user: user,
                  status: status,
                  onActionComplete: onSearchUpdate,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}