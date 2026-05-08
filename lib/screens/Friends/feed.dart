import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Shared/navigationbar.dart';
import '../../services/database.dart';
import 'friend_actions.dart';
import 'dart:async';
import 'friends_list.dart';
import 'profile_view.dart';
import '../../utils/sport_utils.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg       = Color(0xFF111214);
const _card     = Color(0xFF161920);
const _cardLine = Color(0xFF1A1D21);
const _border   = Color(0xFF252830);
const _blue     = Color(0xFF2A9FFF);
const _green    = Color(0xFF1CE9B0);
const _fire     = Color(0xFFFF6030);
const _hard     = Color(0xFFFF4455);
const _mid      = Color(0xFFF0A020);

// ─── Feed screen ──────────────────────────────────────────────────────────────
class Feed extends StatefulWidget {
  const Feed({super.key});
  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  Map<String, dynamic>? _exactMatch;
  bool _isSearching = false;
  bool _isAlreadyFriend = false;
  bool _isSearchExpanded = false;
  bool _requestSent = false;

  StreamSubscription<QuerySnapshot>? _friendsSub;
  Stream<List<Map<String, dynamic>>>? _feedStream;
  String _myProfileUrl = '';
  String _myName = '';

  @override
  void initState() {
    super.initState();
    final me = FirebaseAuth.instance.currentUser;
    if (me != null) {
      _feedStream = DatabaseService(uid: me.uid).friendActivities.asBroadcastStream();
    }
    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text.trim();
        if (_query.isNotEmpty) {
          _searchForMatch();
        } else {
          _exactMatch = null; _isAlreadyFriend = false; _requestSent = false;
        }
      });
    });
    _searchFocus.addListener(() {
      setState(() => _isSearchExpanded = _searchFocus.hasFocus || _query.isNotEmpty);
    });
    _setupFriendsListener();
    _loadMyProfile();
  }

  Future<void> _loadMyProfile() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final data = await DatabaseService(uid: me.uid).getFriendData(me.uid);
    if (data != null && mounted) {
      setState(() {
        _myProfileUrl = data['profileImageUrl'] ?? '';
        _myName = '${data['firstName']} ${data['lastName']}'.trim();
      });
    }
  }

  void _setupFriendsListener() {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    _friendsSub = FirebaseFirestore.instance
        .collection('users').doc(me.uid).collection('friends')
        .snapshots().listen((snap) {
      if (_exactMatch != null && _query.isNotEmpty && !_isAlreadyFriend) {
        final id = _exactMatch!['uid'];
        final now = snap.docs.any((d) => (d.data() as Map)['userId'] == id);
        if (now) setState(() { _isAlreadyFriend = true; _requestSent = false; });
      }
    });
  }

  Future<void> _searchForMatch() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    setState(() { _isSearching = true; _requestSent = false; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').where('username', isEqualTo: _query.toLowerCase()).get();
      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        if (doc.id != me.uid) {
          final status = await _checkFriendship(me.uid, doc.id);
          final d = doc.data();
          setState(() {
            _exactMatch = {
              'uid': doc.id, 'username': d['username'] ?? '',
              'firstName': d['firstName'] ?? '', 'lastName': d['lastName'] ?? '',
              'profileImageUrl': d['profileImageUrl'] ?? '', 'streak': d['streak'] ?? 0,
            };
            _isAlreadyFriend = status['isFriend'] ?? false;
            _requestSent     = status['requestSent'] ?? false;
          });
        } else { setState(() { _exactMatch = null; _isAlreadyFriend = false; _requestSent = false; }); }
      } else { setState(() { _exactMatch = null; _isAlreadyFriend = false; _requestSent = false; }); }
    } catch (_) { setState(() { _exactMatch = null; }); }
    setState(() => _isSearching = false);
  }

  Future<Map<String, bool>> _checkFriendship(String myId, String theirId) async {
    try {
      final f = await FirebaseFirestore.instance
          .collection('users').doc(myId).collection('friends')
          .where('userId', isEqualTo: theirId).get();
      if (f.docs.isNotEmpty) return {'isFriend': true, 'requestSent': false};
      final s = await FirebaseFirestore.instance
          .collection('users').doc(myId).collection('sentRequests').doc(theirId).get();
      if (s.exists) return {'isFriend': false, 'requestSent': true};
      return {'isFriend': false, 'requestSent': false};
    } catch (_) { return {'isFriend': false, 'requestSent': false}; }
  }

  String _timeAgo(Timestamp ts) {
    final d = DateTime.now().difference(ts.toDate());
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return 'jetzt';
  }

  @override
  void dispose() {
    _searchCtrl.dispose(); _searchFocus.dispose(); _friendsSub?.cancel();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: Text('Nicht eingeloggt', style: TextStyle(color: Colors.white))),
        bottomNavigationBar: NavigationsLeiste(currentPage: 1),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────────
                _buildTopBar(context, me.uid),

                // ── Leaderboard ───────────────────────────────────────────────
                _buildLeaderboard(me.uid),

            // ── Divider ───────────────────────────────────────────────────
            Container(height: 1, color: const Color(0xFF1A1D21), margin: const EdgeInsets.fromLTRB(18, 0, 18, 14)),

            // ── Feed list ────────────────────────────────────────────────
            Expanded(child: _buildFeed(context, me.uid)),
          ],
        ),
      ),
          const Positioned(
            bottom: 0, left: 0, right: 0,
            child: NavigationsLeiste(currentPage: 1),
          ),
        ],
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, String uid) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Row(
        children: [
          // Search box
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D21),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      style: GoogleFonts.barlow(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF444444), size: 18),
                        hintText: 'Nutzer suchen…',
                        hintStyle: GoogleFonts.barlow(color: const Color(0xFF444444), fontSize: 13),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Color(0xFF555555), size: 16),
                                onPressed: () {
                                  _searchCtrl.clear(); _searchFocus.unfocus();
                                  setState(() { _query = ''; _exactMatch = null; _isAlreadyFriend = false; _requestSent = false; });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  // Search result dropdown
                  if (_isSearchExpanded && _query.isNotEmpty) ...[
                    Container(height: 1, color: _border),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: _isSearching
                          ? Row(children: [
                              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _blue, strokeWidth: 2)),
                              const SizedBox(width: 10),
                              Text('Suche nach "$_query"…', style: GoogleFonts.barlow(color: const Color(0xFF666666), fontSize: 12)),
                            ])
                          : _exactMatch != null
                              ? _buildSearchResult()
                              : Row(children: [
                                  const Icon(Icons.search_off, color: Color(0xFF444444), size: 16),
                                  const SizedBox(width: 8),
                                  Text('Kein User gefunden', style: GoogleFonts.barlow(color: const Color(0xFF444444), fontSize: 12)),
                                ]),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Friends button (gradient, kept same behavior)
          StreamBuilder<QuerySnapshot>(
            stream: DatabaseService(uid: uid).incomingFriendRequests,
            builder: (context, snap) {
              final count = snap.hasData ? snap.data!.docs.length : 0;
              return Stack(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_blue, _green]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).push(PageRouteBuilder(
                        pageBuilder: (_, __, ___) => FriendsSlideInView(),
                        transitionsBuilder: (_, anim, __, child) => SlideTransition(
                          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                              .chain(CurveTween(curve: Curves.easeInOutCubic)).animate(anim),
                          child: child,
                        ),
                        transitionDuration: const Duration(milliseconds: 300),
                      )),
                      icon: const Icon(Icons.group, color: Colors.white, size: 20),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: -2, top: -2,
                      child: Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle,
                          border: Border.all(color: _bg, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: GoogleFonts.barlow(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
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
    );
  }

  Widget _buildSearchResult() {
    final m = _exactMatch!;
    final imgUrl = m['profileImageUrl']?.toString() ?? '';
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: _border,
          backgroundImage: imgUrl.isNotEmpty ? NetworkImage(imgUrl) : null,
          child: imgUrl.isEmpty ? const Icon(Icons.person, color: Colors.white54, size: 18) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${m['firstName']} ${m['lastName']}'.trim(),
                  style: GoogleFonts.barlow(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              Text('@${m['username']}',
                  style: GoogleFonts.barlow(color: const Color(0xFF555555), fontSize: 11)),
            ],
          ),
        ),
        GestureDetector(
          onTap: (_isAlreadyFriend || _requestSent) ? null : () {
            setState(() => _requestSent = true);
            FriendActions.sendFriendRequest(context, m, () {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: _isAlreadyFriend
                  ? const LinearGradient(colors: [Color(0xFF1CE9B0), Color(0xFF0DB070)])
                  : _requestSent
                      ? null
                      : const LinearGradient(colors: [_blue, _green]),
              color: _requestSent ? _border : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _isAlreadyFriend ? 'Freund ✓' : _requestSent ? 'Gesendet' : '+ Folgen',
              style: GoogleFonts.barlow(
                color: _requestSent ? const Color(0xFF555555) : Colors.white,
                fontSize: 11, fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Leaderboard ────────────────────────────────────────────────────────────
  Widget _buildLeaderboard(String myUid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _feedStream,
      builder: (context, snap) {
        // Collect unique friends from feed to populate leaderboard
        final activities = snap.data ?? [];
        final seen = <String>{};
        final players = <Map<String, dynamic>>[];
        for (final a in activities) {
          final uid = a['userId'] as String? ?? '';
          if (uid.isNotEmpty && !seen.contains(uid)) {
            seen.add(uid);
            players.add({
              'uid': uid,
              'name': (a['userName'] ?? '').toString().split(' ').first,
              'initials': _initials(a['userName'] ?? ''),
              'profileImageUrl': a['userProfileImage'] ?? '',
              'streak': a['userStreak'] ?? 0,
            });
            if (players.length >= 4) break;
          }
        }
        // Add "me" slot
        players.add({'uid': myUid, 'name': 'Du', 'initials': 'Du', 'profileImageUrl': _myProfileUrl, 'streak': 0, 'isMe': true});

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 0, 14),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: players.asMap().entries.map((e) {
                      final rank = e.key + 1;
                      final p    = e.value;
                      final isMe = p['isMe'] == true;
                      return _lbPlayer(rank: rank, p: p, isMe: isMe);
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D21),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: const Icon(Icons.chevron_right, color: Color(0xFF555555), size: 18),
              ),
              const SizedBox(width: 18),
            ],
          ),
        );
      },
    );
  }

  Widget _lbPlayer({required int rank, required Map p, required bool isMe}) {
    final imgUrl = p['profileImageUrl']?.toString() ?? '';

    Color borderColor;
    Color bgColor;
    Color textColor;
    Color pipBg;
    Color pipText;

    if (isMe) {
      borderColor = _blue; bgColor = const Color(0xFF0B2233); textColor = _blue;
      pipBg = _blue; pipText = Colors.white;
    } else if (rank == 1) {
      borderColor = const Color(0xFFF0C040); bgColor = const Color(0xFF1A1400); textColor = const Color(0xFFF0C040);
      pipBg = const Color(0xFFF0C040); pipText = const Color(0xFF1A1000);
    } else if (rank == 2) {
      borderColor = const Color(0xFF8090A8); bgColor = const Color(0xFF141820); textColor = const Color(0xFF8090A8);
      pipBg = const Color(0xFF6080A0); pipText = Colors.white;
    } else if (rank == 3) {
      borderColor = const Color(0xFFC07840); bgColor = const Color(0xFF1A1008); textColor = const Color(0xFFC07840);
      pipBg = const Color(0xFFC07840); pipText = Colors.white;
    } else {
      borderColor = _border; bgColor = const Color(0xFF181B1F); textColor = const Color(0xFF444444);
      pipBg = _border; pipText = const Color(0xFF555555);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: ClipOval(
                  child: imgUrl.isNotEmpty
                      ? Image.network(imgUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _lbInitials(p['initials'] ?? '?', textColor))
                      : _lbInitials(p['initials'] ?? '?', textColor),
                ),
              ),
              Positioned(
                bottom: -4, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: pipBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _bg, width: 1.5),
                    ),
                    child: Text(
                      '$rank',
                      style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w900, color: pipText, height: 1.2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (p['name'] ?? '').toString().length > 6 ? '${p['name'].toString().substring(0, 5)}…' : (p['name'] ?? ''),
            style: GoogleFonts.barlow(
              fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4,
              color: isMe ? _blue : const Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lbInitials(String initials, Color color) => Center(
    child: Text(initials.length > 2 ? initials.substring(0, 2) : initials,
        style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
  );

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  // ── Feed ───────────────────────────────────────────────────────────────────
  Widget _buildFeed(BuildContext context, String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _feedStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: _blue, strokeWidth: 2));
        }
        if (snap.hasError) {
          return Center(child: Text('Fehler beim Laden', style: GoogleFonts.barlow(color: Colors.red.shade400)));
        }
        final acts = snap.data ?? [];
        if (acts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_outlined, size: 64, color: Color(0xFF252830)),
                const SizedBox(height: 16),
                Text('Keine Aktivitäten', style: GoogleFonts.barlow(color: const Color(0xFF444444), fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Füge Freunde hinzu!', style: GoogleFonts.barlow(color: const Color(0xFF333333), fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          itemCount: acts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => ActivityCard(
            activity: acts[i],
            timeAgo: _timeAgo(acts[i]['timestamp']),
            currentUserId: uid,
            currentUserProfileUrl: _myProfileUrl,
            currentUserName: _myName,
          ),
        );
      },
    );
  }
}

// ─── Activity card ────────────────────────────────────────────────────────────
class ActivityCard extends StatefulWidget {
  final Map<String, dynamic> activity;
  final String timeAgo;
  final String currentUserId;
  final String currentUserProfileUrl;
  final String currentUserName;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.timeAgo,
    required this.currentUserId,
    required this.currentUserProfileUrl,
    required this.currentUserName,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  late bool _liked;
  late int  _likeCount;
  late List<Map<String, dynamic>> _likers;
  bool _processing = false;

  @override
  void initState() { super.initState(); _sync(); }

  @override
  void didUpdateWidget(ActivityCard old) {
    super.didUpdateWidget(old);
    if (old.activity != widget.activity) _sync();
  }

  void _sync() {
    _liked     = (widget.activity['likedBy'] as List? ?? []).contains(widget.currentUserId);
    _likeCount = widget.activity['likeCount'] as int? ?? 0;
    _likers    = List<Map<String, dynamic>>.from(widget.activity['likedByProfiles'] ?? []);
  }

  Future<void> _toggleLike() async {
    if (_processing) return;
    final was = _liked;
    setState(() {
      _processing = true; _liked = !was;
      if (was) {
        _likeCount = (_likeCount - 1).clamp(0, 999999);
        _likers.removeWhere((p) => p['uid'] == widget.currentUserId);
      } else {
        _likeCount++;
        if (_likers.length < 4) _likers.add({'uid': widget.currentUserId, 'profileImageUrl': widget.currentUserProfileUrl, 'name': widget.currentUserName});
      }
    });
    try {
      await DatabaseService(uid: widget.currentUserId).likeActivity(
        ownerId: widget.activity['userId'], activityId: widget.activity['activityId'],
        currentlyLiked: was, currentUserId: widget.currentUserId,
        profileImageUrl: widget.currentUserProfileUrl, displayName: widget.currentUserName,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() { _liked = was; _likeCount = was ? _likeCount + 1 : (_likeCount - 1).clamp(0, 999999); });
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _repost() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title: Text('Reposten?', style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Dieser Post wird deinen Freunden angezeigt.', style: GoogleFonts.barlow(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _blue),
            child: const Text('Reposten'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await DatabaseService(uid: widget.currentUserId).repostActivity(widget.activity);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Repost erfolgreich!'), backgroundColor: Colors.green));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fehler beim Reposten'), backgroundColor: Colors.red));
    }
  }

  void _showLikesDialog() {
    final likedBy = List<String>.from(widget.activity['likedBy'] ?? []);
    if (likedBy.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FutureBuilder<List<Map<String, dynamic>?>>(
        future: Future.wait(likedBy.map((uid) => DatabaseService(uid: widget.currentUserId).getFriendData(uid))),
        builder: (_, snap) {
          final users = snap.data?.whereType<Map<String, dynamic>>().toList() ?? [];
          return Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('${likedBy.length} ${likedBy.length == 1 ? 'Like' : 'Likes'}',
                style: GoogleFonts.barlowCondensed(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 8),
            if (!snap.hasData)
              const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: _blue, strokeWidth: 2))
            else
              Flexible(child: ListView.builder(
                shrinkWrap: true, itemCount: users.length,
                itemBuilder: (_, i) {
                  final u = users[i];
                  final img = (u['profileImageUrl'] ?? '').toString();
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: img.isNotEmpty ? NetworkImage(img) : null,
                      child: img.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    title: Text('${u['firstName']} ${u['lastName']}'.trim(), style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text('@${u['username'] ?? ''}', style: GoogleFonts.barlow(color: const Color(0xFF555555))),
                  );
                },
              )),
            const SizedBox(height: 16),
          ]);
        },
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _stackedAvatars() {
    final profiles = _likers.take(4).toList();
    const double sz = 20;
    const double overlap = 13;
    if (profiles.isEmpty) return const SizedBox.shrink();
    final double width = profiles.length * overlap + (sz - overlap);
    return SizedBox(
      width: width, height: sz,
      child: Stack(
        children: profiles.asMap().entries.map((e) {
          final img = (e.value['profileImageUrl'] ?? '').toString();
          return Positioned(
            left: e.key * overlap,
            child: Container(
              width: sz, height: sz,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _card, width: 1.5)),
              child: ClipOval(
                child: img.isNotEmpty
                    ? Image.network(img, fit: BoxFit.cover)
                    : Container(color: const Color(0xFF333333), child: const Icon(Icons.person, size: 11, color: Colors.white54)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _sportBorderColor(String sport) {
    switch (sport.toLowerCase()) {
      case 'laufen':        return const Color(0xFF0E5040);
      case 'radfahren':     return const Color(0xFF1A4A6A);
      case 'krafttraining': return const Color(0xFF3A2060);
      case 'boxen':         return const Color(0xFF6A2020);
      default:              return _border;
    }
  }

  Color _sportBgColor(String sport) {
    switch (sport.toLowerCase()) {
      case 'laufen':        return const Color(0xFF0B2620);
      case 'radfahren':     return const Color(0xFF0B2233);
      case 'krafttraining': return const Color(0xFF1A1030);
      case 'boxen':         return const Color(0xFF2A1010);
      default:              return const Color(0xFF1A1D21);
    }
  }

  Color _sportTextColor(String sport) {
    switch (sport.toLowerCase()) {
      case 'laufen':        return _green;
      case 'radfahren':     return _blue;
      case 'krafttraining': return const Color(0xFF9070E0);
      case 'boxen':         return const Color(0xFFE05050);
      default:              return const Color(0xFF888888);
    }
  }

  Color _intensityColor(String? intensity) {
    switch (intensity) { case 'hard': return _hard; case 'mid': return _mid; default: return _green; }
  }

  int _intensityDots(String? intensity) {
    switch (intensity) { case 'hard': return 3; case 'mid': return 2; default: return 1; }
  }

  String _intensityLabel(String? intensity) {
    switch (intensity) { case 'hard': return 'Hart'; case 'mid': return 'Moderat'; default: return 'Locker'; }
  }

  String _moodEmoji(dynamic emojiVal) {
    final i = int.tryParse('$emojiVal') ?? 3;
    const emojis = ['😢', '😕', '😐', '🙂', '😄'];
    return emojis[((i - 1).clamp(0, 4))];
  }

  String _moodLabel(dynamic emojiVal) {
    final i = int.tryParse('$emojiVal') ?? 3;
    const labels = ['Schlecht', 'Mäßig', 'Ok', 'Gut', 'Top'];
    return labels[((i - 1).clamp(0, 4))];
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final a         = widget.activity;
    final sport     = (a['category'] ?? a['option'] ?? '').toString();
    final hasPhoto  = (a['photoUrl'] ?? '').toString().isNotEmpty;
    final hasCaption = (a['description'] ?? a['text'] ?? '').toString().trim().isNotEmpty;
    final caption   = (a['description'] ?? a['text'] ?? '').toString().trim();
    final isRepost  = a['isRepost'] == true;
    final intensity = a['intensity'] as String?;
    final dauer     = a['dauer'];
    final distanz   = a['distanz'];
    final imgUrl    = (a['userProfileImage'] ?? '').toString();
    final streak    = (a['userStreak'] ?? 0) as int;
    final moodVal   = a['emoji'];

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardLine),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Repost header ─────────────────────────────────────────────
            if (isRepost)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, size: 12, color: Color(0xFF3A4050)),
                    const SizedBox(width: 6),
                    Text('Repost von ${a['userName'] ?? ''}',
                        style: GoogleFonts.barlow(fontSize: 11, color: const Color(0xFF3A4050), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),

            // ── Card header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  // Avatar + streak pip
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProfileView(user: {
                            'uid': a['userId'], 'firstName': (a['userName'] ?? '').toString().split(' ').first,
                            'lastName': (a['userName'] ?? '').toString().split(' ').skip(1).join(' '),
                            'username': a['username'], 'profileImageUrl': a['userProfileImage'], 'streak': a['userStreak'],
                          }),
                        )),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, color: _border,
                            border: Border.all(color: const Color(0xFF2A2D33), width: 1.5),
                          ),
                          child: ClipOval(
                            child: imgUrl.isNotEmpty
                                ? Image.network(imgUrl, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white38, size: 20))
                                : const Icon(Icons.person, color: Colors.white38, size: 20),
                          ),
                        ),
                      ),
                      if (streak > 0)
                        Positioned(
                          bottom: -3, right: -3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A0800),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _card, width: 1.5),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Text('🔥', style: TextStyle(fontSize: 8)),
                              Text('$streak',
                                  style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w900, color: _fire, height: 1.2)),
                            ]),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 10),

                  // Name + handle + time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['userName'] ?? 'Unbekannt',
                            style: GoogleFonts.barlow(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFDDDDDD))),
                        Row(children: [
                          Text('@${a['username'] ?? ''}',
                              style: GoogleFonts.barlow(fontSize: 10, color: const Color(0xFF444444), fontWeight: FontWeight.w600)),
                          const SizedBox(width: 5),
                          Container(width: 2, height: 2, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF333333))),
                          const SizedBox(width: 5),
                          Text(widget.timeAgo,
                              style: GoogleFonts.barlow(fontSize: 10, color: const Color(0xFF444444), fontWeight: FontWeight.w600)),
                        ]),
                      ],
                    ),
                  ),

                  // Sport badge + intensity
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sport.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: _sportBgColor(sport),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _sportBorderColor(sport)),
                          ),
                          child: Text(
                            '${sportEmoji(sport)} ${sport.length > 8 ? sport.substring(0, 7) : sport}',
                            style: GoogleFonts.barlow(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: _sportTextColor(sport)),
                          ),
                        ),
                      if (intensity != null) ...[
                        const SizedBox(height: 5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...List.generate(3, (i) => Container(
                              width: 5, height: 5,
                              margin: const EdgeInsets.only(right: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < _intensityDots(intensity) ? _intensityColor(intensity) : _border,
                              ),
                            )),
                            const SizedBox(width: 4),
                            Text(
                              _intensityLabel(intensity),
                              style: GoogleFonts.barlow(fontSize: 9, fontWeight: FontWeight.w700, color: _intensityColor(intensity)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Image / stats banner ──────────────────────────────────────
            if (hasPhoto || dauer != null || distanz != null)
              Stack(
                children: [
                  // Image or placeholder
                  SizedBox(
                    width: double.infinity,
                    height: hasPhoto
                        ? (MediaQuery.of(context).size.width - 36)
                        : 90,
                    child: hasPhoto
                        ? Image.network(a['photoUrl'], fit: BoxFit.cover,
                            loadingBuilder: (_, child, p) => p == null ? child
                                : Container(color: const Color(0xFF13161A), child: const Center(child: CircularProgressIndicator(color: _blue, strokeWidth: 2))),
                            errorBuilder: (_, __, ___) => _placeholderImg(sport))
                        : _placeholderImg(sport),
                  ),
                  // Stats overlay
                  if (dauer != null || distanz != null)
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xBF000000)],
                          ),
                        ),
                        child: Row(children: [
                          if (distanz != null) ...[
                            _statChip('$distanz', 'km'),
                            const SizedBox(width: 16),
                          ],
                          if (dauer != null) ...[
                            _statChip('$dauer', 'min'),
                            const SizedBox(width: 16),
                          ],
                          if (distanz != null && dauer != null) ...[
                            () {
                              final km = double.tryParse('$distanz') ?? 0;
                              final min = double.tryParse('$dauer') ?? 0;
                              if (km > 0 && min > 0) {
                                final pace = min / km;
                                final paceMin = pace.floor();
                                final paceSec = ((pace - paceMin) * 60).round();
                                return _statChip('$paceMin:${paceSec.toString().padLeft(2, '0')}', 'min/km');
                              }
                              return const SizedBox.shrink();
                            }(),
                          ],
                        ]),
                      ),
                    ),
                ],
              ),

            // ── Caption + mood ────────────────────────────────────────────
            if (hasCaption || moodVal != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 9, 14, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: hasCaption
                          ? _buildCaption(caption, a)
                          : const SizedBox.shrink(),
                    ),
                    if (moodVal != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2228),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _border),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(_moodEmoji(moodVal), style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(_moodLabel(moodVal),
                              style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF666666), letterSpacing: 0.4)),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),

            // ── Location placeholder ──────────────────────────────────────
            const SizedBox(height: 10),

            // ── Action bar ────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _cardLine)),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  // Like
                  Expanded(
                    child: GestureDetector(
                      onTap: _processing ? null : _toggleLike,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _liked ? Icons.favorite : Icons.favorite_border,
                              size: 14, color: _liked ? _hard : const Color(0xFF444444),
                            ),
                            const SizedBox(width: 5),
                            Text('Like',
                                style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5, color: _liked ? _hard : const Color(0xFF444444))),
                            if (_likeCount > 0) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: _showLikesDialog,
                                child: Row(
                                  children: [
                                    _stackedAvatars(),
                                    if (_likers.isNotEmpty) const SizedBox(width: 4),
                                    Text('$_likeCount',
                                        style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700,
                                            color: _liked ? _hard : const Color(0xFF555555))),
                                  ],
                                ),
                              ),
                              // Erweiterte Suchansicht - zeigt Suchergebnisse unter dem Suchfeld an
                              if (_isSearchExpanded &&
                                  _searchQuery.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                Container(
                                  padding: EdgeInsets.all(16),
                                  child: _isSearching
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Suche nach "$_searchQuery"...',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        )
                                      : _exactMatch != null
                                      ? Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Colors.grey[300],
                                              backgroundImage:
                                                  _exactMatch!['profileImageUrl'] !=
                                                          null &&
                                                      _exactMatch!['profileImageUrl']
                                                          .toString()
                                                          .isNotEmpty
                                                  ? NetworkImage(
                                                      _exactMatch!['profileImageUrl'],
                                                    )
                                                  : null,
                                              child:
                                                  _exactMatch!['profileImageUrl'] ==
                                                          null ||
                                                      _exactMatch!['profileImageUrl']
                                                          .toString()
                                                          .isEmpty
                                                  ? Icon(
                                                      Icons.person,
                                                      color: Colors.grey[600],
                                                      size: 24,
                                                    )
                                                  : null,
                                            ),

                                            SizedBox(width: 12),

                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${_exactMatch!['firstName']} ${_exactMatch!['lastName']}'
                                                        .trim(),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    '@${_exactMatch!['username']}',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  if (_exactMatch!['streak'] >
                                                      0)
                                                    Text(
                                                      '🔥 ${_exactMatch!['streak']} Tag${_exactMatch!['streak'] == 1 ? '' : 'e'} Streak',
                                                      style: TextStyle(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w500,
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
                                                        begin: Alignment
                                                            .centerLeft,
                                                        end: Alignment
                                                            .centerRight,
                                                      )
                                                    : _requestSent
                                                    ? null
                                                    : LinearGradient(
                                                        colors: [
                                                          Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .secondary,
                                                        ],
                                                        begin: Alignment
                                                            .centerLeft,
                                                        end: Alignment
                                                            .centerRight,
                                                      ),
                                                color: _requestSent
                                                    ? Colors.grey
                                                    : null,
                                                borderRadius:
                                                    BorderRadius.circular(17.5),
                                                boxShadow: _isAlreadyFriend
                                                    ? [
                                                        BoxShadow(
                                                          color: Color(
                                                            0xFF4CAF50,
                                                          ).withOpacity(0.3),
                                                          blurRadius: 4,
                                                          offset: Offset(0, 2),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: IconButton(
                                                onPressed:
                                                    (_isAlreadyFriend ||
                                                        _requestSent)
                                                    ? null
                                                    : () {
                                                        setState(() {
                                                          _requestSent = true;
                                                        });

                                                        FriendActions.sendFriendRequest(
                                                          context,
                                                          _exactMatch!,
                                                          () {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Freundschaftsanfrage gesendet!',
                                                                ),
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.search_off,
                                              color: Colors.white70,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Kein User mit diesem Namen gefunden',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
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
                  ),

                  Container(width: 1, height: 32, color: _cardLine),

                  // Repost
                  Expanded(
                    child: GestureDetector(
                      onTap: _repost,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.repeat, size: 14, color: Color(0xFF444444)),
                            const SizedBox(width: 5),
                            Text('Reposten',
                                style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5, color: const Color(0xFF444444))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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

  Widget _buildCaption(String text, Map<String, dynamic> activity) {
    final mentions = (activity['mentions'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final confirmedUsernames = mentions.map((m) => m['username'] as String? ?? '').toSet();

    final spans = <InlineSpan>[];
    final regex = RegExp(r'@(\w+)');
    int last = 0;
    final baseStyle = GoogleFonts.barlow(fontSize: 12, color: const Color(0xFF777777), height: 1.4);

    for (final m in regex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: baseStyle));
      }
      final isTagged = confirmedUsernames.contains(m.group(1));
      spans.add(TextSpan(
        text: m.group(0),
        style: baseStyle.copyWith(
          color: isTagged ? const Color(0xFF2A9FFF) : const Color(0xFF2A9FFF).withValues(alpha: 0.55),
          fontWeight: FontWeight.w700,
        ),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: baseStyle));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _statChip(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
      Text(label, style: GoogleFonts.barlow(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: Colors.white54)),
    ],
  );

  Widget _placeholderImg(String sport) => Container(
    color: const Color(0xFF13161A),
    alignment: Alignment.center,
    child: Text(sportEmoji(sport), style: const TextStyle(fontSize: 48, color: Color(0xFF0F1215))),
  );
}
