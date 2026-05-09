import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:streax/services/database.dart';
import 'package:streax/shared/constants/theme_constants.dart';
import 'package:streax/shared/constants/sport_utils.dart';

class FeedPreview extends StatefulWidget {
  final String userId;
  const FeedPreview({super.key, required this.userId});

  @override
  State<FeedPreview> createState() => _FeedPreviewState();
}

class _FeedPreviewState extends State<FeedPreview> {
  late final Stream<List<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = DatabaseService(uid: widget.userId).friendActivities;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final activities = (snapshot.data ?? []).take(3).toList();
        if (activities.isEmpty) {
          return Text(
            'Keine neuen Aktivitäten',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < activities.length; i++) ...[
              _FeedCard(activity: activities[i], rank: i + 1),
              if (i < activities.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _FeedCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final int rank;
  const _FeedCard({required this.activity, required this.rank});

  String _timeAgo(dynamic ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference((ts as Timestamp).toDate());
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'jetzt';
  }

  Color _rankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFF0C040);
      case 2:
        return const Color(0xFF6080A0);
      default:
        return const Color(0xFF3A4555);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _avatarAccent() {
    final palette = [kChipPalette[1], kChipPalette[0], kChipPalette[2], kChipPalette[3]];
    return palette[(rank - 1).clamp(0, 3)]['border'] as Color;
  }

  Color _avatarBg() {
    final palette = [kChipPalette[1], kChipPalette[0], kChipPalette[2], kChipPalette[3]];
    return palette[(rank - 1).clamp(0, 3)]['bg'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    final name = activity['userName'] as String? ?? '';
    final caption = activity['title'] as String? ?? '';
    final category = activity['category'] as String? ?? '';
    final photoUrl = (activity['photoUrl'] ?? '').toString();
    final hasPhoto = photoUrl.isNotEmpty;
    final profileUrl = (activity['userProfileImage'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2228)),
      ),
      child: Row(
        children: [
          // Avatar + rank badge
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _avatarBg(),
                  backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                  child: profileUrl.isEmpty
                      ? Text(
                          _initials(name),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: _avatarAccent(),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF1F2228), width: 1.5),
                    ),
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: _rankColor(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          // Body
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFCCCCCC),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(sportEmoji(category), style: const TextStyle(fontSize: 14)),
                    const Spacer(),
                    Text(
                      _timeAgo(activity['timestamp']),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3A4050),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF555555), height: 1.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          // Thumbnail
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _avatarBg(),
              border: Border.all(color: const Color(0xFF252830)),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _emojiThumb(category),
                  )
                : _emojiThumb(category),
          ),
        ],
      ),
    );
  }

  Widget _emojiThumb(String category) {
    return Center(child: Text(sportEmoji(category), style: const TextStyle(fontSize: 22)));
  }
}
