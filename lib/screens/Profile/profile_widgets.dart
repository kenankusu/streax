import 'package:flutter/material.dart';
import 'package:streax/screens/profile/profile_editing.dart';
import 'package:streax/services/image_service.dart';
import 'package:streax/screens/shared/snackbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

// Profil Header (Avatar, Name, Edit/Share buttons)
class ProfileHeader extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String uid;

  const ProfileHeader({super.key, required this.userData, required this.uid});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  final ImageService _imageService = ImageService();
  bool _isUploading = false;

  // Funktion zum Anzeigen der Bildauswahloptionen
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profilbild ändern'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _updateProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _updateProfileImage(ImageSource.gallery);
                },
              ),
              if (widget.userData['profileImageUrl'] != null &&
                  widget.userData['profileImageUrl'].toString().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Profilbild löschen',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteProfileImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Profilbild aktualisieren
  Future<void> _updateProfileImage(ImageSource source) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final String? newImageUrl = await _imageService.updateProfileImage(
        widget.uid,
        source: source,
      );

      if (newImageUrl != null) {
        // UI wird automatisch aktualisiert wenn userData aktualisiert wird
        SnackBarUtils.showSuccess(
          context,
          'Profilbild erfolgreich aktualisiert!',
        );
      } else {
        // Fehler
        SnackBarUtils.showError(
          context,
          'Fehler beim Aktualisieren des Profilbildes',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'Fehler: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Profilbild löschen
  Future<void> _deleteProfileImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Bild aus Firebase Storage löschen
      await _imageService.deleteProfileImage(widget.uid);

      // URL aus Firestore entfernen
      await _imageService.updateProfileImageUrl(widget.uid, '');

      SnackBarUtils.showSuccess(context, 'Profilbild erfolgreich gelöscht!');
    } catch (e) {
      SnackBarUtils.showError(context, 'Fehler beim Löschen: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Profilbild-URL aus userData oder fallback zu Asset
    final String? profileImageUrl = widget.userData['profileImageUrl'];

    return Column(
      children: [
        GestureDetector(
          onTap: _isUploading ? null : _showImageSourceDialog,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                child: profileImageUrl != null && profileImageUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          profileImageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              width: 100,
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Colors.black38,
                                  size: 35,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        height: 100,
                        width: 100,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.black38,
                            size: 35,
                          ),
                        ),
                      ),
              ),
              if (_isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              if (!_isUploading)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${widget.userData['firstName'] ?? 'Unbekannter'} ${widget.userData['lastName'] ?? 'Name'}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          '@${widget.userData['username'] ?? 'unbekannt'}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                EditProfileDialog.show(context, widget.uid, widget.userData);
              },
            ),
            // Teilenbutton
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {
                final username = widget.userData['username'] ?? 'unbekannt';
                Clipboard.setData(ClipboardData(text: '@$username'));
                SnackBarUtils.showSuccess(
                  context,
                  'Username @$username wurde in die Zwischenablage kopiert',
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

// Profil Info (Streak, Gewicht, Größe etc.)

class ProfileInfo extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileInfo({super.key, required this.userData});

  // Hilfsfunktion für Altersberechnung
  int? _calculateAge(String? birthdateString) {
    if (birthdateString == null) return null;

    final birthdate = DateTime.tryParse(birthdateString);
    if (birthdate == null) return null;

    final now = DateTime.now();
    int age = now.year - birthdate.year;

    // Prüfen ob Geburtstag dieses Jahr schon war
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }

    return age;
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge(userData['birthdate']);

    return Column(
      children: [
        Text(
          "Streax Freunde: ${userData['friends_count'] ?? 0}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          "Dein längster Streak: ${userData['streak_max'] ?? 0}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          "Dein Alter: ${age != null ? '$age Jahre' : 'Fehler beim Berechnen'}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          "Dein Gewicht: ${userData['weight'] != null ? '${userData['weight']} kg' : 'Nicht angegeben'}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          "Deine Größe: ${userData['height'] != null ? '${userData['height']} cm' : 'Nicht angegeben'}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          "Dein Geschlecht: ${userData['gender'] ?? 'Nicht angegeben'}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
