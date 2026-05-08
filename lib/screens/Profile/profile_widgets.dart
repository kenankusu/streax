import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_editing.dart';
import '../../services/image_service.dart';
import '../../utils/snackbar.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _heroBg  = Color(0xFF0D0F11);
const _ringBg  = Color(0xFF161920);
const _btnBg   = Color(0xFF1A1D21);
const _btnLine = Color(0xFF252830);
const _blue    = Color(0xFF2A9FFF);
const _green   = Color(0xFF1CE9B0);
const _orange  = Color(0xFFF0A020);

// ─── Level helpers ────────────────────────────────────────────────────────────
int _getLevel(int streakMax) {
  final xp = streakMax * 10;
  return (xp / 100).floor() + 1;
}

double _getXpProgress(int streakMax) {
  final xp = streakMax * 10;
  return ((xp % 100) / 100.0).clamp(0.0, 1.0);
}

int _getXp(int streakMax)     => streakMax * 10;
int _getNextXp(int streakMax) => (_getLevel(streakMax)) * 100;

String _getRank(int level) {
  if (level >= 9) return 'Legend';
  if (level >= 6) return 'Pro';
  if (level >= 3) return 'Amateur';
  return 'Rookie';
}

// ─── ProfileHeroSection ───────────────────────────────────────────────────────
class ProfileHeroSection extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String uid;

  const ProfileHeroSection({super.key, required this.userData, required this.uid});

  @override
  State<ProfileHeroSection> createState() => _ProfileHeroSectionState();
}

class _ProfileHeroSectionState extends State<ProfileHeroSection> {
  final _imageService = ImageService();
  bool _uploading = false;

  void _showImageDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161920),
        title: Text('Profilbild', style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogTile(Icons.camera_alt_outlined, 'Kamera',  () { Navigator.pop(context); _uploadImage(ImageSource.camera); }),
            _dialogTile(Icons.photo_library_outlined, 'Galerie', () { Navigator.pop(context); _uploadImage(ImageSource.gallery); }),
            if ((widget.userData['profileImageUrl'] ?? '').toString().isNotEmpty)
              _dialogTile(Icons.delete_outline, 'Löschen',   () { Navigator.pop(context); _deleteImage(); }, color: Colors.red.shade400),
          ],
        ),
      ),
    );
  }

  Widget _dialogTile(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? Colors.white70;
    return ListTile(
      leading: Icon(icon, color: c, size: 20),
      title: Text(label, style: GoogleFonts.barlow(color: c, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Future<void> _uploadImage(ImageSource source) async {
    setState(() => _uploading = true);
    try {
      final url = await _imageService.updateProfileImage(widget.uid, source: source);
      if (mounted) {
        url != null
            ? SnackBarUtils.showSuccess(context, 'Profilbild aktualisiert!')
            : SnackBarUtils.showError(context, 'Fehler beim Hochladen');
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Fehler: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteImage() async {
    setState(() => _uploading = true);
    try {
      await _imageService.deleteProfileImage(widget.uid);
      await _imageService.updateProfileImageUrl(widget.uid, '');
      if (mounted) SnackBarUtils.showSuccess(context, 'Profilbild gelöscht');
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Fehler: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl   = (widget.userData['profileImageUrl'] ?? '').toString();
    final firstName  = widget.userData['firstName'] ?? '';
    final lastName   = widget.userData['lastName']  ?? '';
    final username   = widget.userData['username']  ?? '';
    final streakMax  = widget.userData['streak_max'] as int? ?? 0;
    final level      = _getLevel(streakMax);
    final rank       = _getRank(level);
    final xp         = _getXp(streakMax);
    final nextXp     = _getNextXp(streakMax);
    final progress   = _getXpProgress(streakMax);
    final statusBarH = MediaQuery.of(context).padding.top;

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // ── Background ──────────────────────────────────────────────────
          Positioned.fill(child: Container(color: _heroBg)),

          // ── Spotlight radial glow ────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1),
                  radius: 0.9,
                  colors: [Color(0x1F2A9FFF), Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(top: statusBarH + 14, bottom: 24),
            child: Column(
              children: [
                // Avatar
                GestureDetector(
                  onTap: _uploading ? null : _showImageDialog,
                  child: SizedBox(
                    width: 100, height: 100,
                    child: Stack(
                      children: [
                        // Gradient ring
                        Container(
                          width: 100, height: 100,
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [_blue, _green],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _ringBg,
                            ),
                            child: ClipOval(child: _avatarContent(imageUrl)),
                          ),
                        ),
                        // Upload overlay
                        if (_uploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _blue),
                                ),
                              ),
                            ),
                          ),
                        // Camera dot
                        if (!_uploading)
                          Positioned(
                            bottom: 3, right: 3,
                            child: Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [_blue, _green]),
                                border: Border.all(color: _heroBg, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 11, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Level row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B2233),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _blue),
                      ),
                      child: Text('LEVEL',
                          style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: _blue)),
                    ),
                    const SizedBox(width: 8),
                    Text('$level',
                        style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w900, color: _green)),
                  ],
                ),

                const SizedBox(height: 8),

                // Name (first name gradient, last name white)
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      WidgetSpan(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [_blue, _green],
                          ).createShader(bounds),
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            firstName,
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 34, fontWeight: FontWeight.w900,
                              letterSpacing: 0.8, color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (lastName.isNotEmpty)
                        TextSpan(
                          text: ' $lastName',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 34, fontWeight: FontWeight.w900,
                            letterSpacing: 0.8, color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),

                // Handle
                Text(
                  '@$username',
                  style: GoogleFonts.barlow(fontSize: 12, color: const Color(0xFF444444), fontWeight: FontWeight.w600, letterSpacing: 0.4),
                ),

                const SizedBox(height: 14),

                // XP bar
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('XP', style: GoogleFonts.barlow(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: const Color(0xFF3A5A6A))),
                          Text('$xp / $nextXp', style: GoogleFonts.barlow(fontSize: 9, fontWeight: FontWeight.w700, color: _blue)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Stack(
                          children: [
                            Container(height: 3, color: const Color(0xFF1E2228)),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 3,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [_blue, _green]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _heroBtn('Bearbeiten', Icons.edit_outlined,
                        () => EditProfileDialog.show(context, widget.uid, widget.userData)),
                    const SizedBox(width: 10),
                    _heroBtn('Teilen', Icons.share_outlined, () {
                      Clipboard.setData(ClipboardData(text: '@$username'));
                      SnackBarUtils.showSuccess(context, '@$username kopiert');
                    }),
                  ],
                ),
              ],
            ),
          ),

          // ── Floor line ───────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0x4D2A9FFF),
                    Color(0x4D1CE9B0),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Rank badge ───────────────────────────────────────────────────
          Positioned(
            top: statusBarH + 16,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1400),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text(
                    rank.toUpperCase(),
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 11, fontWeight: FontWeight.w900,
                      letterSpacing: 0.8, color: _orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarContent(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: 96, height: 96,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: _blue)),
        errorBuilder: (_, __, ___) => _defaultAvatar(),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() => const Icon(Icons.person, size: 48, color: Color(0x59FFFFFF));

  Widget _heroBtn(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: _btnBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _btnLine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF666666)),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.barlow(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF666666), letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
